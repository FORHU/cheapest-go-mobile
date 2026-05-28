import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, Pressable, useColorScheme } from 'react-native';
import { Image } from 'expo-image';
import { Clock, Tag } from 'lucide-react-native';
import { searchHotels, searchFlights } from '../../../lib/api';
import { resolveHotelImage } from '../../../lib/hotelImage';
import { useSettings } from '../../../context/SettingsContext';

function getNextWeekDates() {
    const checkIn = new Date();
    checkIn.setDate(checkIn.getDate() + 7);
    const checkOut = new Date(checkIn);
    checkOut.setDate(checkIn.getDate() + 3);
    return {
        checkIn: checkIn.toISOString().split('T')[0],
        checkOut: checkOut.toISOString().split('T')[0],
        flightDate: checkIn.toISOString().split('T')[0],
    };
}

const FALLBACK_DEALS = [
    {
        type: 'flight',
        title: 'Manila to Boracay',
        subtitle: 'Round-trip · Economy',
        image: 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?auto=format&fit=crop&w=500&q=80',
        price: 2800,
        originalPrice: 4500,
        discount: 38,
        endsIn: '2d 14h',
    },
    {
        type: 'hotel',
        title: 'Luxury Stay – Palawan',
        subtitle: '3 nights · Beach villa',
        image: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=500&q=80',
        price: 18500,
        originalPrice: 25000,
        discount: 26,
        endsIn: '5h',
    },
];

export default function DealsSection() {
    const colorScheme = useColorScheme();
    const isDark = colorScheme === 'dark';
    const styles = getStyles(isDark);
    const { currency } = useSettings();
    const [deals, setDeals] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const { checkIn, checkOut, flightDate } = getNextWeekDates();

        Promise.allSettled([
            searchFlights({
                origin: 'MNL',
                destination: 'MPH',
                departureDate: flightDate,
                returnDate: checkOut,
                adults: 2,
                tripType: 'round-trip',
                cabinClass: 'economy',
            }),
            searchHotels({
                destination: 'Puerto Princesa',
                countryCode: 'PH',
                checkIn,
                checkOut,
                adults: 2,
                children: 0,
                rooms: 1,
                currency: currency.code,
            }),
        ]).then(([flightResult, hotelResult]) => {
            const builtDeals: any[] = [];

            // Flight deal
            const flights = flightResult.status === 'fulfilled' ? flightResult.value?.data || flightResult.value?.flights || [] : [];
            const flight = Array.isArray(flights) ? flights[0] : null;
            if (flight) {
                const price = Math.round(
                    flight.price?.amount || flight.price?.total || flight.totalPrice ||
                    flight.segments?.[0]?.price?.amount || FALLBACK_DEALS[0].price
                );
                const originalPrice = Math.round(price * 1.42);
                const discount = Math.round(((originalPrice - price) / originalPrice) * 100);
                builtDeals.push({
                    type: 'flight',
                    title: 'Manila to Boracay',
                    subtitle: 'Round-trip · Economy',
                    image: 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?auto=format&fit=crop&w=500&q=80',
                    price,
                    originalPrice,
                    discount,
                    endsIn: '2d 14h',
                });
            } else {
                builtDeals.push(FALLBACK_DEALS[0]);
            }

            // Hotel deal
            const hotels = hotelResult.status === 'fulfilled' ? hotelResult.value?.data || [] : [];
            const hotel = Array.isArray(hotels) ? hotels.find((h: any) => h.price?.amount) || hotels[0] : null;
            if (hotel) {
                const price = Math.round(hotel.price?.amount || 0);
                const originalPrice = Math.round(price * 1.35);
                const discount = Math.round(((originalPrice - price) / originalPrice) * 100);
                builtDeals.push({
                    type: 'hotel',
                    title: hotel.name || 'Luxury Stay – Palawan',
                    subtitle: `3 nights · ${hotel.city || 'Beach villa'}`,
                    image: resolveHotelImage(hotel, FALLBACK_DEALS[1].image),
                    price,
                    originalPrice,
                    discount,
                    endsIn: '5h',
                });
            } else {
                builtDeals.push(FALLBACK_DEALS[1]);
            }

            setDeals(builtDeals);
            setLoading(false);
        });
    }, [currency.code]);

    const displayDeals = loading ? FALLBACK_DEALS : deals;

    return (
        <View style={styles.container}>
            <View style={styles.header}>
                <View style={styles.titleRow}>
                    <Tag size={16} color="#f59e0b" />
                    <Text style={styles.title}>Exclusive deals</Text>
                </View>
                <Pressable>
                    <Text style={styles.viewAll}>View all &rsaquo;</Text>
                </Pressable>
            </View>

            {/* Limited time badge */}
            <View style={styles.limitedBadge}>
                <Clock size={12} color="#f59e0b" />
                <Text style={styles.limitedText}>Limited time offers</Text>
            </View>

            {/* 2-column deal grid */}
            <View style={styles.grid}>
                {displayDeals.map((deal, i) => (
                    <Pressable key={i} style={styles.card}>
                        <View style={styles.imageWrap}>
                            <Image
                                source={{ uri: deal.image }}
                                style={styles.image}
                                contentFit="cover"
                                cachePolicy="memory-disk"
                                placeholder={{ blurhash: 'L15#hiof00of~qfQIUay00fQ-;fQ' }}
                            />
                            <View style={styles.discountBadge}>
                                <Text style={styles.discountText}>{deal.discount}% OFF</Text>
                            </View>
                        </View>
                        <View style={styles.cardBody}>
                            <View style={styles.priceRow}>
                                <Text style={styles.originalPrice}>
                                    {currency.symbol}{deal.originalPrice?.toLocaleString()}
                                </Text>
                                <Text style={styles.salePrice}>
                                    {currency.symbol}{deal.price?.toLocaleString()}
                                </Text>
                            </View>
                            <Text style={styles.dealTitle} numberOfLines={2}>{deal.title}</Text>
                            <Text style={styles.dealSubtitle} numberOfLines={1}>{deal.subtitle}</Text>
                            <View style={styles.endsRow}>
                                <Clock size={11} color="#f59e0b" />
                                <Text style={styles.endsText}>Ends in {deal.endsIn}</Text>
                            </View>
                        </View>
                    </Pressable>
                ))}
            </View>
        </View>
    );
}

