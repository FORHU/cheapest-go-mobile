import AsyncStorage from '@react-native-async-storage/async-storage';
import { useRouter } from 'expo-router';
import {
    BadgeCheck,
    Building2,
    Calendar,
    Check,
    ChevronDown,
    Clock,
    Lock,
    Plane,
    Search,
    ShieldCheck,
    Star,
    Ticket,
    TrendingDown,
    Users,
    Zap,
} from 'lucide-react-native';
import { useEffect, useRef, useState } from 'react';
import {
    Animated,
    Dimensions,
    Easing,
    FlatList,
    NativeScrollEvent,
    NativeSyntheticEvent,
    Pressable,
    ScrollView,
    StyleSheet,
    Text,
    useColorScheme,
    View,
} from 'react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

const { width } = Dimensions.get('window');

const ONBOARDING_KEY = 'hasSeenOnboarding';

type Slide = {
    key: 'search' | 'compare' | 'book';
    title: string;
    description: string;
};

const SLIDES: Slide[] = [
    {
        key: 'search',
        title: 'Find flights & hotels\nin seconds',
        description:
            'Search thousands of airlines and hotel partners worldwide to find the trip that fits your plans and your budget.',
    },
    {
        key: 'compare',
        title: 'Compare & Save',
        description:
            'Get real-time updates on fares and rates. Compare options at a glance to find the best value.',
    },
    {
        key: 'book',
        title: 'Book with confidence',
        description:
            'Secure checkout, instant e-tickets, and verified hotel reservations — all in one app.',
    },
];

// ── Float animation hook ──────────────────────────────────────────────────────
function useFloatAnim(duration = 3000, delay = 0, amplitude = 14) {
    const anim = useRef(new Animated.Value(0)).current;

    useEffect(() => {
        const loop = Animated.loop(
            Animated.sequence([
                Animated.delay(delay),
                Animated.timing(anim, {
                    toValue: 1,
                    duration,
                    easing: Easing.inOut(Easing.sin),
                    useNativeDriver: true,
                }),
                Animated.timing(anim, {
                    toValue: 0,
                    duration,
                    easing: Easing.inOut(Easing.sin),
                    useNativeDriver: true,
                }),
            ])
        );
        loop.start();
        return () => loop.stop();
    }, []);

    return anim.interpolate({
        inputRange: [0, 1],
        outputRange: [0, -amplitude],
    });
}

