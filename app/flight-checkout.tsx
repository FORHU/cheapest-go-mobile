import { useLocalSearchParams, useRouter } from 'expo-router';
import {
    AlertTriangle,
    ArrowLeft,
    Briefcase,
    Check,
    CheckCircle,
    ChevronDown,
    ChevronLeft, ChevronRight,
    ChevronUp,
    Globe,
    Mail,
    MapPin,
    Plus,
    ShieldAlert,
    Ticket,
    User
} from 'lucide-react-native';
import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
    ActivityIndicator, Alert,
    Dimensions,
    KeyboardAvoidingView,
    Modal,
    Platform,
    Pressable, ScrollView,
    StyleSheet,
    Text,
    TextInput,
    useColorScheme,
    View
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useAuth } from '../context/AuthContext';
import { useSettings } from '../context/SettingsContext';
import {
    webFetchBags, webFetchSeatMap, webMobileBook, webMobileConfirm, webRefreshOffer,
    type NormalizedBagOption, type NormalizedSegmentSeatMap,
} from '../lib/booking-api';
import { FlightOffer, formatDuration } from '../lib/flight-types';

let StripeProvider: React.ComponentType<any> | null = null;
let useStripeHook: (() => { initPaymentSheet: any; presentPaymentSheet: any }) | null = null;

try {
    const stripe = require('@stripe/stripe-react-native');
    StripeProvider = stripe.StripeProvider;
    useStripeHook = stripe.useStripe;
} catch (e) {
    // eslint-disable-next-line no-console
    console.warn('Stripe is not available:', e);
}

const { width } = Dimensions.get('window');
const BOOKING_STEPS = [
    'Verifying rate...',
    'Securing your airline reservation...',
    'Confirming passenger details...',
    'Issuing e-ticket PNR...',
] as const;

interface SeatConfig {
    code: string;
    type: 'taken' | 'paid' | 'legroom' | 'exit' | 'free';
    price?: number;
}

interface RowConfig {
    row: number;
    seats: SeatConfig[];
}

const SEAT_ROWS: RowConfig[] = [
    { row: 12, seats: [{ code: 'A', type: 'legroom' }, { code: 'B', type: 'taken' }, { code: 'C', type: 'legroom' }, { code: 'D', type: 'taken' }, { code: 'E', type: 'legroom' }] },
    { row: 14, seats: [{ code: 'A', type: 'exit' }, { code: 'B', type: 'free' }, { code: 'C', type: 'exit' }, { code: 'D', type: 'free' }, { code: 'E', type: 'exit' }] },
    { row: 15, seats: [{ code: 'A', type: 'free' }, { code: 'B', type: 'free' }, { code: 'C', type: 'taken' }, { code: 'D', type: 'free' }, { code: 'E', type: 'free' }] },
    { row: 16, seats: [{ code: 'A', type: 'free' }, { code: 'B', type: 'taken' }, { code: 'C', type: 'free' }, { code: 'D', type: 'free' }, { code: 'E', type: 'taken' }] },
    { row: 17, seats: [{ code: 'A', type: 'paid', price: 15 }, { code: 'B', type: 'free' }, { code: 'C', type: 'paid', price: 15 }, { code: 'D', type: 'free' }, { code: 'E', type: 'paid', price: 15 }] },
    { row: 18, seats: [{ code: 'A', type: 'free' }, { code: 'B', type: 'free' }, { code: 'C', type: 'free' }, { code: 'D', type: 'taken' }, { code: 'E', type: 'free' }] },
    { row: 19, seats: [{ code: 'A', type: 'free' }, { code: 'B', type: 'free' }, { code: 'C', type: 'free' }, { code: 'D', type: 'free' }, { code: 'E', type: 'free' }] },
    { row: 20, seats: [{ code: 'A', type: 'free' }, { code: 'B', type: 'taken' }, { code: 'C', type: 'free' }, { code: 'D', type: 'taken' }, { code: 'E', type: 'free' }] },
];

const COUNTRIES = [
    { code: 'KR', name: 'South Korea', dialCode: '82' },
    { code: 'PH', name: 'Philippines', dialCode: '63' },
    { code: 'US', name: 'United States', dialCode: '1' },
    { code: 'JP', name: 'Japan', dialCode: '81' },
    { code: 'SG', name: 'Singapore', dialCode: '65' },
    { code: 'TH', name: 'Thailand', dialCode: '66' },
    { code: 'VN', name: 'Vietnam', dialCode: '84' },
    { code: 'MY', name: 'Malaysia', dialCode: '60' },
    { code: 'ID', name: 'Indonesia', dialCode: '62' },
    { code: 'GB', name: 'United Kingdom', dialCode: '44' },
    { code: 'CA', name: 'Canada', dialCode: '1' },
    { code: 'AU', name: 'Australia', dialCode: '61' },
    { code: 'CN', name: 'China', dialCode: '86' },
    { code: 'IN', name: 'India', dialCode: '91' },
    { code: 'DE', name: 'Germany', dialCode: '49' },
    { code: 'FR', name: 'France', dialCode: '33' },
    { code: 'IT', name: 'Italy', dialCode: '39' },
    { code: 'ES', name: 'Spain', dialCode: '34' },
    { code: 'AE', name: 'United Arab Emirates', dialCode: '971' },
    { code: 'HK', name: 'Hong Kong', dialCode: '852' },
    { code: 'TW', name: 'Taiwan', dialCode: '886' },
    { code: 'NZ', name: 'New Zealand', dialCode: '64' },
    { code: 'BR', name: 'Brazil', dialCode: '55' },
    { code: 'MX', name: 'Mexico', dialCode: '52' },
    { code: 'ZA', name: 'South Africa', dialCode: '27' },
    { code: 'RU', name: 'Russia', dialCode: '7' },
    { code: 'NL', name: 'Netherlands', dialCode: '31' },
    { code: 'CH', name: 'Switzerland', dialCode: '41' },
    { code: 'SE', name: 'Sweden', dialCode: '46' },
    { code: 'NO', name: 'Norway', dialCode: '47' },
    { code: 'FI', name: 'Finland', dialCode: '358' },
    { code: 'DK', name: 'Denmark', dialCode: '45' },
    { code: 'IE', name: 'Ireland', dialCode: '353' },
    { code: 'BE', name: 'Belgium', dialCode: '32' },
    { code: 'AT', name: 'Austria', dialCode: '43' },
    { code: 'PT', name: 'Portugal', dialCode: '351' },
    { code: 'GR', name: 'Greece', dialCode: '30' },
    { code: 'TR', name: 'Turkey', dialCode: '90' },
    { code: 'SA', name: 'Saudi Arabia', dialCode: '966' },
    { code: 'QA', name: 'Qatar', dialCode: '974' },
    { code: 'IL', name: 'Israel', dialCode: '972' },
    { code: 'EG', name: 'Egypt', dialCode: '20' },
    { code: 'PK', name: 'Pakistan', dialCode: '92' },
    { code: 'BD', name: 'Bangladesh', dialCode: '880' },
];

const GENDER_OPTIONS = [
    { label: 'Male', value: 'M' },
    { label: 'Female', value: 'F' }
];

const getFlagEmoji = (countryCode: string) => {
    const codePoints = countryCode
        .toUpperCase()
        .split('')
        .map(char => 127397 + char.charCodeAt(0));
    try {
        return String.fromCodePoint(...codePoints);
    } catch {
        return '🏳️';
    }
};

const getCountryName = (code: string) => {
    const found = COUNTRIES.find(c => c.code.toUpperCase() === code.toUpperCase());
    return found ? found.name : code;
};

export default function FlightCheckoutScreen() {
    const STRIPE_KEY = process.env.EXPO_PUBLIC_STRIPE_PUBLISHABLE_KEY ?? '';
    if (StripeProvider && STRIPE_KEY) {
        const SP = StripeProvider;
        return (
            <SP
                publishableKey={STRIPE_KEY}
                merchantIdentifier="com.cheapestgo.mobile"
                urlScheme="mobileapp"
            >
                <FlightCheckoutContent stripeAvailable />
            </SP>
        );
    }
    return <FlightCheckoutContent stripeAvailable={false} />;
}

