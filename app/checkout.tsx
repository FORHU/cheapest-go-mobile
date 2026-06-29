import { useLocalSearchParams, useRouter } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { AlertTriangle, ArrowLeft, Check, CheckCircle, Mail } from 'lucide-react-native';
import React, { useCallback, useEffect, useRef, useState } from 'react';
import {
    ActivityIndicator, Alert, Image, KeyboardAvoidingView,
    Platform, Pressable, ScrollView, StyleSheet, Text, TextInput,
    useColorScheme, View
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useSettings } from '../context/SettingsContext';
import { useAuth } from '../context/AuthContext';
import { prebookRoom, PrebookResponse } from '../lib/travel-api';
import { confirmHotelBooking, createHotelPayment } from '../lib/booking-api';
import { looksLikeHotelCode } from '../lib/hotel-format';

// Stripe is a native module — only available in EAS dev/production builds, not Expo Go.
// We lazy-require it so the rest of the app never crashes if the native binary is absent.
let StripeProvider: React.ComponentType<any> | null = null;
let useStripeHook: (() => { initPaymentSheet: any; presentPaymentSheet: any }) | null = null;
try {
    // Optional native module — must be require()'d in a try/catch so the app still
    // runs in environments where Stripe isn't installed (e.g. Expo Go).
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const stripe = require('@stripe/stripe-react-native');
    StripeProvider = stripe.StripeProvider;
    useStripeHook = stripe.useStripe;
} catch {
    // Running in Expo Go — Stripe native module not compiled in.
}

export default function CheckoutScreen() {
    const STRIPE_KEY = process.env.EXPO_PUBLIC_STRIPE_PUBLISHABLE_KEY ?? '';
    if (StripeProvider && STRIPE_KEY) {
        const SP = StripeProvider;
        return (
            <SP
                publishableKey={STRIPE_KEY}
                merchantIdentifier="com.cheapestgo.mobile"
                urlScheme="mobileapp"
            >
                <StripeCheckout />
            </SP>
        );
    }
    return <CheckoutContent stripeAvailable={false} initPaymentSheet={null} presentPaymentSheet={null} />;
}

// Only mounted when Stripe is available, so the Stripe hook can be called
// unconditionally here (satisfying the rules-of-hooks). useStripeHook is set in the
// same try-block as StripeProvider, so it is non-null whenever this renders.
function StripeCheckout() {
    const { initPaymentSheet, presentPaymentSheet } = useStripeHook!();
    return (
        <CheckoutContent
            stripeAvailable
            initPaymentSheet={initPaymentSheet}
            presentPaymentSheet={presentPaymentSheet}
        />
    );
}

// A small acknowledgment checkbox reused for room-substitution consent and terms.
function AckCheckbox({ checked, onToggle, styles, children }: {
    checked: boolean;
    onToggle: () => void;
    styles: ReturnType<typeof getStyles>;
    children: React.ReactNode;
}) {
    return (
        <Pressable style={styles.checkRow} onPress={onToggle} hitSlop={6}>
            <View style={[styles.checkBox, checked && styles.checkBoxChecked]}>
                {checked && <Check size={14} color="#ffffff" strokeWidth={3} />}
            </View>
            <Text style={styles.checkLabel}>{children}</Text>
        </Pressable>
    );
}

