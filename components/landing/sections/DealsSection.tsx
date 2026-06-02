import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, Pressable, useColorScheme, ScrollView, TouchableOpacity } from 'react-native';
import { Image } from 'expo-image';
import { LinearGradient } from 'expo-linear-gradient';
import { Clock, Tag, Heart } from 'lucide-react-native';
import { fetchFlightDeals, type FlightDeal } from '../../../lib/landing';
import { convertCurrency } from '../../../lib/currency';
import { useSettings } from '../../../context/SettingsContext';
import { searchAirports } from '../../../data/airports';
import { getDestinationPhoto, isPlaceholderUrl } from '../../../lib/googlePlaces';

function getCity(iata: string): string {
    const r = searchAirports(iata, 1);
    return r[0]?.city ?? iata;
}

function getCountry(iata: string): string {
    const r = searchAirports(iata, 1);
    return r[0]?.country ?? iata;
}

const CABIN_LABELS: Record<string, string> = {
    economy: 'Economy',
    premium_economy: 'Premium Economy',
    business: 'Business Class',
    first: 'First Class',
};

export default function DealsSection() {
    const colorScheme = useColorScheme();
    const isDark = colorScheme === 'dark';
    const S = styles(isDark);
    const { currency } = useSettings();

    const [deals, setDeals] = useState<FlightDeal[]>([]);
    const [loading, setLoading] = useState(true);
    const [saved, setSaved] = useState<Record<string, boolean>>({});
    const [resolvedImages, setResolvedImages] = useState<Record<string, string>>({});

    useEffect(() => {
        fetchFlightDeals().then(data => {
            const sliced = data.slice(0, 6);
            setDeals(sliced);
            setLoading(false);

            // Fetch Google Places photos for any deal with a missing/placeholder image
            sliced.forEach(deal => {
                if (isPlaceholderUrl(deal.imageUrl)) {
                    const city = getCity(deal.destination);
                    const country = getCountry(deal.destination);
                    getDestinationPhoto(deal.destination, city, country).then(url => {
                        if (url) setResolvedImages(prev => ({ ...prev, [deal.id]: url }));
                    });
                }
            });
        });
    }, []);

    return (
        <View>
            {/* Section header */}
            <View style={S.header}>
                <View style={S.titleRow}>
                    <Tag size={15} color="#f59e0b" />
                    <Text style={S.title}>Exclusive deals</Text>
                </View>
                <Pressable>
                    <Text style={S.viewAll}>View all ›</Text>
                </Pressable>
            </View>

            {/* Live badge */}
            <View style={S.liveBadge}>
                <Clock size={11} color="#f59e0b" />
                <Text style={S.liveText}>Live prices · updated every 6 hours</Text>
            </View>

            {/* Cards */}
            <ScrollView
                horizontal
                showsHorizontalScrollIndicator={false}
                contentContainerStyle={S.scroll}
            >
                {loading
                    ? [0, 1, 2].map(i => <View key={i} style={[S.card, S.skeleton]} />)
                    : deals.map(deal => {
                        const price = Math.round(convertCurrency(deal.price, deal.currency, currency.code));
                        const origPrice = Math.round(convertCurrency(deal.originalPrice, deal.currency, currency.code));
                        const originCity = getCity(deal.origin);
                        const destCity = getCity(deal.destination);
                        const originCountry = getCountry(deal.origin);
                        const destCountry = getCountry(deal.destination);
                        const isOneWay = !deal.returnDate;
                        const cabinKey = (deal.airline ?? '').toLowerCase().replace(' ', '_');
                        const cabinLabel = CABIN_LABELS[cabinKey] ?? deal.airline ?? 'Economy';

                        const imageUri = resolvedImages[deal.id] ?? deal.imageUrl;

                        return (
                            <Pressable key={deal.id} style={S.card}>
                                {/* ── Image section ── */}
                                <View style={S.imageWrap}>
                                    <Image
                                        source={{ uri: imageUri }}
                                        style={S.image}
                                        contentFit="cover"
                                        cachePolicy="memory-disk"
                                        placeholder={{ blurhash: 'L15#hiof00of~qfQIUay00fQ-;fQ' }}
                                    />

                                    {/* Discount badge — top left */}
                                    {deal.discountPct > 0 && (
                                        <View style={S.discountBadge}>
                                            <Text style={S.discountText}>{deal.discountPct}% OFF</Text>
                                        </View>
                                    )}

                                    {/* Heart save button — top right */}
                                    <TouchableOpacity
                                        style={S.bookmarkBtn}
                                        onPress={() => setSaved(prev => ({ ...prev, [deal.id]: !prev[deal.id] }))}
                                        hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
                                    >
                                        <Heart
                                            size={14}
                                            color={saved[deal.id] ? '#ef4444' : '#ffffff'}
                                            fill={saved[deal.id] ? '#ef4444' : 'transparent'}
                                        />
                                    </TouchableOpacity>

                                    {/* Price overlay — gradient at bottom */}
                                    <LinearGradient
                                        colors={['transparent', 'rgba(0,0,0,0.78)']}
                                        style={S.gradient}
                                    >
                                        <Text style={S.startingFrom}>STARTING FROM</Text>
                                        <View style={S.priceRow}>
                                            <View style={S.priceLeft}>
                                                {origPrice > 0 && origPrice > price && (
                                                    <Text style={S.origPrice}>
                                                        {currency.symbol}{origPrice.toLocaleString()}
                                                    </Text>
                                                )}
                                                <Text style={S.price}>
                                                    {currency.symbol}{price.toLocaleString()}
                                                </Text>
                                            </View>
                                            {deal.endsIn ? (
                                                <Text style={S.endsIn}>Ends in {deal.endsIn}</Text>
                                            ) : null}
                                        </View>
                                    </LinearGradient>
                                </View>

                                {/* ── Card body ── */}
                                <View style={S.body}>
                                    {/* Route */}
                                    <Text style={S.route} numberOfLines={1}>
                                        {originCity} ({deal.origin}) → {destCity} ({deal.destination})
                                    </Text>

                                    {/* Countries */}
                                    <Text style={S.countries} numberOfLines={1}>
                                        {originCountry} → {destCountry}
                                    </Text>

                                    {/* Cabin class */}
                                    <Text style={S.cabin} numberOfLines={1}>
                                        {cabinLabel}
                                    </Text>

                                    {/* Footer: trip type + Book Now */}
                                    <View style={S.footer}>
                                        <View style={S.tripPill}>
                                            <Text style={S.tripPillText}>
                                                {isOneWay ? 'One Way' : 'Round Trip'}
                                            </Text>
                                        </View>
                                        <Pressable style={S.bookBtn}>
                                            <Text style={S.bookBtnText}>Book Now →</Text>
                                        </Pressable>
                                    </View>
                                </View>
                            </Pressable>
                        );
                    })
                }
            </ScrollView>
        </View>
    );
}