function FlightCheckoutContent({ stripeAvailable }: { stripeAvailable: boolean }) {
    const params = useLocalSearchParams();
    const router = useRouter();
    const colorScheme = useColorScheme();
    const isDark = colorScheme === 'dark';
    const { currency } = useSettings();
    const { user } = useAuth();
    const styles = getStyles(isDark);

    const stripeHook = stripeAvailable && useStripeHook ? useStripeHook() : null;
    const initPaymentSheet = stripeHook?.initPaymentSheet;
    const presentPaymentSheet = stripeHook?.presentPaymentSheet;

    // Parse Selected Offer
    const offer: FlightOffer | null = useMemo(() => {
        if (!params.offerData) return null;
        try {
            return JSON.parse(params.offerData as string);
        } catch (e) {
            console.error('Failed to parse offerData', e);
            return null;
        }
    }, [params.offerData]);

    // Booking Steps state
    const [step, setStep] = useState<'form' | 'confirming' | 'success'>('form');
    const [booking, setBooking] = useState(false);
    const [bookingStepIdx, setBookingStepIdx] = useState(0);
    const [bookingResult, setBookingResult] = useState<any>(null);

    // Form State (Single Passenger for GDS validation)
    // Passengers — pre-fill name from logged-in user
    const [passengers, setPassengers] = useState<any[]>([
        {
            type: 'ADT',
            firstName: user?.firstName ?? '',
            lastName: user?.lastName ?? '',
            gender: '',
            birthDate: '',
            nationality: '',
            passport: '',
            passportExpiry: ''
        }
    ]);

    // Contact — pre-fill email from logged-in user
    const [email, setEmail] = useState(user?.email ?? '');
    const [phone, setPhone] = useState('');

    const [countryCode, setCountryCode] = useState('63');

    // Billing Address
    const [addressLine1, setAddressLine1] = useState('123');
    const [addressLine2, setAddressLine2] = useState('123');
    const [postalCode, setPostalCode] = useState('1000');
    const [billingCountry, setBillingCountry] = useState('KR');

    // Accordions
    const [bagsExpanded, setBagsExpanded] = useState(false);
    const [seatsExpanded, setSeatsExpanded] = useState(false);

    // Form Errors
    const [errors, setErrors] = useState<Record<string, string>>({});
    const scrollRef = useRef<ScrollView>(null);

    // Custom Date Picker Modal State
    const [pickerVisible, setPickerVisible] = useState(false);
    const [pickerTarget, setPickerTarget] = useState<'birthDate' | 'passportExpiry' | null>(null);
    const [pickerYear, setPickerYear] = useState(1995);
    const [pickerMonth, setPickerMonth] = useState(7); // August (0-indexed)
    const [pickerDay, setPickerDay] = useState(15);
    const [monthDropdownOpen, setMonthDropdownOpen] = useState(false);
    const [yearDropdownOpen, setYearDropdownOpen] = useState(false);

    // Custom Dropdown Modal State
    const [dropdownVisible, setDropdownVisible] = useState(false);
    const [dropdownTarget, setDropdownTarget] = useState<'gender' | 'nationality' | 'billingCountry' | 'countryCode' | null>(null);
    const [dropdownSearch, setDropdownSearch] = useState('');

    // Seat Selection State (live from API)
    const [selectedSeats, setSelectedSeats] = useState<Record<string, string>>({}); // designator → serviceId
    const [activeSegmentTab, setActiveSegmentTab] = useState(0);
    const [seatMaps, setSeatMaps] = useState<NormalizedSegmentSeatMap[]>([]);
    const [seatMapLoading, setSeatMapLoading] = useState(false);
    const [seatMapUnavailable, setSeatMapUnavailable] = useState(false);

    // Bag Selection State (live from API)
    const [bagOptions, setBagOptions] = useState<NormalizedBagOption[]>([]);
    const [bagLoading, setBagLoading] = useState(false);
    const [selectedBags, setSelectedBags] = useState<Record<string, number>>({}); // serviceId → quantity

    // Date Calculation Helpers
    const getDaysInMonth = useCallback((year: number, month: number) => {
        return new Date(year, month + 1, 0).getDate();
    }, []);

    const getFirstDayOfMonth = useCallback((year: number, month: number) => {
        return new Date(year, month, 1).getDay();
    }, []);

    // Progress animation during booking
    useEffect(() => {
        if (step !== 'confirming') return;
        setBookingStepIdx(0);
        const timer = setInterval(() => {
            setBookingStepIdx(i => Math.min(i + 1, BOOKING_STEPS.length - 1));
        }, 3500);
        return () => clearInterval(timer);
    }, [step]);

    // Format helper for Airport Title
    const destinationAirport = offer?.segments[offer.segments.length - 1]?.arrival?.airport || 'Destination';
    const destinationCode = offer?.segments[offer.segments.length - 1]?.arrival?.airport || 'DAD';
    const isRoundTrip = offer?.tripType === 'round-trip';
    const titleText = `${isRoundTrip ? 'Round trip' : 'One way'} to ${destinationAirport} (${destinationCode})`;

    // ── Load real bags + seat-map from web API when screen mounts ─────────
    useEffect(() => {
        if (!offer) return;
        const rawOffer = (offer as any)._rawOffer;
        if (!rawOffer?.id) return;

        const duffelPassengerIds: string[] = (rawOffer.passengers ?? []).map((p: any) => p.id);
        const offerSegments = (offer.segments ?? []).map((s: any) => ({
            origin: s.departure?.airport ?? s.origin ?? '',
            destination: s.arrival?.airport ?? s.destination ?? '',
        }));

        // Bags
        setBagLoading(true);
        webFetchBags(rawOffer.id, duffelPassengerIds)
            .then(res => { if (res.success) setBagOptions(res.bagOptions); })
            .catch(() => { })
            .finally(() => setBagLoading(false));

        // Seat map
        setSeatMapLoading(true);
        webFetchSeatMap(rawOffer.id, offerSegments)
            .then(res => {
                if (res.unavailable) { setSeatMapUnavailable(true); return; }
                if (res.success) setSeatMaps(res.seatMaps);
            })
            .catch(async (err) => {
                // Offer expired → try refresh
                if (err.status === 404 && rawOffer) {
                    try {
                        const refreshed = await webRefreshOffer(rawOffer);
                        if (refreshed.success && refreshed.newOffer) {
                            const newRaw = (refreshed.newOffer as any)._rawOffer;
                            if (newRaw?.id) {
                                const retry = await webFetchSeatMap(newRaw.id, offerSegments);
                                if (retry.success) setSeatMaps(retry.seatMaps);
                            }
                        }
                    } catch {/* seat map optional */ }
                }
            })
            .finally(() => setSeatMapLoading(false));
    }, [offer]);

    const openDatePicker = (target: 'birthDate' | 'passportExpiry', currentValue: string) => {
        setPickerTarget(target);
        if (currentValue && /^\d{4}-\d{2}-\d{2}$/.test(currentValue)) {
            const [y, m, d] = currentValue.split('-').map(Number);
            setPickerYear(y);
            setPickerMonth(m - 1);
            setPickerDay(d);
        } else {
            const fallbackYear = target === 'birthDate' ? 1995 : 2030;
            setPickerYear(fallbackYear);
            setPickerMonth(7); // August
            setPickerDay(15);
        }
        setMonthDropdownOpen(false);
        setYearDropdownOpen(false);
        setPickerVisible(true);
    };

    const handlePrevMonth = () => {
        if (pickerMonth === 0) {
            setPickerMonth(11);
            setPickerYear(y => y - 1);
        } else {
            setPickerMonth(m => m - 1);
        }
    };

    const handleNextMonth = () => {
        if (pickerMonth === 11) {
            setPickerMonth(0);
            setPickerYear(y => y + 1);
        } else {
            setPickerMonth(m => m + 1);
        }
    };

    const MONTHS = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];

    const daysInMonth = getDaysInMonth(pickerYear, pickerMonth);
    const firstDayIndex = getFirstDayOfMonth(pickerYear, pickerMonth);

    const cells: (number | null)[] = [];
    for (let i = 0; i < firstDayIndex; i++) {
        cells.push(null);
    }
    for (let i = 1; i <= daysInMonth; i++) {
        cells.push(i);
    }

    const handleSelectDate = () => {
        const monthStr = String(pickerMonth + 1).padStart(2, '0');
        const dayStr = String(pickerDay).padStart(2, '0');
        const formattedDate = `${pickerYear}-${monthStr}-${dayStr}`;

        const next = [...passengers];
        if (pickerTarget === 'birthDate') {
            next[0].birthDate = formattedDate;
        } else if (pickerTarget === 'passportExpiry') {
            next[0].passportExpiry = formattedDate;
        }
        setPassengers(next);
        setPickerVisible(false);
    };

    const validateForm = () => {
        const errs: Record<string, string> = {};
        if (!email.trim() || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
            errs.email = 'Valid email is required';
        }
        if (!phone.trim()) {
            errs.phone = 'Phone number is required';
        }

        // Validate passenger 1
        const p1 = passengers[0];
        if (!p1.firstName.trim()) errs.firstName = 'First name is required';
        if (!p1.lastName.trim()) errs.lastName = 'Last name is required';
        if (!p1.gender) errs.gender = 'Gender is required';
        if (!p1.birthDate.trim() || !/^\d{4}-\d{2}-\d{2}$/.test(p1.birthDate)) {
            errs.birthDate = 'Birthdate required (YYYY-MM-DD)';
        }
        if (!p1.nationality) errs.nationality = 'Nationality is required';
        if (!p1.passport.trim()) errs.passport = 'Passport number is required';
        if (!p1.passportExpiry.trim() || !/^\d{4}-\d{2}-\d{2}$/.test(p1.passportExpiry)) {
            errs.passportExpiry = 'Expiry required (YYYY-MM-DD)';
        }

        setErrors(errs);
        return Object.keys(errs).length === 0;
    };

    const handleConfirmBooking = async () => {
        if (!validateForm()) {
            scrollRef.current?.scrollTo({ y: 0, animated: true });
            return;
        }
        if (!offer) {
            Alert.alert('Error', 'No flight offer selected.');
            return;
        }

        if (!stripeAvailable || !initPaymentSheet || !presentPaymentSheet) {
            Alert.alert(
                'Payment unavailable',
                'Stripe payments require an EAS development build. Run:\n\neas build --profile development --platform android\n\nThen install the APK and open with "expo start --dev-client".'
            );
            return;
        }

        setBooking(true);

        try {
            // Collect selected seat service IDs
            const seatServiceIds = Object.values(selectedSeats).filter(Boolean);
            const seatTotal = seatMaps
                .flatMap(sm => sm.rows.flatMap(r => r.sections.flat()))
                .filter(s => seatServiceIds.includes(s.serviceId ?? ''))
                .reduce((sum, s) => sum + (s.price ?? 0), 0);

            // Collect selected bag service IDs
            const bagServiceIds: string[] = [];
            let bagTotal = 0;
            for (const [serviceId, qty] of Object.entries(selectedBags)) {
                if (qty > 0) {
                    for (let i = 0; i < qty; i++) bagServiceIds.push(serviceId);
                    const opt = bagOptions.find(b => b.serviceId === serviceId);
                    if (opt) bagTotal += opt.price * qty;
                }
            }

            // Step 1: Duffel pre-order + Stripe PaymentIntent (via web API)
            const bookResult = await webMobileBook({
                provider: 'duffel',
                flight: offer,
                passengers: passengers.map(p => ({
                    type: p.type,
                    title: p.gender === 'F' ? 'ms' : 'mr',
                    firstName: p.firstName,
                    lastName: p.lastName,
                    gender: p.gender as string,
                    birthDate: p.birthDate,
                    nationality: p.nationality || undefined,
                    passport: p.passport || undefined,
                    passportExpiry: p.passportExpiry || undefined,
                })),
                contact: { email, phone, countryCode },
                idempotencyKey: `mob-${Date.now()}-${Math.random().toString(36).slice(2)}`,
                ...(seatServiceIds.length ? { seatServiceIds, seatTotal } : {}),
                ...(bagServiceIds.length ? { bagServiceIds, bagTotal } : {}),
                confirmedPrice: offer.price?.total,
            });

            if (!bookResult.clientSecret) {
                throw new Error('Failed to create payment session');
            }

            // Step 2: Initialize Stripe payment sheet
            const { error: initError } = await initPaymentSheet({
                paymentIntentClientSecret: bookResult.clientSecret,
                merchantDisplayName: 'CheapestGo',
                applePay: { merchantCountryCode: 'US' },
                googlePay: { merchantCountryCode: 'US', testEnv: __DEV__ },
                style: isDark ? 'alwaysDark' : 'alwaysLight',
                returnURL: 'mobileapp://flight-checkout-return',
                defaultBillingDetails: { email, name: `${passengers[0].firstName} ${passengers[0].lastName}` },
            });
            if (initError) throw new Error(initError.message);

            // Present Payment Sheet
            const { error: paymentError } = await presentPaymentSheet();
            if (paymentError) {
                if (paymentError.code === 'Canceled') {
                    return;
                }
                throw new Error(paymentError.message);
            }

            const paymentIntentId = bookResult.clientSecret.split('_secret_')[0];

            // Confirm booking + issue ticket (via web API)
            const confirmResult = await webMobileConfirm(paymentIntentId, bookResult.sessionId);

            setBookingResult(confirmResult);
            setStep('success');
        } catch (err: any) {
            const isPriceChanged = err.priceChanged;
            if (isPriceChanged) {
                // Only show the animated steps screen on price change so user sees the verification step
                setStep('confirming');
                setBookingStepIdx(0);
            } else {
                setStep('form');
            }
            Alert.alert(
                isPriceChanged ? 'Price Changed' : 'Booking Failed',
                isPriceChanged
                    ? `The flight price has changed. Please go back and reselect the flight.`
                    : (err.message || 'Something went wrong during reservation. Please try again.'),
                [{ text: 'OK', onPress: () => setStep('form') }]
            );
        } finally {
            setBooking(false);
        }
    };

    if (step === 'success') {
        const pnr = bookingResult?.pnr || bookingResult?.bookingId || '—';
        return (
            <SafeAreaView style={styles.container}>
                <View style={styles.successContainer}>
                    <View style={styles.successIconWrap}>
                        <CheckCircle size={56} color="#10b981" />
                    </View>
                    <Text style={styles.successTitle}>Booking Successful!</Text>
                    <Text style={styles.successSubtitle}>Your flight tickets have been issued.</Text>

                    <View style={styles.successCard}>
                        <View style={styles.successRow}>
                            <Text style={styles.successLabel}>Airline PNR</Text>
                            <Text style={styles.successValue}>{pnr}</Text>
                        </View>
                        <View style={styles.successRow}>
                            <Text style={styles.successLabel}>Origin</Text>
                            <Text style={styles.successValue}>{offer?.segments[0]?.departure?.airport || 'Origin'}</Text>
                        </View>
                        <View style={styles.successRow}>
                            <Text style={styles.successLabel}>Destination</Text>
                            <Text style={styles.successValue}>{offer?.segments[offer.segments.length - 1]?.arrival?.airport || 'Destination'}</Text>
                        </View>
                        <View style={[styles.successRow, { borderBottomWidth: 0 }]}>
                            <Text style={styles.successLabel}>Total Paid</Text>
                            <Text style={[styles.successValue, { color: '#2563eb', fontWeight: '800' }]}>
                                {offer?.price?.currency || 'USD'} {Math.round(offer?.price?.total || 0).toLocaleString()}
                            </Text>
                        </View>
                    </View>

                    <View style={styles.successEmailRow}>
                        <Mail size={16} color="#94a3b8" />
                        <Text style={styles.successEmailText}>Confirmation sent to {email}</Text>
                    </View>

                    <Pressable style={styles.successBtn} onPress={() => router.dismissAll()}>
                        <Text style={styles.successBtnText}>Back to Home</Text>
                    </Pressable>
                </View>
            </SafeAreaView>
        );
    }

    if (step === 'confirming') {
        return (
            <SafeAreaView style={styles.container}>
                <View style={styles.confirmingContainer}>
                    <ActivityIndicator size="large" color="#2563eb" style={{ marginBottom: 24 }} />
                    <Text style={styles.confirmingTitle}>Confirming your booking</Text>
                    <Text style={styles.confirmingStep}>{BOOKING_STEPS[bookingStepIdx]}</Text>
                    <View style={{ marginTop: 32, gap: 14, width: '100%', maxWidth: 280 }}>
                        {BOOKING_STEPS.map((label, i) => (
                            <View key={label} style={{ flexDirection: 'row', alignItems: 'center', gap: 10 }}>
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
                    <Text style={styles.confirmingHint}>Please do not close or minimize the application</Text>
                </View>
            </SafeAreaView>
        );
    }

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
                    <Text style={styles.headerTitle} numberOfLines={1}>{titleText}</Text>
                    <View style={{ width: 40 }} />
                </View>

                <ScrollView
                    ref={scrollRef}
                    style={styles.scrollView}
                    showsVerticalScrollIndicator={false}
                    contentContainerStyle={{ paddingBottom: 60 }}
                >
                    {/* Selected Flight Summary Card */}
                    {offer && (
                        <View style={styles.summaryCard}>
                            <View style={styles.summaryHeader}>
                                <View style={styles.carrierLogoWrap}>
                                    <View style={styles.planeIconBackground}>
                                        <Briefcase size={16} color="#ffffff" />
                                    </View>
                                </View>
                                <View style={{ flex: 1 }}>
                                    <Text style={styles.carrierName}>{offer.validatingAirline || offer.segments[0]?.airline?.name || offer.provider}</Text>
                                    <Text style={styles.flightCode}>{offer.segments[0]?.airline?.code || ''}{offer.segments[0]?.flightNumber || 'ZZ7764'}</Text>
                                </View>
                                <View style={{ alignItems: 'flex-end' }}>
                                    <Text style={styles.summaryPrice}>{offer.price.currency} {Math.round(offer.price.total).toLocaleString()}</Text>
                                    <Text style={styles.summaryPriceLabel}>total price</Text>
                                </View>
                            </View>

                            <View style={styles.routeContainer}>
                                <View style={styles.routeRow}>
                                    <View style={{ flex: 1 }}>
                                        <Text style={styles.routeTime}>{offer.segments[0]?.departure?.time ? new Date(offer.segments[0].departure.time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: false }) : '13:50'}</Text>
                                        <Text style={styles.routeAirport}>{offer.segments[0]?.departure?.airport || 'CRK'}</Text>
                                    </View>

                                    <View style={styles.timelineContainer}>
                                        <Text style={styles.timelineDuration}>{formatDuration(offer.totalDuration)}</Text>
                                        <View style={styles.timelineLine} />
                                        <Text style={styles.timelineStops}>{offer.totalStops === 0 ? 'Nonstop' : `${offer.totalStops} stop${offer.totalStops > 1 ? 's' : ''}`}</Text>
                                    </View>

                                    <View style={{ flex: 1, alignItems: 'flex-end' }}>
                                        <Text style={styles.routeTime}>{offer.segments[offer.segments.length - 1]?.arrival?.time ? new Date(offer.segments[offer.segments.length - 1].arrival.time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: false }) : '19:30'}</Text>
                                        <Text style={styles.routeAirport}>{offer.segments[offer.segments.length - 1]?.arrival?.airport || 'DAD'}</Text>
                                    </View>
                                </View>
                            </View>
                        </View>
                    )}

                    {/* Expo Go warning — Stripe not available */}
                    {!stripeAvailable && (
                        <View style={styles.errorBanner}>
                            <AlertTriangle size={18} color="#d97706" />
                            <Text style={[styles.errorBannerText, { color: '#d97706' }]}>
                                Stripe payments require an EAS dev build — not available in Expo Go.
                            </Text>
                        </View>
                    )}

                    {/* Explore prices section */}
                    <View style={styles.exploreSection}>
                        <Globe size={16} color={isDark ? '#38bdf8' : '#2563eb'} />
                        <Text style={styles.exploreText}>Explore prices by date (Round-trip)</Text>
                        <View style={styles.exploreBadge}>
                            <Text style={styles.exploreBadgeText}>From $118</Text>
                            <ChevronDown size={14} color={isDark ? '#94a3b8' : '#64748b'} />
                        </View>
                    </View>

                    {/* Fare Policy Alert/Warning Banner */}
                    <View style={styles.warningCard}>
                        <View style={styles.warningHeader}>
                            <AlertTriangle size={20} color="#f59e0b" />
                            <Text style={styles.warningTitle}>Fare policy updated</Text>
                        </View>
                        <Text style={styles.warningText}>
                            The refundability of this fare has changed since you selected it. Please review before proceeding.
                        </Text>

                        <View style={styles.farePolicySection}>
                            <View style={styles.policyRow}>
                                <Text style={styles.policyRowLabel}>Fare Policy</Text>
                                <Text style={styles.policyRowStatus}>✓ Airline confirmed</Text>
                            </View>

                            <View style={styles.policyBadge}>
                                <ShieldAlert size={14} color="#ef4444" />
                                <Text style={styles.policyBadgeText}>Non-refundable</Text>
                            </View>

                            <Text style={styles.policyFooter}>Real fare rules confirmed by airline during booking.</Text>
                        </View>
                    </View>

                    {/* Inline Validation Alert */}
                    {Object.keys(errors).length > 0 && (
                        <View style={styles.inlineValidationCard}>
                            <View style={styles.inlineValidationHeader}>
                                <AlertTriangle size={18} color="#ef4444" />
                                <Text style={styles.inlineValidationTitle}>Incomplete Information</Text>
                            </View>
                            <Text style={styles.inlineValidationText}>
                                Please complete the required passenger and contact fields highlighted in red below to confirm your booking.
                            </Text>
                        </View>
                    )}

                    {/* Passenger details card (Passenger 1) */}
                    <View style={styles.card}>
                        <View style={styles.cardHeader}>
                            <User size={18} color="#2563eb" />
                            <Text style={styles.cardTitle}>Passenger 1</Text>
                            <View style={styles.passengerTypeDropdown}>
                                <Text style={styles.passengerTypeText}>Adult</Text>
                                <ChevronDown size={14} color={isDark ? '#94a3b8' : '#64748b'} />
                            </View>
                        </View>

                        <View style={styles.inputGroup}>
                            <TextInput
                                style={[styles.input, errors.firstName ? styles.inputError : null]}
                                placeholder="First Name *"
                                placeholderTextColor={isDark ? '#475569' : '#94a3b8'}
                                value={passengers[0].firstName}
                                onChangeText={(text) => {
                                    const next = [...passengers];
                                    next[0].firstName = text;
                                    setPassengers(next);
                                }}
                            />
                            {errors.firstName && <Text style={styles.errorText}>{errors.firstName}</Text>}
                        </View>

                        <View style={styles.inputGroup}>
                            <TextInput
                                style={[styles.input, errors.lastName ? styles.inputError : null]}
                                placeholder="Last Name *"
                                placeholderTextColor={isDark ? '#475569' : '#94a3b8'}
                                value={passengers[0].lastName}
                                onChangeText={(text) => {
                                    const next = [...passengers];
                                    next[0].lastName = text;
                                    setPassengers(next);
                                }}
                            />
                            {errors.lastName && <Text style={styles.errorText}>{errors.lastName}</Text>}
                        </View>

                        <View style={styles.inputGroup}>
                            <Pressable
                                style={[styles.dropdownPlaceholder, errors.gender ? styles.inputError : null]}
                                onPress={() => {
                                    setDropdownTarget('gender');
                                    setDropdownSearch('');
                                    setDropdownVisible(true);
                                }}
                            >
                                <Text style={{
                                    fontSize: 14,
                                    color: passengers[0].gender ? (isDark ? '#ffffff' : '#0f172a') : (isDark ? '#475569' : '#94a3b8'),
                                    fontWeight: passengers[0].gender ? '500' : 'normal'
                                }}>
                                    {passengers[0].gender
                                        ? (passengers[0].gender === 'M' ? 'Male' : 'Female')
                                        : 'Gender *'}
                                </Text>
                                <ChevronDown size={16} color={isDark ? '#94a3b8' : '#64748b'} />
                            </Pressable>
                            {errors.gender && <Text style={styles.errorText}>{errors.gender}</Text>}
                        </View>

                        <View style={styles.inputGroup}>
                            <Pressable
                                style={[styles.input, errors.birthDate ? styles.inputError : null, { justifyContent: 'center' }]}
                                onPress={() => openDatePicker('birthDate', passengers[0].birthDate)}
                            >
                                <Text style={{
                                    fontSize: 14,
                                    color: passengers[0].birthDate ? (isDark ? '#ffffff' : '#0f172a') : (isDark ? '#475569' : '#94a3b8'),
                                    fontWeight: passengers[0].birthDate ? '500' : 'normal'
                                }}>
                                    {passengers[0].birthDate || 'Birthdate * (YYYY-MM-DD)'}
                                </Text>
                            </Pressable>
                            {errors.birthDate && <Text style={styles.errorText}>{errors.birthDate}</Text>}
                        </View>

                        <View style={styles.inputGroup}>
                            <Pressable
                                style={[styles.dropdownPlaceholder, errors.nationality ? styles.inputError : null]}
                                onPress={() => {
                                    setDropdownTarget('nationality');
                                    setDropdownSearch('');
                                    setDropdownVisible(true);
                                }}
                            >
                                <Text style={{
                                    fontSize: 14,
                                    color: passengers[0].nationality ? (isDark ? '#ffffff' : '#0f172a') : (isDark ? '#475569' : '#94a3b8'),
                                    fontWeight: passengers[0].nationality ? '500' : 'normal'
                                }}>
                                    {passengers[0].nationality
                                        ? getCountryName(passengers[0].nationality)
                                        : 'Nationality *'}
                                </Text>
                                <ChevronDown size={16} color={isDark ? '#94a3b8' : '#64748b'} />
                            </Pressable>
                            {errors.nationality && <Text style={styles.errorText}>{errors.nationality}</Text>}
                        </View>

                        <View style={styles.inputGroup}>
                            <TextInput
                                style={[styles.input, errors.passport ? styles.inputError : null]}
                                placeholder="Passport Number *"
                                placeholderTextColor={isDark ? '#475569' : '#94a3b8'}
                                value={passengers[0].passport}
                                onChangeText={(text) => {
                                    const next = [...passengers];
                                    next[0].passport = text;
                                    setPassengers(next);
                                }}
                            />
                            {errors.passport && <Text style={styles.errorText}>{errors.passport}</Text>}
                        </View>

                        <View style={styles.inputGroup}>
                            <Pressable
                                style={[styles.input, errors.passportExpiry ? styles.inputError : null, { justifyContent: 'center' }]}
                                onPress={() => openDatePicker('passportExpiry', passengers[0].passportExpiry)}
                            >
                                <Text style={{
                                    fontSize: 14,
                                    color: passengers[0].passportExpiry ? (isDark ? '#ffffff' : '#0f172a') : (isDark ? '#475569' : '#94a3b8'),
                                    fontWeight: passengers[0].passportExpiry ? '500' : 'normal'
                                }}>
                                    {passengers[0].passportExpiry || 'Passport Expiry Date * (YYYY-MM-DD)'}
                                </Text>
                            </Pressable>
                            {errors.passportExpiry && <Text style={styles.errorText}>{errors.passportExpiry}</Text>}
                        </View>
                    </View>

                    {/* Add Passenger Button */}
                    <Pressable style={styles.addPassengerBtn}>
                        <Plus size={16} color={isDark ? '#38bdf8' : '#2563eb'} />
                        <Text style={styles.addPassengerText}>Add Passenger</Text>
                    </Pressable>

                    {/* Contact details */}
                    <View style={styles.card}>
                        <View style={styles.cardHeader}>
                            <Mail size={18} color="#2563eb" />
                            <Text style={styles.cardTitle}>Contact Information</Text>
                        </View>

                        <View style={styles.inputGroup}>
                            <TextInput
                                style={[styles.input, errors.email ? styles.inputError : null]}
                                placeholder="Email *"
                                placeholderTextColor={isDark ? '#475569' : '#94a3b8'}
                                value={email}
                                onChangeText={setEmail}
                                keyboardType="email-address"
                                autoCapitalize="none"
                            />
                            {errors.email && <Text style={styles.errorText}>{errors.email}</Text>}
                        </View>

                        <View style={styles.phoneInputRow}>
                            <Pressable
                                style={styles.countryCodeSelector}
                                onPress={() => {
                                    setDropdownTarget('countryCode');
                                    setDropdownSearch('');
                                    setDropdownVisible(true);
                                }}
                            >
                                <Text style={styles.countryCodeText}>+{countryCode}</Text>
                                <ChevronDown size={14} color={isDark ? '#94a3b8' : '#64748b'} />
                            </Pressable>

                            <View style={{ flex: 1 }}>
                                <TextInput
                                    style={[styles.input, errors.phone ? styles.inputError : null]}
                                    placeholder="Phone Number *"
                                    placeholderTextColor={isDark ? '#475569' : '#94a3b8'}
                                    value={phone}
                                    onChangeText={setPhone}
                                    keyboardType="phone-pad"
                                />
                                {errors.phone && <Text style={styles.errorText}>{errors.phone}</Text>}
                            </View>
                        </View>
                    </View>

                    {/* Billing address details */}
                    <View style={styles.card}>
                        <View style={styles.cardHeader}>
                            <MapPin size={18} color="#2563eb" />
                            <Text style={styles.cardTitle}>Billing Address</Text>
                        </View>

                        <View style={styles.inputGroup}>
                            <TextInput
                                style={styles.input}
                                placeholder="Address Line 1"
                                placeholderTextColor={isDark ? '#475569' : '#94a3b8'}
                                value={addressLine1}
                                onChangeText={setAddressLine1}
                            />
                        </View>

                        <View style={styles.inputGroup}>
                            <TextInput
                                style={styles.input}
                                placeholder="Address Line 2"
                                placeholderTextColor={isDark ? '#475569' : '#94a3b8'}
                                value={addressLine2}
                                onChangeText={setAddressLine2}
                            />
                        </View>

                        <View style={styles.inputGroup}>
                            <TextInput
                                style={styles.input}
                                placeholder="Postal Code"
                                placeholderTextColor={isDark ? '#475569' : '#94a3b8'}
                                value={postalCode}
                                onChangeText={setPostalCode}
                            />
                        </View>

                        <View style={styles.inputGroup}>
                            <Pressable
                                style={styles.dropdownPlaceholder}
                                onPress={() => {
                                    setDropdownTarget('billingCountry');
                                    setDropdownSearch('');
                                    setDropdownVisible(true);
                                }}
                            >
                                <Text style={{
                                    fontSize: 14,
                                    color: billingCountry ? (isDark ? '#ffffff' : '#0f172a') : (isDark ? '#475569' : '#94a3b8'),
                                    fontWeight: billingCountry ? '500' : 'normal'
                                }}>
                                    {billingCountry ? getCountryName(billingCountry) : 'Billing Country *'}
                                </Text>
                                <ChevronDown size={16} color={isDark ? '#94a3b8' : '#64748b'} />
                            </Pressable>
                        </View>
                    </View>

                    {/* Bags accordion */}
                    <View style={styles.card}>
                        <Pressable style={styles.accordionHeader} onPress={() => setBagsExpanded(!bagsExpanded)}>
                            <View style={styles.accordionTitleWrap}>
                                <View style={styles.accordionIconBG}>
                                    <Briefcase size={16} color="#3b82f6" />
                                </View>
                                <View>
                                    <Text style={styles.accordionTitle}>Extra Bags</Text>
                                    <Text style={styles.accordionSubtitle}>Optional — add checked or carry-on bags</Text>
                                </View>
                            </View>
                            {bagsExpanded ? <ChevronUp size={18} color="#64748b" /> : <ChevronDown size={18} color="#64748b" />}
                        </Pressable>

                        {bagsExpanded && (
                            <View style={styles.accordionContent}>
                                <Text style={styles.accordionText}>Checked bag options will load from the airline during payment verification.</Text>
                            </View>
                        )}
                    </View>

                    {/* Seat selection accordion */}
                    <View style={styles.card}>
                        <Pressable style={styles.accordionHeader} onPress={() => setSeatsExpanded(!seatsExpanded)}>
                            <View style={styles.accordionTitleWrap}>
                                <View style={styles.accordionIconBG}>
                                    <Ticket size={16} color="#3b82f6" />
                                </View>
                                <View>
                                    <Text style={styles.accordionTitle}>Seat Selection</Text>
                                    <Text style={styles.accordionSubtitle}>Optional — pick your seat on the cabin map</Text>
                                </View>
                            </View>
                            {seatsExpanded ? <ChevronUp size={18} color="#64748b" /> : <ChevronDown size={18} color="#64748b" />}
                        </Pressable>

                        {seatsExpanded && (() => {
                            const totalSegs = offer?.segments?.length || 2;
                            const selectedCount = Object.keys(selectedSeats).length;
                            const progressVal = totalSegs > 0 ? selectedCount / totalSegs : 0;

                            const activeTabs = offer?.segments && offer.segments.length > 0
                                ? offer.segments.map(seg => ({
                                    origin: seg.origin || 'CRK',
                                    destination: seg.destination || 'DAD',
                                }))
                                : [
                                    { origin: 'CRK', destination: 'DAD' },
                                    { origin: 'DAD', destination: 'CRK' }
                                ];

                            return (
                                <View style={styles.accordionContent}>
                                    {/* Progress row */}
                                    <View style={styles.seatProgressRow}>
                                        <View style={styles.seatProgressOuterBar}>
                                            <View style={[styles.seatProgressInnerBar, { width: `${Math.min(1, progressVal) * 100}%` }]} />
                                        </View>
                                        <Text style={styles.seatProgressCount}>{selectedCount}/{totalSegs} seats</Text>
                                    </View>

                                    {/* Segment tabs */}
                                    <View style={styles.seatTabsRow}>
                                        {activeTabs.map((tab, idx) => (
                                            <Pressable
                                                key={idx}
                                                style={[styles.seatTabBtn, activeSegmentTab === idx && styles.seatTabBtnActive]}
                                                onPress={() => setActiveSegmentTab(idx)}
                                            >
                                                <Text style={[styles.seatTabBtnText, activeSegmentTab === idx && styles.seatTabBtnTextActive]}>
                                                    ✈ {tab.origin} ➔ {tab.destination}
                                                </Text>
                                            </Pressable>
                                        ))}
                                    </View>

                                    <Text style={styles.seatSelectHint}>Tap a seat to select it</Text>

                                    {/* Cabin outer container */}
                                    <View style={styles.cabinContainer}>
                                        <Text style={styles.cabinClassLabel}>ECONOMY</Text>

                                        {/* Column Headers */}
                                        <View style={styles.cabinHeaderRow}>
                                            <Text style={styles.cabinColumnHeader}>A</Text>
                                            <Text style={styles.cabinColumnHeader}>B</Text>
                                            <Text style={styles.cabinColumnHeader}>C</Text>
                                            <View style={styles.cabinAisleSpace} />
                                            <Text style={styles.cabinColumnHeader}>D</Text>
                                            <Text style={styles.cabinColumnHeader}>E</Text>
                                        </View>

                                        {/* Grid Rows */}
                                        {SEAT_ROWS.map((rowConfig: RowConfig) => (
                                            <View key={rowConfig.row} style={styles.cabinRow}>
                                                <Text style={styles.cabinRowLabel}>{rowConfig.row}</Text>

                                                {/* Seat A, B, C */}
                                                {rowConfig.seats.slice(0, 3).map((seat: SeatConfig) => {
                                                    const seatCode = `${rowConfig.row}${seat.code}`;
                                                    const isSelected = selectedSeats[activeSegmentTab] === seatCode;
                                                    const isTaken = seat.type === 'taken';

                                                    // Seat classes based on type
                                                    let seatStyle: any = styles.seatFree;
                                                    let textStyle: any = styles.seatTextFree;

                                                    if (isTaken) {
                                                        seatStyle = styles.seatTaken;
                                                        textStyle = styles.seatTextTaken;
                                                    } else if (isSelected) {
                                                        seatStyle = styles.seatSelected;
                                                        textStyle = styles.seatTextSelected;
                                                    } else if (seat.type === 'paid') {
                                                        seatStyle = styles.seatPaid;
                                                        textStyle = styles.seatTextPaid;
                                                    } else if (seat.type === 'legroom') {
                                                        seatStyle = styles.seatLegroom;
                                                        textStyle = styles.seatTextLegroom;
                                                    } else if (seat.type === 'exit') {
                                                        seatStyle = styles.seatExit;
                                                        textStyle = styles.seatTextExit;
                                                    }

                                                    return (
                                                        <Pressable
                                                            key={seat.code}
                                                            disabled={isTaken}
                                                            style={[styles.seatButton, seatStyle]}
                                                            onPress={() => {
                                                                const next = { ...selectedSeats };
                                                                if (next[activeSegmentTab] === seatCode) {
                                                                    delete next[activeSegmentTab];
                                                                } else {
                                                                    next[activeSegmentTab] = seatCode;
                                                                }
                                                                setSelectedSeats(next);
                                                            }}
                                                        >
                                                            <Text style={[styles.seatButtonText, textStyle]}>
                                                                {seat.code}
                                                            </Text>
                                                        </Pressable>
                                                    );
                                                })}

                                                {/* Aisle */}
                                                <View style={styles.cabinAisleSpace} />

                                                {/* Seat D, E */}
                                                {rowConfig.seats.slice(3, 5).map((seat: SeatConfig) => {
                                                    const seatCode = `${rowConfig.row}${seat.code}`;
                                                    const isSelected = selectedSeats[activeSegmentTab] === seatCode;
                                                    const isTaken = seat.type === 'taken';

                                                    let seatStyle: any = styles.seatFree;
                                                    let textStyle: any = styles.seatTextFree;

                                                    if (isTaken) {
                                                        seatStyle = styles.seatTaken;
                                                        textStyle = styles.seatTextTaken;
                                                    } else if (isSelected) {
                                                        seatStyle = styles.seatSelected;
                                                        textStyle = styles.seatTextSelected;
                                                    } else if (seat.type === 'paid') {
                                                        seatStyle = styles.seatPaid;
                                                        textStyle = styles.seatTextPaid;
                                                    } else if (seat.type === 'legroom') {
                                                        seatStyle = styles.seatLegroom;
                                                        textStyle = styles.seatTextLegroom;
                                                    } else if (seat.type === 'exit') {
                                                        seatStyle = styles.seatExit;
                                                        textStyle = styles.seatTextExit;
                                                    }

                                                    return (
                                                        <Pressable
                                                            key={seat.code}
                                                            disabled={isTaken}
                                                            style={[styles.seatButton, seatStyle]}
                                                            onPress={() => {
                                                                const next = { ...selectedSeats };
                                                                if (next[activeSegmentTab] === seatCode) {
                                                                    delete next[activeSegmentTab];
                                                                } else {
                                                                    next[activeSegmentTab] = seatCode;
                                                                }
                                                                setSelectedSeats(next);
                                                            }}
                                                        >
                                                            <Text style={[styles.seatButtonText, textStyle]}>
                                                                {seat.code}
                                                            </Text>
                                                        </Pressable>
                                                    );
                                                })}
                                            </View>
                                        ))}
                                    </View>

                                    {/* Legend Grid */}
                                    <View style={styles.legendContainer}>
                                        <View style={styles.legendRow}>
                                            <View style={styles.legendItem}>
                                                <View style={[styles.legendBox, styles.seatFreeBox, { width: 14, height: 14 }]} />
                                                <Text style={styles.legendText}>Free</Text>
                                            </View>
                                            <View style={styles.legendItem}>
                                                <View style={[styles.legendBox, styles.seatPaidBox, { width: 14, height: 14 }]} />
                                                <Text style={styles.legendText}>Paid</Text>
                                            </View>
                                            <View style={styles.legendItem}>
                                                <View style={[styles.legendBox, styles.seatTakenBox, { width: 14, height: 14 }]} />
                                                <Text style={styles.legendText}>Taken</Text>
                                            </View>
                                            <View style={styles.legendItem}>
                                                <View style={[styles.legendBox, styles.seatSelectedBox, { width: 14, height: 14 }]} />
                                                <Text style={styles.legendText}>Selected</Text>
                                            </View>
                                        </View>
                                        <View style={styles.legendRow}>
                                            <View style={styles.legendItem}>
                                                <View style={[styles.legendBox, styles.seatLegroomBox, { width: 14, height: 14 }]} />
                                                <Text style={styles.legendText}>Extra legroom</Text>
                                            </View>
                                            <View style={styles.legendItem}>
                                                <View style={[styles.legendBox, styles.seatExitBox, { width: 14, height: 14 }]} />
                                                <Text style={styles.legendText}>Exit row</Text>
                                            </View>
                                        </View>
                                    </View>

                                    {/* Bottom Buttons matching Screenshot 3 */}
                                    <View style={styles.seatAccordionFooter}>
                                        <Pressable
                                            style={styles.seatSkipButton}
                                            onPress={() => setSeatsExpanded(false)}
                                        >
                                            <Text style={styles.seatSkipButtonText}>Skip</Text>
                                        </Pressable>

                                        <Pressable
                                            style={styles.seatScrollTopButton}
                                            onPress={() => setSeatsExpanded(false)}
                                        >
                                            <ArrowLeft size={16} color="white" style={{ transform: [{ rotate: '90deg' }] }} />
                                        </Pressable>
                                    </View>
                                </View>
                            );
                        })()}
                    </View>

                    {/* Custom Date Picker Modal */}
                    <Modal
                        visible={pickerVisible}
                        transparent={true}
                        animationType="fade"
                        onRequestClose={() => setPickerVisible(false)}
                    >
                        <View style={styles.modalOverlay}>
                            <View style={styles.datePickerContainer}>
                                {/* Header Month / Year Selectors */}
                                <View style={styles.datePickerHeader}>
                                    <View style={{ flexDirection: 'row', gap: 16, alignItems: 'center' }}>
                                        {/* Month Toggle */}
                                        <Pressable
                                            style={styles.selectorPressable}
                                            onPress={() => {
                                                setMonthDropdownOpen(!monthDropdownOpen);
                                                setYearDropdownOpen(false);
                                            }}
                                        >
                                            <Text style={styles.selectorText}>{MONTHS[pickerMonth]}</Text>
                                            <ChevronDown size={14} color="#3b82f6" />
                                        </Pressable>

                                        {/* Year Toggle */}
                                        <Pressable
                                            style={styles.selectorPressable}
                                            onPress={() => {
                                                setYearDropdownOpen(!yearDropdownOpen);
                                                setMonthDropdownOpen(false);
                                            }}
                                        >
                                            <Text style={styles.selectorText}>{pickerYear}</Text>
                                            <ChevronDown size={14} color="#3b82f6" />
                                        </Pressable>
                                    </View>

                                    {/* Arrow Navs */}
                                    <View style={{ flexDirection: 'row', gap: 14 }}>
                                        <Pressable onPress={handlePrevMonth} style={styles.arrowButton}>
                                            <ChevronLeft size={18} color="#94a3b8" />
                                        </Pressable>
                                        <Pressable onPress={handleNextMonth} style={styles.arrowButton}>
                                            <ChevronRight size={18} color="#94a3b8" />
                                        </Pressable>
                                    </View>
                                </View>

                                {/* Month Dropdown Grid Overlay */}
                                {monthDropdownOpen && (
                                    <View style={styles.dropdownOverlayContainer}>
                                        <Text style={styles.dropdownTitle}>Select Month</Text>
                                        <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8, justifyContent: 'center' }}>
                                            {MONTHS.map((m, idx) => (
                                                <Pressable
                                                    key={m}
                                                    style={[styles.dropdownItem, pickerMonth === idx && styles.dropdownItemActive]}
                                                    onPress={() => {
                                                        setPickerMonth(idx);
                                                        setMonthDropdownOpen(false);
                                                    }}
                                                >
                                                    <Text style={[styles.dropdownItemText, pickerMonth === idx && styles.dropdownItemTextActive]}>{m}</Text>
                                                </Pressable>
                                            ))}
                                        </View>
                                    </View>
                                )}

                                {/* Year Dropdown Scroll Overlay */}
                                {yearDropdownOpen && (
                                    <View style={styles.dropdownOverlayContainer}>
                                        <Text style={styles.dropdownTitle}>Select Year</Text>
                                        <ScrollView
                                            style={{ maxHeight: 200 }}
                                            showsVerticalScrollIndicator={false}
                                            contentContainerStyle={{ gap: 6 }}
                                        >
                                            {Array.from({ length: pickerTarget === 'birthDate' ? 80 : 30 }, (_, i) => {
                                                const y = pickerTarget === 'birthDate' ? 2026 - i : 2026 + i;
                                                return (
                                                    <Pressable
                                                        key={y}
                                                        style={[styles.dropdownItemYear, pickerYear === y && styles.dropdownItemYearActive]}
                                                        onPress={() => {
                                                            setPickerYear(y);
                                                            setYearDropdownOpen(false);
                                                        }}
                                                    >
                                                        <Text style={[styles.dropdownItemText, pickerYear === y && styles.dropdownItemTextActive]}>{y}</Text>
                                                    </Pressable>
                                                );
                                            })}
                                        </ScrollView>
                                    </View>
                                )}

                                {/* Day names headers: S M T W T F S */}
                                {!monthDropdownOpen && !yearDropdownOpen && (
                                    <>
                                        <View style={styles.calendarDayNamesRow}>
                                            {['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day, i) => (
                                                <Text key={i} style={styles.calendarDayName}>{day}</Text>
                                            ))}
                                        </View>

                                        {/* Days Grid */}
                                        <View style={styles.calendarDaysGrid}>
                                            {cells.map((dayNum, idx) => {
                                                const isSelected = dayNum === pickerDay;
                                                return (
                                                    <Pressable
                                                        key={idx}
                                                        disabled={dayNum === null}
                                                        style={[
                                                            styles.calendarDayCell,
                                                            dayNum === null && { opacity: 0 },
                                                            isSelected && styles.calendarDayCellSelected
                                                        ]}
                                                        onPress={() => dayNum !== null && setPickerDay(dayNum)}
                                                    >
                                                        <Text style={[
                                                            styles.calendarDayText,
                                                            isSelected && styles.calendarDayTextSelected
                                                        ]}>
                                                            {dayNum || ''}
                                                        </Text>
                                                    </Pressable>
                                                );
                                            })}
                                        </View>
                                    </>
                                )}

                                {/* Footer Actions */}
                                <View style={styles.datePickerFooter}>
                                    <Pressable
                                        style={styles.datePickerCancelBtn}
                                        onPress={() => setPickerVisible(false)}
                                    >
                                        <Text style={styles.datePickerCancelBtnText}>Cancel</Text>
                                    </Pressable>
                                    <Pressable
                                        style={styles.datePickerConfirmBtn}
                                        onPress={handleSelectDate}
                                    >
                                        <Text style={styles.datePickerConfirmBtnText}>Select</Text>
                                    </Pressable>
                                </View>
                            </View>
                        </View>
                    </Modal>

                    {/* Custom Dropdown Picker Modal */}
                    <Modal
                        visible={dropdownVisible}
                        transparent={true}
                        animationType="fade"
                        onRequestClose={() => setDropdownVisible(false)}
                    >
                        <View style={styles.modalOverlay}>
                            <View style={[styles.datePickerContainer, { maxHeight: '80%' }]}>
                                <View style={styles.dropdownModalHeader}>
                                    <Text style={styles.dropdownModalTitle}>
                                        {dropdownTarget === 'gender' && 'Select Gender'}
                                        {dropdownTarget === 'nationality' && 'Select Nationality'}
                                        {dropdownTarget === 'billingCountry' && 'Select Billing Country'}
                                        {dropdownTarget === 'countryCode' && 'Select Country Code'}
                                    </Text>
                                    <Pressable
                                        style={styles.dropdownModalCloseBtn}
                                        onPress={() => setDropdownVisible(false)}
                                    >
                                        <Text style={styles.datePickerCancelBtnText}>Close</Text>
                                    </Pressable>
                                </View>

                                {dropdownTarget !== 'gender' && (
                                    <View style={styles.searchBarContainer}>
                                        <TextInput
                                            style={styles.searchBarInput}
                                            placeholder="Search country..."
                                            placeholderTextColor={isDark ? '#475569' : '#94a3b8'}
                                            value={dropdownSearch}
                                            onChangeText={setDropdownSearch}
                                        />
                                    </View>
                                )}

                                <ScrollView
                                    style={{ height: dropdownTarget === 'gender' ? 120 : 300, marginTop: 8 }}
                                    showsVerticalScrollIndicator={true}
                                    keyboardShouldPersistTaps="handled"
                                >
                                    {dropdownTarget === 'gender' && (
                                        <View style={{ gap: 8, paddingHorizontal: 4 }}>
                                            {GENDER_OPTIONS.map((opt) => {
                                                const isSelected = passengers[0].gender === opt.value;
                                                return (
                                                    <Pressable
                                                        key={opt.value}
                                                        style={[
                                                            styles.dropdownOptionItem,
                                                            isSelected && styles.dropdownOptionItemActive
                                                        ]}
                                                        onPress={() => {
                                                            const next = [...passengers];
                                                            next[0].gender = opt.value;
                                                            setPassengers(next);
                                                            setDropdownVisible(false);
                                                        }}
                                                    >
                                                        <Text style={[
                                                            styles.dropdownOptionText,
                                                            isSelected && styles.dropdownOptionTextActive
                                                        ]}>
                                                            {opt.label}
                                                        </Text>
                                                        {isSelected && (
                                                            <Check size={16} color="#3b82f6" />
                                                        )}
                                                    </Pressable>
                                                );
                                            })}
                                        </View>
                                    )}

                                    {dropdownTarget !== 'gender' && (() => {
                                        const filtered = COUNTRIES.filter(c =>
                                            c.name.toLowerCase().includes(dropdownSearch.toLowerCase()) ||
                                            c.code.toLowerCase().includes(dropdownSearch.toLowerCase()) ||
                                            c.dialCode.includes(dropdownSearch)
                                        );

                                        if (filtered.length === 0) {
                                            return (
                                                <Text style={styles.noResultsText}>No countries found</Text>
                                            );
                                        }

                                        return (
                                            <View style={{ gap: 4, paddingHorizontal: 4 }}>
                                                {filtered.map((country) => {
                                                    let isSelected = false;
                                                    if (dropdownTarget === 'nationality') {
                                                        isSelected = passengers[0].nationality === country.code;
                                                    } else if (dropdownTarget === 'billingCountry') {
                                                        isSelected = billingCountry === country.code;
                                                    } else if (dropdownTarget === 'countryCode') {
                                                        isSelected = countryCode === country.dialCode;
                                                    }

                                                    return (
                                                        <Pressable
                                                            key={country.code}
                                                            style={[
                                                                styles.dropdownOptionItem,
                                                                isSelected && styles.dropdownOptionItemActive
                                                            ]}
                                                            onPress={() => {
                                                                if (dropdownTarget === 'nationality') {
                                                                    const next = [...passengers];
                                                                    next[0].nationality = country.code;
                                                                    setPassengers(next);
                                                                } else if (dropdownTarget === 'billingCountry') {
                                                                    setBillingCountry(country.code);
                                                                } else if (dropdownTarget === 'countryCode') {
                                                                    setCountryCode(country.dialCode);
                                                                }
                                                                setDropdownVisible(false);
                                                            }}
                                                        >
                                                            <View style={{ flex: 1, flexDirection: 'row', alignItems: 'center', gap: 12 }}>
                                                                <Text style={styles.countryFlagText}>
                                                                    {getFlagEmoji(country.code)}
                                                                </Text>
                                                                <Text style={[
                                                                    styles.dropdownOptionText,
                                                                    isSelected && styles.dropdownOptionTextActive
                                                                ]}>
                                                                    {country.name}
                                                                </Text>
                                                                {dropdownTarget === 'countryCode' && (
                                                                    <Text style={styles.countryDialCodeText}>
                                                                        (+{country.dialCode})
                                                                    </Text>
                                                                )}
                                                            </View>
                                                            {isSelected && (
                                                                <Check size={16} color="#3b82f6" />
                                                            )}
                                                        </Pressable>
                                                    );
                                                })}
                                            </View>
                                        );
                                    })()}
                                </ScrollView>
                            </View>
                        </View>
                    </Modal>

                    {/* Action button */}
                    <Pressable
                        style={[styles.confirmBtn, booking && { opacity: 0.8 }]}
                        onPress={handleConfirmBooking}
                        disabled={booking}
                    >
                        <Text style={styles.confirmBtnText}>
                            {booking ? 'Processing...' : `Confirm Booking - ${offer ? offer.price.currency + ' ' + Math.round(offer.price.total).toLocaleString() : ''}`}
                        </Text>
                    </Pressable>
                </ScrollView>
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
        paddingVertical: 14,
        borderBottomWidth: 1,
        borderBottomColor: isDark ? '#1e293b' : '#e2e8f0',
    },
    backBtn: {
        padding: 4,
    },
    headerTitle: {
        fontSize: 16,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
        textAlign: 'center',
        flex: 1,
        marginHorizontal: 8,
    },
    scrollView: {
        flex: 1,
        paddingHorizontal: 16,
        paddingTop: 16,
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
        marginBottom: 16,
    },
    errorBannerText: {
        flex: 1,
        fontSize: 13,
        color: isDark ? '#fca5a5' : '#dc2626',
        fontWeight: '500',
    },
    // Selected Flight Card
    summaryCard: {
        backgroundColor: isDark ? '#0b0f19' : '#ffffff',
        borderRadius: 16,
        padding: 16,
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
        marginBottom: 16,
    },
    summaryHeader: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 12,
        borderBottomWidth: 1,
        borderBottomColor: isDark ? '#1e293b' : '#f1f5f9',
        paddingBottom: 14,
        marginBottom: 14,
    },
    carrierLogoWrap: {
        width: 38,
        height: 38,
        borderRadius: 8,
        backgroundColor: isDark ? '#1e293b' : '#f1f5f9',
        alignItems: 'center',
        justifyContent: 'center',
    },
    planeIconBackground: {
        width: 24,
        height: 24,
        borderRadius: 12,
        backgroundColor: '#3b82f6',
        alignItems: 'center',
        justifyContent: 'center',
    },
    carrierName: {
        fontSize: 14,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
    },
    flightCode: {
        fontSize: 11,
        color: isDark ? '#64748b' : '#94a3b8',
        fontWeight: '600',
        marginTop: 2,
    },
    summaryPrice: {
        fontSize: 18,
        fontWeight: '800',
        color: isDark ? '#38bdf8' : '#2563eb',
    },
    summaryPriceLabel: {
        fontSize: 10,
        color: isDark ? '#64748b' : '#94a3b8',
        fontWeight: '600',
        marginTop: 2,
    },
    routeContainer: {
        marginTop: 4,
    },
    routeRow: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
    },
    routeTime: {
        fontSize: 16,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
    },
    routeAirport: {
        fontSize: 12,
        color: isDark ? '#64748b' : '#94a3b8',
        fontWeight: '600',
        marginTop: 4,
    },
    timelineContainer: {
        flex: 2,
        alignItems: 'center',
        paddingHorizontal: 8,
    },
    timelineDuration: {
        fontSize: 10,
        color: isDark ? '#64748b' : '#94a3b8',
        fontWeight: '600',
        marginBottom: 4,
    },
    timelineLine: {
        height: 2,
        backgroundColor: isDark ? '#334155' : '#cbd5e1',
        width: '100%',
        position: 'relative',
    },
    timelineStops: {
        fontSize: 10,
        color: '#10b981',
        fontWeight: '700',
        marginTop: 4,
    },
    // Explore section
    exploreSection: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: isDark ? '#080c14' : '#f1f5f9',
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
        borderRadius: 12,
        paddingHorizontal: 12,
        paddingVertical: 10,
        marginBottom: 16,
        gap: 8,
    },
    exploreText: {
        flex: 1,
        fontSize: 12,
        fontWeight: '600',
        color: isDark ? '#94a3b8' : '#64748b',
    },
    exploreBadge: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: isDark ? '#1e293b' : '#ffffff',
        borderWidth: 1,
        borderColor: isDark ? '#334155' : '#cbd5e1',
        paddingHorizontal: 8,
        paddingVertical: 4,
        borderRadius: 8,
        gap: 6,
    },
    exploreBadgeText: {
        fontSize: 11,
        fontWeight: '700',
        color: isDark ? '#38bdf8' : '#2563eb',
    },
    // Warning banner
    warningCard: {
        backgroundColor: isDark ? '#0f0a05' : '#fffbeb',
        borderRadius: 16,
        padding: 16,
        borderWidth: 1,
        borderColor: isDark ? '#78350f44' : '#fde68a',
        marginBottom: 16,
    },
    inlineValidationCard: {
        backgroundColor: isDark ? 'rgba(239, 68, 68, 0.1)' : '#fef2f2',
        borderWidth: 1,
        borderColor: isDark ? '#ef4444' : '#fecaca',
        borderRadius: 12,
        padding: 14,
        marginHorizontal: 16,
        marginBottom: 12,
    },
    inlineValidationHeader: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 8,
        marginBottom: 6,
    },
    inlineValidationTitle: {
        fontSize: 14,
        fontWeight: '700',
        color: isDark ? '#fca5a5' : '#b91c1c',
    },
    inlineValidationText: {
        fontSize: 12,
        color: isDark ? '#f87171' : '#dc2626',
        lineHeight: 16,
    },
    warningHeader: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 8,
        marginBottom: 8,
    },
    warningTitle: {
        fontSize: 13,
        fontWeight: '700',
        color: '#f59e0b',
    },
    warningText: {
        fontSize: 12,
        lineHeight: 18,
        color: isDark ? '#d97706' : '#b45309',
        marginBottom: 14,
    },
    farePolicySection: {
        borderTopWidth: 1,
        borderTopColor: isDark ? '#78350f22' : '#fef3c7',
        paddingTop: 14,
    },
    policyRow: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: 10,
    },
    policyRowLabel: {
        fontSize: 13,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
    },
    policyRowStatus: {
        fontSize: 11,
        fontWeight: '700',
        color: '#10b981',
    },
    policyBadge: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 6,
        backgroundColor: isDark ? '#ef444415' : '#fef2f2',
        borderWidth: 1,
        borderColor: isDark ? '#ef444430' : '#fecaca',
        paddingHorizontal: 10,
        paddingVertical: 6,
        borderRadius: 8,
        alignSelf: 'flex-start',
    },
    policyBadgeText: {
        fontSize: 11,
        fontWeight: '700',
        color: '#ef4444',
    },
    policyFooter: {
        fontSize: 10,
        color: isDark ? '#475569' : '#94a3b8',
        fontWeight: '500',
        marginTop: 10,
    },
    // Form Cards
    card: {
        backgroundColor: isDark ? '#0b0f19' : '#ffffff',
        borderRadius: 16,
        padding: 16,
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
        marginBottom: 16,
    },
    cardHeader: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 8,
        marginBottom: 16,
    },
    cardTitle: {
        fontSize: 14,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
        flex: 1,
    },
    passengerTypeDropdown: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: isDark ? '#1e293b' : '#f1f5f9',
        paddingHorizontal: 10,
        paddingVertical: 5,
        borderRadius: 8,
        gap: 6,
    },
    passengerTypeText: {
        fontSize: 11,
        fontWeight: '700',
        color: isDark ? '#e2e8f0' : '#475569',
    },
    // Inputs
    inputGroup: {
        marginBottom: 12,
    },
    input: {
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#cbd5e1',
        borderRadius: 10,
        paddingHorizontal: 14,
        paddingVertical: 11,
        fontSize: 14,
        color: isDark ? '#ffffff' : '#0f172a',
        backgroundColor: isDark ? '#030712' : '#f8fafc',
    },
    inputError: {
        borderColor: '#ef4444',
    },
    dropdownModalHeader: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        paddingBottom: 14,
        borderBottomWidth: 1,
        borderBottomColor: isDark ? '#1e293b' : '#f1f5f9',
        marginBottom: 10,
    },
    dropdownModalTitle: {
        fontSize: 16,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
    },
    dropdownModalCloseBtn: {
        paddingVertical: 4,
        paddingHorizontal: 8,
    },
    searchBarContainer: {
        marginBottom: 10,
    },
    searchBarInput: {
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#cbd5e1',
        borderRadius: 8,
        paddingHorizontal: 12,
        paddingVertical: 8,
        fontSize: 14,
        color: isDark ? '#ffffff' : '#0f172a',
        backgroundColor: isDark ? '#090d16' : '#ffffff',
    },
    dropdownOptionItem: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        paddingVertical: 12,
        paddingHorizontal: 14,
        borderRadius: 8,
        backgroundColor: 'transparent',
    },
    dropdownOptionItemActive: {
        backgroundColor: isDark ? 'rgba(59, 130, 246, 0.15)' : 'rgba(59, 130, 246, 0.08)',
    },
    dropdownOptionText: {
        fontSize: 14,
        color: isDark ? '#cbd5e1' : '#334155',
    },
    dropdownOptionTextActive: {
        color: '#3b82f6',
        fontWeight: '600',
    },
    noResultsText: {
        textAlign: 'center',
        color: isDark ? '#64748b' : '#94a3b8',
        fontSize: 14,
        paddingVertical: 20,
    },
    countryFlagText: {
        fontSize: 18,
    },
    countryDialCodeText: {
        fontSize: 13,
        color: isDark ? '#64748b' : '#94a3b8',
        marginLeft: 4,
    },
    dropdownPlaceholder: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#cbd5e1',
        borderRadius: 10,
        paddingHorizontal: 14,
        paddingVertical: 12,
        backgroundColor: isDark ? '#030712' : '#f8fafc',
    },
    dropdownValue: {
        fontSize: 14,
        color: isDark ? '#ffffff' : '#0f172a',
        fontWeight: '500',
    },
    errorText: {
        fontSize: 11,
        color: '#ef4444',
        marginTop: 4,
        fontWeight: '500',
    },
    phoneInputRow: {
        flexDirection: 'row',
        gap: 8,
    },
    countryCodeSelector: {
        flexDirection: 'row',
        alignItems: 'center',
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#cbd5e1',
        borderRadius: 10,
        paddingHorizontal: 12,
        backgroundColor: isDark ? '#030712' : '#f8fafc',
        gap: 4,
    },
    countryCodeText: {
        fontSize: 14,
        fontWeight: '600',
        color: isDark ? '#ffffff' : '#0f172a',
    },
    // Accordions
    accordionHeader: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
    },
    accordionTitleWrap: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 12,
    },
    accordionIconBG: {
        width: 32,
        height: 32,
        borderRadius: 8,
        backgroundColor: isDark ? '#3b82f620' : '#eff6ff',
        alignItems: 'center',
        justifyContent: 'center',
    },
    accordionTitle: {
        fontSize: 13,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
    },
    accordionSubtitle: {
        fontSize: 11,
        color: isDark ? '#64748b' : '#94a3b8',
        marginTop: 2,
    },
    accordionContent: {
        borderTopWidth: 1,
        borderTopColor: isDark ? '#1e293b' : '#f1f5f9',
        marginTop: 12,
        paddingTop: 12,
    },
    accordionText: {
        fontSize: 12,
        color: isDark ? '#64748b' : '#94a3b8',
        lineHeight: 18,
    },
    // Add passenger dashed button
    addPassengerBtn: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        borderWidth: 1,
        borderStyle: 'dashed',
        borderColor: isDark ? '#3b82f650' : '#3b82f6',
        borderRadius: 12,
        paddingVertical: 12,
        marginBottom: 16,
        gap: 8,
        backgroundColor: isDark ? '#1d4ed810' : '#eff6ff',
    },
    addPassengerText: {
        fontSize: 13,
        fontWeight: '700',
        color: isDark ? '#38bdf8' : '#2563eb',
    },
    // Confirm Button
    confirmBtn: {
        backgroundColor: '#2563eb',
        borderRadius: 12,
        paddingVertical: 14,
        alignItems: 'center',
        justifyContent: 'center',
        marginTop: 12,
        marginBottom: 40,
    },
    confirmBtnText: {
        color: '#ffffff',
        fontSize: 14,
        fontWeight: '700',
    },
    // Confirming overlay
    confirmingContainer: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        paddingHorizontal: 24,
        backgroundColor: isDark ? '#020617' : '#ffffff',
    },
    confirmingTitle: {
        fontSize: 18,
        fontWeight: '800',
        color: isDark ? '#ffffff' : '#0f172a',
        marginBottom: 8,
    },
    confirmingStep: {
        fontSize: 13,
        fontWeight: '600',
        color: '#2563eb',
        textAlign: 'center',
        marginBottom: 24,
    },
    confirmingHint: {
        fontSize: 11,
        color: isDark ? '#475569' : '#94a3b8',
        marginTop: 40,
        textAlign: 'center',
    },
    stepDot: {
        width: 18,
        height: 18,
        borderRadius: 9,
        borderWidth: 1.5,
        borderColor: isDark ? '#334155' : '#cbd5e1',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: 'transparent',
    },
    stepDotActive: {
        borderColor: '#2563eb',
        backgroundColor: '#2563eb',
    },
    stepDotDone: {
        borderColor: '#10b981',
        backgroundColor: '#10b981',
    },
    stepDotText: {
        fontSize: 9,
        fontWeight: '700',
        color: isDark ? '#94a3b8' : '#64748b',
    },
    stepLabel: {
        fontSize: 13,
        fontWeight: '500',
        color: isDark ? '#475569' : '#94a3b8',
    },
    stepLabelActive: {
        color: isDark ? '#ffffff' : '#0f172a',
        fontWeight: '600',
    },
    // Success Screen
    successContainer: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        paddingHorizontal: 24,
        backgroundColor: isDark ? '#020617' : '#f8fafc',
    },
    successIconWrap: {
        width: 80,
        height: 80,
        borderRadius: 40,
        backgroundColor: isDark ? '#064e3b33' : '#d1fae5',
        alignItems: 'center',
        justifyContent: 'center',
        marginBottom: 20,
    },
    successTitle: {
        fontSize: 20,
        fontWeight: '800',
        color: isDark ? '#ffffff' : '#0f172a',
        textAlign: 'center',
        marginBottom: 6,
    },
    successSubtitle: {
        fontSize: 13,
        color: isDark ? '#94a3b8' : '#64748b',
        textAlign: 'center',
        marginBottom: 32,
    },
    successCard: {
        backgroundColor: isDark ? '#0b0f19' : '#ffffff',
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
        borderRadius: 16,
        paddingHorizontal: 16,
        paddingVertical: 8,
        width: '100%',
        marginBottom: 20,
    },
    successRow: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        paddingVertical: 12,
        borderBottomWidth: 1,
        borderBottomColor: isDark ? '#1e293b' : '#f1f5f9',
    },
    successLabel: {
        fontSize: 13,
        fontWeight: '600',
        color: isDark ? '#64748b' : '#94a3b8',
    },
    successValue: {
        fontSize: 13,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
    },
    successEmailRow: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 6,
        marginBottom: 40,
    },
    successEmailText: {
        fontSize: 12,
        color: isDark ? '#64748b' : '#94a3b8',
        fontWeight: '500',
    },
    successBtn: {
        backgroundColor: '#2563eb',
        paddingVertical: 14,
        paddingHorizontal: 40,
        borderRadius: 12,
        width: '100%',
        alignItems: 'center',
    },
    successBtnText: {
        color: '#ffffff',
        fontSize: 14,
        fontWeight: '700',
    },
    // Custom Date Picker Modal styles
    modalOverlay: {
        flex: 1,
        backgroundColor: 'rgba(0,0,0,0.7)',
        justifyContent: 'center',
        alignItems: 'center',
    },
    datePickerContainer: {
        backgroundColor: isDark ? '#090d16' : '#ffffff',
        width: width * 0.9,
        borderRadius: 16,
        padding: 18,
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#cbd5e1',
        shadowColor: '#2563eb',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.15,
        shadowRadius: 10,
        elevation: 10,
    },
    datePickerHeader: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: 16,
    },
    selectorPressable: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 6,
        backgroundColor: isDark ? '#1e293b' : '#f1f5f9',
        paddingHorizontal: 10,
        paddingVertical: 6,
        borderRadius: 8,
    },
    selectorText: {
        fontSize: 14,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
    },
    arrowButton: {
        padding: 4,
    },
    calendarDayNamesRow: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        marginBottom: 10,
    },
    calendarDayName: {
        width: (width * 0.9 - 36) / 7,
        textAlign: 'center',
        fontSize: 11,
        fontWeight: '600',
        color: isDark ? '#64748b' : '#94a3b8',
    },
    calendarDaysGrid: {
        flexDirection: 'row',
        flexWrap: 'wrap',
    },
    calendarDayCell: {
        width: (width * 0.9 - 36) / 7,
        height: 38,
        alignItems: 'center',
        justifyContent: 'center',
        marginBottom: 6,
        borderRadius: 10,
    },
    calendarDayCellSelected: {
        backgroundColor: '#2563eb',
    },
    calendarDayText: {
        fontSize: 13,
        fontWeight: '600',
        color: isDark ? '#ffffff' : '#0f172a',
    },
    calendarDayTextSelected: {
        color: '#ffffff',
        fontWeight: '800',
    },
    dropdownOverlayContainer: {
        height: 200,
        backgroundColor: isDark ? '#020617' : '#f8fafc',
        borderRadius: 12,
        padding: 12,
        marginBottom: 10,
    },
    dropdownTitle: {
        fontSize: 12,
        fontWeight: '700',
        color: isDark ? '#94a3b8' : '#64748b',
        marginBottom: 10,
        textAlign: 'center',
    },
    dropdownItem: {
        width: (width * 0.9 - 72) / 3,
        paddingVertical: 8,
        alignItems: 'center',
        backgroundColor: isDark ? '#1e293b' : '#e2e8f0',
        borderRadius: 8,
    },
    dropdownItemActive: {
        backgroundColor: '#2563eb',
    },
    dropdownItemYear: {
        paddingVertical: 10,
        alignItems: 'center',
        backgroundColor: isDark ? '#1e293b' : '#e2e8f0',
        borderRadius: 8,
        marginBottom: 4,
    },
    dropdownItemYearActive: {
        backgroundColor: '#2563eb',
    },
    dropdownItemText: {
        fontSize: 12,
        fontWeight: '700',
        color: isDark ? '#e2e8f0' : '#475569',
    },
    dropdownItemTextActive: {
        color: '#ffffff',
    },
    datePickerFooter: {
        flexDirection: 'row',
        justifyContent: 'flex-end',
        gap: 12,
        marginTop: 14,
        borderTopWidth: 1,
        borderTopColor: isDark ? '#1e293b' : '#f1f5f9',
        paddingTop: 14,
    },
    datePickerCancelBtn: {
        paddingVertical: 10,
        paddingHorizontal: 18,
        borderRadius: 10,
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#cbd5e1',
    },
    datePickerCancelBtnText: {
        color: isDark ? '#94a3b8' : '#64748b',
        fontSize: 13,
        fontWeight: '700',
    },
    datePickerConfirmBtn: {
        paddingVertical: 10,
        paddingHorizontal: 22,
        borderRadius: 10,
        backgroundColor: '#2563eb',
    },
    datePickerConfirmBtnText: {
        color: '#ffffff',
        fontSize: 13,
        fontWeight: '700',
    },

    // Interactive Seat Map styles
    seatProgressRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 10,
        marginBottom: 12,
    },
    seatProgressOuterBar: {
        flex: 1,
        height: 6,
        backgroundColor: isDark ? '#1e293b' : '#cbd5e1',
        borderRadius: 3,
    },
    seatProgressInnerBar: {
        height: 6,
        backgroundColor: '#3b82f6',
        borderRadius: 3,
    },
    seatProgressCount: {
        fontSize: 11,
        fontWeight: '700',
        color: isDark ? '#94a3b8' : '#64748b',
    },
    seatTabsRow: {
        flexDirection: 'row',
        gap: 8,
        marginBottom: 14,
    },
    seatTabBtn: {
        flex: 1,
        paddingVertical: 10,
        borderRadius: 10,
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#cbd5e1',
        alignItems: 'center',
        justifyContent: 'center',
    },
    seatTabBtnActive: {
        backgroundColor: '#3b82f6',
        borderColor: '#2563eb',
    },
    seatTabBtnText: {
        fontSize: 12,
        fontWeight: '700',
        color: isDark ? '#94a3b8' : '#64748b',
    },
    seatTabBtnTextActive: {
        color: '#ffffff',
    },
    seatSelectHint: {
        fontSize: 11,
        color: isDark ? '#64748b' : '#94a3b8',
        fontWeight: '600',
        marginBottom: 12,
    },
    cabinContainer: {
        backgroundColor: isDark ? '#080c14' : '#f8fafc',
        borderRadius: 16,
        padding: 14,
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#cbd5e1',
        marginBottom: 16,
    },
    cabinClassLabel: {
        fontSize: 10,
        fontWeight: '800',
        color: isDark ? '#475569' : '#94a3b8',
        letterSpacing: 1.5,
        textAlign: 'center',
        marginBottom: 12,
    },
    cabinHeaderRow: {
        flexDirection: 'row',
        justifyContent: 'center',
        marginBottom: 8,
        paddingHorizontal: 20,
    },
    cabinColumnHeader: {
        width: 32,
        textAlign: 'center',
        fontSize: 11,
        fontWeight: '700',
        color: isDark ? '#475569' : '#94a3b8',
    },
    cabinAisleSpace: {
        width: 32,
    },
    cabinRow: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        marginBottom: 8,
        paddingHorizontal: 20,
    },
    cabinRowLabel: {
        width: 24,
        fontSize: 12,
        fontWeight: '700',
        color: isDark ? '#475569' : '#94a3b8',
        marginRight: 8,
    },
    seatButton: {
        width: 32,
        height: 32,
        borderRadius: 8,
        alignItems: 'center',
        justifyContent: 'center',
        marginHorizontal: 3,
    },
    seatButtonText: {
        fontSize: 11,
        fontWeight: '700',
    },
    seatFree: {
        borderWidth: 1.5,
        borderColor: '#10b981',
        backgroundColor: 'transparent',
    },
    seatTextFree: {
        color: '#10b981',
    },
    seatPaid: {
        borderWidth: 1.5,
        borderColor: '#f97316',
        backgroundColor: 'transparent',
    },
    seatTextPaid: {
        color: '#f97316',
    },
    seatTaken: {
        backgroundColor: isDark ? '#1e293b' : '#e2e8f0',
        borderWidth: 0,
    },
    seatTextTaken: {
        color: isDark ? '#475569' : '#94a3b8',
    },
    seatSelected: {
        backgroundColor: '#3b82f6',
        borderWidth: 0,
    },
    seatTextSelected: {
        color: '#ffffff',
    },
    seatLegroom: {
        borderWidth: 1.5,
        borderColor: '#10b981',
        backgroundColor: isDark ? '#052e16' : '#d1fae5',
    },
    seatTextLegroom: {
        color: '#10b981',
    },
    seatExit: {
        borderWidth: 1.5,
        borderColor: '#db2777',
        backgroundColor: isDark ? '#500724' : '#fce7f3',
    },
    seatTextExit: {
        color: '#db2777',
    },
    legendContainer: {
        gap: 8,
        marginBottom: 18,
        borderTopWidth: 1,
        borderTopColor: isDark ? '#1e293b' : '#f1f5f9',
        paddingTop: 14,
    },
    legendRow: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        paddingHorizontal: 4,
    },
    legendItem: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 6,
    },
    legendBox: {
        borderRadius: 4,
    },
    seatFreeBox: {
        borderWidth: 1.5,
        borderColor: '#10b981',
    },
    seatPaidBox: {
        borderWidth: 1.5,
        borderColor: '#f97316',
    },
    seatTakenBox: {
        backgroundColor: isDark ? '#1e293b' : '#e2e8f0',
    },
    seatSelectedBox: {
        backgroundColor: '#3b82f6',
    },
    seatLegroomBox: {
        borderWidth: 1.5,
        borderColor: '#10b981',
        backgroundColor: isDark ? '#052e16' : '#d1fae5',
    },
    seatExitBox: {
        borderWidth: 1.5,
        borderColor: '#db2777',
        backgroundColor: isDark ? '#500724' : '#fce7f3',
    },
    legendText: {
        fontSize: 11,
        fontWeight: '600',
        color: isDark ? '#94a3b8' : '#64748b',
    },
    seatAccordionFooter: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        gap: 12,
    },
    seatSkipButton: {
        flex: 1,
        paddingVertical: 12,
        borderRadius: 10,
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#cbd5e1',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: isDark ? '#0b0f19' : '#ffffff',
    },
    seatSkipButtonText: {
        fontSize: 13,
        fontWeight: '700',
        color: isDark ? '#94a3b8' : '#64748b',
    },
    seatScrollTopButton: {
        width: 44,
        height: 44,
        borderRadius: 22,
        backgroundColor: '#2563eb',
        alignItems: 'center',
        justifyContent: 'center',
    },
});