function CheckoutContent({ stripeAvailable, initPaymentSheet, presentPaymentSheet }: {
    stripeAvailable: boolean;
    initPaymentSheet: any;
    presentPaymentSheet: any;
}) {
    const params = useLocalSearchParams();
    const router = useRouter();
    const colorScheme = useColorScheme();
    const isDark = colorScheme === 'dark';
    const { currency } = useSettings();
    const { user } = useAuth();
    const insets = useSafeAreaInsets();
    const styles = getStyles(isDark, insets.bottom);

    // Params from room selection
    const offerId = params.offerId as string;
    const roomName = params.roomName as string || 'Room';
    const roomPrice = parseInt(params.roomPrice as string) || 0;
    const roomCurrency = (params.roomCurrency as string) || currency.code;
    const hotelName = params.hotelName as string || 'Hotel';
    const hotelCode = params.hotelCode as string || '';
    // Never persist a raw hotel code where a display name belongs. If all we have is a
    // code, send no name (the booking carries `hotelCode` so the read side can resolve it).
    const safePropertyName = looksLikeHotelCode(hotelName) ? undefined : hotelName;
    const hotelImage = params.hotelImage as string || '';
    const checkIn = params.checkIn as string || '';
    const checkOut = params.checkOut as string || '';
    const adults = parseInt(params.adults as string) || 2;
    const children = parseInt(params.children as string) || 0;

    // Derived display values
    const displaySymbol = currency.symbol;
    const nights = checkIn && checkOut
        ? Math.max(1, Math.ceil((new Date(checkOut).getTime() - new Date(checkIn).getTime()) / 86400000))
        : 1;

    // State
    const [step, setStep] = useState<'form' | 'paying' | 'success'>('form');
    const [prebookData, setPrebookData] = useState<PrebookResponse | null>(null);
    const [prebooking, setPrebooking] = useState(false);
    const [prebookError, setPrebookError] = useState<string | null>(null);
    const [processing, setProcessing] = useState(false);
    const [bookingId, setBookingId] = useState<string | null>(null);
    // Once Stripe captures the payment we stash the PaymentIntent id here. If confirm
    // then fails, the next Pay Now tap retries *confirm only* with this id instead of
    // creating a second PaymentIntent — preventing a double charge.
    const capturedPaymentRef = useRef<string | null>(null);

    // Form state — prefilled from the signed-in profile (the app is auth-gated, so
    // `user` is virtually always present by the time checkout mounts).
    const [firstName, setFirstName] = useState(user?.firstName ?? '');
    const [lastName, setLastName] = useState(user?.lastName ?? '');
    const [email, setEmail] = useState(user?.email ?? '');
    const [specialRequests, setSpecialRequests] = useState('');
    const [formErrors, setFormErrors] = useState<Record<string, string>>({});

    // Backfill guest details once the profile resolves (session validation can land
    // after mount). Only fills blanks, so it never clobbers what the guest has typed.
    useEffect(() => {
        if (!user) return;
        setFirstName(prev => prev || user.firstName || '');
        setLastName(prev => prev || user.lastName || '');
        setEmail(prev => prev || user.email || '');
    }, [user]);

    // Prebook on mount — locks the rate and gets a quote token
    useEffect(() => {
        if (!offerId) return;
        const doPrebook = async () => {
            setPrebooking(true);
            setPrebookError(null);
            try {
                const result = await prebookRoom({
                    offerId,
                    currency: roomCurrency,
                    adults,
                    children,
                    roomName: params.roomName as string || undefined,
                });
                setPrebookData(result);
            } catch (err: any) {
                setPrebookError(err.message || 'Failed to verify room availability');
            } finally {
                setPrebooking(false);
            }
        };
        doPrebook();
    }, [offerId, adults, children, params.roomName, roomCurrency]);

    // Room substitution — the prebook (authoritative) can lock a different room than
    // the guest selected. We must show this, book the real room name, and require the
    // guest to acknowledge the swap before paying.
    const roomSubstituted = !!prebookData?.roomSubstituted;
    const effectiveRoomName =
        (roomSubstituted && prebookData?.substitutedRoomName) || roomName;
    const [substitutionAck, setSubstitutionAck] = useState(false);

    // Terms / cancellation-policy acceptance — required before we charge.
    const [termsAccepted, setTermsAccepted] = useState(false);
    const isRefundable = prebookData?.cancellationPolicies?.refundableTag === 'RFN';
    const isNonRefundable =
        !!prebookData?.cancellationPolicies && !isRefundable;

    // Pricing — the prebook total is authoritative and tax-inclusive. We don't have a
    // real tax/fee breakdown from the supplier yet, so we show the honest total with a
    // "taxes & fees included" note rather than inventing a split. (TODO: render the real
    // breakdown once the prebook response exposes taxes & fees.)
    const confirmedPrice = prebookData?.price ?? roomPrice;
    const total = Math.max(0, confirmedPrice);

    const validateForm = useCallback(() => {
        const errors: Record<string, string> = {};
        if (!firstName.trim()) errors.firstName = 'Required';
        if (!lastName.trim()) errors.lastName = 'Required';
        if (!email.trim()) errors.email = 'Required';
        else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) errors.email = 'Invalid email';
        setFormErrors(errors);
        return Object.keys(errors).length === 0;
    }, [firstName, lastName, email]);

    const handlePayNow = useCallback(async () => {
        if (!validateForm()) return;
        if (!prebookData?.prebookId) {
            Alert.alert('Not Ready', 'Still verifying room availability. Please wait a moment.');
            return;
        }
        if (roomSubstituted && !substitutionAck) {
            Alert.alert('Room changed', 'Please review and accept the updated room before continuing.');
            return;
        }
        if (!termsAccepted) {
            Alert.alert('Accept terms', 'Please accept the cancellation policy and booking terms to continue.');
            return;
        }

        if (!stripeAvailable || !initPaymentSheet || !presentPaymentSheet) {
            Alert.alert(
                'Payment unavailable',
                'Stripe payments require an EAS development build. Run:\n\neas build --profile development --platform android\n\nThen install the APK and open with "expo start --dev-client".',
            );
            return;
        }

        setProcessing(true);
        try {
            // If a previous attempt already captured payment but failed to confirm,
            // reuse that PaymentIntent and skip straight to confirm — never re-charge.
            let paymentIntentId = capturedPaymentRef.current;

            if (!paymentIntentId) {
                // Step 1: Create Stripe PaymentIntent via web backend
                const chargeAmount = total;
                const paymentResult = await createHotelPayment({
                    prebookId: prebookData.prebookId,
                    amount: chargeAmount,
                    currency: roomCurrency,
                    holderEmail: email,
                    propertyName: safePropertyName,
                    roomName: effectiveRoomName,
                    checkIn,
                    checkOut,
                });

                if (!paymentResult.success || !paymentResult.data?.clientSecret) {
                    throw new Error((paymentResult as any).error || 'Failed to create payment session');
                }

                const { clientSecret, paymentIntentId: pid } = paymentResult.data;

                // Step 2: Initialise Stripe payment sheet
                const { error: initError } = await initPaymentSheet({
                    paymentIntentClientSecret: clientSecret,
                    merchantDisplayName: 'CheapestGo',
                    applePay: { merchantCountryCode: 'US' },
                    googlePay: { merchantCountryCode: 'US', testEnv: __DEV__ },
                    style: isDark ? 'alwaysDark' : 'alwaysLight',
                    returnURL: 'mobileapp://checkout-return',
                    defaultBillingDetails: { email, name: `${firstName} ${lastName}` },
                });
                if (initError) throw new Error(initError.message);

                // Step 3: Present sheet — user enters card / uses Apple Pay / Google Pay
                setStep('paying');
                const { error: paymentError } = await presentPaymentSheet();
                if (paymentError) {
                    setStep('form');
                    if (paymentError.code !== 'Canceled') {
                        Alert.alert('Payment Failed', paymentError.message);
                    }
                    return;
                }

                // Payment captured. Remember it so any confirm failure retries confirm
                // only — it must never trigger a second createHotelPayment.
                paymentIntentId = pid;
                capturedPaymentRef.current = pid;
            }

            // Step 4: Confirm booking with provider + save to DB, with retry.
            // The backend is idempotent on paymentIntentId, so a dropped/timed-out
            // confirm response is safe to retry: it returns the same booking instead
            // of creating a second one.
            setStep('paying');
            const confirmPayload = {
                prebookId: prebookData.prebookId,
                paymentIntentId,
                holder: { firstName, lastName, email },
                guests: [{ occupancyNumber: 1, firstName, lastName, email, remarks: specialRequests || undefined }],
                payment: { method: 'ACC_CREDIT_CARD' },
                propertyName: safePropertyName,
                hotelCode: hotelCode || undefined,
                roomName: effectiveRoomName,
                checkIn,
                checkOut,
                adults,
                children,
                currency: roomCurrency,
                specialRequests: specialRequests || undefined,
                acceptedTermsAt: new Date().toISOString(),
            };

            let confirmResult: Awaited<ReturnType<typeof confirmHotelBooking>> | null = null;
            let lastConfirmErr: any;
            for (let attempt = 1; attempt <= 3; attempt++) {
                try {
                    confirmResult = await confirmHotelBooking(confirmPayload as any);
                    break;
                } catch (err: any) {
                    lastConfirmErr = err;
                    if (attempt < 3) await new Promise(r => setTimeout(r, 1500 * attempt));
                }
            }
            if (!confirmResult) throw lastConfirmErr ?? new Error('Booking confirmation failed');

            if (!confirmResult.success) {
                throw new Error((confirmResult as any).error || 'Booking confirmation failed');
            }

            // Booking secured — clear the captured-payment guard.
            capturedPaymentRef.current = null;
            setBookingId(confirmResult.data?.bookingId || paymentIntentId);
            setStep('success');
        } catch (err: any) {
            setStep('form');
            if (capturedPaymentRef.current) {
                // Card was charged but confirmation didn't complete. The next Pay Now
                // tap retries confirm with the same PaymentIntent — no second charge.
                Alert.alert(
                    'Almost done',
                    "Your payment went through, but we couldn't finalize the booking. Tap Pay Now once more to complete it — you will not be charged again.",
                );
            } else {
                Alert.alert('Booking Failed', err.message || 'Something went wrong. Please try again.');
            }
        } finally {
            setProcessing(false);
        }
    }, [
        validateForm, prebookData, firstName, lastName, email,
        specialRequests, total, roomCurrency,
        safePropertyName, hotelCode, effectiveRoomName, roomSubstituted, substitutionAck,
        termsAccepted, checkIn, checkOut, adults, children, isDark,
        stripeAvailable, initPaymentSheet, presentPaymentSheet,
    ]);

    // ── Success screen ──────────────────────────────────────────────────────
    if (step === 'success') {
        return (
            <SafeAreaView style={styles.container}>
                <View style={styles.successContainer}>
                    <View style={styles.successIconWrap}>
                        <CheckCircle size={64} color="#10b981" />
                    </View>
                    <Text style={styles.successTitle}>Booking Confirmed!</Text>
                    <Text style={styles.successSubtitle}>{hotelName}</Text>
                    <View style={styles.successCard}>
                        {[
                            { label: 'Booking ID', value: bookingId },
                            { label: 'Check-in',   value: checkIn },
                            { label: 'Check-out',  value: checkOut },
                            { label: 'Room',       value: effectiveRoomName },
                            { label: 'Total',      value: `${displaySymbol}${total.toLocaleString()}`, blue: true },
                        ].map(({ label, value, blue }, i, arr) => (
                            <View key={label} style={[styles.successRow, i === arr.length - 1 && { borderBottomWidth: 0 }]}>
                                <Text style={styles.successLabel}>{label}</Text>
                                <Text style={[styles.successValue, blue && { color: '#2563eb', fontWeight: '800' }]}>{value}</Text>
                            </View>
                        ))}
                    </View>
                    <View style={styles.successEmailRow}>
                        <Mail size={16} color="#64748b" />
                        <Text style={styles.successEmailText}>Confirmation sent to {email}</Text>
                    </View>
                    <Pressable style={styles.successBtn} onPress={() => router.dismissAll()}>
                        <Text style={styles.successBtnText}>Back to Home</Text>
                    </Pressable>
                </View>
            </SafeAreaView>
        );
    }

    // ── Paying overlay (Stripe sheet is visible, just show spinner behind it) ──
    if (step === 'paying') {
        return (
            <SafeAreaView style={styles.container}>
                <View style={styles.confirmingContainer}>
                    <ActivityIndicator size="large" color="#2563eb" style={{ marginBottom: 24 }} />
                    <Text style={styles.confirmingTitle}>Processing payment…</Text>
                    <Text style={styles.confirmingStep}>Please complete the payment in the sheet below.</Text>
                    <Text style={styles.confirmingHint}>Do not close this screen</Text>
                </View>
            </SafeAreaView>
        );
    }

    // ── Main form screen ───────────────────────────────────────────────────
    const payDisabled =
        !prebookData || prebooking || processing ||
        (roomSubstituted && !substitutionAck) || !termsAccepted;

    return (
        <SafeAreaView style={styles.container}>
            <KeyboardAvoidingView style={{ flex: 1 }} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>

                {/* Header */}
                <View style={styles.header}>
                    <Pressable onPress={() => router.back()} style={styles.backBtn}>
                        <ArrowLeft size={22} color={isDark ? '#e2e8f0' : '#0f172a'} />
                    </Pressable>
                    <Text style={styles.headerTitle}>Secure your booking</Text>
                    <View style={{ width: 40 }} />
                </View>

                <ScrollView style={styles.scrollView} showsVerticalScrollIndicator={false} contentContainerStyle={{ paddingBottom: 120 }}>

                    {/* Booking Summary Card */}
                    <View style={styles.summaryCard}>
                        {hotelImage ? <Image source={{ uri: hotelImage }} style={styles.summaryImage} /> : null}
                        <View style={styles.summaryInfo}>
                            <Text style={styles.summaryHotel} numberOfLines={2}>{hotelName}</Text>
                            <Text style={styles.summaryRoom} numberOfLines={1}>{effectiveRoomName}</Text>
                            <Text style={styles.summaryDates}>{checkIn} → {checkOut} · {nights} night{nights > 1 ? 's' : ''}</Text>
                            <Text style={styles.summaryGuests}>{adults} guest{adults > 1 ? 's' : ''}</Text>
                        </View>
                    </View>

                    {/* Expo Go warning — Stripe not available */}
                    {!stripeAvailable && (
                        <View style={styles.errorBanner}>
                            <AlertTriangle size={18} color="#d97706" />
                            <Text style={[styles.errorBannerText, { color: '#d97706' }]}>
                                Stripe payments require an EAS dev build — not available in Expo Go.
                            </Text>
                        </View>
                    )}

                    {/* Prebook status */}
                    {prebooking && (
                        <View style={styles.prebookBanner}>
                            <ActivityIndicator size="small" color="#2563eb" />
                            <Text style={styles.prebookText}>Verifying room availability…</Text>
                        </View>
                    )}
                    {prebookError && (
                        <View style={styles.errorBanner}>
                            <AlertTriangle size={18} color="#ef4444" />
                            <Text style={styles.errorBannerText}>{prebookError}</Text>
                        </View>
                    )}

                    {/* Room substitution notice — supplier locked a different room than selected */}
                    {roomSubstituted && (
                        <View style={styles.substituteBanner}>
                            <View style={styles.substituteHeader}>
                                <AlertTriangle size={18} color="#d97706" />
                                <Text style={styles.substituteTitle}>The room changed</Text>
                            </View>
                            <Text style={styles.substituteText}>
                                The supplier confirmed a different room than the one you selected. You'll be booking:
                            </Text>
                            <Text style={styles.substituteRoom}>{effectiveRoomName}</Text>
                            {roomName ? <Text style={styles.substituteWas}>Originally selected: {roomName}</Text> : null}
                            <AckCheckbox checked={substitutionAck} onToggle={() => setSubstitutionAck(v => !v)} styles={styles}>
                                I understand and accept this room change.
                            </AckCheckbox>
                        </View>
                    )}

                    {/* Guest Details */}
                    <View style={styles.formSection}>
                        <Text style={styles.formSectionTitle}>Guest Details</Text>
                        <View style={styles.inputRow}>
                            <View style={[styles.inputGroup, { flex: 1, marginRight: 8 }]}>
                                <Text style={styles.inputLabel}>First Name</Text>
                                <TextInput style={[styles.input, formErrors.firstName && styles.inputError]} placeholder="John" placeholderTextColor={isDark ? '#475569' : '#94a3b8'} value={firstName} onChangeText={setFirstName} autoCapitalize="words" />
                                {formErrors.firstName && <Text style={styles.errorText}>{formErrors.firstName}</Text>}
                            </View>
                            <View style={[styles.inputGroup, { flex: 1 }]}>
                                <Text style={styles.inputLabel}>Last Name</Text>
                                <TextInput style={[styles.input, formErrors.lastName && styles.inputError]} placeholder="Doe" placeholderTextColor={isDark ? '#475569' : '#94a3b8'} value={lastName} onChangeText={setLastName} autoCapitalize="words" />
                                {formErrors.lastName && <Text style={styles.errorText}>{formErrors.lastName}</Text>}
                            </View>
                        </View>
                        <View style={styles.inputGroup}>
                            <Text style={styles.inputLabel}>Email</Text>
                            <TextInput style={[styles.input, formErrors.email && styles.inputError]} placeholder="john@example.com" placeholderTextColor={isDark ? '#475569' : '#94a3b8'} value={email} onChangeText={setEmail} keyboardType="email-address" autoCapitalize="none" />
                            {formErrors.email && <Text style={styles.errorText}>{formErrors.email}</Text>}
                        </View>
                    </View>

                    {/* Special Requests */}
                    <View style={styles.formSection}>
                        <Text style={styles.formSectionTitle}>Special Requests</Text>
                        <TextInput style={[styles.input, { height: 80, textAlignVertical: 'top' }]} placeholder="E.g. late check-in, extra pillows…" placeholderTextColor={isDark ? '#475569' : '#94a3b8'} value={specialRequests} onChangeText={setSpecialRequests} multiline />
                        <Text style={styles.hintText}>Special requests are not guaranteed but we'll do our best.</Text>
                    </View>

                    {/* Price Breakdown */}
                    <View style={styles.formSection}>
                        <Text style={styles.formSectionTitle}>Price Summary</Text>
                        <View style={styles.priceRow}>
                            <Text style={styles.priceLabel}>1 room × {nights} night{nights > 1 ? 's' : ''}</Text>
                            <Text style={styles.priceValue}>{displaySymbol}{confirmedPrice.toLocaleString()}</Text>
                        </View>
                        <View style={[styles.priceRow, styles.totalRow]}>
                            <Text style={styles.totalLabel}>Total</Text>
                            <Text style={styles.totalValue}>{displaySymbol}{total.toLocaleString()}</Text>
                        </View>
                        <Text style={styles.taxesIncludedNote}>Taxes &amp; fees included</Text>
                    </View>

                    {/* Cancellation policy from prebook */}
                    {prebookData?.cancellationPolicies && (
                        <View style={styles.formSection}>
                            <Text style={styles.formSectionTitle}>Cancellation Policy</Text>
                            <View style={[styles.policyBadge, prebookData.cancellationPolicies.refundableTag === 'RFN' ? styles.policyRefundable : styles.policyNonRefundable]}>
                                <Text style={[styles.policyBadgeText, { color: prebookData.cancellationPolicies.refundableTag === 'RFN' ? '#059669' : '#d97706' }]}>
                                    {prebookData.cancellationPolicies.refundableTag === 'RFN' ? '✓ Free cancellation' : 'Non-refundable'}
                                </Text>
                            </View>
                        </View>
                    )}

                    {/* Terms & cancellation-policy acceptance — gates Pay Now */}
                    <View style={styles.formSection}>
                        {isNonRefundable && (
                            <View style={styles.nonRefundableNotice}>
                                <AlertTriangle size={16} color="#d97706" />
                                <Text style={styles.nonRefundableText}>
                                    This rate is non-refundable. You will be charged the full amount and cannot cancel for a refund.
                                </Text>
                            </View>
                        )}
                        <AckCheckbox checked={termsAccepted} onToggle={() => setTermsAccepted(v => !v)} styles={styles}>
                            {isNonRefundable
                                ? 'I understand this booking is non-refundable and accept the cancellation policy and booking terms.'
                                : 'I accept the cancellation policy and booking terms.'}
                        </AckCheckbox>
                    </View>
                </ScrollView>

                {/* Bottom Pay Bar */}
                <View style={styles.bottomBar}>
                    <View>
                        <Text style={styles.bottomPrice}>{displaySymbol}{total.toLocaleString()}</Text>
                        <Text style={styles.bottomNights}>{nights} night{nights > 1 ? 's' : ''} total</Text>
                    </View>
                    <Pressable
                        style={[styles.confirmBtn, payDisabled && styles.confirmBtnDisabled]}
                        onPress={handlePayNow}
                        disabled={payDisabled}
                    >
                        {processing
                            ? <ActivityIndicator size="small" color="white" />
                            : <Text style={styles.confirmBtnText}>{prebooking ? 'Verifying…' : 'Pay Now'}</Text>}
                    </Pressable>
                </View>
            </KeyboardAvoidingView>
        </SafeAreaView>
    );
}

