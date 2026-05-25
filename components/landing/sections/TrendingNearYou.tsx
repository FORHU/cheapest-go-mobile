import React from 'react';
import { View, Text, StyleSheet, Pressable, ScrollView, Image, useColorScheme } from 'react-native';
import { TrendingUp, MapPin, Star } from 'lucide-react-native';

const TRENDING_PLACES = [
    {
        id: 't1',
        name: 'Baguio City',
        location: 'Benguet, PH',
        price: 2800,
        rating: 4.8,
        image: 'https://images.unsplash.com/photo-1518509562904-e7ef99cdcc86?auto=format&fit=crop&w=500&q=80',
    },
    {
        id: 't2',
        name: 'Tagaytay',
        location: 'Cavite, PH',
        price: 3200,
        rating: 4.7,
        image: 'https://images.unsplash.com/photo-1578469550956-0e16b69c6a3d?auto=format&fit=crop&w=500&q=80',
    },
    {
        id: 't3',
        name: 'Boracay',
        location: 'Aklan, PH',
        price: 4500,
        rating: 4.9,
        image: 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?auto=format&fit=crop&w=500&q=80',
    },
    {
        id: 't4',
        name: 'El Nido',
        location: 'Palawan, PH',
        price: 5800,
        rating: 4.9,
        image: 'https://images.unsplash.com/photo-1518391846015-55a9cc003b25?auto=format&fit=crop&w=500&q=80',
    },
];

export default function TrendingNearYou() {
    const colorScheme = useColorScheme();
    const isDark = colorScheme === 'dark';
    const styles = getStyles(isDark);

    return (
        <View style={styles.container}>
            <View style={styles.header}>
                <View style={styles.titleRow}>
                    <TrendingUp size={16} color={isDark ? '#64748b' : '#94a3b8'} />
                    <Text style={styles.title}>Trending near you</Text>
                </View>
                <Pressable>
                    <Text style={styles.seeAll}>See all</Text>
                </Pressable>
            </View>

            <ScrollView
                horizontal
                showsHorizontalScrollIndicator={false}
                contentContainerStyle={styles.scrollContent}
            >
                {TRENDING_PLACES.map((place) => (
                    <Pressable key={place.id} style={styles.card}>
                        <Image source={{ uri: place.image }} style={styles.image} />
                        <View style={styles.cardContent}>
                            <Text style={styles.placeName} numberOfLines={1}>{place.name}</Text>
                            <View style={styles.locationRow}>
                                <MapPin size={11} color={isDark ? '#475569' : '#94a3b8'} />
                                <Text style={styles.locationText}>{place.location}</Text>
                            </View>
                            <View style={styles.footer}>
                                <View style={styles.ratingRow}>
                                    <Star size={11} color="#fbbf24" fill="#fbbf24" />
                                    <Text style={styles.ratingText}>{place.rating}</Text>
                                </View>
                                <Text style={styles.price}>₱{place.price.toLocaleString()}</Text>
                            </View>
                        </View>
                    </Pressable>
                ))}
            </ScrollView>
        </View>
    );
}

const getStyles = (isDark: boolean) => StyleSheet.create({
    container: {
        marginTop: 8,
    },
    header: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        paddingHorizontal: 20,
        marginBottom: 12,
    },
    titleRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 7,
    },
    title: {
        fontSize: 16,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
    },
    seeAll: {
        fontSize: 13,
        fontWeight: '500',
        color: '#3b82f6',
    },
    scrollContent: {
        paddingHorizontal: 20,
        gap: 12,
        paddingBottom: 4,
    },
    card: {
        width: 160,
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        borderRadius: 16,
        overflow: 'hidden',
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
    },
    image: {
        width: '100%',
        height: 100,
    },
    cardContent: {
        padding: 10,
        gap: 4,
    },
    placeName: {
        fontSize: 13,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
    },
    locationRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 3,
    },
    locationText: {
        fontSize: 11,
        color: isDark ? '#64748b' : '#94a3b8',
    },
    footer: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        marginTop: 4,
    },
    ratingRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 3,
    },
    ratingText: {
        fontSize: 11,
        fontWeight: '600',
        color: isDark ? '#94a3b8' : '#475569',
    },
    price: {
        fontSize: 12,
        fontWeight: '700',
        color: '#2563eb',
    },
});