// ── Slide 1: Search Illustration + Flight Form ────────────────────────────────
function SearchIllustration({ isDark }: { isDark: boolean }) {
    const C = isDark ? DC : LC;
    const translateY1 = useFloatAnim(3200, 0, 8);

    return (
        <View style={il.root}>
            {/* Floating search card */}
            <Animated.View
                style={[
                    il.mainCard,
                    {
                        backgroundColor: C.cardBg,
                        borderColor: C.cardBorder,
                        shadowColor: C.shadow,
                        transform: [{ translateY: translateY1 }],
                        width: '100%',
                    },
                ]}
            >
                {/* Pill tabs */}
                <View style={il.pillRow}>
                    <View style={[il.pill, il.pillActive]}>
                        <Plane size={13} color="#fff" />
                        <Text style={il.pillTextActive}>Flights</Text>
                    </View>
                    <View style={[il.pill, { backgroundColor: isDark ? '#1e293b' : '#f1f5f9' }]}>
                        <Building2 size={13} color={isDark ? '#64748b' : '#94a3b8'} />
                        <Text style={[il.pillText, { color: isDark ? '#64748b' : '#94a3b8' }]}>Hotels</Text>
                    </View>
                    <View style={[il.pill, { backgroundColor: isDark ? '#1e293b' : '#f1f5f9' }]}>
                        <Text style={[il.pillText, { color: isDark ? '#64748b' : '#94a3b8' }]}>Round Trip</Text>
                        <ChevronDown size={11} color={isDark ? '#64748b' : '#94a3b8'} />
                    </View>
                </View>

                {/* From / To row */}
                <View style={il.fromToRow}>
                    <View style={[il.airportField, { backgroundColor: isDark ? '#030712' : '#f8fafc', borderColor: isDark ? '#1e293b' : '#e2e8f0', flex: 1 }]}>
                        <Text style={[il.fieldLabel, { color: isDark ? '#475569' : '#94a3b8' }]}>FROM</Text>
                        <Text style={[il.fieldValue, { color: isDark ? '#f1f5f9' : '#0f172a' }]}>MNL</Text>
                        <Text style={[il.fieldSubtext, { color: isDark ? '#475569' : '#94a3b8' }]}>Manila</Text>
                    </View>
                    <View style={il.swapBtn}>
                        <Plane size={14} color="#2563eb" />
                    </View>
                    <View style={[il.airportField, { backgroundColor: isDark ? '#030712' : '#f8fafc', borderColor: isDark ? '#1e293b' : '#e2e8f0', flex: 1 }]}>
                        <Text style={[il.fieldLabel, { color: isDark ? '#475569' : '#94a3b8' }]}>TO</Text>
                        <Text style={[il.fieldValue, { color: isDark ? '#cbd5e1' : '#94a3b8' }]}>NRT</Text>
                        <Text style={[il.fieldSubtext, { color: isDark ? '#475569' : '#94a3b8' }]}>Tokyo</Text>
                    </View>
                </View>

                {/* Date row */}
                <View style={il.dateRow}>
                    <View style={[il.dateField, { backgroundColor: isDark ? '#030712' : '#f8fafc', borderColor: isDark ? '#1e293b' : '#e2e8f0' }]}>
                        <View style={il.dateFieldInner}>
                            <Calendar size={13} color="#2563eb" />
                            <Text style={[il.fieldLabel, { color: isDark ? '#475569' : '#94a3b8', marginLeft: 4 }]}>DEPART</Text>
                        </View>
                        <Text style={[il.fieldValue, { color: isDark ? '#f1f5f9' : '#0f172a', fontSize: 13 }]}>Jul 15, 2025</Text>
                    </View>
                    <View style={[il.dateField, { backgroundColor: isDark ? '#030712' : '#f8fafc', borderColor: isDark ? '#1e293b' : '#e2e8f0' }]}>
                        <View style={il.dateFieldInner}>
                            <Calendar size={13} color={isDark ? '#334155' : '#cbd5e1'} />
                            <Text style={[il.fieldLabel, { color: isDark ? '#475569' : '#94a3b8', marginLeft: 4 }]}>RETURN</Text>
                        </View>
                        <Text style={[il.fieldValue, { color: isDark ? '#475569' : '#94a3b8', fontSize: 13 }]}>Add date</Text>
                    </View>
                </View>

                {/* Passengers row */}
                <View style={[il.passengerRow, { backgroundColor: isDark ? '#030712' : '#f8fafc', borderColor: isDark ? '#1e293b' : '#e2e8f0' }]}>
                    <Users size={14} color={isDark ? '#475569' : '#94a3b8'} />
                    <View style={{ flex: 1, marginLeft: 10 }}>
                        <Text style={[il.fieldLabel, { color: isDark ? '#475569' : '#94a3b8' }]}>PASSENGERS & CLASS</Text>
                        <Text style={[il.fieldValue, { color: isDark ? '#f1f5f9' : '#0f172a', fontSize: 13 }]}>1 Adult · Economy</Text>
                    </View>
                    <ChevronDown size={15} color={isDark ? '#475569' : '#94a3b8'} />
                </View>

                {/* Search Flights button */}
                <Pressable style={il.searchFlightsBtn}>
                    <Search size={16} color="#fff" />
                    <Text style={il.searchFlightsBtnText}>Search Flights</Text>
                </Pressable>
            </Animated.View>

            {/* Badge */}
            <View style={[il.badge, il.badgeSearch]}>
                <Clock size={13} color="#fff" />
                <Text style={il.badgeText}>500+ airlines searched</Text>
            </View>
        </View>
    );
}

