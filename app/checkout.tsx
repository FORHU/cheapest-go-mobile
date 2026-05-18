import { BlurView } from 'expo-blur';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { AlertTriangle, ArrowLeft, Check, CheckCircle, ChevronDown, Loader, Mail, Tag, User } from 'lucide-react-native';
import React, { useCallback, useEffect, useState } from 'react';
import {
    ActivityIndicator, Alert, Dimensions, Image, KeyboardAvoidingView,
    Platform, Pressable, ScrollView, StyleSheet, Text, TextInput,
    useColorScheme, View
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useSettings } from '../context/SettingsContext';
import { confirmBooking, prebookRoom, PrebookResponse, validatePromoCode } from '../lib/api';

const { width } = Dimensions.get('window');

const BOOKING_STEPS = [
    'Verifying rate...',
    'Securing your reservation...',
    'Confirming with the hotel...',
    'Finalizing booking...',
] as const;

export default function CheckoutScreen() {
    const params = useLocalSearchParams();
    const router = useRouter();
    const colorScheme = useColorScheme();
    const isDark = colorScheme === 'dark';
    const { currency } = useSettings();
    const styles = getStyles(isDark);

    // Params from room selection
    const offerId = params.offerId as string;
    const roomName = params.roomName as string || 'Room';
    const roomPrice = parseInt(params.roomPrice as string) || 0;
    const hotelName = params.hotelName as string || 'Hotel';
    const hotelImage = params.hotelImage as string || '';
    const checkIn = params.checkIn as string || '';
    const checkOut = params.checkOut as string || '';
    const adults = parseInt(params.adults as string) || 2;

    // State
    const [step, setStep] = useState<'form' | 'confirming' | 'success'>('form');
    const [prebookData, setPrebookData] = useState<PrebookResponse | null>(null);
    const [prebooking, setPrebooking] = useState(false);
    const [prebookError, setPrebookError] = useState<string | null>(null);
    const [booking, setBooking] = useState(false);
    const [bookingStepIdx, setBookingStepIdx] = useState(0);
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

    // Prebook on mount
    useEffect(() => {
        if (!offerId) return;
        const doPrebook = async () => {
            setPrebooking(true);
            setPrebookError(null);
            try {
                const result = await prebookRoom({
                    offerId,
                    currency: currency.code,
                });
                setPrebookData(result);
            } catch (err: any) {
                setPrebookError(err.message || 'Failed to verify room availability');
            } finally {
                setPrebooking(false);
            }
        };
        doPrebook();
    }, [offerId]);

    // Progress animation during booking
    useEffect(() => {
        if (step !== 'confirming') return;
        setBookingStepIdx(0);
        const timer = setInterval(() => {
            setBookingStepIdx(i => Math.min(i + 1, BOOKING_STEPS.length - 1));
        }, 3000);
        return () => clearInterval(timer);
    }, [step]);

    const handleApplyPromo = async () => {
        if (!promoCode.trim()) return;
        setPromoLoading(true);
        setPromoError(null);
        try {
            const result = await validatePromoCode(promoCode, roomPrice);
            if (result && result.valid) {
                setAppliedPromo(result);
                Alert.alert('Success', `Promo code "${result.promo?.code || promoCode.toUpperCase()}" applied successfully!`);
            } else {
                setPromoError(result?.message || 'Invalid or expired promo code');
                setAppliedPromo(null);
            }
        } catch (err: any) {
            setPromoError(err.message || 'Failed to apply promo code');
            setAppliedPromo(null);
        } finally {
            setPromoLoading(false);
        }
    };

    const handleRemovePromo = () => {
        setAppliedPromo(null);
        setPromoCode('');
        setPromoError(null);
    };

    // Recalculated pricing for breakdown
    const basePrice = prebookData?.price || roomPrice;
    const taxes = Math.round(basePrice * 0.107); // 10.7% taxes & fees
    const subtotal = basePrice - taxes;
    const discount = appliedPromo?.discountAmount || 0;
    const total = Math.max(0, basePrice - discount);

    const validateForm = useCallback(() => {
        const errors: Record<string, string> = {};
        if (!firstName.trim()) errors.firstName = 'First name is required';
        if (!lastName.trim()) errors.lastName = 'Last name is required';
        if (!email.trim()) errors.email = 'Email is required';
        else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) errors.email = 'Invalid email';
        setFormErrors(errors);
        return Object.keys(errors).length === 0;
    }, [firstName, lastName, email]);

    const handleBooking = useCallback(async () => {
        if (!validateForm()) return;
        if (!prebookData?.prebookId) {
            Alert.alert('Error', 'Room is not available. Please go back and try again.');
            return;
        }

        setStep('confirming');
        setBooking(true);
        try {
            const result = await confirmBooking({
                prebookId: prebookData.prebookId,
                holder: { firstName, lastName, email },
                guests: [{
                    occupancyNumber: 1,
                    firstName,
                    lastName,
                    email,
                    remarks: specialRequests || undefined,
                }],
                payment: {
                    method: prebookData.transactionId ? 'TRANSACTION_ID' : 'ACC_CREDIT_CARD',
                    transactionId: prebookData.transactionId || undefined,
                },
                // Pass applied vouchers/vouchers info to backend
                voucherCode: appliedPromo?.promo?.code || undefined,
                discountAmount: appliedPromo?.discountAmount || undefined,
            } as any);
            setBookingId(result.bookingId || 'N/A');
            setStep('success');
        } catch (err: any) {
            Alert.alert('Booking Failed', err.message || 'Something went wrong. Please try again.');
            setStep('form');
        } finally {
            setBooking(false);
        }
    }, [validateForm, prebookData, firstName, lastName, email, specialRequests, appliedPromo]);

    // Calculate nights
    const nights = checkIn && checkOut
        ? Math.max(1, Math.ceil((new Date(checkOut).getTime() - new Date(checkIn).getTime()) / 86400000))
        : 1;

    // Success screen
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
                        <View style={styles.successRow}>
                            <Text style={styles.successLabel}>Booking ID</Text>
                            <Text style={styles.successValue}>{bookingId}</Text>
                        </View>
                        <View style={styles.successRow}>
                            <Text style={styles.successLabel}>Check-in</Text>
                            <Text style={styles.successValue}>{checkIn}</Text>
                        </View>
                        <View style={styles.successRow}>
                            <Text style={styles.successLabel}>Check-out</Text>
                            <Text style={styles.successValue}>{checkOut}</Text>
                        </View>
                        <View style={styles.successRow}>
                            <Text style={styles.successLabel}>Room</Text>
                            <Text style={styles.successValue}>{roomName}</Text>
                        </View>
                        <View style={[styles.successRow, { borderBottomWidth: 0 }]}>
                            <Text style={styles.successLabel}>Total</Text>
                            <Text style={[styles.successValue, { color: '#2563eb', fontWeight: '800' }]}>
                                {currency.symbol}{total}
                            </Text>
                        </View>
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

    // Confirming overlay
    if (step === 'confirming') {
        return (
            <SafeAreaView style={styles.container}>
                <View style={styles.confirmingContainer}>
                    <ActivityIndicator size="large" color="#2563eb" style={{ marginBottom: 24 }} />
                    <Text style={styles.confirmingTitle}>Confirming your booking</Text>
                    <Text style={styles.confirmingStep}>{BOOKING_STEPS[bookingStepIdx]}</Text>
                    <View style={{ marginTop: 24, gap: 12, width: '100%', maxWidth: 280 }}>
                        {BOOKING_STEPS.map((label, i) => (
                            <View key={label} style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
                                <View style={[
                                    styles.stepDot,
                                    i < bookingStepIdx && styles.stepDotDone,
                                    i === bookingStepIdx && styles.stepDotActive,
                                ]}>
                                    {i < bookingStepIdx
                                        ? <Check size={10} color="white" />
                                        : <Text style={styles.stepDotText}>{i + 1}</Text>
                                    }
                                </View>
                                <Text style={[
                                    styles.stepLabel,
                                    i <= bookingStepIdx && styles.stepLabelActive,
                                ]}>{label}</Text>
                            </View>
                        ))}
                    </View>
                    <Text style={styles.confirmingHint}>Please don't close this screen</Text>
                </View>
            </SafeAreaView>
        );
    }

    // Form screen
    return (
        <SafeAreaView style={styles.container}>
            <KeyboardAvoidingView
                style={{ flex: 1 }}
                behavior={Platform.OS === 'ios' ? 'padding' : undefined}
            >
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
                        {hotelImage ? (
                            <Image source={{ uri: hotelImage }} style={styles.summaryImage} />
                        ) : null}
                        <View style={styles.summaryInfo}>
                            <Text style={styles.summaryHotel} numberOfLines={2}>{hotelName}</Text>
                            <Text style={styles.summaryRoom} numberOfLines={1}>{roomName}</Text>
                            <Text style={styles.summaryDates}>
                                {checkIn} → {checkOut} • {nights} night{nights > 1 ? 's' : ''}
                            </Text>
                            <Text style={styles.summaryGuests}>{adults} guest{adults > 1 ? 's' : ''}</Text>
                        </View>
                    </View>

                    {/* Prebook Status */}
                    {prebooking && (
                        <View style={styles.prebookBanner}>
                            <ActivityIndicator size="small" color="#2563eb" />
                            <Text style={styles.prebookText}>Verifying room availability...</Text>
                        </View>
                    )}
                    {prebookError && (
                        <View style={styles.errorBanner}>
                            <AlertTriangle size={18} color="#ef4444" />
                            <Text style={styles.errorBannerText}>{prebookError}</Text>
                        </View>
                    )}

                    {/* Promo Code Input Card */}
                    <View style={styles.promoCard}>
                        <View style={styles.promoHeader}>
                            <Tag size={16} color={isDark ? '#60a5fa' : '#2563eb'} />
                            <Text style={styles.promoTitle}>Have a promo code?</Text>
                        </View>
                        
                        {appliedPromo ? (
                            <View style={styles.appliedPromoRow}>
                                <View style={{ flex: 1 }}>
                                    <Text style={styles.appliedPromoCode}>
                                        Code: {appliedPromo.promo?.code}
                                    </Text>
                                    <Text style={styles.appliedPromoDesc}>
                                        {appliedPromo.promo?.description || 'Discount Applied'}
                                    </Text>
                                </View>
                                <Pressable style={styles.removePromoBtn} onPress={handleRemovePromo}>
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
                                    {promoLoading ? (
                                        <ActivityIndicator size="small" color="#64748b" />
                                    ) : (
                                        <Text style={styles.promoApplyBtnText}>Apply</Text>
                                    )}
                                </Pressable>
                            </View>
                        )}
                        {promoError && <Text style={styles.promoErrorText}>{promoError}</Text>}
                    </View>

                    {/* Guest Details Form */}
                    <View style={styles.formSection}>
                        <Text style={styles.formSectionTitle}>Guest Details</Text>

                        <View style={styles.inputRow}>
                            <View style={[styles.inputGroup, { flex: 1, marginRight: 8 }]}>
                                <Text style={styles.inputLabel}>First Name</Text>
                                <TextInput
                                    style={[styles.input, formErrors.firstName && styles.inputError]}
                                    placeholder="John"
                                    placeholderTextColor={isDark ? '#475569' : '#94a3b8'}
                                    value={firstName}
                                    onChangeText={setFirstName}
                                    autoCapitalize="words"
                                />
                                {formErrors.firstName && <Text style={styles.errorText}>{formErrors.firstName}</Text>}
                            </View>
                            <View style={[styles.inputGroup, { flex: 1 }]}>
                                <Text style={styles.inputLabel}>Last Name</Text>
                                <TextInput
                                    style={[styles.input, formErrors.lastName && styles.inputError]}
                                    placeholder="Doe"
                                    placeholderTextColor={isDark ? '#475569' : '#94a3b8'}
                                    value={lastName}
                                    onChangeText={setLastName}
                                    autoCapitalize="words"
                                />
                                {formErrors.lastName && <Text style={styles.errorText}>{formErrors.lastName}</Text>}
                            </View>
                        </View>

                        <View style={styles.inputGroup}>
                            <Text style={styles.inputLabel}>Email</Text>
                            <TextInput
                                style={[styles.input, formErrors.email && styles.inputError]}
                                placeholder="john@example.com"
                                placeholderTextColor={isDark ? '#475569' : '#94a3b8'}
                                value={email}
                                onChangeText={setEmail}
                                keyboardType="email-address"
                                autoCapitalize="none"
                            />
                            {formErrors.email && <Text style={styles.errorText}>{formErrors.email}</Text>}
                        </View>
                    </View>

                    {/* Special Requests */}
                    <View style={styles.formSection}>
                        <Text style={styles.formSectionTitle}>Special Requests</Text>
                        <TextInput
                            style={[styles.input, { height: 80, textAlignVertical: 'top' }]}
                            placeholder="E.g. late check-in, extra pillows..."
                            placeholderTextColor={isDark ? '#475569' : '#94a3b8'}
                            value={specialRequests}
                            onChangeText={setSpecialRequests}
                            multiline
                        />
                        <Text style={styles.hintText}>Special requests are not guaranteed but we'll do our best.</Text>
                    </View>

                    {/* Price Breakdown */}
                    <View style={styles.formSection}>
                        <Text style={styles.formSectionTitle}>Price Summary</Text>
                        <View style={styles.priceRow}>
                            <Text style={styles.priceLabel}>1 room × {nights} night{nights > 1 ? 's' : ''}</Text>
                            <Text style={styles.priceValue}>{currency.symbol}{subtotal}</Text>
                        </View>
                        <View style={styles.priceRow}>
                            <Text style={styles.priceLabel}>Included taxes and fees</Text>
                            <Text style={styles.priceValue}>{currency.symbol}{taxes}</Text>
                        </View>
                        {appliedPromo && (
                            <View style={styles.priceRow}>
                                <Text style={[styles.priceLabel, { color: '#059669', fontWeight: '600' }]}>
                                    Discount ({appliedPromo.promo?.code})
                                </Text>
                                <Text style={[styles.priceValue, { color: '#059669', fontWeight: '700' }]}>
                                    -{currency.symbol}{discount}
                                </Text>
                            </View>
                        )}
                        <View style={[styles.priceRow, styles.totalRow]}>
                            <Text style={styles.totalLabel}>Total</Text>
                            <Text style={styles.totalValue}>{currency.symbol}{total}</Text>
                        </View>
                    </View>

                    {/* Cancellation Policy */}
                    {prebookData?.cancellationPolicies && (
                        <View style={styles.formSection}>
                            <Text style={styles.formSectionTitle}>Cancellation Policy</Text>
                            <View style={[
                                styles.policyBadge,
                                prebookData.cancellationPolicies.refundableTag === 'RFN'
                                    ? styles.policyRefundable
                                    : styles.policyNonRefundable
                            ]}>
                                <Text style={[
                                    styles.policyBadgeText,
                                    prebookData.cancellationPolicies.refundableTag === 'RFN'
                                        ? { color: '#059669' }
                                        : { color: '#d97706' }
                                ]}>
                                    {prebookData.cancellationPolicies.refundableTag === 'RFN' ? 'Refundable' : 'Non-refundable'}
                                </Text>
                            </View>
                        </View>
                    )}
                </ScrollView>

                {/* Bottom Booking Bar */}
                <BlurView intensity={80} tint={isDark ? 'dark' : 'light'} style={styles.bottomBar}>
                    <View>
                        <Text style={styles.bottomPrice}>{currency.symbol}{total}</Text>
                        <Text style={styles.bottomNights}>{nights} night{nights > 1 ? 's' : ''} total</Text>
                    </View>
                    <Pressable
                        style={[styles.confirmBtn, (!prebookData || prebooking) && styles.confirmBtnDisabled]}
                        onPress={handleBooking}
                        disabled={!prebookData || prebooking || booking}
                    >
                        {booking ? (
                            <ActivityIndicator size="small" color="white" />
                        ) : (
                            <Text style={styles.confirmBtnText}>
                                {prebooking ? 'Verifying...' : 'Confirm Booking'}
                            </Text>
                        )}
                    </Pressable>
                </BlurView>
            </KeyboardAvoidingView>
        </SafeAreaView>
    );
}

