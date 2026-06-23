import { useLocalSearchParams, useRouter } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { rError, rLog } from '../lib/remoteLog';
import { AlertTriangle, ArrowLeft, Check, CheckCircle, Mail, Tag } from 'lucide-react-native';
import React, { useCallback, useEffect, useState } from 'react';
import {
    ActivityIndicator, Alert, Image, KeyboardAvoidingView,
    Platform, Pressable, ScrollView, StyleSheet, Text, TextInput,
    useColorScheme, View
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useSettings } from '../context/SettingsContext';
import { prebookRoom, PrebookResponse, validatePromoCode } from '../lib/travel-api';
import { confirmHotelBooking, createHotelPayment } from '../lib/booking-api';

// Stripe is a native module — only available in EAS dev/production builds, not Expo Go.
// We lazy-require it so the rest of the app never crashes if the native binary is absent.
let StripeProvider: React.ComponentType<any> | null = null;
let useStripeHook: (() => { initPaymentSheet: any; presentPaymentSheet: any }) | null = null;
try {
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
                <CheckoutContent stripeAvailable />
            </SP>
        );
    }
    return <CheckoutContent stripeAvailable={false} />;
}

function CheckoutContent({ stripeAvailable }: { stripeAvailable: boolean }) {
    const params = useLocalSearchParams();
    const router = useRouter();
    const colorScheme = useColorScheme();
    const isDark = colorScheme === 'dark';
    const { currency } = useSettings();
    const insets = useSafeAreaInsets();
    const styles = getStyles(isDark, insets.bottom);
    const stripeHook = stripeAvailable && useStripeHook ? useStripeHook() : null;
    const initPaymentSheet = stripeHook?.initPaymentSheet;
    const presentPaymentSheet = stripeHook?.presentPaymentSheet;

    // Params from room selection
    const offerId = params.offerId as string;
    const roomName = params.roomName as string || 'Room';
    const roomPrice = parseInt(params.roomPrice as string) || 0;
    const roomCurrency = (params.roomCurrency as string) || currency.code;
    const hotelName = params.hotelName as string || 'Hotel';
    const hotelImage = params.hotelImage as string || '';
    const checkIn = params.checkIn as string || '';
    const checkOut = params.checkOut as string || '';
    const adults = parseInt(params.adults as string) || 2;

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

    // Form state
    const [firstName, setFirstName] = useState('');
    const [lastName, setLastName] = useState('');
    const [email, setEmail] = useState('');
    const [specialRequests, setSpecialRequests] = useState('');
    const [formErrors, setFormErrors] = useState<Record<string, string>>({});

    // Promo code state
    const [promoCode, setPromoCode] = useState('');
    const [appliedPromo, setAppliedPromo] = useState<any | null>(null);
    const [promoLoading, setPromoLoading] = useState(false);
    const [promoError, setPromoError] = useState<string | null>(null);

    // Prebook on mount — locks the rate and gets a quote token
    useEffect(() => {
        if (!offerId) return;
        const doPrebook = async () => {
            setPrebooking(true);
            setPrebookError(null);
            try {
                rLog('Checkout', 'checkout', 'Prebooking room', { offerId, hotelName, checkIn, checkOut, adults });
                const result = await prebookRoom({
                    offerId,
                    currency: roomCurrency,
                    adults,
                    roomName: params.roomName as string || undefined,
                });
                rLog('Checkout', 'checkout', 'Prebook success', { prebookId: result.prebookId, price: result.price });
                setPrebookData(result);
            } catch (err: any) {
                rError('Checkout', 'checkout', 'Prebook failed', { offerId, hotelName, error: err.message });
                setPrebookError(err.message || 'Failed to verify room availability');
            } finally {
                setPrebooking(false);
            }
        };
        doPrebook();
    }, [offerId]);

    // Pricing
    const confirmedPrice = prebookData?.price ?? roomPrice;
    const taxes = Math.round(confirmedPrice * 0.107);
    const subtotal = confirmedPrice - taxes;
    const discount = appliedPromo?.discountAmount || 0;
    const total = Math.max(0, confirmedPrice - discount);

    const handleApplyPromo = async () => {
        if (!promoCode.trim()) return;
        setPromoLoading(true);
        setPromoError(null);
        try {
            const result = await validatePromoCode(promoCode, total);
            if (result?.valid) {
                setAppliedPromo(result);
                Alert.alert('Success', `Promo "${result.promo?.code || promoCode.toUpperCase()}" applied!`);
            } else {
                setPromoError(result?.message || 'Invalid or expired promo code');
                setAppliedPromo(null);
            }
        } catch (err: any) {
            setPromoError(err.message || 'Failed to apply promo code');
        } finally {
            setPromoLoading(false);
        }
    };

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

        if (!stripeAvailable || !initPaymentSheet || !presentPaymentSheet) {
            Alert.alert(
                'Payment unavailable',
                'Stripe payments require an EAS development build. Run:\n\neas build --profile development --platform android\n\nThen install the APK and open with "expo start --dev-client".',
            );
            return;
        }

        setProcessing(true);
        rLog('Checkout', 'checkout', 'Pay now tapped', { offerId, hotelName, checkIn, checkOut, total, email });
        try {
            // Step 1: Create Stripe PaymentIntent via web backend
            const chargeAmount = appliedPromo?.finalPrice ?? total;
            const paymentResult = await createHotelPayment({
                prebookId: prebookData.prebookId,
                amount: chargeAmount,
                currency: roomCurrency,
                holderEmail: email,
                propertyName: hotelName,
                roomName,
                checkIn,
                checkOut,
            });

            rLog('Checkout', 'checkout', 'Payment intent created', { paymentIntentId: paymentResult.data?.paymentIntentId, amount: chargeAmount });
            if (!paymentResult.success || !paymentResult.data?.clientSecret) {
                throw new Error((paymentResult as any).error || 'Failed to create payment session');
            }

            const { clientSecret, paymentIntentId } = paymentResult.data;

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

            // Step 4: Confirm booking with provider + save to DB
            const confirmResult = await confirmHotelBooking({
                prebookId: prebookData.prebookId,
                paymentIntentId,
                holder: { firstName, lastName, email },
                guests: [{ occupancyNumber: 1, firstName, lastName, email, remarks: specialRequests || undefined }],
                payment: { method: 'ACC_CREDIT_CARD' },
                propertyName: hotelName,
                roomName,
                checkIn,
                checkOut,
                adults,
                currency: roomCurrency,
                specialRequests: specialRequests || undefined,
                voucherCode: appliedPromo?.promo?.code,
                discountAmount: appliedPromo?.discountAmount,
            } as any);

            if (!confirmResult.success) {
                throw new Error((confirmResult as any).error || 'Booking confirmation failed');
            }

            rLog('Checkout', 'checkout', 'Hotel booking confirmed', { bookingId: confirmResult.data?.bookingId, hotelName, checkIn, checkOut });
            setBookingId(confirmResult.data?.bookingId || paymentIntentId);
            setStep('success');
        } catch (err: any) {
            rError('Checkout', 'checkout', 'Hotel booking failed', { hotelName, checkIn, checkOut, error: err.message });
            setStep('form');
            Alert.alert('Booking Failed', err.message || 'Something went wrong. Please try again.');
        } finally {
            setProcessing(false);
        }
    }, [
        validateForm, prebookData, firstName, lastName, email,
        specialRequests, appliedPromo, total, roomCurrency,
        hotelName, roomName, checkIn, checkOut, adults, isDark,
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
                            { label: 'Room',       value: roomName },
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
                            <Text style={styles.summaryRoom} numberOfLines={1}>{roomName}</Text>
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

                    {/* Promo code */}
                    <View style={styles.promoCard}>
                        <View style={styles.promoHeader}>
                            <Tag size={16} color={isDark ? '#60a5fa' : '#2563eb'} />
                            <Text style={styles.promoTitle}>Have a promo code?</Text>
                        </View>
                        {appliedPromo ? (
                            <View style={styles.appliedPromoRow}>
                                <View style={{ flex: 1 }}>
                                    <Text style={styles.appliedPromoCode}>Code: {appliedPromo.promo?.code}</Text>
                                    <Text style={styles.appliedPromoDesc}>{appliedPromo.promo?.description || 'Discount Applied'}</Text>
                                </View>
                                <Pressable style={styles.removePromoBtn} onPress={() => { setAppliedPromo(null); setPromoCode(''); setPromoError(null); }}>
                                    <Text style={styles.removePromoText}>Remove</Text>
                                </Pressable>
                            </View>
                        ) : (
                            <View style={styles.promoInputRow}>
                                <TextInput
                                    style={[styles.promoInput, promoError && styles.promoInputError]}
                                    placeholder="ENTER PROMO CODE"
                                    placeholderTextColor={isDark ? '#475569' : '#94a3b8'}
                                    value={promoCode}
                                    onChangeText={setPromoCode}
                                    autoCapitalize="characters"
                                    editable={!promoLoading}
                                />
                                <Pressable
                                    style={[styles.promoApplyBtn, (!promoCode.trim() || promoLoading) && styles.promoApplyBtnDisabled]}
                                    onPress={handleApplyPromo}
                                    disabled={!promoCode.trim() || promoLoading}
                                >
                                    {promoLoading
                                        ? <ActivityIndicator size="small" color="#64748b" />
                                        : <Text style={styles.promoApplyBtnText}>Apply</Text>}
                                </Pressable>
                            </View>
                        )}
                        {promoError && <Text style={styles.promoErrorText}>{promoError}</Text>}
                    </View>

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
                            <Text style={styles.priceValue}>{displaySymbol}{subtotal.toLocaleString()}</Text>
                        </View>
                        <View style={styles.priceRow}>
                            <Text style={styles.priceLabel}>Taxes & fees</Text>
                            <Text style={styles.priceValue}>{displaySymbol}{taxes.toLocaleString()}</Text>
                        </View>
                        {appliedPromo && (
                            <View style={styles.priceRow}>
                                <Text style={[styles.priceLabel, { color: '#059669', fontWeight: '600' }]}>Discount ({appliedPromo.promo?.code})</Text>
                                <Text style={[styles.priceValue, { color: '#059669', fontWeight: '700' }]}>-{displaySymbol}{discount.toLocaleString()}</Text>
                            </View>
                        )}
                        <View style={[styles.priceRow, styles.totalRow]}>
                            <Text style={styles.totalLabel}>Total</Text>
                            <Text style={styles.totalValue}>{displaySymbol}{total.toLocaleString()}</Text>
                        </View>
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
                </ScrollView>

                {/* Bottom Pay Bar */}
                <View style={styles.bottomBar}>
                    <View>
                        <Text style={styles.bottomPrice}>{displaySymbol}{total.toLocaleString()}</Text>
                        <Text style={styles.bottomNights}>{nights} night{nights > 1 ? 's' : ''} total</Text>
                    </View>
                    <Pressable
                        style={[styles.confirmBtn, (!prebookData || prebooking || processing) && styles.confirmBtnDisabled]}
                        onPress={handlePayNow}
                        disabled={!prebookData || prebooking || processing}
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
    promoCard:           { marginTop: 16, backgroundColor: isDark ? '#0f172a' : '#ffffff', borderRadius: 16, padding: 16, borderWidth: 1, borderColor: isDark ? '#1e293b' : '#e2e8f0' },
    promoHeader:         { flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 12 },
    promoTitle:          { fontSize: 15, fontWeight: '700', color: isDark ? '#ffffff' : '#0f172a' },
    promoInputRow:       { flexDirection: 'row', gap: 8 },
    promoInput:          { flex: 1, borderWidth: 1, borderColor: isDark ? '#334155' : '#e2e8f0', borderRadius: 12, paddingHorizontal: 14, paddingVertical: 12, fontSize: 14, fontWeight: '600', color: isDark ? '#ffffff' : '#0f172a', backgroundColor: isDark ? '#1e293b' : '#f8fafc' },
    promoInputError:     { borderColor: '#ef4444' },
    promoApplyBtn:       { backgroundColor: isDark ? '#1e293b' : '#e2e8f0', paddingHorizontal: 20, justifyContent: 'center', alignItems: 'center', borderRadius: 12 },
    promoApplyBtnDisabled: { opacity: 0.6 },
    promoApplyBtnText:   { color: isDark ? '#94a3b8' : '#475569', fontWeight: '700', fontSize: 14 },
    promoErrorText:      { fontSize: 12, color: '#ef4444', marginTop: 6, fontWeight: '500' },
    appliedPromoRow:     { flexDirection: 'row', alignItems: 'center', backgroundColor: isDark ? '#064e3b22' : '#d1fae544', padding: 12, borderRadius: 12, borderWidth: 1, borderColor: isDark ? '#065f4655' : '#10b98133' },
    appliedPromoCode:    { fontSize: 14, fontWeight: '700', color: isDark ? '#34d399' : '#059669' },
    appliedPromoDesc:    { fontSize: 12, color: isDark ? '#a7f3d0' : '#047857', marginTop: 2 },
    removePromoBtn:      { paddingHorizontal: 12, paddingVertical: 6, borderRadius: 8, backgroundColor: isDark ? '#7f1d1d22' : '#fee2e2' },
    removePromoText:     { fontSize: 12, fontWeight: '700', color: isDark ? '#fca5a5' : '#dc2626' },
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