const getStyles = (isDark: boolean, bottomInset: number = 0) => StyleSheet.create({
    container:           { flex: 1, backgroundColor: isDark ? '#020617' : '#f8fafc' },
    header:              { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 16, paddingVertical: 12, borderBottomWidth: 1, borderBottomColor: isDark ? '#1e293b' : '#e2e8f0' },
    backBtn:             { width: 40, height: 40, borderRadius: 20, alignItems: 'center', justifyContent: 'center' },
    headerTitle:         { fontSize: 17, fontWeight: '700', color: isDark ? '#ffffff' : '#0f172a' },
    scrollView:          { flex: 1, paddingHorizontal: 20 },
    summaryCard:         { flexDirection: 'row', backgroundColor: isDark ? '#0f172a' : '#ffffff', borderRadius: 16, marginTop: 16, overflow: 'hidden', borderWidth: 1, borderColor: isDark ? '#1e293b' : '#e2e8f0' },
    summaryImage:        { width: 100, height: 110 },
    summaryInfo:         { flex: 1, padding: 12, justifyContent: 'center' },
    summaryHotel:        { fontSize: 15, fontWeight: '700', color: isDark ? '#ffffff' : '#0f172a', marginBottom: 2 },
    summaryRoom:         { fontSize: 13, color: isDark ? '#94a3b8' : '#64748b', marginBottom: 4 },
    summaryDates:        { fontSize: 12, color: isDark ? '#64748b' : '#94a3b8', marginBottom: 2 },
    summaryGuests:       { fontSize: 12, color: isDark ? '#64748b' : '#94a3b8' },
    prebookBanner:       { flexDirection: 'row', alignItems: 'center', gap: 10, marginTop: 12, padding: 12, backgroundColor: isDark ? '#0c1a3a' : '#eff6ff', borderRadius: 12, borderWidth: 1, borderColor: isDark ? '#1e3a6b' : '#bfdbfe' },
    prebookText:         { fontSize: 13, color: isDark ? '#93c5fd' : '#2563eb', fontWeight: '600' },
    errorBanner:         { flexDirection: 'row', alignItems: 'center', gap: 10, marginTop: 12, padding: 12, backgroundColor: isDark ? '#2a0a0a' : '#fef2f2', borderRadius: 12, borderWidth: 1, borderColor: isDark ? '#7f1d1d' : '#fecaca' },
    errorBannerText:     { flex: 1, fontSize: 13, color: isDark ? '#fca5a5' : '#dc2626', fontWeight: '500' },
    substituteBanner:    { marginTop: 12, padding: 14, backgroundColor: isDark ? '#2a1a05' : '#fffbeb', borderRadius: 12, borderWidth: 1, borderColor: isDark ? '#78350f' : '#fde68a' },
    substituteHeader:    { flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 8 },
    substituteTitle:     { fontSize: 14, fontWeight: '700', color: isDark ? '#fbbf24' : '#b45309' },
    substituteText:      { fontSize: 13, color: isDark ? '#fcd34d' : '#92400e', lineHeight: 18 },
    substituteRoom:      { fontSize: 14, fontWeight: '700', color: isDark ? '#ffffff' : '#0f172a', marginTop: 6 },
    substituteWas:       { fontSize: 12, color: isDark ? '#a8a29e' : '#78716c', marginTop: 2, textDecorationLine: 'line-through' },
    checkRow:            { flexDirection: 'row', alignItems: 'center', gap: 10, marginTop: 12 },
    checkBox:            { width: 22, height: 22, borderRadius: 6, borderWidth: 2, borderColor: isDark ? '#475569' : '#94a3b8', alignItems: 'center', justifyContent: 'center', backgroundColor: 'transparent' },
    checkBoxChecked:     { backgroundColor: '#2563eb', borderColor: '#2563eb' },
    checkLabel:          { flex: 1, fontSize: 13, color: isDark ? '#e2e8f0' : '#334155', fontWeight: '500', lineHeight: 18 },
    nonRefundableNotice: { flexDirection: 'row', alignItems: 'flex-start', gap: 8, marginBottom: 12, padding: 10, backgroundColor: isDark ? '#2a1a05' : '#fffbeb', borderRadius: 10, borderWidth: 1, borderColor: isDark ? '#78350f' : '#fde68a' },
    nonRefundableText:   { flex: 1, fontSize: 12, color: isDark ? '#fcd34d' : '#92400e', lineHeight: 17, fontWeight: '500' },
    formSection:         { marginTop: 20, backgroundColor: isDark ? '#0f172a' : '#ffffff', borderRadius: 16, padding: 16, borderWidth: 1, borderColor: isDark ? '#1e293b' : '#e2e8f0' },
    formSectionTitle:    { fontSize: 15, fontWeight: '700', color: isDark ? '#ffffff' : '#0f172a', marginBottom: 12 },
    inputRow:            { flexDirection: 'row' },
    inputGroup:          { marginBottom: 12 },
    inputLabel:          { fontSize: 12, fontWeight: '600', color: isDark ? '#94a3b8' : '#64748b', marginBottom: 6 },
    input:               { borderWidth: 1, borderColor: isDark ? '#334155' : '#e2e8f0', borderRadius: 12, paddingHorizontal: 14, paddingVertical: 12, fontSize: 15, color: isDark ? '#ffffff' : '#0f172a', backgroundColor: isDark ? '#1e293b' : '#f8fafc' },
    inputError:          { borderColor: '#ef4444' },
    errorText:           { fontSize: 11, color: '#ef4444', marginTop: 4 },
    hintText:            { fontSize: 11, color: isDark ? '#475569' : '#94a3b8', marginTop: 8 },
    priceRow:            { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 8 },
    priceLabel:          { fontSize: 14, color: isDark ? '#94a3b8' : '#64748b' },
    priceValue:          { fontSize: 14, color: isDark ? '#e2e8f0' : '#475569', fontWeight: '600' },
    totalRow:            { borderTopWidth: 1, borderTopColor: isDark ? '#334155' : '#e2e8f0', marginTop: 4, paddingTop: 12 },
    totalLabel:          { fontSize: 16, fontWeight: '700', color: isDark ? '#ffffff' : '#0f172a' },
    totalValue:          { fontSize: 18, fontWeight: '800', color: '#2563eb' },
    taxesIncludedNote:   { fontSize: 11, color: isDark ? '#64748b' : '#94a3b8', marginTop: 6, textAlign: 'right' },
    policyBadge:         { alignSelf: 'flex-start', paddingHorizontal: 12, paddingVertical: 6, borderRadius: 20 },
    policyRefundable:    { backgroundColor: isDark ? '#064e3b33' : '#d1fae5' },
    policyNonRefundable: { backgroundColor: isDark ? '#78350f33' : '#fef3c7' },
    policyBadgeText:     { fontSize: 13, fontWeight: '700' },
    bottomBar:           { position: 'absolute', bottom: 0, left: 0, right: 0, flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 24, paddingTop: 16, paddingBottom: bottomInset + 16, borderTopWidth: 1, borderTopColor: isDark ? '#1e293b' : '#e2e8f0', backgroundColor: isDark ? '#020617' : '#ffffff' },
    bottomPrice:         { fontSize: 20, fontWeight: '800', color: isDark ? '#ffffff' : '#0f172a' },
    bottomNights:        { fontSize: 12, color: isDark ? '#64748b' : '#94a3b8' },
    confirmBtn:          { backgroundColor: '#2563eb', paddingHorizontal: 24, paddingVertical: 14, borderRadius: 16, minWidth: 130, alignItems: 'center', shadowColor: '#2563eb', shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.3, shadowRadius: 8, elevation: 6 },
    confirmBtnDisabled:  { backgroundColor: '#64748b', shadowOpacity: 0 },
    confirmBtnText:      { color: 'white', fontWeight: '700', fontSize: 15 },
    successContainer:    { flex: 1, alignItems: 'center', justifyContent: 'center', padding: 24 },
    successIconWrap:     { marginBottom: 20 },
    successTitle:        { fontSize: 24, fontWeight: '800', color: isDark ? '#ffffff' : '#0f172a', marginBottom: 4 },
    successSubtitle:     { fontSize: 15, color: isDark ? '#94a3b8' : '#64748b', marginBottom: 24 },
    successCard:         { width: '100%', backgroundColor: isDark ? '#0f172a' : '#ffffff', borderRadius: 16, padding: 16, borderWidth: 1, borderColor: isDark ? '#1e293b' : '#e2e8f0' },
    successRow:          { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 10, borderBottomWidth: 1, borderBottomColor: isDark ? '#1e293b' : '#f1f5f9' },
    successLabel:        { fontSize: 13, color: isDark ? '#64748b' : '#94a3b8' },
    successValue:        { fontSize: 13, fontWeight: '600', color: isDark ? '#e2e8f0' : '#0f172a' },
    successEmailRow:     { flexDirection: 'row', alignItems: 'center', gap: 8, marginTop: 16 },
    successEmailText:    { fontSize: 12, color: isDark ? '#64748b' : '#94a3b8' },
    successBtn:          { marginTop: 24, backgroundColor: '#2563eb', paddingHorizontal: 32, paddingVertical: 14, borderRadius: 16 },
    successBtnText:      { color: 'white', fontWeight: '700', fontSize: 15 },
    confirmingContainer: { flex: 1, alignItems: 'center', justifyContent: 'center', padding: 24 },
    confirmingTitle:     { fontSize: 20, fontWeight: '700', color: isDark ? '#ffffff' : '#0f172a', marginBottom: 8 },
    confirmingStep:      { fontSize: 14, color: '#2563eb', fontWeight: '600', textAlign: 'center' },
    confirmingHint:      { marginTop: 24, fontSize: 12, color: isDark ? '#475569' : '#94a3b8' },
    stepDot:             { width: 22, height: 22, borderRadius: 11, backgroundColor: isDark ? '#334155' : '#e2e8f0', alignItems: 'center', justifyContent: 'center' },
    stepDotDone:         { backgroundColor: '#10b981' },
    stepDotActive:       { backgroundColor: '#2563eb' },
    stepDotText:         { fontSize: 10, fontWeight: '700', color: isDark ? '#64748b' : '#94a3b8' },
    stepLabel:           { fontSize: 13, color: isDark ? '#475569' : '#94a3b8' },
    stepLabelActive:     { color: isDark ? '#e2e8f0' : '#334155', fontWeight: '600' },
});
