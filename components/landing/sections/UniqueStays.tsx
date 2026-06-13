import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, Pressable, ScrollView, useColorScheme } from 'react-native';
import { Image } from 'expo-image';
import { Sparkles, Heart, Star } from 'lucide-react-native';
import { searchHotels } from '../../../lib/travel-api';
import { resolveHotelImage } from '../../../lib/hotel-image';
import { useSettings } from '../../../context/SettingsContext';

const ESCAPES = [
    { name: 'Maldives Water Villas', location: 'Maldives', destination: 'Maldives', badge: 'Water Villa', badgeIcon: 'star', fallbackImage: 'https://images.unsplash.com/photo-1439066615861-d1af74d74000?auto=format&fit=crop&w=500&q=80' },
    { name: 'Arctic Glass Igloo', location: 'Finland', destination: 'Rovaniemi', badge: 'Bucket List', badgeIcon: 'heart', fallbackImage: 'https://images.unsplash.com/photo-1517059224940-d4af9eec41b7?auto=format&fit=crop&w=500&q=80' },
    { name: 'Bamboo Treehouse', location: 'Bali, Indonesia', destination: 'Ubud', badge: 'Eco-Friendly', badgeIcon: 'star', fallbackImage: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?auto=format&fit=crop&w=500&q=80' },
    { name: 'Historic Castle Stay', location: 'Scotland', destination: 'Edinburgh', badge: 'Authentic', badgeIcon: 'heart', fallbackImage: 'https://images.unsplash.com/photo-1533154683836-84ea7a0bc310?auto=format&fit=crop&w=500&q=80' },
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

export default function UniqueStays() {
    const colorScheme = useColorScheme();
    const isDark = colorScheme === 'dark';
    const { currency } = useSettings();

    const [stays, setStays] = useState<any[]>(
        ESCAPES.map(e => ({ ...e, price: null, image: e.fallbackImage, loading: true }))
    );

    useEffect(() => {
        const { checkIn, checkOut } = getNextWeekDates();

        Promise.allSettled(
            ESCAPES.map(escape =>
                searchHotels({
                    destination: escape.destination,
                    checkIn,
                    checkOut,
                    adults: 2,
                    children: 0,
                    rooms: 1,
                    currency: currency.code,
                })
            )
        ).then(results => {
            setStays(
                ESCAPES.map((escape, i) => {
                    const result = results[i];
                    const hotel = result.status === 'fulfilled' ? result.value?.data?.[0] : null;
                    return {
                        ...escape,
                        loading: false,
                        image: resolveHotelImage(hotel, escape.fallbackImage),
                        price: hotel?.price?.amount ? Math.round(hotel.price.amount) : null,
                    };
                })
            );
        });
    }, [currency.code]);

    return (
        <View style={styles.container}>
            <View style={styles.header}>
                <View>
                    <View style={styles.titleRow}>
                        <Sparkles size={16} color="#fbbf24" />
                        <Text style={[styles.title, isDark && styles.titleDark]}>Extraordinary escapes</Text>
                    </View>
                    <Text style={styles.subtitle}>One-of-a-kind places for your next trip</Text>
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
                {stays.map((stay, i) => (
                    <Pressable key={i} style={[styles.card, isDark && styles.cardDark]}>
                        <View style={styles.imageContainer}>
                            <Image
                                source={{ uri: stay.image }}
                                style={styles.image}
                                contentFit="cover"
                                cachePolicy="memory-disk"
                                placeholder={{ blurhash: 'L15#hiof00of~qfQIUay00fQ-;fQ' }}
                            />
                            <View style={styles.badge}>
                                {stay.badgeIcon === 'heart'
                                    ? <Heart size={10} color="white" fill="white" />
                                    : <Star size={10} color="white" fill="white" />
                                }
                                <Text style={styles.badgeText}>{stay.badge}</Text>
                            </View>
                        </View>
                        <View style={styles.content}>
                            <Text style={[styles.name, isDark && styles.nameDark]} numberOfLines={1}>{stay.name}</Text>
                            <Text style={styles.location}>{stay.location}</Text>
                            <View style={styles.footer}>
                                {stay.loading
                                    ? <Text style={styles.price}>...</Text>
                                    : stay.price
                                        ? <>
                                            <Text style={styles.price}>{currency.symbol}{stay.price.toLocaleString()}</Text>
                                            <Text style={styles.perNight}> / night</Text>
                                        </>
                                        : <Text style={styles.price}>—</Text>
                                }
                            </View>
                        </View>
                    </Pressable>
                ))}
            </ScrollView>
        </View>
    );
}

const styles = StyleSheet.create({
    container: { marginTop: 8 },
    header: {
        paddingHorizontal: 20,
        marginBottom: 16,
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'flex-start',
    },
    titleRow: { flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 2 },
    title: { fontSize: 16, fontWeight: '700', color: '#0f172a' },
    titleDark: { color: '#ffffff' },
    subtitle: { fontSize: 13, color: '#64748b' },
    seeAll: { fontSize: 13, fontWeight: '500', color: '#3b82f6', marginTop: 2 },
    scrollContent: { paddingHorizontal: 20, gap: 16, paddingBottom: 4 },
    card: {
        width: 200,
        backgroundColor: '#ffffff',
        borderRadius: 20,
        overflow: 'hidden',
        borderWidth: 1,
        borderColor: '#e2e8f0',
    },
    cardDark: { backgroundColor: '#0f172a', borderColor: '#1e293b' },
    imageContainer: { width: '100%', height: 130, position: 'relative' },
    image: { width: '100%', height: '100%', backgroundColor: '#1e293b' },
    badge: {
        position: 'absolute',
        top: 10,
        left: 10,
        backgroundColor: 'rgba(37, 99, 235, 0.9)',
        paddingHorizontal: 9,
        paddingVertical: 4,
        borderRadius: 20,
        flexDirection: 'row',
        alignItems: 'center',
        gap: 4,
    },
    badgeText: { color: 'white', fontSize: 10, fontWeight: '700' },
    content: { padding: 12 },
    name: { fontSize: 14, fontWeight: '700', color: '#0f172a' },
    nameDark: { color: '#ffffff' },
    location: { fontSize: 12, color: '#64748b', marginTop: 2, marginBottom: 8 },
    footer: { flexDirection: 'row', alignItems: 'baseline' },
    price: { fontSize: 15, fontWeight: '800', color: '#2563eb' },
    perNight: { fontSize: 11, color: '#94a3b8' },
});
