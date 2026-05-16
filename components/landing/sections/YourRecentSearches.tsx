import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, Pressable, ScrollView, useColorScheme } from 'react-native';
import { History, MapPin, Calendar, ChevronRight } from 'lucide-react-native';
import { getRecentSearches, RecentSearch } from '../../../lib/search-history';
import { useRouter } from 'expo-router';

const YourRecentSearches = () => {
    const [recentSearches, setRecentSearches] = useState<RecentSearch[]>([]);
    const colorScheme = useColorScheme();
    const isDark = colorScheme === 'dark';
    const router = useRouter();

    useEffect(() => {
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
                currency: 'USD'
            }
        });
    };

    return (
        <View style={localStyles.container}>
            <View style={localStyles.header}>
                <View style={localStyles.titleRow}>
                    <History size={18} color={isDark ? '#38bdf8' : '#2563eb'} />
                    <Text style={[localStyles.title, isDark && localStyles.titleDark]}>Your recent searches</Text>
                </View>
            </View>

            <ScrollView 
                horizontal 
                showsHorizontalScrollIndicator={false}
                contentContainerStyle={localStyles.scrollContent}
            >
                {recentSearches.map((search, index) => (
                    <Pressable 
                        key={search.id || `search-${index}`} 
                        style={[localStyles.card, isDark && localStyles.cardDark]}
                        onPress={() => handleSearchClick(search)}
                    >
                        <View style={localStyles.destRow}>
                            <MapPin size={14} color={isDark ? '#64748b' : '#94a3b8'} />
                            <Text style={[localStyles.destText, isDark && localStyles.destTextDark]} numberOfLines={1}>
                                {search.destination}
                            </Text>
                        </View>
                        <View style={localStyles.dateRow}>
                            <Calendar size={12} color={isDark ? '#475569' : '#94a3b8'} />
                            <Text style={localStyles.dateText}>
                                {search.checkIn} - {search.checkOut}
                            </Text>
                        </View>
                        <View style={localStyles.guestRow}>
                            <Text style={localStyles.guestText}>
                                {search.adults} guests • {search.rooms} room{search.rooms !== 1 ? 's' : ''}
                            </Text>
                            <ChevronRight size={14} color="#2563eb" />
                        </View>
                    </Pressable>
                ))}
            </ScrollView>
        </View>
    );
};

const localStyles = StyleSheet.create({
    container: {
        marginTop: 24,
    },
    header: {
        paddingHorizontal: 20,
        marginBottom: 12,
    },
    titleRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 8,
    },
    title: {
        fontSize: 18,
        fontWeight: '700',
        color: '#0f172a',
    },
    titleDark: {
        color: '#ffffff',
    },
    scrollContent: {
        paddingHorizontal: 20,
        gap: 12,
        paddingBottom: 4,
    },
    card: {
        width: 200,
        backgroundColor: '#ffffff',
        borderRadius: 16,
        padding: 16,
        borderWidth: 1,
        borderColor: '#e2e8f0',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.05,
        shadowRadius: 4,
        elevation: 2,
    },
    cardDark: {
        backgroundColor: '#0f172a',
        borderColor: '#1e293b',
    },
    destRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 6,
        marginBottom: 6,
    },
    destText: {
        fontSize: 15,
        fontWeight: '600',
        color: '#0f172a',
        flex: 1,
    },
    destTextDark: {
        color: '#ffffff',
    },
    dateRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 6,
        marginBottom: 8,
    },
    dateText: {
        fontSize: 12,
        color: '#64748b',
    },
    guestRow: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
    },
    guestText: {
        fontSize: 11,
        fontWeight: '500',
        color: '#2563eb',
    },
});

export default YourRecentSearches;
