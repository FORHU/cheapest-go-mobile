import React, { useState, useEffect, useMemo, useCallback, useRef } from 'react';
import { View, Text, StyleSheet, Pressable, FlatList, ActivityIndicator, Alert, useColorScheme, Animated } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { ChevronLeft, Filter, Plane, Search, RefreshCw } from 'lucide-react-native';
import { searchFlights, type FlightSearchParams } from '../lib/travel-api';
import { FlightOffer, FilterState, normalizeFlightOffer, formatDuration } from '../lib/flight-types';
import FlightFilters from '../components/flights/FlightFilters';
import FlightCard from '../components/flights/FlightCard';
import SortBar from '../components/flights/SortBar';
import { useSettings } from '../context/SettingsContext';

// ─── Constants ────────────────────────────────────────────────────────
const SLOW_SEARCH_MS = 15_000;

// ─── Helpers ──────────────────────────────────────────────────────────

function getAirlineName(o: FlightOffer): string {
    return o.validatingAirline || o.segments[0]?.airline?.name || o.segments[0]?.airline?.code || o.provider;
}

function getAirlines(offers: FlightOffer[]): string[] {
    const set = new Set<string>();
    for (const o of offers) {
        const airline = getAirlineName(o);
        if (airline) set.add(airline);
    }
    return Array.from(set).sort();
}

// ─── Loading Skeleton ─────────────────────────────────────────────────

function FlightCardSkeleton({ isDark, delay = 0 }: { isDark: boolean; delay?: number }) {
    const opacity = useRef(new Animated.Value(0.3)).current;

    useEffect(() => {
        const animation = Animated.loop(
            Animated.sequence([
                Animated.timing(opacity, { toValue: 1, duration: 800, useNativeDriver: true, delay }),
                Animated.timing(opacity, { toValue: 0.3, duration: 800, useNativeDriver: true }),
            ])
        );
        animation.start();
        return () => animation.stop();
    }, []);

    const bg = isDark ? '#1e293b' : '#f1f5f9';
    return (
        <Animated.View style={[skeletonStyles.card, {
            opacity,
            backgroundColor: isDark ? '#0f172a' : '#ffffff',
            borderColor: isDark ? '#1e293b' : '#e2e8f0',
        }]}>
            {/* Body row: logo col + route col — mirrors FlightCard body */}
            <View style={skeletonStyles.body}>
                {/* Airline col */}
                <View style={skeletonStyles.airlineCol}>
                    <View style={[skeletonStyles.logo, { backgroundColor: bg }]} />
                    <View style={[skeletonStyles.box, { width: 40, height: 8, borderRadius: 4, backgroundColor: bg }]} />
                    <View style={[skeletonStyles.box, { width: 28, height: 7, borderRadius: 4, backgroundColor: bg }]} />
                </View>
                {/* Route col */}
                <View style={skeletonStyles.routeCol}>
                    {/* Times row */}
                    <View style={skeletonStyles.timesRow}>
                        <View style={skeletonStyles.timeBlock}>
                            <View style={[skeletonStyles.box, { width: 44, height: 20, borderRadius: 4, backgroundColor: bg }]} />
                            <View style={[skeletonStyles.box, { width: 28, height: 9, borderRadius: 4, marginTop: 4, backgroundColor: bg }]} />
                        </View>
                        <View style={skeletonStyles.durationBlock}>
                            <View style={[skeletonStyles.box, { width: 32, height: 8, borderRadius: 4, backgroundColor: bg }]} />
                            <View style={[skeletonStyles.box, { height: 2, borderRadius: 1, marginVertical: 4, backgroundColor: bg, alignSelf: 'stretch' }]} />
                            <View style={[skeletonStyles.box, { width: 40, height: 8, borderRadius: 4, backgroundColor: bg }]} />
                        </View>
                        <View style={[skeletonStyles.timeBlock, { alignItems: 'flex-end' }]}>
                            <View style={[skeletonStyles.box, { width: 44, height: 20, borderRadius: 4, backgroundColor: bg }]} />
                            <View style={[skeletonStyles.box, { width: 28, height: 9, borderRadius: 4, marginTop: 4, backgroundColor: bg }]} />
                        </View>
                    </View>
                    {/* Tags row */}
                    <View style={skeletonStyles.tagsRow}>
                        <View style={[skeletonStyles.box, { width: 68, height: 14, borderRadius: 5, backgroundColor: bg }]} />
                        <View style={[skeletonStyles.box, { width: 44, height: 14, borderRadius: 5, backgroundColor: bg }]} />
                        <View style={[skeletonStyles.box, { width: 52, height: 14, borderRadius: 5, backgroundColor: bg }]} />
                    </View>
                </View>
            </View>
            {/* Footer */}
            <View style={[skeletonStyles.footerRow, { borderTopColor: isDark ? '#1e293b' : '#f1f5f9' }]}>
                <View>
                    <View style={[skeletonStyles.box, { width: 88, height: 20, borderRadius: 4, backgroundColor: bg }]} />
                    <View style={[skeletonStyles.box, { width: 60, height: 9, borderRadius: 4, marginTop: 4, backgroundColor: bg }]} />
                </View>
                <View style={{ flexDirection: 'row', gap: 8, alignItems: 'center' }}>
                    <View style={[skeletonStyles.box, { width: 32, height: 32, borderRadius: 8, backgroundColor: bg }]} />
                    <View style={[skeletonStyles.box, { width: 72, height: 36, borderRadius: 9, backgroundColor: bg }]} />
                </View>
            </View>
        </Animated.View>
    );
}