const CARD_W = 248;

const styles = (isDark: boolean) => StyleSheet.create({
    header: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        paddingHorizontal: 20,
        marginBottom: 10,
    },
    titleRow: { flexDirection: 'row', alignItems: 'center', gap: 6 },
    title: { fontSize: 16, fontWeight: '700', color: isDark ? '#f8fafc' : '#0f172a' },
    viewAll: { fontSize: 13, fontWeight: '500', color: '#3b82f6' },

    liveBadge: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 5,
        alignSelf: 'flex-start',
        marginHorizontal: 20,
        marginBottom: 14,
        backgroundColor: isDark ? 'rgba(120,53,15,0.3)' : '#fef3c7',
        borderWidth: 1,
        borderColor: isDark ? 'rgba(217,119,6,0.35)' : '#fde68a',
        paddingHorizontal: 10,
        paddingVertical: 5,
        borderRadius: 20,
    },
    liveText: { fontSize: 11, fontWeight: '600', color: '#f59e0b' },

    scroll: { paddingHorizontal: 20, gap: 12, paddingBottom: 4 },

    card: {
        width: CARD_W,
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        borderRadius: 0,
        overflow: 'hidden',
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
    },
    skeleton: {
        height: 270,
        backgroundColor: isDark ? '#1e293b' : '#f1f5f9',
    },

    /* Image section */
    imageWrap: { position: 'relative', height: 145 },
    image: {
        width: '100%',
        height: '100%',
        backgroundColor: isDark ? '#1e293b' : '#f1f5f9',
    },

    discountBadge: {
        position: 'absolute',
        top: 10,
        left: 10,
        backgroundColor: '#2563eb',
        paddingHorizontal: 7,
        paddingVertical: 3,
        borderRadius: 6,
        zIndex: 3,
    },
    discountText: { fontSize: 10, fontWeight: '800', color: '#ffffff', letterSpacing: 0.3 },

    bookmarkBtn: {
        position: 'absolute',
        top: 10,
        right: 10,
        width: 30,
        height: 30,
        borderRadius: 15,
        backgroundColor: 'rgba(0,0,0,0.45)',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 3,
    },

    gradient: {
        position: 'absolute',
        bottom: 0,
        left: 0,
        right: 0,
        paddingHorizontal: 12,
        paddingTop: 30,
        paddingBottom: 10,
    },
    startingFrom: {
        fontSize: 8,
        fontWeight: '600',
        color: 'rgba(255,255,255,0.75)',
        letterSpacing: 1,
        textTransform: 'uppercase',
        marginBottom: 2,
    },
    priceRow: {
        flexDirection: 'row',
        alignItems: 'flex-end',
        justifyContent: 'space-between',
    },
    priceLeft: { flexDirection: 'column', alignItems: 'flex-start', gap: 1 },
    origPrice: { fontSize: 11, color: 'rgba(255,255,255,0.55)', textDecorationLine: 'line-through' },
    price: { fontSize: 22, fontWeight: '800', color: '#ffffff' },
    endsIn: { fontSize: 10, fontWeight: '600', color: 'rgba(255,255,255,0.8)', marginBottom: 2 },

    /* Card body */
    body: { paddingHorizontal: 12, paddingTop: 10, paddingBottom: 12, gap: 3 },
    route: { fontSize: 10, fontWeight: '700', color: isDark ? '#f1f5f9' : '#0f172a' },
    countries: { fontSize: 11, color: isDark ? '#94a3b8' : '#64748b' },
    cabin: { fontSize: 11, color: isDark ? '#64748b' : '#94a3b8', marginBottom: 6 },

    footer: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
    },
    tripPill: {
        backgroundColor: isDark ? 'rgba(59,130,246,0.12)' : '#eff6ff',
        borderWidth: 1,
        borderColor: isDark ? 'rgba(59,130,246,0.35)' : '#bfdbfe',
        paddingHorizontal: 10,
        paddingVertical: 4,
        borderRadius: 20,
    },
    tripPillText: { fontSize: 11, fontWeight: '600', color: '#3b82f6' },
    bookBtn: {
        backgroundColor: '#2563eb',
        paddingHorizontal: 14,
        paddingVertical: 7,
        borderRadius: 0,
    },
    bookBtnText: { fontSize: 12, fontWeight: '700', color: '#ffffff' },
});
