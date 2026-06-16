import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, Pressable, ScrollView, useColorScheme } from 'react-native';
import { Image } from 'expo-image';
import { Sparkles, Heart, Star } from 'lucide-react-native';
import { useSettings } from '../../../context/SettingsContext';
import { fetchUniqueStays, UniqueStay } from '../../../lib/landing';
import { convertCurrency } from '../../../lib/currency';

export default function UniqueStays() {
    const colorScheme = useColorScheme();
    const isDark = colorScheme === 'dark';
    const styles = getStyles(isDark);
    const { currency } = useSettings();

    const [stays, setStays] = useState<UniqueStay[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchUniqueStays().then(data => {
            setStays(data);
            setLoading(false);
        });
    }, []);

    const placeholders = Array.from({ length: 3 });

    return (
        <View style={styles.container}>
            <View style={styles.header}>
                <View style={styles.titleRow}>
                    <Sparkles size={16} color="#fbbf24" />
                    <Text style={styles.title}>Extraordinary escapes</Text>
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
                    : stays.map(stay => {
                        const converted = Math.round(convertCurrency(stay.price, 'PHP', currency.code));
                        const badgeIcon = stay.badge === 'Unique' || stay.badge === 'Featured' ? 'star' : 'heart';
                        return (
                            <Pressable key={stay.id} style={styles.card}>
                                <View style={styles.imageWrap}>
                                    <Image
                                        source={{ uri: stay.imageUrl }}
                                        style={styles.image}
                                        contentFit="cover"
                                        cachePolicy="memory-disk"
                                        placeholder={{ blurhash: 'L15#hiof00of~qfQIUay00fQ-;fQ' }}
                                    />
                                    {stay.badge && (
                                        <View style={styles.badge}>
                                            {badgeIcon === 'heart'
                                                ? <Heart size={10} color="white" fill="white" />
                                                : <Star size={10} color="white" fill="white" />
                                            }
                                            <Text style={styles.badgeText}>{stay.badge}</Text>
                                        </View>
                                    )}
                                </View>
                                <View style={styles.cardBody}>
                                    <Text style={styles.name} numberOfLines={1}>{stay.name}</Text>
                                    <Text style={styles.location}>{stay.location}</Text>
                                    <View style={styles.footer}>
                                        {converted > 0
                                            ? <>
                                                <Text style={styles.price}>{currency.symbol}{converted.toLocaleString()}</Text>
                                                <Text style={styles.perNight}> / night</Text>
                                            </>
                                            : <Text style={styles.price}>—</Text>
                                        }
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
        width: 200,
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        borderRadius: 16,
        overflow: 'hidden',
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
    },
    skeleton: { height: 210, backgroundColor: isDark ? '#1e293b' : '#f1f5f9' },
    imageWrap: { position: 'relative', height: 130 },
    image: { width: '100%', height: '100%', backgroundColor: isDark ? '#1e293b' : '#f1f5f9' },
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
    cardBody: { padding: 10, gap: 3 },
    name: { fontSize: 13, fontWeight: '700', color: isDark ? '#ffffff' : '#0f172a' },
    location: { fontSize: 11, color: isDark ? '#64748b' : '#94a3b8' },
    footer: { flexDirection: 'row', alignItems: 'baseline', marginTop: 4 },
    price: { fontSize: 13, fontWeight: '800', color: isDark ? '#ffffff' : '#0f172a' },
    perNight: { fontSize: 11, color: isDark ? '#64748b' : '#94a3b8' },
});