// ─── Main Screen ──────────────────────────────────────────────────────

export default function FlightsScreen() {
    const params = useLocalSearchParams();
    const router = useRouter();
    const colorScheme = useColorScheme();
    const isDark = colorScheme === 'dark';
    const { currency } = useSettings();

    const [loading, setLoading] = useState(true);
    const [isSlowSearch, setIsSlowSearch] = useState(false);
    const [allOffers, setAllOffers] = useState<FlightOffer[]>([]);
    const [isFilterVisible, setIsFilterVisible] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [retryKey, setRetryKey] = useState(0);
    const [filters, setFilters] = useState<FilterState>({
        sortBy: 'price',
        selectedAirlines: [],
        maxStops: null,
        refundableOnly: false,
        selectedProviders: [],
    });

    const cheapestPrice = useMemo(() => {
        if (!allOffers.length) return null;
        return Math.min(...allOffers.map(o => o.price.total));
    }, [allOffers]);

    const fastestDuration = useMemo(() => {
        if (!allOffers.length) return null;
        return Math.min(...allOffers.map(o => o.totalDuration ?? Infinity));
    }, [allOffers]);

    const styles = getStyles(isDark);

    // ─── Fetch flights ────────────────────────────────────────────────
    useEffect(() => {
        let cancelled = false;

        const fetchFlights = async () => {
            setLoading(true);
            setIsSlowSearch(false);
            setError(null);

            // Show "still searching" after 15s
            const slowTimer = setTimeout(() => {
                if (!cancelled) setIsSlowSearch(true);
            }, SLOW_SEARCH_MS);

            try {
                const adultsCount = parseInt(params.adults as string || params.passengers as string || '1');
                const childrenCount = params.children ? parseInt(params.children as string) : 0;
                const infantsCount = params.infants ? parseInt(params.infants as string) : 0;
                
                const searchParams: FlightSearchParams = {
                    origin: params.from as string,
                    destination: params.to as string,
                    departureDate: params.departure as string,
                    returnDate: (params.returnDate as string) || undefined,
                    adults: adultsCount,
                    children: childrenCount,
                    infants: infantsCount,
                    cabinClass: params.cabin as string || 'economy',
                    tripType: (params.tripType as 'one-way' | 'round-trip' | 'multi-city') || 'one-way',
                    multiCitySegments: params.multiCitySegments ? JSON.parse(params.multiCitySegments as string) : undefined,
                };

                const result = await searchFlights(searchParams);
                clearTimeout(slowTimer);

                if (cancelled) return;

                if (result.success === false) {
                    setError(result.error || 'Failed to fetch flights');
                    return;
                }

                // The unified-flight-search edge function returns data in the same shape as the web app's 
                // POST /api/flights/search → { success: true, data: { offers: [...] } }
                // OR directly as { flights: [...] } or { data: { offers: [...] } }
                let rawOffers: any[] = [];
                if (result.data?.offers) {
                    rawOffers = result.data.offers;
                } else if (result.flights) {
                    rawOffers = result.flights;
                } else if (result.data && Array.isArray(result.data)) {
                    rawOffers = result.data;
                } else if (Array.isArray(result)) {
                    rawOffers = result;
                }

                const tripType = searchParams.returnDate ? 'round-trip' : 'one-way';
                const seenIds = new Set<string>();
                const normalized = rawOffers.map((raw: any) => {
                    const offer = normalizeFlightOffer(raw, tripType);
                    if (seenIds.has(offer.offerId)) {
                        offer.offerId = `${offer.offerId}_dup_${Math.random().toString(36).substring(2, 6)}`;
                    }
                    seenIds.add(offer.offerId);
                    return offer;
                });

                // Sort by price initially
                normalized.sort((a: FlightOffer, b: FlightOffer) => a.price.total - b.price.total);

                setAllOffers(normalized);
            } catch (err: any) {
                clearTimeout(slowTimer);
                if (!cancelled) {
                    setError(err.message || 'An unexpected error occurred');
                }
            } finally {
                if (!cancelled) {
                    setLoading(false);
                    setIsSlowSearch(false);
                }
            }
        };

        fetchFlights();
        return () => { cancelled = true; };
    }, [params.from, params.to, params.departure, params.returnDate, params.passengers, params.cabin, params.tripType, retryKey]);

    // ─── Derived data ─────────────────────────────────────────────────
    const airlines = useMemo(() => getAirlines(allOffers), [allOffers]);

    const filteredOffers = useMemo(() => {
        let offers = [...allOffers];

        // Airline filter
        if (filters.selectedAirlines.length > 0) {
            offers = offers.filter(o => {
                const name = getAirlineName(o);
                return filters.selectedAirlines.includes(name);
            });
        }

        // Stops filter
        if (filters.maxStops !== null) {
            offers = offers.filter(o => o.totalStops <= filters.maxStops!);
        }

        // Refundable filter
        if (filters.refundableOnly) {
            offers = offers.filter(o => (o.farePolicy?.isRefundable ?? o.refundable) === true);
        }

        // Sort
        switch (filters.sortBy) {
            case 'duration':
                offers.sort((a, b) => (a.totalDuration ?? 0) - (b.totalDuration ?? 0));
                break;
            case 'departure':
                offers.sort((a, b) =>
                    new Date(a.segments[0]?.departure?.time ?? 0).getTime() -
                    new Date(b.segments[0]?.departure?.time ?? 0).getTime()
                );
                break;
            default: // price
                offers.sort((a, b) => a.price.total - b.price.total);
        }

        return offers;
    }, [allOffers, filters]);

    const activeFilterCount = filters.selectedAirlines.length +
        (filters.maxStops !== null ? 1 : 0) +
        (filters.refundableOnly ? 1 : 0);

    // ─── Handlers ─────────────────────────────────────────────────────

    const handleSelectFlight = useCallback((offer: FlightOffer) => {
        router.push({
            pathname: '/flight-checkout',
            params: {
                offerData: JSON.stringify(offer),
            }
        });
    }, [router]);

    const handleFilterChange = useCallback((newFilters: FilterState) => {
        setFilters(newFilters);
    }, []);

    // ─── Render ───────────────────────────────────────────────────────
    return (
        <SafeAreaView style={styles.container}>
            {/* Header */}
            <View style={styles.header}>
                <Pressable onPress={() => router.back()} style={styles.backButton}>
                    <ChevronLeft size={24} color={isDark ? '#ffffff' : '#0f172a'} />
                </Pressable>
                <View style={styles.headerTitleContainer}>
                    <Text style={styles.headerTitle}>
                        {params.tripType === 'multi-city' && params.multiCitySegments ? (() => {
                            try {
                                const segments = JSON.parse(params.multiCitySegments as string);
                                return segments.map((s: any) => s.origin).join(' ➔ ') + ' ➔ ' + segments[segments.length - 1].destination;
                            } catch {
                                return 'Multi-City';
                            }
                        })() : `${params.from} → ${params.to}`}
                    </Text>
                    <Text style={styles.headerSubtitle}>
                        {params.departure} • {(() => {
                            const a = parseInt(params.adults as string || '0');
                            const c = parseInt(params.children as string || '0');
                            const inf = parseInt(params.infants as string || '0');
                            const total = a + c + inf || parseInt(params.passengers as string || '1');
                            
                            const parts = [];
                            if (a > 0) parts.push(`${a} Adult${a > 1 ? 's' : ''}`);
                            if (c > 0) parts.push(`${c} Child${c > 1 ? 'ren' : ''}`);
                            if (inf > 0) parts.push(`${inf} Infant${inf > 1 ? 's' : ''}`);
                            
                            const paxText = parts.length > 0 ? parts.join(', ') : `${total} Guest${total !== 1 ? 's' : ''}`;
                            const cabinText = params.cabin ? params.cabin.toString() : 'Economy';
                            return `${paxText} • ${cabinText.charAt(0).toUpperCase() + cabinText.slice(1)}`;
                        })()}
                    </Text>
                </View>
                <Pressable onPress={() => setIsFilterVisible(true)} style={[
                        styles.filterButton,
                        activeFilterCount > 0 && styles.filterButtonActive,
                    ]}>
                    <Filter size={20} color={isDark ? '#38bdf8' : '#2563eb'} />
                    {activeFilterCount > 0 && (
                        <View style={styles.filterCountBadge}>
                            <Text style={styles.filterCountText}>{activeFilterCount}</Text>
                        </View>
                    )}
                </Pressable>
            </View>

            {/* Slow search banner */}
            {isSlowSearch && loading && (
                <View style={styles.slowBanner}>
                    <ActivityIndicator size="small" color="#f59e0b" />
                    <View>
                        <Text style={styles.slowBannerTitle}>Still searching...</Text>
                        <Text style={styles.slowBannerSubtitle}>Flight providers are responding slowly. Hang tight!</Text>
                    </View>
                </View>
            )}

            {loading ? (
                <View style={styles.loadingContainer}>
                    {/* Animated search indicator */}
                    <View style={styles.searchIndicator}>
                        <View style={styles.searchIconContainer}>
                            <Plane size={20} color="#6366f1" />
                        </View>
                        <View>
                            <Text style={styles.searchingText}>Searching flights...</Text>
                            <Text style={styles.searchingSubtext}>Checking multiple providers</Text>
                        </View>
                    </View>

                    {/* Skeleton cards */}
                    {[0, 1, 2, 3, 4].map((i) => (
                        <FlightCardSkeleton key={i} isDark={isDark} delay={i * 150} />
                    ))}
                </View>
            ) : error ? (
                <View style={styles.centerContainer}>
                    <View style={styles.errorIcon}>
                        <Search size={28} color="#ef4444" />
                    </View>
                    <Text style={styles.errorTitle}>Search Failed</Text>
                    <Text style={styles.errorText}>{error}</Text>
                    <Pressable style={styles.retryButton} onPress={() => setRetryKey(k => k + 1)}>
                        <RefreshCw size={16} color="#ffffff" />
                        <Text style={styles.retryText}>Try Again</Text>
                    </Pressable>
                    <Pressable style={styles.backLink} onPress={() => router.back()}>
                        <Text style={styles.backLinkText}>New Search</Text>
                    </Pressable>
                </View>
            ) : allOffers.length === 0 ? (
                <View style={styles.centerContainer}>
                    <View style={styles.emptyIcon}>
                        <Search size={28} color={isDark ? '#64748b' : '#94a3b8'} />
                    </View>
                    <Text style={styles.emptyTitle}>No flights found</Text>
                    <Text style={styles.emptyText}>
                        Try adjusting your dates or search for different routes.
                    </Text>
                    <Pressable style={styles.retryButton} onPress={() => router.back()}>
                        <Text style={styles.retryText}>New Search</Text>
                    </Pressable>
                </View>
            ) : (
                <>
                    {/* Results count + cheapest price hint */}
                    <View style={styles.resultsHeader}>
                        <View>
                            <View style={styles.resultsCountRow}>
                                <Text style={styles.resultsCountNumber}>{filteredOffers.length}</Text>
                                <Text style={styles.resultsCountLabel}> flight{filteredOffers.length !== 1 ? 's' : ''} found</Text>
                            </View>
                            {cheapestPrice !== null && (
                                <Text style={styles.cheapestHint}>
                                    from {currency.symbol} {Math.round(cheapestPrice).toLocaleString()}/person
                                </Text>
                            )}
                        </View>
                        {activeFilterCount > 0 && (
                            <Pressable onPress={() => setFilters({
                                sortBy: 'price', selectedAirlines: [], maxStops: null, refundableOnly: false, selectedProviders: [],
                            })}>
                                <Text style={styles.clearFiltersText}>Clear filters</Text>
                            </Pressable>
                        )}
                    </View>

                    <SortBar
                        active={filters.sortBy as 'price' | 'duration' | 'departure'}
                        onChange={(sort) => setFilters(f => ({ ...f, sortBy: sort }))}
                        isDark={isDark}
                    />

                    {filteredOffers.length === 0 && allOffers.length > 0 ? (
                        <View style={styles.centerContainer}>
                            <Text style={styles.emptyTitle}>No flights match your filters</Text>
                            <Text style={styles.emptyText}>Try adjusting your filter criteria.</Text>
                        </View>
                    ) : (
                        <FlatList
                            data={filteredOffers}
                            keyExtractor={(item) => item.offerId}
                            renderItem={({ item }) => (
                                <FlightCard
                                    offer={item}
                                    onSelect={handleSelectFlight}
                                    currencySymbol={currency.symbol}
                                    isCheapest={cheapestPrice !== null && item.price.total === cheapestPrice}
                                    isFastest={fastestDuration !== null && (item.totalDuration ?? Infinity) === fastestDuration}
                                />
                            )}
                            contentContainerStyle={styles.listContent}
                            showsVerticalScrollIndicator={false}
                            ListFooterComponent={
                                <View style={styles.listFooter}>
                                    <Text style={styles.footerText}>
                                        All {filteredOffers.length} flights shown
                                    </Text>
                                </View>
                            }
                        />
                    )}
                </>
            )}

            {/* Filter Modal */}
            {isFilterVisible && (
                <View style={styles.modalOverlay}>
                    <SafeAreaView style={[styles.modalContent, {
                        backgroundColor: isDark ? '#020617' : '#ffffff',
                    }]}>
                        <View style={styles.modalHeader}>
                            <Text style={styles.modalTitle}>Filters</Text>
                            <Pressable onPress={() => setIsFilterVisible(false)} style={styles.closeModalButton}>
                                <Text style={styles.closeModalText}>Done</Text>
                            </Pressable>
                        </View>
                        <FlightFilters airlines={airlines} onFilterChange={handleFilterChange} />
                    </SafeAreaView>
                </View>
            )}
        </SafeAreaView>
    );
}