// ── Slide 2: Compare Illustration ────────────────────────────────────────────
function CompareIllustration({ isDark }: { isDark: boolean }) {
    const C = isDark ? DC : LC;
    const translateY1 = useFloatAnim(3400, 0, 13);
    const translateY2 = useFloatAnim(2900, 800, 9);

    return (
        <View style={il.root}>
            <Animated.View
                style={[
                    il.ghostCard,
                    il.ghostFare,
                    {
                        backgroundColor: C.cardBg,
                        borderColor: C.cardBorder,
                        shadowColor: C.shadow,
                        transform: [{ translateY: translateY2 }],
                    },
                ]}
            >
                <View style={il.fareRow}>
                    <View style={{ flex: 1 }}>
                        <Text style={[il.fareAirlineMuted, { color: isDark ? '#475569' : '#94a3b8' }]}>AeroGlobal</Text>
                        <Text style={[il.fareRoute, { color: isDark ? '#334155' : '#cbd5e1' }]}>MNL → NRT · 1 stop</Text>
                    </View>
                    <Text style={[il.farePriceMuted, { color: isDark ? '#475569' : '#94a3b8' }]}>$412</Text>
                </View>
                <View style={[il.ghostBar, { backgroundColor: isDark ? '#1e293b' : '#f1f5f9', marginTop: 10 }]} />
            </Animated.View>

            <Animated.View
                style={[
                    il.mainCard,
                    il.mainFare,
                    {
                        backgroundColor: C.cardBg,
                        borderColor: '#2563eb',
                        shadowColor: '#2563eb',
                        shadowOpacity: isDark ? 0.25 : 0.12,
                        transform: [{ translateY: translateY1 }],
                    },
                ]}
            >
                <View style={il.fareRow}>
                    <View style={{ flex: 1 }}>
                        <Text style={il.fareAirline}>SkyLink Airways</Text>
                        <Text style={[il.fareRoute, { color: isDark ? '#64748b' : '#94a3b8' }]}>MNL → NRT · Direct</Text>
                    </View>
                    <Text style={[il.farePrice, { color: isDark ? '#f1f5f9' : '#0f172a' }]}>$348</Text>
                </View>
                <View style={il.routeBar}>
                    <View style={il.routeDot} />
                    <View style={[il.routeLine, { backgroundColor: isDark ? '#1e293b' : '#e2e8f0' }]} />
                    <Plane size={14} color="#2563eb" />
                    <View style={[il.routeLine, { backgroundColor: isDark ? '#1e293b' : '#e2e8f0' }]} />
                    <View style={il.routeDot} />
                </View>
                <View style={il.routeTimes}>
                    <Text style={[il.routeTime, { color: isDark ? '#94a3b8' : '#64748b' }]}>10:45 AM</Text>
                    <Text style={[il.routeTimeRight, { color: isDark ? '#94a3b8' : '#64748b' }]}>02:30 PM</Text>
                </View>
            </Animated.View>

            <View style={[il.badge, il.badgeCompare]}>
                <TrendingDown size={13} color="#fff" />
                <Text style={il.badgeText}>Lowest Fare Found</Text>
            </View>
        </View>
    );
}

// ── Slide 3: Book Illustration ────────────────────────────────────────────────
function BookIllustration({ isDark }: { isDark: boolean }) {
    const C = isDark ? DC : LC;
    const translateY1 = useFloatAnim(3000, 0, 10);
    const translateY2 = useFloatAnim(3600, 400, 7);

    const pulse = useRef(new Animated.Value(1)).current;
    useEffect(() => {
        Animated.loop(
            Animated.sequence([
                Animated.timing(pulse, { toValue: 1.08, duration: 900, easing: Easing.inOut(Easing.ease), useNativeDriver: true }),
                Animated.timing(pulse, { toValue: 1, duration: 900, easing: Easing.inOut(Easing.ease), useNativeDriver: true }),
            ])
        ).start();
    }, []);

    return (
        <View style={il.root}>
            <Animated.View
                style={[
                    il.ghostCard,
                    il.ghostBook,
                    {
                        backgroundColor: C.cardBg,
                        borderColor: C.cardBorder,
                        shadowColor: C.shadow,
                        transform: [{ translateY: translateY2 }],
                    },
                ]}
            >
                <View style={il.fareRow}>
                    <Ticket size={14} color={isDark ? '#334155' : '#cbd5e1'} />
                    <Text style={[il.ghostLabel, { color: isDark ? '#334155' : '#cbd5e1', marginLeft: 6 }]}>
                        E-Ticket · MNL → NRT
                    </Text>
                </View>
                <View style={[il.ghostBar, { backgroundColor: isDark ? '#1e293b' : '#f1f5f9', marginTop: 10 }]} />
            </Animated.View>

            <Animated.View
                style={[
                    il.mainCard,
                    il.bookCard,
                    {
                        backgroundColor: C.cardBg,
                        borderColor: C.cardBorder,
                        shadowColor: C.shadow,
                        transform: [{ translateY: translateY1 }],
                    },
                ]}
            >
                <Animated.View style={[il.checkCircle, { transform: [{ scale: pulse }] }]}>
                    <Check size={24} color="#fff" strokeWidth={3} />
                </Animated.View>
                <Text style={[il.bookTitle, { color: isDark ? '#f1f5f9' : '#0f172a' }]}>Booking confirmed</Text>
                <View style={il.bookRow}>
                    <ShieldCheck size={13} color="#10b981" />
                    <Text style={[il.bookRowText, { color: isDark ? '#64748b' : '#94a3b8' }]}>
                        Secure payment · Instant e-ticket
                    </Text>
                </View>
            </Animated.View>

            <View style={[il.badge, il.badgeBook]}>
                <Lock size={12} color="#fff" />
                <Text style={il.badgeText}>Payment Verified Through Stripe</Text>
            </View>
        </View>
    );
}

