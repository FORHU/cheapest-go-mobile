import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, Pressable, useColorScheme } from 'react-native';
import { Image } from 'expo-image';
import { Compass } from 'lucide-react-native';
import { fetchPopularDestinations, type PopularDestination } from '../../../lib/landing';
import { convertCurrency } from '../../../lib/currency';
import { useSettings } from '../../../context/SettingsContext';

export default function ExploreVacationPackages() {
    const colorScheme = useColorScheme();
    const isDark = colorScheme === 'dark';
    const styles = getStyles(isDark);
    const { currency } = useSettings();

    const [destinations, setDestinations] = useState<PopularDestination[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchPopularDestinations().then(data => {
            setDestinations(data);
            setLoading(false);
        });
    }, []);

    const placeholders = [0, 1, 2, 3];

    return (
        <View style={styles.container}>
            <View style={styles.header}>
                <View style={styles.titleRow}>
                    <Compass size={16} color="#3b82f6" />
                    <Text style={styles.title}>Popular destinations</Text>
                </View>
                <Pressable>
                    <Text style={styles.seeAll}>See all &rsaquo;</Text>
                </Pressable>
            </View>

            <View style={styles.grid}>
                {loading
                    ? placeholders.map(i => (
                        <View key={i} style={[styles.card, styles.skeleton]} />
                    ))
                    : destinations.map(dest => {
                        const avgPrice = dest.averagePrice > 0
                            ? Math.round(convertCurrency(dest.averagePrice, 'PHP', currency.code))
                            : null;
                        return (
                            <Pressable key={dest.id} style={styles.card}>
                                <View style={styles.imageWrap}>
                                    <Image
                                        source={{ uri: dest.imageUrl }}
                                        style={styles.image}
                                        contentFit="cover"
                                        cachePolicy="memory-disk"
                                        placeholder={{ blurhash: 'L15#hiof00of~qfQIUay00fQ-;fQ' }}
                                    />
                                </View>
                                <View style={styles.cardBody}>
                                    <Text style={styles.cardTitle} numberOfLines={1}>{dest.city}</Text>
                                    <Text style={styles.cardSubtitle} numberOfLines={1}>{dest.country}</Text>
                                    {avgPrice && avgPrice > 0 && (
                                        <Text style={styles.cardPrice}>
                                            from {currency.symbol}{avgPrice.toLocaleString()}
                                        </Text>
                                    )}
                                </View>
                            </Pressable>
                        );
                    })
                }
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
        marginBottom: 12,
    },
    titleRow: { flexDirection: 'row', alignItems: 'center', gap: 7 },
    title: { fontSize: 16, fontWeight: '700', color: isDark ? '#ffffff' : '#0f172a' },
    seeAll: { fontSize: 13, fontWeight: '500', color: '#3b82f6' },
    grid: { flexDirection: 'row', flexWrap: 'wrap', gap: 10 },
    card: {
        width: '47.5%',
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        borderRadius: 16,
        overflow: 'hidden',
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
    },
    skeleton: { height: 175, backgroundColor: isDark ? '#1e293b' : '#f1f5f9' },
    imageWrap: { height: 110 },
    image: { width: '100%', height: '100%', backgroundColor: isDark ? '#1e293b' : '#f1f5f9' },
    cardBody: { padding: 10, gap: 3 },
    cardTitle: { fontSize: 13, fontWeight: '700', color: isDark ? '#ffffff' : '#0f172a' },
    cardSubtitle: { fontSize: 11, color: isDark ? '#64748b' : '#94a3b8' },
    cardPrice: { fontSize: 11, fontWeight: '600', color: isDark ? '#94a3b8' : '#475569', marginTop: 2 },
});