// ─── Skeleton Styles ──────────────────────────────────────────────────

const skeletonStyles = StyleSheet.create({
    card: {
        borderRadius: 16,
        borderWidth: 1,
        marginBottom: 12,
        padding: 16,
    },
    headerRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 10,
        marginBottom: 14,
    },
    routeRow: {
        flexDirection: 'row',
        alignItems: 'center',
        marginBottom: 12,
    },
    tagsRow: {
        flexDirection: 'row',
        gap: 6,
        marginBottom: 12,
        marginTop: 8,
    },
    footerRow: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        borderTopWidth: 1,
        paddingTop: 12,
    },
    box: {
        borderRadius: 4,
    },
    body: {
        flexDirection: 'row',
        alignItems: 'center',
        marginBottom: 12,
    },
    airlineCol: {
        width: 60,
        alignItems: 'center',
        gap: 4,
    },
    logo: {
        width: 32,
        height: 32,
        borderRadius: 8,
        marginBottom: 4,
    },
    routeCol: {
        flex: 1,
        marginLeft: 12,
    },
    timesRow: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
    },
    timeBlock: {
        gap: 2,
    },
    durationBlock: {
        alignItems: 'center',
        flex: 1,
        paddingHorizontal: 8,
    },
});

// ─── Main Styles ──────────────────────────────────────────────────────