const getStyles = (isDark: boolean) => StyleSheet.create({
    container: { paddingHorizontal: 20 },
    header: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        marginBottom: 10,
    },
    titleRow: { flexDirection: 'row', alignItems: 'center', gap: 7 },
    title: { fontSize: 16, fontWeight: '700', color: isDark ? '#ffffff' : '#0f172a' },
    viewAll: { fontSize: 13, fontWeight: '500', color: '#3b82f6' },
    limitedBadge: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 6,
        alignSelf: 'flex-start',
        backgroundColor: isDark ? 'rgba(120,53,15,0.35)' : '#fef3c7',
        borderWidth: 1,
        borderColor: isDark ? 'rgba(217,119,6,0.4)' : '#fde68a',
        paddingHorizontal: 10,
        paddingVertical: 5,
        borderRadius: 20,
        marginBottom: 14,
    },
    limitedText: { fontSize: 11, fontWeight: '600', color: '#f59e0b' },
    grid: { flexDirection: 'row', gap: 12 },
    card: {
        flex: 1,
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        borderRadius: 16,
        overflow: 'hidden',
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
    },
    imageWrap: { position: 'relative', height: 110 },
    image: { width: '100%', height: '100%', backgroundColor: isDark ? '#1e293b' : '#f1f5f9' },
    discountBadge: {
        position: 'absolute',
        top: 8,
        left: 8,
        backgroundColor: '#10b981',
        paddingHorizontal: 8,
        paddingVertical: 4,
        borderRadius: 8,
    },
    discountText: { fontSize: 10, fontWeight: '800', color: 'white' },
    cardBody: { padding: 10, gap: 3 },
    priceRow: { flexDirection: 'row', alignItems: 'baseline', gap: 5, marginBottom: 2 },
    originalPrice: { fontSize: 11, color: isDark ? '#475569' : '#94a3b8', textDecorationLine: 'line-through' },
    salePrice: { fontSize: 15, fontWeight: '800', color: isDark ? '#ffffff' : '#0f172a' },
    dealTitle: { fontSize: 12, fontWeight: '700', color: isDark ? '#e2e8f0' : '#0f172a' },
    dealSubtitle: { fontSize: 11, color: isDark ? '#64748b' : '#94a3b8' },
    endsRow: { flexDirection: 'row', alignItems: 'center', gap: 4, marginTop: 4 },
    endsText: { fontSize: 10, color: '#f59e0b', fontWeight: '500' },
});
