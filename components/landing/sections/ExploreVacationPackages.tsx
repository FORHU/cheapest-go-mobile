import React from 'react';
import { View, Text, StyleSheet, Pressable, useColorScheme } from 'react-native';
import { Image } from 'expo-image';
import { Compass } from 'lucide-react-native';

const DESTINATIONS = [
    { title: 'Siargao', subtitle: 'Surfing Capital', image: 'https://images.unsplash.com/photo-1542332213-9b5a5a3fad35?auto=format&fit=crop&w=500&q=80' },
    { title: 'Batanes', subtitle: 'Scotland of the East', image: 'https://images.unsplash.com/photo-1516690561799-46d8f74f90f6?auto=format&fit=crop&w=500&q=80' },
    { title: 'El Nido', subtitle: 'Island Hopping', image: 'https://images.unsplash.com/photo-1518391846015-55a9cc003b25?auto=format&fit=crop&w=500&q=80' },
    { title: 'Cebu City', subtitle: 'Queen of the South', image: 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?auto=format&fit=crop&w=500&q=80' },
];

export default function ExploreVacationPackages() {
    const colorScheme = useColorScheme();
    const isDark = colorScheme === 'dark';
    const styles = getStyles(isDark);

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
                {DESTINATIONS.map((dest, i) => (
                    <Pressable key={i} style={styles.card}>
                        <Image
                            source={{ uri: dest.image }}
                            style={styles.image}
                            contentFit="cover"
                            cachePolicy="memory-disk"
                            placeholder={{ blurhash: 'L15#hiof00of~qfQIUay00fQ-;fQ' }}
                        />
                        <View style={styles.overlay} />
                        <View style={styles.cardLabel}>
                            <Text style={styles.cardTitle}>{dest.title}</Text>
                            <Text style={styles.cardSubtitle}>{dest.subtitle}</Text>
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
        marginBottom: 12,
    },
    titleRow: { flexDirection: 'row', alignItems: 'center', gap: 7 },
    title: { fontSize: 16, fontWeight: '700', color: isDark ? '#ffffff' : '#0f172a' },
    seeAll: { fontSize: 13, fontWeight: '500', color: '#3b82f6' },
    grid: {
        flexDirection: 'row',
        flexWrap: 'wrap',
        gap: 10,
    },
    card: {
        width: '47.5%',
        height: 130,
        borderRadius: 16,
        overflow: 'hidden',
        position: 'relative',
        backgroundColor: isDark ? '#1e293b' : '#f1f5f9',
    },
    image: {
        position: 'absolute',
        top: 0, left: 0, right: 0, bottom: 0,
    },
    overlay: {
        position: 'absolute',
        top: 0, left: 0, right: 0, bottom: 0,
        backgroundColor: 'rgba(0,0,0,0.32)',
    },
    cardLabel: {
        position: 'absolute',
        bottom: 10,
        left: 12,
        right: 12,
    },
    cardTitle: {
        fontSize: 14,
        fontWeight: '700',
        color: '#ffffff',
    },
    cardSubtitle: {
        fontSize: 11,
        color: 'rgba(255,255,255,0.75)',
        marginTop: 1,
    },
});