const getStyles = (isDark: boolean) => StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: isDark ? '#020617' : '#f8fafc',
    },
    header: {
        flexDirection: 'row',
        alignItems: 'center',
        paddingHorizontal: 16,
        paddingVertical: 12,
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        borderBottomWidth: 1,
        borderBottomColor: isDark ? '#1e293b' : '#e2e8f0',
    },
    backButton: {
        width: 40,
        height: 40,
        borderRadius: 20,
        alignItems: 'center',
        justifyContent: 'center',
    },
    headerTitleContainer: {
        flex: 1,
        marginLeft: 8,
    },
    headerTitle: {
        fontSize: 16,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
    },
    headerSubtitle: {
        fontSize: 12,
        color: isDark ? '#94a3b8' : '#64748b',
        marginTop: 2,
    },
    filterButton: {
        width: 40,
        height: 40,
        borderRadius: 20,
        backgroundColor: isDark ? '#1e293b' : '#f1f5f9',
        alignItems: 'center',
        justifyContent: 'center',
    },
    filterButtonActive: {
        backgroundColor: isDark ? 'rgba(37, 99, 235, 0.2)' : '#dbeafe',
    },
    filterCountBadge: {
        position: 'absolute',
        top: 6,
        right: 6,
        width: 14,
        height: 14,
        borderRadius: 7,
        backgroundColor: '#2563eb',
        alignItems: 'center',
        justifyContent: 'center',
    },
    filterCountText: {
        fontSize: 8,
        fontWeight: '800',
        color: '#ffffff',
    },
    slowBanner: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 12,
        marginHorizontal: 16,
        marginTop: 12,
        padding: 14,
        borderRadius: 12,
        backgroundColor: isDark ? 'rgba(245, 158, 11, 0.08)' : '#fffbeb',
        borderWidth: 1,
        borderColor: isDark ? '#92400e' : '#fde68a',
    },
    slowBannerTitle: {
        fontSize: 13,
        fontWeight: '600',
        color: isDark ? '#fbbf24' : '#b45309',
    },
    slowBannerSubtitle: {
        fontSize: 11,
        color: isDark ? '#d97706' : '#92400e',
        marginTop: 1,
    },
    loadingContainer: {
        flex: 1,
        padding: 16,
    },
    searchIndicator: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 12,
        paddingVertical: 16,
        marginBottom: 8,
    },
    searchIconContainer: {
        width: 40,
        height: 40,
        borderRadius: 20,
        backgroundColor: isDark ? 'rgba(99, 102, 241, 0.1)' : '#eef2ff',
        alignItems: 'center',
        justifyContent: 'center',
    },
    searchingText: {
        fontSize: 14,
        fontWeight: '600',
        color: isDark ? '#e2e8f0' : '#0f172a',
    },
    searchingSubtext: {
        fontSize: 11,
        color: isDark ? '#64748b' : '#94a3b8',
        marginTop: 1,
    },
    centerContainer: {
        flex: 1,
        alignItems: 'center',
        justifyContent: 'center',
        padding: 20,
    },
    errorIcon: {
        width: 56,
        height: 56,
        borderRadius: 28,
        backgroundColor: isDark ? 'rgba(239, 68, 68, 0.1)' : '#fef2f2',
        alignItems: 'center',
        justifyContent: 'center',
        marginBottom: 16,
    },
    errorTitle: {
        fontSize: 18,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
        marginBottom: 8,
    },
    errorText: {
        fontSize: 14,
        color: isDark ? '#94a3b8' : '#64748b',
        textAlign: 'center',
        marginBottom: 20,
        maxWidth: 300,
    },
    retryButton: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 8,
        paddingHorizontal: 24,
        paddingVertical: 12,
        backgroundColor: '#2563eb',
        borderRadius: 12,
    },
    retryText: {
        color: '#ffffff',
        fontWeight: '600',
        fontSize: 14,
    },
    backLink: {
        marginTop: 16,
    },
    backLinkText: {
        fontSize: 14,
        color: isDark ? '#60a5fa' : '#2563eb',
        fontWeight: '500',
    },
    emptyIcon: {
        width: 56,
        height: 56,
        borderRadius: 28,
        backgroundColor: isDark ? '#1e293b' : '#f1f5f9',
        alignItems: 'center',
        justifyContent: 'center',
        marginBottom: 16,
    },
    emptyTitle: {
        fontSize: 18,
        fontWeight: '700',
        color: isDark ? '#e2e8f0' : '#0f172a',
        marginBottom: 8,
    },
    emptyText: {
        fontSize: 14,
        color: isDark ? '#94a3b8' : '#64748b',
        textAlign: 'center',
        marginBottom: 20,
        maxWidth: 300,
    },
    resultsHeader: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        paddingHorizontal: 16,
        paddingTop: 14,
        paddingBottom: 6,
        backgroundColor: isDark ? '#020617' : '#f8fafc',
    },
    resultsCountRow: {
        flexDirection: 'row',
        alignItems: 'baseline',
    },
    resultsCountNumber: {
        fontSize: 20,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
    },
    resultsCountLabel: {
        fontSize: 13,
        fontWeight: '400',
        color: isDark ? '#64748b' : '#94a3b8',
    },
    cheapestHint: {
        fontSize: 11,
        color: isDark ? '#34d399' : '#059669',
        fontWeight: '500',
        marginTop: 2,
    },
    clearFiltersText: {
        fontSize: 12,
        color: '#2563eb',
        fontWeight: '600',
    },
    listContent: {
        padding: 16,
        paddingBottom: 40,
    },
    listFooter: {
        alignItems: 'center',
        paddingVertical: 20,
    },
    footerText: {
        fontSize: 10,
        color: isDark ? '#475569' : '#94a3b8',
        textTransform: 'uppercase',
        letterSpacing: 1,
    },
    modalOverlay: {
        position: 'absolute',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        backgroundColor: 'rgba(0,0,0,0.5)',
        zIndex: 1000,
    },
    modalContent: {
        flex: 1,
        marginTop: 100,
        borderTopLeftRadius: 30,
        borderTopRightRadius: 30,
    },
    modalHeader: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        paddingHorizontal: 24,
        paddingVertical: 20,
        borderBottomWidth: 1,
        borderBottomColor: isDark ? '#1e293b' : '#f1f5f9',
    },
    modalTitle: {
        fontSize: 20,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
    },
    closeModalButton: {
        padding: 4,
    },
    closeModalText: {
        fontSize: 16,
        fontWeight: '600',
        color: '#2563eb',
    },
});
