import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, Pressable, ScrollView, useColorScheme } from 'react-native';
import { Image } from 'expo-image';
import { TrendingUp, MapPin, Star } from 'lucide-react-native';
import { searchHotels } from '../../../lib/api';
import { resolveHotelImage } from '../../../lib/hotelImage';
import { useSettings } from '../../../context/SettingsContext';

const DESTINATIONS = [
    { name: 'Baguio City', location: 'Benguet, PH', countryCode: 'PH', fallbackImage: 'https://images.unsplash.com/photo-1518509562904-e7ef99cdcc86?auto=format&fit=crop&w=500&q=80' },
    { name: 'Tagaytay', location: 'Cavite, PH', countryCode: 'PH', fallbackImage: 'https://images.unsplash.com/photo-1578469550956-0e16b69c6a3d?auto=format&fit=crop&w=500&q=80' },
    { name: 'Boracay', location: 'Aklan, PH', countryCode: 'PH', fallbackImage: 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?auto=format&fit=crop&w=500&q=80' },
    { name: 'El Nido', location: 'Palawan, PH', countryCode: 'PH', fallbackImage: 'https://images.unsplash.com/photo-1518391846015-55a9cc003b25?auto=format&fit=crop&w=500&q=80' },
];

function getNextWeekDates() {
    const checkIn = new Date();
    checkIn.setDate(checkIn.getDate() + 7);
    const checkOut = new Date(checkIn);
    checkOut.setDate(checkIn.getDate() + 2);
    return {
        checkIn: checkIn.toISOString().split('T')[0],
        checkOut: checkOut.toISOString().split('T')[0],
    };
}

export default function TrendingNearYou() {
    const colorScheme = useColorScheme();
    const isDark = colorScheme === 'dark';
    const styles = getStyles(isDark);
    const { currency } = useSettings();

    const [places, setPlaces] = useState<any[]>(
        DESTINATIONS.map(d => ({ ...d, price: null, rating: null, image: d.fallbackImage, loading: true }))
    );

    useEffect(() => {
        const { checkIn, checkOut } = getNextWeekDates();

        Promise.allSettled(
            DESTINATIONS.map(dest =>
                searchHotels({
                    destination: dest.name,
                    countryCode: dest.countryCode,
                    checkIn,
                    checkOut,
                    adults: 2,
                    children: 0,
                    rooms: 1,
                    currency: currency.code,
                })
            )
        ).then(results => {
            setPlaces(
                DESTINATIONS.map((dest, i) => {
                    const result = results[i];
                    const hotel = result.status === 'fulfilled' ? result.value?.data?.[0] : null;
                    return {
                        ...dest,
                        loading: false,
                        image: resolveHotelImage(hotel, dest.fallbackImage),
                        price: hotel?.price?.amount ? Math.round(hotel.price.amount) : null,
                        rating: hotel?.reviewRating ? (hotel.reviewRating / 2).toFixed(1) : null,
                    };
                })
            );
        });
    }, [currency.code]);

    return (
        <View style={styles.container}>
            <View style={styles.header}>
                <View style={styles.titleRow}>
                    <TrendingUp size={16} color="#3b82f6" />
                    <Text style={styles.title}>Trending near you</Text>
                </View>
                <Pressable>
                    <Text style={styles.seeAll}>See all &rsaquo;</Text>
                </Pressable>
            </View>

            <ScrollView
                horizontal
                showsHorizontalScrollIndicator={false}
                contentContainerStyle={styles.scrollContent}
            >
                {places.map((place, i) => (
                    <Pressable key={i} style={styles.card}>
                        <Image
                            source={{ uri: place.image }}
                            style={styles.image}
                            contentFit="cover"
                            cachePolicy="memory-disk"
                            placeholder={{ blurhash: 'L15#hiof00of~qfQIUay00fQ-;fQ' }}
                        />
                        <View style={styles.cardContent}>
                            <Text style={styles.placeName} numberOfLines={1}>{place.name}</Text>
                            <View style={styles.locationRow}>
                                <MapPin size={11} color={isDark ? '#475569' : '#94a3b8'} />
                                <Text style={styles.locationText}>{place.location}</Text>
                            </View>
                            <View style={styles.footer}>
                                <View style={styles.ratingRow}>
                                    <Star size={11} color="#fbbf24" fill="#fbbf24" />
                                    <Text style={styles.ratingText}>
                                        {place.loading ? '—' : (place.rating || '4.5')}
                                    </Text>
                                </View>
                                <Text style={styles.price}>
                                    {place.loading
                                        ? '...'
                                        : place.price
                                            ? `${currency.symbol}${place.price.toLocaleString()}`
                                            : `${currency.symbol}—`}
                                </Text>
                            </View>
                        </View>
                    </Pressable>
                ))}
            </ScrollView>
        </View>
    );
}

const getStyles = (isDark: boolean) => StyleSheet.create({
    container: { marginTop: 8 },
    header: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        paddingHorizontal: 20,
        marginBottom: 12,
    },
    titleRow: { flexDirection: 'row', alignItems: 'center', gap: 7 },
    title: { fontSize: 16, fontWeight: '700', color: isDark ? '#ffffff' : '#0f172a' },
    seeAll: { fontSize: 13, fontWeight: '500', color: '#3b82f6' },
    scrollContent: { paddingHorizontal: 20, gap: 12, paddingBottom: 4 },
    card: {
        width: 160,
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        borderRadius: 16,
        overflow: 'hidden',
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
    },
    image: { width: '100%', height: 110, backgroundColor: isDark ? '#1e293b' : '#f1f5f9' },
    cardContent: { padding: 10, gap: 4 },
    placeName: { fontSize: 13, fontWeight: '700', color: isDark ? '#ffffff' : '#0f172a' },
    locationRow: { flexDirection: 'row', alignItems: 'center', gap: 3 },
    locationText: { fontSize: 11, color: isDark ? '#64748b' : '#94a3b8' },
    footer: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginTop: 4 },
    ratingRow: { flexDirection: 'row', alignItems: 'center', gap: 3 },
    ratingText: { fontSize: 11, fontWeight: '600', color: isDark ? '#94a3b8' : '#475569' },
    price: { fontSize: 12, fontWeight: '700', color: '#2563eb' },
});