// ── Feature bento grid per slide ──────────────────────────────────────────────
const SLIDE_FEATURES = {
    search: [
        { icon: Zap, label: 'Live Data' },
        { icon: Star, label: '500+ Airlines' },
    ],
    compare: [
        { icon: Zap, label: 'Live Data' },
        { icon: BadgeCheck, label: 'Best Price' },
    ],
    book: [
        { icon: ShieldCheck, label: 'Secure Pay' },
        { icon: Ticket, label: 'Instant Ticket' },
    ],
};

function BentoGrid({ slideKey, isDark }: { slideKey: Slide['key']; isDark: boolean }) {
    const features = SLIDE_FEATURES[slideKey];
    return (
        <View style={bento.row}>
            {features.map(({ icon: Icon, label }) => (
                <View
                    key={label}
                    style={[bento.cell, { backgroundColor: isDark ? '#0f172a' : '#f8fafc', borderColor: isDark ? '#1e293b' : '#f1f5f9' }]}
                >
                    <View style={bento.iconWrap}>
                        <Icon size={18} color="#2563eb" />
                    </View>
                    <Text style={[bento.label, { color: isDark ? '#e2e8f0' : '#0f172a' }]}>{label}</Text>
                </View>
            ))}
        </View>
    );
}

// ── Palette ───────────────────────────────────────────────────────────────────
const DC = {
    bg: '#070e1c',
    cardBg: '#0b1329',
    cardBorder: '#172036',
    panelBg: '#0b1329',
    panelBorder: '#172036',
    shadow: '#000',
    title: '#f1f5f9',
    subtitle: '#64748b',
    dot: '#1e293b',
    skipText: '#475569',
};
const LC = {
    bg: '#f0f6ff',
    cardBg: '#ffffff',
    cardBorder: '#e2e8f0',
    panelBg: '#ffffff',
    panelBorder: '#e2e8f0',
    shadow: '#0f172a',
    title: '#0f172a',
    subtitle: '#64748b',
    dot: '#e2e8f0',
    skipText: '#94a3b8',
};