const getStyles = (isDark: boolean) => StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: isDark ? '#020617' : '#f8fafc',
    },
    header: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        paddingHorizontal: 16,
        paddingVertical: 12,
        borderBottomWidth: 1,
        borderBottomColor: isDark ? '#1e293b' : '#e2e8f0',
    },
    backBtn: {
        width: 40,
        height: 40,
        borderRadius: 20,
        alignItems: 'center',
        justifyContent: 'center',
    },
    headerTitle: {
        fontSize: 17,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
    },
    scrollView: {
        flex: 1,
        paddingHorizontal: 20,
    },
    summaryCard: {
        flexDirection: 'row',
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        borderRadius: 16,
        marginTop: 16,
        overflow: 'hidden',
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
    },
    summaryImage: {
        width: 100,
        height: 110,
    },
    summaryInfo: {
        flex: 1,
        padding: 12,
        justifyContent: 'center',
    },
    summaryHotel: {
        fontSize: 15,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
        marginBottom: 2,
    },
    summaryRoom: {
        fontSize: 13,
        color: isDark ? '#94a3b8' : '#64748b',
        marginBottom: 4,
    },
    summaryDates: {
        fontSize: 12,
        color: isDark ? '#64748b' : '#94a3b8',
        marginBottom: 2,
    },
    summaryGuests: {
        fontSize: 12,
        color: isDark ? '#64748b' : '#94a3b8',
    },
    prebookBanner: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 10,
        marginTop: 12,
        padding: 12,
        backgroundColor: isDark ? '#0c1a3a' : '#eff6ff',
        borderRadius: 12,
        borderWidth: 1,
        borderColor: isDark ? '#1e3a6b' : '#bfdbfe',
    },
    prebookText: {
        fontSize: 13,
        color: isDark ? '#93c5fd' : '#2563eb',
        fontWeight: '600',
    },
    errorBanner: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 10,
        marginTop: 12,
        padding: 12,
        backgroundColor: isDark ? '#2a0a0a' : '#fef2f2',
        borderRadius: 12,
        borderWidth: 1,
        borderColor: isDark ? '#7f1d1d' : '#fecaca',
    },
    errorBannerText: {
        flex: 1,
        fontSize: 13,
        color: isDark ? '#fca5a5' : '#dc2626',
        fontWeight: '500',
    },
    promoCard: {
        marginTop: 16,
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        borderRadius: 16,
        padding: 16,
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
        shadowColor: '#000000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: isDark ? 0.2 : 0.05,
        shadowRadius: 4,
        elevation: 2,
    },
    promoHeader: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 8,
        marginBottom: 12,
    },
    promoTitle: {
        fontSize: 15,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
    },
    promoInputRow: {
        flexDirection: 'row',
        gap: 8,
    },
    promoInput: {
        flex: 1,
        borderWidth: 1,
        borderColor: isDark ? '#334155' : '#e2e8f0',
        borderRadius: 12,
        paddingHorizontal: 14,
        paddingVertical: 12,
        fontSize: 14,
        fontWeight: '600',
        color: isDark ? '#ffffff' : '#0f172a',
        backgroundColor: isDark ? '#1e293b' : '#f8fafc',
    },
    promoInputError: {
        borderColor: '#ef4444',
    },
    promoApplyBtn: {
        backgroundColor: isDark ? '#1e293b' : '#e2e8f0',
        paddingHorizontal: 20,
        justifyContent: 'center',
        alignItems: 'center',
        borderRadius: 12,
    },
    promoApplyBtnDisabled: {
        opacity: 0.6,
    },
    promoApplyBtnText: {
        color: isDark ? '#94a3b8' : '#475569',
        fontWeight: '700',
        fontSize: 14,
    },
    promoErrorText: {
        fontSize: 12,
        color: '#ef4444',
        marginTop: 6,
        fontWeight: '500',
    },
    appliedPromoRow: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: isDark ? '#064e3b22' : '#d1fae544',
        padding: 12,
        borderRadius: 12,
        borderWidth: 1,
        borderColor: isDark ? '#065f4655' : '#10b98133',
    },
    appliedPromoCode: {
        fontSize: 14,
        fontWeight: '700',
        color: isDark ? '#34d399' : '#059669',
    },
    appliedPromoDesc: {
        fontSize: 12,
        color: isDark ? '#a7f3d0' : '#047857',
        marginTop: 2,
    },
    removePromoBtn: {
        paddingHorizontal: 12,
        paddingVertical: 6,
        borderRadius: 8,
        backgroundColor: isDark ? '#7f1d1d22' : '#fee2e2',
    },
    removePromoText: {
        fontSize: 12,
        fontWeight: '700',
        color: isDark ? '#fca5a5' : '#dc2626',
    },
    formSection: {
        marginTop: 20,
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        borderRadius: 16,
        padding: 16,
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
    },
    formSectionTitle: {
        fontSize: 15,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
        marginBottom: 12,
    },
    inputRow: {
        flexDirection: 'row',
    },
    inputGroup: {
        marginBottom: 12,
    },
    inputLabel: {
        fontSize: 12,
        fontWeight: '600',
        color: isDark ? '#94a3b8' : '#64748b',
        marginBottom: 6,
    },
    input: {
        borderWidth: 1,
        borderColor: isDark ? '#334155' : '#e2e8f0',
        borderRadius: 12,
        paddingHorizontal: 14,
        paddingVertical: 12,
        fontSize: 15,
        color: isDark ? '#ffffff' : '#0f172a',
        backgroundColor: isDark ? '#1e293b' : '#f8fafc',
    },
    inputError: {
        borderColor: '#ef4444',
    },
    errorText: {
        fontSize: 11,
        color: '#ef4444',
        marginTop: 4,
    },
    hintText: {
        fontSize: 11,
        color: isDark ? '#475569' : '#94a3b8',
        marginTop: 8,
    },
    priceRow: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        paddingVertical: 8,
    },
    priceLabel: {
        fontSize: 14,
        color: isDark ? '#94a3b8' : '#64748b',
    },
    priceValue: {
        fontSize: 14,
        color: isDark ? '#e2e8f0' : '#475569',
        fontWeight: '600',
    },
    totalRow: {
        borderTopWidth: 1,
        borderTopColor: isDark ? '#334155' : '#e2e8f0',
        marginTop: 4,
        paddingTop: 12,
    },
    totalLabel: {
        fontSize: 16,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
    },
    totalValue: {
        fontSize: 18,
        fontWeight: '800',
        color: '#2563eb',
    },
    policyBadge: {
        alignSelf: 'flex-start',
        paddingHorizontal: 12,
        paddingVertical: 6,
        borderRadius: 20,
    },
    policyRefundable: {
        backgroundColor: isDark ? '#064e3b33' : '#d1fae5',
    },
    policyNonRefundable: {
        backgroundColor: isDark ? '#78350f33' : '#fef3c7',
    },
    policyBadgeText: {
        fontSize: 13,
        fontWeight: '700',
    },
    bottomBar: {
        position: 'absolute',
        bottom: 0,
        left: 0,
        right: 0,
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        paddingHorizontal: 24,
        paddingTop: 16,
        paddingBottom: Platform.OS === 'ios' ? 36 : 20,
        borderTopWidth: 1,
        borderTopColor: isDark ? '#1e293b' : '#e2e8f0',
    },
    bottomPrice: {
        fontSize: 20,
        fontWeight: '800',
        color: isDark ? '#ffffff' : '#0f172a',
    },
    bottomNights: {
        fontSize: 12,
        color: isDark ? '#64748b' : '#94a3b8',
    },
    confirmBtn: {
        backgroundColor: '#2563eb',
        paddingHorizontal: 24,
        paddingVertical: 14,
        borderRadius: 16,
        minWidth: 160,
        alignItems: 'center',
        shadowColor: '#2563eb',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.3,
        shadowRadius: 8,
        elevation: 6,
    },
    confirmBtnDisabled: {
        backgroundColor: '#64748b',
        shadowOpacity: 0,
    },
    confirmBtnText: {
        color: 'white',
        fontWeight: '700',
        fontSize: 15,
    },
    // Success styles
    successContainer: {
        flex: 1,
        alignItems: 'center',
        justifyContent: 'center',
        padding: 24,
    },
    successIconWrap: {
        marginBottom: 20,
    },
    successTitle: {
        fontSize: 24,
        fontWeight: '800',
        color: isDark ? '#ffffff' : '#0f172a',
        marginBottom: 4,
    },
    successSubtitle: {
        fontSize: 15,
        color: isDark ? '#94a3b8' : '#64748b',
        marginBottom: 24,
    },
    successCard: {
        width: '100%',
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        borderRadius: 16,
        padding: 16,
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
    },
    successRow: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        paddingVertical: 10,
        borderBottomWidth: 1,
        borderBottomColor: isDark ? '#1e293b' : '#f1f5f9',
    },
    successLabel: {
        fontSize: 13,
        color: isDark ? '#64748b' : '#94a3b8',
    },
    successValue: {
        fontSize: 13,
        fontWeight: '600',
        color: isDark ? '#e2e8f0' : '#0f172a',
    },
    successEmailRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 8,
        marginTop: 16,
    },
    successEmailText: {
        fontSize: 12,
        color: isDark ? '#64748b' : '#94a3b8',
    },
    successBtn: {
        marginTop: 24,
        backgroundColor: '#2563eb',
        paddingHorizontal: 32,
        paddingVertical: 14,
        borderRadius: 16,
    },
    successBtnText: {
        color: 'white',
        fontWeight: '700',
        fontSize: 15,
    },
    // Confirming styles
    confirmingContainer: {
        flex: 1,
        alignItems: 'center',
        justifyContent: 'center',
        padding: 24,
    },
    confirmingTitle: {
        fontSize: 20,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
        marginBottom: 8,
    },
    confirmingStep: {
        fontSize: 14,
        color: '#2563eb',
        fontWeight: '600',
    },
    confirmingHint: {
        marginTop: 24,
        fontSize: 12,
        color: isDark ? '#475569' : '#94a3b8',
    },
    stepDot: {
        width: 22,
        height: 22,
        borderRadius: 11,
        backgroundColor: isDark ? '#334155' : '#e2e8f0',
        alignItems: 'center',
        justifyContent: 'center',
    },
    stepDotDone: {
        backgroundColor: '#10b981',
    },
    stepDotActive: {
        backgroundColor: '#2563eb',
    },
    stepDotText: {
        fontSize: 10,
        fontWeight: '700',
        color: isDark ? '#64748b' : '#94a3b8',
    },
    stepLabel: {
        fontSize: 13,
        color: isDark ? '#475569' : '#94a3b8',
    },
    stepLabelActive: {
        color: isDark ? '#e2e8f0' : '#334155',
        fontWeight: '600',
    },
});
