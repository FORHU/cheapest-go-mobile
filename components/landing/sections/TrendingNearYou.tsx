import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, Pressable, ScrollView, useColorScheme } from 'react-native';
import { Image } from 'expo-image';
import { TrendingUp, MapPin, Star } from 'lucide-react-native';
import { useSettings } from '../../../context/SettingsContext';
import { fetchWeekendDeals, WeekendDeal } from '../../../lib/landing';
import { convertCurrency } from '../../../lib/currency';

export default function TrendingNearYou() {
    const colorScheme = useColorScheme();
    const isDark = colorScheme === 'dark';
    const styles = getStyles(isDark);
    const { currency } = useSettings();

    const [deals, setDeals] = useState<WeekendDeal[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchWeekendDeals().then(data => {
            setDeals(data);
            setLoading(false);
        });
    }, []);

    const placeholders = Array.from({ length: 3 });

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
                {loading
                    ? placeholders.map((_, i) => (
                        <View key={i} style={[styles.card, styles.skeleton]} />
                    ))
                    : deals.map(deal => {
                        const converted = Math.round(convertCurrency(deal.salePrice, 'PHP', currency.code));
                        return (
                            <Pressable key={deal.id} style={styles.card}>
                                <View style={styles.imageWrap}>
                                    <Image
                                        source={{ uri: deal.imageUrl }}
                                        style={styles.image}
                                        contentFit="cover"
                                        cachePolicy="memory-disk"
                                        placeholder={{ blurhash: 'L15#hiof00of~qfQIUay00fQ-;fQ' }}
                                    />
                                </View>
                                <View style={styles.cardBody}>
                                    <Text style={styles.placeName} numberOfLines={1}>{deal.name}</Text>
                                    <View style={styles.locationRow}>
                                        <MapPin size={11} color={isDark ? '#475569' : '#94a3b8'} />
                                        <Text style={styles.locationText}>{deal.location}</Text>
                                    </View>
                                    <View style={styles.footer}>
                                        <View style={styles.ratingRow}>
                                            <Star size={11} color="#fbbf24" fill="#fbbf24" />
                                            <Text style={styles.ratingText}>
                                                {deal.rating > 0 ? deal.rating.toFixed(1) : '—'}
                                            </Text>
                                        </View>
                                        <Text style={styles.price}>
                                            {converted > 0 ? `${currency.symbol}${converted.toLocaleString()}` : '—'}
                                        </Text>
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
    skeleton: { height: 180, backgroundColor: isDark ? '#1e293b' : '#f1f5f9' },
    imageWrap: { position: 'relative', height: 110 },
    image: { width: '100%', height: '100%', backgroundColor: isDark ? '#1e293b' : '#f1f5f9' },
    cardBody: { padding: 10, gap: 3 },
    placeName: { fontSize: 13, fontWeight: '700', color: isDark ? '#ffffff' : '#0f172a' },
    locationRow: { flexDirection: 'row', alignItems: 'center', gap: 3 },
    locationText: { fontSize: 11, color: isDark ? '#64748b' : '#94a3b8' },
    footer: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginTop: 4 },
    ratingRow: { flexDirection: 'row', alignItems: 'center', gap: 3 },
    ratingText: { fontSize: 11, fontWeight: '600', color: isDark ? '#94a3b8' : '#475569' },
    price: { fontSize: 12, fontWeight: '700', color: isDark ? '#ffffff' : '#0f172a' },
});