// ── Main Screen ───────────────────────────────────────────────────────────────
export default function OnboardingScreen() {
    const router = useRouter();
    const isDark = useColorScheme() === 'dark';
    const C = isDark ? DC : LC;
    const insets = useSafeAreaInsets();
    const bottomPad = Math.max(insets.bottom + 12, 20);

    const [activeIndex, setActiveIndex] = useState(0);
    const listRef = useRef<FlatList<Slide>>(null);
    const isLastSlide = activeIndex === SLIDES.length - 1;

    const panelSlide = useRef(new Animated.Value(40)).current;
    const panelFade = useRef(new Animated.Value(0)).current;
    useEffect(() => {
        Animated.parallel([
            Animated.timing(panelSlide, { toValue: 0, duration: 560, delay: 120, easing: Easing.out(Easing.cubic), useNativeDriver: true }),
            Animated.timing(panelFade, { toValue: 1, duration: 560, delay: 120, easing: Easing.out(Easing.cubic), useNativeDriver: true }),
        ]).start();
    }, []);

    const finishOnboarding = async () => {
        try { await AsyncStorage.setItem(ONBOARDING_KEY, 'true'); } catch { }
        router.replace('/(auth)/login');
    };

    const handleScroll = (e: NativeSyntheticEvent<NativeScrollEvent>) => {
        const idx = Math.round(e.nativeEvent.contentOffset.x / width);
        if (idx !== activeIndex) setActiveIndex(idx);
    };

    return (
        <SafeAreaView style={[s.safe, { backgroundColor: C.bg }]} edges={['top', 'bottom']}>
            {/* Atmospheric blobs */}
            <View pointerEvents="none" style={StyleSheet.absoluteFill}>
                <View style={[s.blob1, { backgroundColor: isDark ? 'rgba(37,99,235,0.08)' : 'rgba(37,99,235,0.06)' }]} />
                <View style={[s.blob2, { backgroundColor: isDark ? 'rgba(37,99,235,0.05)' : 'rgba(37,99,235,0.04)' }]} />
            </View>

            {/* Skip button */}
            <Pressable style={s.skipBtn} onPress={finishOnboarding}>
                <Text style={[s.skipText, { color: C.skipText }]}>Skip</Text>
            </Pressable>

            <FlatList
                ref={listRef}
                data={SLIDES}
                horizontal
                pagingEnabled
                showsHorizontalScrollIndicator={false}
                keyExtractor={(item) => item.key}
                onMomentumScrollEnd={handleScroll}
                scrollEventThrottle={16}
                style={s.illustrationList}
                renderItem={({ item }) => (
                    <View style={[s.illustrationPage, { width }]}>
                        {item.key === 'search' && <SearchIllustration isDark={isDark} />}
                        {item.key === 'compare' && <CompareIllustration isDark={isDark} />}
                        {item.key === 'book' && <BookIllustration isDark={isDark} />}
                    </View>
                )}
            />
            <Animated.View
                style={[
                    s.panel,
                    {
                        backgroundColor: C.panelBg,
                        borderTopColor: isDark ? C.panelBorder : 'transparent',
                        shadowColor: '#2563eb',
                        transform: [{ translateY: panelSlide }],
                        opacity: panelFade,
                        maxHeight: activeIndex === 0 ? '38%' : activeIndex === 2 ? '58%' : '52%',
                    },
                ]}
            >
                {/* Scrollable content area */}
                <ScrollView
                    style={s.panelScrollArea}
                    contentContainerStyle={s.panelContent}
                    showsVerticalScrollIndicator={false}
                    bounces={false}
                >
                    {/* Progress dots */}
                    <View style={s.dotsRow}>
                        {SLIDES.map((slide, i) => (
                            <Animated.View
                                key={slide.key}
                                style={[
                                    s.dot,
                                    { backgroundColor: i === activeIndex ? '#2563eb' : C.dot },
                                    i === activeIndex && s.dotActive,
                                ]}
                            />
                        ))}
                    </View>

                    {/* Text */}
                    <Text style={[s.title, { color: C.title }]}>{SLIDES[activeIndex].title}</Text>
                    <Text style={[s.description, { color: C.subtitle }]}>{SLIDES[activeIndex].description}</Text>

                    {/* Feature bento */}
                    <BentoGrid slideKey={SLIDES[activeIndex].key} isDark={isDark} />
                </ScrollView>
                {/* Pinned footer — only shows on last slide */}
                {isLastSlide && (
                    <View style={[s.panelFooter, { paddingBottom: bottomPad }]}>
                        <Pressable
                            onPress={finishOnboarding}
                            android_ripple={{ color: 'rgba(255,255,255,0.18)', borderless: false }}
                            style={s.ctaBtn}
                        >
                            {({ pressed }) => (
                                <View style={[s.ctaBtnInner, pressed && s.ctaBtnPressed]}>
                                    <Text style={s.ctaText}>Let's Get Started</Text>
                                    <Zap size={16} color="#fff" style={{ marginLeft: 8 }} />
                                </View>
                            )}
                        </Pressable>
                    </View>
                )}
            </Animated.View>
        </SafeAreaView>
    );
}

// ── Illustration shared styles ────────────────────────────────────────────────
const CARD_WIDTH = width * 0.82;

