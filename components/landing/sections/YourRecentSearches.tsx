import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, Pressable, ScrollView, useColorScheme, Alert } from 'react-native';
import { Clock, MapPin, Calendar, Users } from 'lucide-react-native';
import { getRecentSearches, clearSearchHistory, RecentSearch } from '../../../lib/search-history';
import { useRouter } from 'expo-router';

const YourRecentSearches = () => {
    const [recentSearches, setRecentSearches] = useState<RecentSearch[]>([]);
    const colorScheme = useColorScheme();
    const isDark = colorScheme === 'dark';
    const router = useRouter();

    const loadHistory = async () => {
        try {
            const history = await getRecentSearches();
            if (history && Array.isArray(history)) {
                setRecentSearches(history);
            }
        } catch (error) {
            console.error('Failed to load recent searches:', error);
        }
    };

    useEffect(() => {
        loadHistory();
    }, []);

    if (recentSearches.length === 0) return null;

    const handleSearchClick = (search: RecentSearch) => {
        router.push({
            pathname: '/search',
            params: {
                destination: search.destination,
                placeId: search.placeId || '',
                countryCode: search.countryCode || '',
                checkIn: search.checkIn,
                checkOut: search.checkOut,
                adults: search.adults.toString(),
                rooms: search.rooms.toString(),
                currency: 'USD',
            },
        });
    };

    const handleClearAll = () => {
        Alert.alert('Clear recent searches', 'Are you sure?', [
            { text: 'Cancel', style: 'cancel' },
            {
                text: 'Clear',
                style: 'destructive',
                onPress: async () => {
                    await clearSearchHistory();
                    setRecentSearches([]);
                },
            },
        ]);
    };

    const styles = getStyles(isDark);

    return (
        <View style={styles.container}>
            <View style={styles.header}>
                <View style={styles.titleRow}>
                    <Clock size={16} color={isDark ? '#64748b' : '#94a3b8'} />
                    <Text style={styles.title}>Recent searches</Text>
                </View>
                <Pressable onPress={handleClearAll}>
                    <Text style={styles.clearAll}>Clear all</Text>
                </Pressable>
            </View>

            <ScrollView
                horizontal
                showsHorizontalScrollIndicator={false}
                contentContainerStyle={styles.scrollContent}
            >
                {recentSearches.map((search, index) => (
                    <Pressable
                        key={search.id || `search-${index}`}
                        style={styles.card}
                        onPress={() => handleSearchClick(search)}
                    >
                        <View style={styles.destRow}>
                            <MapPin size={13} color="#3b82f6" />
                            <Text style={styles.destText} numberOfLines={1}>
                                {search.destination}
                            </Text>
                        </View>
                        <View style={styles.metaRow}>
                            <Calendar size={11} color={isDark ? '#475569' : '#94a3b8'} />
                            <Text style={styles.metaText}>
                                {search.checkIn} - {search.checkOut}
                            </Text>
                        </View>
                        <View style={styles.metaRow}>
                            <Users size={11} color={isDark ? '#475569' : '#94a3b8'} />
                            <Text style={styles.metaText}>
                                {search.adults} guests
                            </Text>
                        </View>
                    </Pressable>
                ))}
            </ScrollView>
        </View>
    );
};

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
    clearAll: {
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
        padding: 14,
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
        gap: 6,
    },
    destRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 5,
        marginBottom: 2,
    },
    destText: {
        fontSize: 14,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
        flex: 1,
    },
    metaRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 5,
    },
    metaText: {
        fontSize: 12,
        color: isDark ? '#64748b' : '#94a3b8',
        fontWeight: '400',
    },
});

export default YourRecentSearches;