const il = StyleSheet.create({
    root: {
        width: '100%',
        alignItems: 'center',
        justifyContent: 'center',
        flex: 1,
        paddingHorizontal: 16,
    },
    mainCard: {
        width: CARD_WIDTH,
        borderRadius: 18,
        padding: 14,
        borderWidth: 1,
        shadowOffset: { width: 0, height: 8 },
        shadowOpacity: 0.1,
        shadowRadius: 20,
        elevation: 8,
        zIndex: 10,
    },
    ghostCard: {
        width: CARD_WIDTH,
        borderRadius: 18,
        padding: 14,
        borderWidth: 1,
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.06,
        shadowRadius: 12,
        elevation: 4,
        zIndex: 5,
        opacity: 0.6,
        position: 'absolute',
        bottom: -10,
        left: 10,
        transform: [{ scale: 0.95 }],
    },

    // Search form fields
    pillRow: { flexDirection: 'row', gap: 7, marginBottom: 12 },
    pill: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 4,
        paddingHorizontal: 10,
        paddingVertical: 6,
        borderRadius: 10,
    },
    pillActive: { backgroundColor: '#2563eb' },
    pillText: { fontSize: 11, fontWeight: '700' },
    pillTextActive: { fontSize: 11, fontWeight: '700', color: '#fff' },

    fromToRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 8,
        marginBottom: 8,
    },
    airportField: {
        borderWidth: 1,
        borderRadius: 10,
        paddingHorizontal: 10,
        paddingVertical: 8,
    },
    swapBtn: {
        width: 30,
        height: 30,
        borderRadius: 15,
        backgroundColor: 'rgba(37,99,235,0.1)',
        alignItems: 'center',
        justifyContent: 'center',
    },
    fieldLabel: { fontSize: 9, fontWeight: '700', letterSpacing: 0.6, marginBottom: 2 },
    fieldValue: { fontSize: 16, fontWeight: '800' },
    fieldSubtext: { fontSize: 10, fontWeight: '500', marginTop: 1 },

    dateRow: { flexDirection: 'row', gap: 8, marginBottom: 8 },
    dateField: {
        flex: 1,
        borderWidth: 1,
        borderRadius: 10,
        paddingHorizontal: 10,
        paddingVertical: 8,
    },
    dateFieldInner: { flexDirection: 'row', alignItems: 'center', marginBottom: 2 },

    passengerRow: {
        flexDirection: 'row',
        alignItems: 'center',
        borderWidth: 1,
        borderRadius: 10,
        paddingHorizontal: 12,
        paddingVertical: 10,
        marginBottom: 12,
    },

    searchFlightsBtn: {
        backgroundColor: '#2563eb',
        borderRadius: 12,
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        paddingVertical: 12,
        gap: 8,
        shadowColor: '#1d4ed8',
        shadowOffset: { width: 0, height: 3 },
        shadowOpacity: 0.4,
        shadowRadius: 8,
        elevation: 5,
    },
    searchFlightsBtnText: {
        color: '#fff',
        fontSize: 14,
        fontWeight: '700',
        letterSpacing: 0.2,
    },

    // Ghost internals
    ghostRow: { flexDirection: 'row', alignItems: 'center', gap: 6, marginBottom: 10 },
    ghostLabel: { fontSize: 12, fontWeight: '600' },
    ghostBar: { height: 8, borderRadius: 4, width: '100%' },
    ghostBarShort: { height: 6, borderRadius: 4, width: '60%', marginTop: 6 },

    // Compare
    ghostFare: { bottom: -14, left: 0 },
    mainFare: {},
    fareRow: { flexDirection: 'row', alignItems: 'center' },
    fareAirline: { fontSize: 14, fontWeight: '700', color: '#2563eb' },
    fareAirlineMuted: { fontSize: 14, fontWeight: '700' },
    fareRoute: { fontSize: 11, marginTop: 2, fontWeight: '500' },
    farePrice: { fontSize: 20, fontWeight: '800' },
    farePriceMuted: { fontSize: 17, fontWeight: '700' },
    routeBar: { flexDirection: 'row', alignItems: 'center', marginTop: 12, gap: 4 },
    routeDot: { width: 6, height: 6, borderRadius: 3, backgroundColor: '#2563eb' },
    routeLine: { flex: 1, height: 1.5, borderRadius: 1 },
    routeTimes: { flexDirection: 'row', justifyContent: 'space-between', marginTop: 4 },
    routeTime: { fontSize: 11, fontWeight: '500' },
    routeTimeRight: { fontSize: 11, fontWeight: '500' },

    // Book
    ghostBook: { bottom: -14, left: 0 },
    bookCard: { alignItems: 'center', paddingVertical: 24 },
    checkCircle: {
        width: 56,
        height: 56,
        borderRadius: 28,
        backgroundColor: '#10b981',
        alignItems: 'center',
        justifyContent: 'center',
        marginBottom: 14,
        shadowColor: '#10b981',
        shadowOffset: { width: 0, height: 6 },
        shadowOpacity: 0.35,
        shadowRadius: 12,
        elevation: 8,
    },
    bookTitle: { fontSize: 17, fontWeight: '800', marginBottom: 10 },
    bookRow: { flexDirection: 'row', alignItems: 'center', gap: 6 },
    bookRowText: { fontSize: 12, fontWeight: '600' },

    // Badges
    badge: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 6,
        backgroundColor: '#2563eb',
        paddingHorizontal: 14,
        paddingVertical: 9,
        borderRadius: 24,
        shadowColor: '#2563eb',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.4,
        shadowRadius: 10,
        elevation: 6,
        zIndex: 20,
        marginTop: 16,
    },
    badgeSearch: {},
    badgeCompare: {},
    badgeBook: {},
    badgeText: { color: '#fff', fontSize: 12, fontWeight: '700' },
});

// ── Bento grid styles ─────────────────────────────────────────────────────────
const bento = StyleSheet.create({
    row: { flexDirection: 'row', gap: 10, marginBottom: 4 },
    cell: {
        flex: 1,
        borderRadius: 14,
        paddingVertical: 12,
        paddingHorizontal: 12,
        alignItems: 'center',
        gap: 6,
        borderWidth: 1,
    },
    iconWrap: {
        width: 36,
        height: 36,
        borderRadius: 18,
        backgroundColor: 'rgba(37,99,235,0.1)',
        alignItems: 'center',
        justifyContent: 'center',
    },
    label: { fontSize: 11, fontWeight: '700' },
});

// ── Main screen styles ────────────────────────────────────────────────────────
const s = StyleSheet.create({
    safe: { flex: 1 },

    blob1: {
        position: 'absolute',
        top: -60,
        left: -60,
        width: 280,
        height: 280,
        borderRadius: 140,
    },
    blob2: {
        position: 'absolute',
        bottom: 200,
        right: -80,
        width: 320,
        height: 320,
        borderRadius: 160,
    },

    skipBtn: {
        position: 'absolute',
        top: 56,
        right: 20,
        zIndex: 30,
        paddingHorizontal: 14,
        paddingVertical: 8,
    },
    skipText: { fontSize: 14, fontWeight: '600' },

    illustrationList: { flex: 1 },
    illustrationPage: {
        flex: 1,
        paddingTop: 32,
        paddingBottom: 16,
    },
    panel: {
        borderTopLeftRadius: 32,
        borderTopRightRadius: 32,
        borderTopWidth: 1,
        shadowOffset: { width: 0, height: -6 },
        shadowOpacity: 0.06,
        shadowRadius: 24,
        elevation: 12,
        flexDirection: 'column',
    },

    panelScrollArea: {
        flexShrink: 1,
    },
    panelContent: {
        paddingHorizontal: 24,
        paddingTop: 20,
        paddingBottom: 8,
    },

    panelFooter: {
        paddingHorizontal: 24,
        paddingTop: 8,
    },

    dotsRow: {
        flexDirection: 'row',
        justifyContent: 'center',
        gap: 6,
        marginBottom: 16,
    },
    dot: { height: 6, width: 6, borderRadius: 3 },
    dotActive: { width: 22, borderRadius: 3 },

    title: {
        fontSize: 22,
        fontWeight: '800',
        marginBottom: 6,
        letterSpacing: -0.4,
        lineHeight: 28,
    },
    description: {
        fontSize: 13,
        lineHeight: 20,
        fontWeight: '400',
        marginBottom: 14,
    },
    ctaBtn: {
        backgroundColor: '#2563eb',
        borderRadius: 14,
        height: 54,
        shadowColor: '#1d4ed8',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.4,
        shadowRadius: 12,
        elevation: 6,
        overflow: 'hidden',
    },
    ctaBtnInner: {
        flex: 1,
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
    },
    ctaBtnPressed: { opacity: 0.65, transform: [{ scale: 0.98 }] },
    ctaText: {
        color: '#fff',
        fontSize: 15,
        fontWeight: '700',
        letterSpacing: 0.3,
    },
});