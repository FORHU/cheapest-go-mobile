import React, { useState, useEffect, useRef } from 'react';
import { View, Text, StyleSheet, Pressable, ScrollView, useColorScheme, Dimensions, ActivityIndicator, Image, TextInput } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { ChevronLeft, List, Map as MapIcon, Search, Filter, Star, MapPin, Heart, MousePointer2, Move, X } from 'lucide-react-native';
import { searchHotels, autocompleteDestinations, Destination } from '../../lib/api';
import MapboxWebView from '../../components/search/MapboxWebView';
import FilterModal from '../../components/search/FilterModal';
import HotelSearchModal from '../../components/search/HotelSearchModal';
import StarRating from '../../components/ui/StarRating';
import { useSettings } from '../../context/SettingsContext';
import { getFavorites, toggleFavorite } from '../../lib/favorites';
import { FACILITY_MAP } from '../../components/search/FilterModal';
import Skeleton from '../../components/ui/Skeleton';
import * as Location from 'expo-location';

const { width, height } = Dimensions.get('window');

const getDisplayPrice = (hotel: any) => {
    // 1. Direct price number
    if (typeof hotel.price === 'number' && hotel.price > 0) {
        return Math.round(hotel.price);
    }
    
    // 2. minPrice (commonly returned by search summaries)
    if (typeof hotel.minPrice === 'number' && hotel.minPrice > 0) {
        return Math.round(hotel.minPrice);
    }
    if (typeof hotel.minPrice === 'string' && !isNaN(parseFloat(hotel.minPrice))) {
        return Math.round(parseFloat(hotel.minPrice));
    }

    // 3. Price object with amount
    if (hotel.price && typeof hotel.price === 'object') {
        const amt = hotel.price.amount || hotel.price.total || hotel.price.value;
        if (typeof amt === 'number') return Math.round(amt);
        if (typeof amt === 'string' && !isNaN(parseFloat(amt))) return Math.round(parseFloat(amt));
    }
    
    // 4. Nested in roomTypes (LiteAPI standard)
    // retailRate.total can be an array [{amount, currency}] or an object {amount}
    if (hotel.roomTypes && hotel.roomTypes.length > 0) {
        const rates = hotel.roomTypes[0]?.rates;
        if (rates && rates.length > 0) {
            const total = rates[0]?.retailRate?.total;
            if (Array.isArray(total) && total.length > 0) {
                const amt = total[0]?.amount;
                if (typeof amt === 'number' && amt > 0) return Math.round(amt);
            }
            if (typeof total === 'object' && total !== null && !Array.isArray(total) && 'amount' in total) {
                const amt = (total as any).amount;
                if (typeof amt === 'number' && amt > 0) return Math.round(amt);
            }
            if (typeof total === 'number' && total > 0) return Math.round(total);

            // Fallback: other price paths
            const price = rates[0]?.price?.amount || 
                          rates[0]?.total_amount ||
                          rates[0]?.price;
            
            if (typeof price === 'number' && price > 0) return Math.round(price);
            if (typeof price === 'string' && !isNaN(parseFloat(price)) && parseFloat(price) > 0) return Math.round(parseFloat(price));
        }
    }
    
    return '???';
};

const getPriceColor = (price: any) => {
    if (typeof price !== 'number') return '#2563eb';
    if (price < 1000) return '#22c55e'; // Budget - Green
    if (price > 5000) return '#eab308'; // Luxury - Gold
    return '#2563eb'; // Midrange - Blue
};

const getRatingColor = (rating: any) => {
    const val = parseFloat(rating);
    if (isNaN(val)) return '#94a3b8';
    if (val >= 9) return '#10b981'; // Excellent
    if (val >= 8) return '#22c55e'; // Very Good
    if (val >= 7) return '#f59e0b'; // Good
    return '#f43f5e'; // Poor
};

import OptimizedImage from '../../components/ui/OptimizedImage';

const ImageWithSkeleton = ({ uri, style }: { uri: string, style: any }) => {
    return <OptimizedImage uri={uri} style={style} type="hotel" />;
};

export default function SearchScreen() {
    const params = useLocalSearchParams();
    const router = useRouter();
    const colorScheme = useColorScheme();
    const isDark = colorScheme === 'dark';
    const { currency } = useSettings();
    
    const [loading, setLoading] = useState(true);
    const [rawHotels, setRawHotels] = useState<any[]>([]); // Original data from API
    const [hotels, setHotels] = useState<any[]>([]); // Filtered & sorted data
    const [viewMode, setViewMode] = useState<'map' | 'list'>('map');
    const [selectedHotel, setSelectedHotel] = useState<any>(null);
    const [error, setError] = useState<string | null>(null);
    const isFetching = useRef(false);
    const cardsScrollRef = useRef<ScrollView>(null);
    const isInternalScroll = useRef(false);
    const lastScrolledIndex = useRef(-1);
    // Filter & Sort State
    const [isFilterVisible, setIsFilterVisible] = useState(false);
    const [isSearchModalVisible, setIsSearchModalVisible] = useState(false);
    const [localDestination, setLocalDestination] = useState(params.destination as string || '');
    const [filters, setFilters] = useState({
        hotelName: '',
        starRating: [] as number[],
        minRating: 0,
        facilities: [] as number[],
        minPrice: 0,
        maxPrice: 10000,
    });
    const [sortBy, setSortBy] = useState<'price_low' | 'price_high' | 'rating' | 'name'>('price_low');
    const [favorites, setFavorites] = useState<string[]>([]);
    const [showMapHints, setShowMapHints] = useState(true);
    const [displayLimit, setDisplayLimit] = useState(10);

    const styles = getStyles(isDark);

    useEffect(() => {
        getFavorites().then(setFavorites);
        
        // Hide map hints after 4 seconds
        const timer = setTimeout(() => setShowMapHints(false), 4000);
        return () => clearTimeout(timer);
    }, []);

    const toggleFav = async (id: string) => {
        const added = await toggleFavorite(id);
        setFavorites(prev => added ? [...prev, id] : prev.filter(fid => fid !== id));
    };

    useEffect(() => {
        const fetchResults = async () => {
            if (isFetching.current) return;
            isFetching.current = true;
            
            setLoading(true);
            setError(null);
            try {

                const results = await searchHotels({
                    destination: params.destination as string,
                    countryCode: params.countryCode as string,
                    placeId: params.placeId as string,
                    checkIn: params.checkIn as string,
                    checkOut: params.checkOut as string,
                    adults: parseInt(params.adults as string || '2'),
                    children: parseInt(params.children as string || '0'),
                    childrenAges: params.childrenAges as string,
                    rooms: parseInt(params.rooms as string || '1'),
                    currency: currency.code,
                });
                
                const hotelData = results?.data || [];

                
                // Transform data into a standardized format and filter out low-quality results
                const standardizedData = hotelData
                    .map((h: any) => {
                        const lat = h.latitude || h.details?.latitude || h.details?.location?.latitude || h.lat || h.location?.lat || 0;
                        const lng = h.longitude || h.details?.longitude || h.details?.location?.longitude || h.lng || h.location?.lng || 0;
                        const name = h.name || h.hotelName || h.propertyName;
                        const price = getDisplayPrice(h);
                        
                        // Only return standardized object if we have a name and a valid location
                        if (!name || lat === 0 || lng === 0) return null;

                        return {
                            ...h,
                            name: name,
                            latitude: parseFloat(lat.toString()),
                            longitude: parseFloat(lng.toString()),
                            displayPrice: price,
                            thumbnailUrl: h.thumbnailUrl || h.details?.main_photo || (h.details?.hotel_images_photos?.[0]?.url) || h.image || h.mainPhotoUrl,
                            address: h.address || h.details?.address || h.location || h.city || 'Location unavailable'
                        };
                    })
                    .filter((h: any) => h !== null && h.displayPrice !== '???');

                setRawHotels(standardizedData);
            } catch (error: any) {

                setError(error.message || 'Failed to fetch hotels');
            } finally {
                setLoading(false);
                isFetching.current = false;
            }
        };

        if (params.destination) {
            fetchResults();
        }
    }, [params.destination, params.checkIn, params.checkOut, params.adults, params.rooms, currency.code]);

    const handleHotelSelect = (hotel: any) => {
        setSelectedHotel(hotel);
    };

    // Apply Filters & Sorting
    useEffect(() => {
        let result = [...rawHotels];

        // 1. Property Name
        if (filters.hotelName) {
            result = result.filter(h => h.name.toLowerCase().includes(filters.hotelName.toLowerCase()));
        }

        // 2. Star Rating
        if (filters.starRating.length > 0) {
            result = result.filter(h => filters.starRating.includes(h.starRating));
        }

        // 3. Guest Rating
        if (filters.minRating > 0) {
            result = result.filter(h => (h.reviewRating || h.starRating) >= filters.minRating);
        }

        // 4. Facilities (LiteAPI returns them in facilities array)
        if (filters.facilities.length > 0) {
            result = result.filter(h => 
                filters.facilities.every((fid: number) => 
                    (h.facilities || []).some((f: any) => f.id === fid || f === fid)
                )
            );
        }

        // 5. Price Range
        if (filters.minPrice > 0 || filters.maxPrice < 10000) {
            result = result.filter(h => {
                const price = Number(h.displayPrice);
                return price >= filters.minPrice && price <= filters.maxPrice;
            });
        }

        // 5. Sorting
        result.sort((a, b) => {
            const priceA = a.displayPrice === '???' ? 0 : Number(a.displayPrice);
            const priceB = b.displayPrice === '???' ? 0 : Number(b.displayPrice);
            
            if (sortBy === 'price_low') return (priceA || Infinity) - (priceB || Infinity);
            if (sortBy === 'price_high') return priceB - priceA;
            if (sortBy === 'rating') return (b.reviewRating || b.starRating || 0) - (a.reviewRating || a.starRating || 0);
            if (sortBy === 'name') return a.name.localeCompare(b.name);
            return 0;
        });

        setHotels(result);
        if (result.length > 0 && (!selectedHotel || !result.find(h => h.hotelId === selectedHotel.hotelId))) {
            setSelectedHotel(result[0]);
        }
        setDisplayLimit(10);
    }, [rawHotels, filters, sortBy]);

    useEffect(() => {
        if (selectedHotel && viewMode === 'map' && cardsScrollRef.current) {
            const index = hotels.findIndex(h => h.hotelId === selectedHotel.hotelId);
            if (index !== -1 && index !== lastScrolledIndex.current) {
                isInternalScroll.current = true;
                lastScrolledIndex.current = index;
                cardsScrollRef.current.scrollTo({
                    x: index * 312,
                    animated: true
                });
                setTimeout(() => { isInternalScroll.current = false; }, 300);
            }
        }
    }, [selectedHotel, viewMode]);

    const handleApplyFilters = (newFilters: any) => {
        setFilters(newFilters);
    };

    const navigateToHotel = (hotel: any) => {
        router.push({
            pathname: '/(tabs)/hotel/[id]',
            params: {
                id: hotel.hotelId,
                checkIn: params.checkIn,
                checkOut: params.checkOut,
                adults: params.adults,
                rooms: params.rooms,
                currency: currency.code
            }
        });
    };

    const activeFilterCount = (filters.starRating.length > 0 ? 1 : 0) + 
                             (filters.facilities.length > 0 ? 1 : 0) + 
                             (filters.minRating > 0 ? 1 : 0) + 
                             (filters.hotelName ? 1 : 0);

    const FilterChips = () => {
        const activeFilters: { id: string; label: string; onClear: () => void }[] = [];
        
        if (filters.hotelName) {
            activeFilters.push({ id: 'name', label: filters.hotelName, onClear: () => setFilters({ ...filters, hotelName: '' }) });
        }
        filters.starRating.forEach(star => {
            activeFilters.push({ 
                id: `star-${star}`, 
                label: `${star} Stars`, 
                onClear: () => setFilters({ ...filters, starRating: filters.starRating.filter(s => s !== star) }) 
            });
        });
        if (filters.minRating > 0) {
            activeFilters.push({ 
                id: 'rating', 
                label: `${filters.minRating}+ Rating`, 
                onClear: () => setFilters({ ...filters, minRating: 0 }) 
            });
        }
        filters.facilities.forEach(fid => {
            const facility = FACILITY_MAP.find(f => f.id === fid);
            if (facility) {
                activeFilters.push({ 
                    id: `fac-${fid}`, 
                    label: facility.label, 
                    onClear: () => setFilters({ ...filters, facilities: filters.facilities.filter(f => f !== fid) }) 
                });
            }
        });

        if (activeFilters.length === 0) return null;

        return (
            <ScrollView 
                horizontal 
                showsHorizontalScrollIndicator={false} 
                style={styles.filterChipsContainer}
                contentContainerStyle={styles.filterChipsContent}
            >
                {activeFilters.map(chip => (
                    <Pressable key={chip.id} style={styles.filterChip} onPress={chip.onClear}>
                        <Text style={styles.filterChipText}>{chip.label}</Text>
                        <X size={12} color="#2563eb" />
                    </Pressable>
                ))}
            </ScrollView>
        );
    };

    return (
        <View style={styles.container}>
            {/* ... Header ... */}
            {/* Header */}
            <View style={styles.header}>
                <Pressable onPress={() => router.back()} style={styles.backBtn}>
                    <ChevronLeft size={24} color={isDark ? '#ffffff' : '#0f172a'} />
                </Pressable>
                <View style={styles.searchInputContainer}>
                    <Search size={16} color={isDark ? '#94a3b8' : '#64748b'} />
                    <TextInput 
                        style={styles.searchPill} 
                        placeholder="Search location..."
                        placeholderTextColor={isDark ? '#94a3b8' : '#64748b'}
                        value={localDestination}
                        onChangeText={setLocalDestination}
                        onSubmitEditing={() => {
                            router.setParams({ destination: localDestination });
                        }}
                    />
                </View>
                <Pressable style={styles.filterBtn} onPress={() => setIsFilterVisible(true)}>
                    <Filter size={20} color={isDark ? '#ffffff' : '#0f172a'} />
                    {activeFilterCount > 0 && (
                        <View style={styles.filterBadge}>
                            <Text style={styles.filterBadgeText}>{activeFilterCount}</Text>
                        </View>
                    )}
                </Pressable>
            </View>

            {/* Content */}
            <View style={styles.content}>
                {loading ? (
                    <View style={styles.loadingContainer}>
                        <ActivityIndicator size="large" color="#2563eb" />
                        <Text style={styles.loadingText}>Finding the best deals...</Text>
                    </View>
                ) : error ? (
                    <View style={styles.errorContainer}>
                        <Text style={styles.errorTitle}>Oops!</Text>
                        <Text style={styles.errorText}>{error}</Text>
                        <Pressable style={styles.retryBtn} onPress={() => router.back()}>
                            <Text style={styles.retryBtnText}>Try different search</Text>
                        </Pressable>
                    </View>
                ) : (
                    <>
                        <FilterChips />

                        {/* Sub-header / Sort & View Toggle */}
                        <View style={styles.subHeader}>
                            <View style={styles.resultsCount}>
                                <Text style={styles.resultsCountText}>
                                    {hotels.length} hotels found
                                    {activeFilterCount > 0 && ` • ${activeFilterCount} active`}
                                </Text>
                            </View>
                            <View style={styles.actions}>
                                <Pressable 
                                    style={[styles.viewToggle, viewMode === 'list' && styles.viewToggleActive]} 
                                    onPress={() => setViewMode('list')}
                                >
                                    <List size={18} color={viewMode === 'list' ? 'white' : '#2563eb'} />
                                </Pressable>
                                <Pressable 
                                    style={[styles.viewToggle, viewMode === 'map' && styles.viewToggleActive]} 
                                    onPress={() => setViewMode('map')}
                                >
                                    <MapIcon size={18} color={viewMode === 'map' ? 'white' : '#2563eb'} />
                                </Pressable>
                            </View>
                        </View>

                        {viewMode === 'map' ? (
                            <View style={styles.mapContainer}>
                                <MapboxWebView 
                                    hotels={hotels}
                                    selectedHotelId={selectedHotel?.hotelId}
                                    onHotelSelect={handleHotelSelect}
                                    isDark={isDark}
                                    currencySymbol={currency.symbol}
                                />
                                
                                {showMapHints && (
                                    <View style={styles.mapHints}>
                                        <View style={styles.hintItem}>
                                            <MousePointer2 size={16} color="white" />
                                            <Text style={styles.hintText}>Pinch to zoom</Text>
                                        </View>
                                        <View style={styles.hintItem}>
                                            <Move size={16} color="white" />
                                            <Text style={styles.hintText}>Drag to pan</Text>
                                        </View>
                                    </View>
                                )}

                                {hotels.length > 0 && (
                                    <View style={styles.floatingCards}>
                                        <ScrollView 
                                            ref={cardsScrollRef}
                                            horizontal 
                                            showsHorizontalScrollIndicator={false} 
                                            contentContainerStyle={styles.cardsScroll}
                                            snapToInterval={312}
                                            decelerationRate="fast"
                                            onMomentumScrollEnd={(e) => {
                                                if (isInternalScroll.current) return;
                                                const x = e.nativeEvent.contentOffset.x;
                                                const index = Math.round(x / 312);
                                                if (index !== lastScrolledIndex.current && hotels[index]) {
                                                    lastScrolledIndex.current = index;
                                                    if (selectedHotel?.hotelId !== hotels[index].hotelId) {
                                                        setSelectedHotel(hotels[index]);
                                                    }
                                                }
                                            }}
                                            onScrollBeginDrag={() => { 
                                                isInternalScroll.current = false; 
                                            }}
                                        >
                                            {hotels.map((hotel, index) => (
                                                <Pressable 
                                                    key={hotel.hotelId} 
                                                    style={[styles.hotelCard, selectedHotel?.hotelId === hotel.hotelId && styles.hotelCardSelected]}
                                                    onPress={() => handleHotelSelect(hotel)}
                                                >
                                                    {/* Image section */}
                                                    <Pressable onPress={() => navigateToHotel(hotel)} style={{ position: 'relative' }}>
                                                        <ImageWithSkeleton 
                                                            uri={hotel.thumbnailUrl || 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=300&q=80'} 
                                                            style={styles.hotelCardImage} 
                                                        />
                                                        {/* Rank badge */}
                                                        <View style={styles.rankBadge}>
                                                            <Text style={styles.rankBadgeText}>{index + 1}</Text>
                                                        </View>
                                                        {/* Free cancellation badge */}
                                                        {hotel.refundable && (
                                                            <View style={styles.freeCancelBadge}>
                                                                <Text style={styles.freeCancelText}>Free cancel</Text>
                                                            </View>
                                                        )}
                                                    </Pressable>

                                                    {/* Favourite */}
                                                    <Pressable 
                                                        style={styles.heartBtn} 
                                                        onPress={(e) => {
                                                            e.stopPropagation();
                                                            toggleFav(hotel.hotelId);
                                                        }}
                                                    >
                                                        <Heart 
                                                            size={14} 
                                                            color={favorites.includes(hotel.hotelId) ? '#ef4444' : '#64748b'} 
                                                            fill={favorites.includes(hotel.hotelId) ? '#ef4444' : 'transparent'} 
                                                        />
                                                    </Pressable>

                                                    {/* Content */}
                                                    <Pressable style={styles.hotelCardContent} onPress={() => navigateToHotel(hotel)}>
                                                        {/* Name */}
                                                        <Text style={styles.hotelName} numberOfLines={2}>{hotel.name}</Text>

                                                        {/* Location */}
                                                        {(hotel.address || hotel.city) && (
                                                            <View style={styles.hotelLocationRow}>
                                                                <MapPin size={11} color={isDark ? '#64748b' : '#94a3b8'} />
                                                                <Text style={styles.hotelLocationText} numberOfLines={1}>
                                                                    {hotel.address || hotel.city}
                                                                </Text>
                                                            </View>
                                                        )}

                                                        {/* Rating row */}
                                                        <View style={styles.hotelRatingRow}>
                                                            {/* Review score badge */}
                                                            {(hotel.reviewRating > 0 || hotel.rating > 0) && (() => {
                                                                const score = hotel.reviewRating || hotel.rating;
                                                                const label = score >= 9 ? 'Excellent'
                                                                    : score >= 8 ? 'Very Good'
                                                                    : score >= 7 ? 'Good'
                                                                    : 'Fair';
                                                                return (
                                                                    <View style={[styles.reviewBadge, { backgroundColor: getRatingColor(score) }]}>
                                                                        <Text style={styles.reviewBadgeScore}>{score.toFixed(1)}</Text>
                                                                        <Text style={styles.reviewBadgeLabel}>{label}</Text>
                                                                    </View>
                                                                );
                                                            })()}
                                                            {/* Star classification */}
                                                            {hotel.starRating > 0 && (
                                                                <StarRating rating={hotel.starRating} size={11} gold />
                                                            )}
                                                            {/* Review count */}
                                                            {hotel.reviews > 0 && (
                                                                <Text style={styles.reviewCountText}>
                                                                    {hotel.reviews.toLocaleString()} reviews
                                                                </Text>
                                                            )}
                                                        </View>

                                                        {/* Price + CTA */}
                                                        <View style={styles.hotelPriceRow}>
                                                            <View>
                                                                <Text style={[styles.hotelPrice, { color: getPriceColor(hotel.displayPrice) }]}>
                                                                    {currency.symbol}{hotel.displayPrice}
                                                                </Text>
                                                                <Text style={styles.hotelPerNight}>/night</Text>
                                                            </View>
                                                            <View style={styles.cardViewBtn}>
                                                                <Text style={styles.cardViewBtnText}>View Deal</Text>
                                                            </View>
                                                        </View>
                                                    </Pressable>
                                                </Pressable>
                                            ))}
                                        </ScrollView>
                                        
                                        {/* Pagination Indicator */}
                                        <View style={styles.paginationDots}>
                                            {hotels.slice(0, Math.min(hotels.length, 10)).map((_, i) => (
                                                <View 
                                                    key={i} 
                                                    style={[
                                                        styles.dot, 
                                                        Math.round(hotels.findIndex(h => h.hotelId === selectedHotel?.hotelId)) === i && styles.activeDot
                                                    ]} 
                                                />
                                            ))}
                                        </View>
                                    </View>
                                )}
                            </View>
                        ) : (
                            <ScrollView 
                                style={styles.listView} 
                                contentContainerStyle={styles.listContent}
                                onScroll={(e) => {
                                    const { layoutMeasurement, contentOffset, contentSize } = e.nativeEvent;
                                    const isCloseToBottom = layoutMeasurement.height + contentOffset.y >= contentSize.height - 200;
                                    if (isCloseToBottom && displayLimit < hotels.length) {
                                        setDisplayLimit(prev => prev + 10);
                                    }
                                }}
                                scrollEventThrottle={16}
                            >
                                {hotels.length === 0 ? (
                                    <View style={styles.emptyContainer}>
                                        <Text style={styles.emptyText}>No hotels found for this search.</Text>
                                    </View>
                                ) : (
                                    hotels.slice(0, displayLimit).map((hotel) => (
                                            <Pressable key={hotel.hotelId} style={styles.listCard} onPress={() => navigateToHotel(hotel)}>
                                                {/* Star rating badge — top-left corner over image */}
                                                {(hotel.starRating > 0 || hotel.rating > 0) && (
                                                    <View style={styles.listRatingContainer}>
                                                        <StarRating
                                                            rating={hotel.starRating || 0}
                                                            size={11}
                                                            gold
                                                        />
                                                    </View>
                                                )}
                                                <ImageWithSkeleton 
                                                    uri={hotel.thumbnailUrl || 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=500&q=80'} 
                                                    style={styles.listImage} 
                                                />
                                                <Pressable 
                                                    style={styles.heartBtn} 
                                                    onPress={(e) => {
                                                        e.stopPropagation();
                                                        toggleFav(hotel.hotelId);
                                                    }}
                                                >
                                                    <Heart 
                                                        size={14} 
                                                        color={favorites.includes(hotel.hotelId) ? '#ef4444' : 'white'} 
                                                        fill={favorites.includes(hotel.hotelId) ? '#ef4444' : 'rgba(0,0,0,0.3)'} 
                                                    />
                                                </Pressable>
                                                <View style={styles.listDetails}>
                                                    <View style={styles.listHeaderRow}>
                                                        <Text style={styles.listHotelName} numberOfLines={1}>{hotel.name}</Text>
                                                    </View>
                                                    <View style={styles.listLocationRow}>
                                                        <MapPin size={12} color={isDark ? '#64748b' : '#94a3b8'} />
                                                        <Text style={styles.listLocationText} numberOfLines={1}>{hotel.address || hotel.city || 'Location unavailable'}</Text>
                                                    </View>
                                                    {/* Star rating row — only renders when rating is available */}
                                                    {hotel.starRating > 0 && (
                                                        <View style={styles.listStarRow}>
                                                            <StarRating
                                                                rating={hotel.starRating}
                                                                size={13}
                                                                gold
                                                            />
                                                            <Text style={styles.listStarLabel}>
                                                                {hotel.starRating}-star property
                                                            </Text>
                                                        </View>
                                                    )}
                                                    <View style={styles.listFooterRow}>
                                                        <View style={styles.listPriceCol}>
                                                            <Text style={[styles.listPriceText, { color: getPriceColor(hotel.displayPrice) }]}>
                                                                {currency.symbol}{hotel.displayPrice}
                                                            </Text>
                                                            <Text style={styles.listPerNightText}>total per night</Text>
                                                        </View>
                                                        <View style={[styles.viewBtn, { backgroundColor: '#2563eb' }]}>
                                                            <Text style={[styles.viewBtnText, { color: 'white' }]}>View</Text>
                                                        </View>
                                                    </View>
                                                </View>
                                            </Pressable>
                                    ))
                                )}
                            </ScrollView>
                        )}


                    </>
                )}
            </View>

            <FilterModal 
                visible={isFilterVisible} 
                onClose={() => setIsFilterVisible(false)} 
                filters={filters}
                onApply={handleApplyFilters}
            />

            <HotelSearchModal 
                visible={isSearchModalVisible}
                onClose={() => setIsSearchModalVisible(false)}
                initialParams={params}
            />

        </View>
    );
}

const getStyles = (isDark: boolean) => StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: isDark ? '#020617' : '#f8fafc',
    },
    header: {
        flexDirection: 'row',
        alignItems: 'center',
        paddingHorizontal: 16,
        paddingTop: 44, // Increased for status bar + breathing room
        paddingBottom: 16, // Increased for better spacing
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        borderBottomWidth: 1,
        borderBottomColor: isDark ? '#1e293b' : '#e2e8f0',
        zIndex: 10,
    },
    backBtn: {
        padding: 4,
    },
    searchInputContainer: {
        flex: 1,
        flexDirection: 'row',
        alignItems: 'center',
        height: 36,
        marginLeft: 10,
        marginRight: 10,
        borderBottomWidth: 1.5,
        borderBottomColor: isDark ? '#334155' : '#e2e8f0',
        paddingHorizontal: 4,
    },
    searchPill: {
        flex: 1,
        height: '100%',
        color: isDark ? '#ffffff' : '#0f172a',
        fontSize: 13,
        fontWeight: '500',
        marginLeft: 8,
    },
    searchInfo: {
        flex: 1,
    },
    destinationText: {
        fontSize: 15,
        fontWeight: '800',
        color: isDark ? '#ffffff' : '#0f172a',
        letterSpacing: -0.3,
    },
    dateText: {
        fontSize: 12,
        fontWeight: '500',
        color: isDark ? '#94a3b8' : '#64748b',
    },
    filterBtn: {
        width: 36,
        height: 36,
        borderRadius: 10,
        backgroundColor: isDark ? '#1e293b' : '#f1f5f9',
        alignItems: 'center',
        justifyContent: 'center',
        position: 'relative',
    },
    filterBadge: {
        position: 'absolute',
        top: -4,
        right: -4,
        backgroundColor: '#2563eb',
        width: 18,
        height: 18,
        borderRadius: 9,
        alignItems: 'center',
        justifyContent: 'center',
        borderWidth: 2,
        borderColor: isDark ? '#020617' : '#ffffff',
    },
    filterBadgeText: {
        color: 'white',
        fontSize: 10,
        fontWeight: 'bold',
    },
    subHeader: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        paddingHorizontal: 20,
        paddingVertical: 12,
        backgroundColor: isDark ? '#020617' : '#f8fafc',
    },
    resultsCount: {
        flex: 1,
    },
    resultsCountText: {
        fontSize: 13,
        fontWeight: '600',
        color: isDark ? '#94a3b8' : '#64748b',
    },
    actions: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 8,
    },
    viewToggle: {
        width: 38,
        height: 38,
        borderRadius: 19,
        backgroundColor: isDark ? '#1e293b' : '#ffffff',
        alignItems: 'center',
        justifyContent: 'center',
        borderWidth: 1.5,
        borderColor: isDark ? '#334155' : '#e2e8f0',
    },
    viewToggleActive: {
        backgroundColor: '#2563eb',
        borderColor: '#2563eb',
    },
    content: {
        flex: 1,
    },
    loadingContainer: {
        flex: 1,
        alignItems: 'center',
        justifyContent: 'center',
        gap: 16,
    },
    loadingText: {
        fontSize: 16,
        color: isDark ? '#64748b' : '#94a3b8',
        fontWeight: '500',
    },
    errorContainer: {
        flex: 1,
        alignItems: 'center',
        justifyContent: 'center',
        padding: 40,
    },
    errorTitle: {
        fontSize: 24,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
        marginBottom: 8,
    },
    errorText: {
        fontSize: 16,
        color: isDark ? '#64748b' : '#94a3b8',
        textAlign: 'center',
        marginBottom: 24,
    },
    retryBtn: {
        paddingHorizontal: 24,
        paddingVertical: 12,
        backgroundColor: '#2563eb',
        borderRadius: 12,
    },
    retryBtnText: {
        color: 'white',
        fontWeight: '600',
    },
    mapContainer: {
        flex: 1,
    },
    map: {
        flex: 1,
    },
    markerContainer: {
        alignItems: 'center',
        justifyContent: 'center',
    },
    markerPriceContainer: {
        backgroundColor: 'white',
        paddingHorizontal: 8,
        paddingVertical: 4,
        borderRadius: 12,
        borderWidth: 1,
        borderColor: '#e2e8f0',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 4,
        elevation: 3,
    },
    markerPriceText: {
        fontSize: 12,
        fontWeight: '700',
        color: '#0f172a',
    },
    markerPriceTextSelected: {
        color: 'white',
    },
    markerSelected: {
        zIndex: 10,
    },
    markerPriceContainerSelected: {
        backgroundColor: '#2563eb',
        borderColor: '#1d4ed8',
    },
    markerArrow: {
        width: 0,
        height: 0,
        borderLeftWidth: 6,
        borderRightWidth: 6,
        borderTopWidth: 6,
        borderLeftColor: 'transparent',
        borderRightColor: 'transparent',
        borderTopColor: 'white',
        marginTop: -1,
    },
    markerArrowSelected: {
        borderTopColor: '#2563eb',
    },
    floatingCards: {
        position: 'absolute',
        bottom: 30,
        left: 0,
        right: 0,
        zIndex: 20,
    },
    cardsScroll: {
        paddingHorizontal: 20,
        paddingBottom: 10,
        gap: 12,
    },
    hotelCard: {
        width: 320,
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        borderRadius: 20,
        overflow: 'hidden',
        borderWidth: 1.5,
        borderColor: isDark ? '#1e293b' : '#f1f5f9',
        flexDirection: 'row',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 12 },
        shadowOpacity: 0.25,
        shadowRadius: 20,
        elevation: 15,
    },
    hotelCardSelected: {
        borderColor: '#2563eb',
        borderWidth: 2,
    },
    hotelCardImage: {
        width: 110,
        height: 130,
        backgroundColor: isDark ? '#1e293b' : '#f1f5f9',
    },
    rankBadge: {
        position: 'absolute',
        top: 8,
        left: 8,
        zIndex: 10,
        width: 22,
        height: 22,
        borderRadius: 11,
        backgroundColor: '#2563eb',
        alignItems: 'center',
        justifyContent: 'center',
    },
    rankBadgeText: {
        color: '#ffffff',
        fontSize: 11,
        fontWeight: '800',
    },
    freeCancelBadge: {
        position: 'absolute',
        bottom: 6,
        left: 6,
        zIndex: 10,
        backgroundColor: '#22c55e',
        paddingHorizontal: 6,
        paddingVertical: 2,
        borderRadius: 6,
    },
    freeCancelText: {
        color: '#ffffff',
        fontSize: 9,
        fontWeight: '700',
    },
    hotelCardContent: {
        flex: 1,
        padding: 10,
        justifyContent: 'space-between',
    },
    hotelName: {
        fontSize: 13,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
        marginBottom: 2,
        paddingRight: 28,
        lineHeight: 18,
    },
    hotelLocationRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 3,
        marginBottom: 4,
    },
    hotelLocationText: {
        fontSize: 11,
        color: isDark ? '#64748b' : '#94a3b8',
        flex: 1,
    },
    hotelRatingRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 5,
        flexWrap: 'wrap',
        marginBottom: 6,
    },
    reviewBadge: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 3,
        paddingHorizontal: 6,
        paddingVertical: 2,
        borderRadius: 6,
    },
    reviewBadgeScore: {
        fontSize: 11,
        fontWeight: '800',
        color: '#ffffff',
    },
    reviewBadgeLabel: {
        fontSize: 10,
        fontWeight: '600',
        color: 'rgba(255,255,255,0.9)',
    },
    reviewCountText: {
        fontSize: 10,
        color: isDark ? '#475569' : '#94a3b8',
        fontWeight: '500',
    },
    hotelPriceRow: {
        flexDirection: 'row',
        alignItems: 'flex-end',
        justifyContent: 'space-between',
    },
    hotelPrice: {
        fontSize: 15,
        fontWeight: '800',
        color: '#2563eb',
        lineHeight: 18,
    },
    hotelPerNight: {
        fontSize: 10,
        color: isDark ? '#64748b' : '#94a3b8',
    },
    cardViewBtn: {
        backgroundColor: '#2563eb',
        paddingHorizontal: 10,
        paddingVertical: 6,
        borderRadius: 8,
    },
    cardViewBtnText: {
        color: 'white',
        fontSize: 11,
        fontWeight: '700',
    },
    listRatingContainer: {
        position: 'absolute',
        top: 10,
        left: 10,
        zIndex: 10,
        backgroundColor: 'rgba(0,0,0,0.55)',
        paddingHorizontal: 7,
        paddingVertical: 4,
        borderRadius: 8,
    },
    listStarRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 6,
        marginBottom: 10,
    },
    listStarLabel: {
        fontSize: 12,
        color: isDark ? '#94a3b8' : '#64748b',
        fontWeight: '500',
    },
    paginationDots: {
        flexDirection: 'row',
        justifyContent: 'center',
        alignItems: 'center',
        gap: 6,
        marginTop: 12,
    },
    dot: {
        width: 6,
        height: 6,
        borderRadius: 3,
        backgroundColor: isDark ? '#334155' : '#cbd5e1',
    },
    activeDot: {
        width: 20,
        backgroundColor: '#2563eb',
    },
    listView: {
        flex: 1,
    },
    listContent: {
        padding: 16,
    },
    listCard: {
        marginBottom: 20,
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        borderRadius: 24,
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
        overflow: 'hidden',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 8 },
        shadowOpacity: 0.12,
        shadowRadius: 16,
        elevation: 8,
    },
    listImage: {
        height: 200,
        width: '100%',
        backgroundColor: isDark ? '#1e293b' : '#f1f5f9',
    },
    listDetails: {
        padding: 16,
    },
    listHeaderRow: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: 4,
    },
    listHotelName: {
        flex: 1,
        fontSize: 18,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
        marginRight: 12,
    },
    listRatingBadge: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 4,
        backgroundColor: '#2563eb',
        paddingHorizontal: 8,
        paddingVertical: 4,
        borderRadius: 8,
    },
    listRatingText: {
        fontSize: 12,
        fontWeight: '700',
        color: 'white',
    },
    listStarRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 6,
        marginBottom: 8,
    },
    listStarLabel: {
        fontSize: 12,
        color: isDark ? '#94a3b8' : '#64748b',
    },
    listLocationRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 4,
        marginBottom: 16,
    },
    listLocationText: {
        fontSize: 13,
        color: isDark ? '#64748b' : '#94a3b8',
    },
    listFooterRow: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'flex-end',
        borderTopWidth: 1,
        borderTopColor: isDark ? '#1e293b' : '#f1f5f9',
        paddingTop: 12,
    },
    listPriceCol: {
        gap: 0,
    },
    listPriceText: {
        fontSize: 20,
        fontWeight: '700',
        color: '#2563eb',
    },
    listPerNightText: {
        fontSize: 11,
        color: isDark ? '#64748b' : '#94a3b8',
    },
    viewBtn: {
        backgroundColor: isDark ? '#1e293b' : '#f8fafc',
        paddingHorizontal: 20,
        paddingVertical: 10,
        borderRadius: 12,
        borderWidth: 1,
        borderColor: isDark ? '#334155' : '#e2e8f0',
    },
    viewBtnText: {
        fontSize: 14,
        fontWeight: '600',
        color: isDark ? '#ffffff' : '#0f172a',
    },
    emptyContainer: {
        padding: 40,
        alignItems: 'center',
    },
    emptyText: {
        fontSize: 16,
        color: isDark ? '#64748b' : '#94a3b8',
        textAlign: 'center',
    },
    toggleBtn: {
        position: 'absolute',
        bottom: 32,
        alignSelf: 'center',
        flexDirection: 'row',
        alignItems: 'center',
        gap: 8,
        backgroundColor: '#0f172a',
        paddingHorizontal: 20,
        paddingVertical: 12,
        borderRadius: 24,
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.3,
        shadowRadius: 8,
        elevation: 6,
    },
    toggleBtnText: {
        color: 'white',
        fontWeight: '700',
        fontSize: 14,
    },
    cardViewBtn: {
        backgroundColor: '#2563eb',
        paddingHorizontal: 12,
        paddingVertical: 6,
        borderRadius: 8,
    },
    cardViewBtnText: {
        color: 'white',
        fontSize: 12,
        fontWeight: '700',
    },
    filterChipsContainer: {
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        paddingVertical: 10,
        borderBottomWidth: 1,
        borderBottomColor: isDark ? '#1e293b' : '#e2e8f0',
        flexGrow: 0,
    },
    filterChipsContent: {
        paddingHorizontal: 20,
        gap: 8,
    },
    filterChip: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 6,
        paddingHorizontal: 12,
        paddingVertical: 6,
        backgroundColor: isDark ? '#1e293b' : '#f1f5f9',
        borderRadius: 20,
        borderWidth: 1.5,
        borderColor: '#2563eb',
        alignSelf: 'center',
    },
    filterChipText: {
        fontSize: 12,
        fontWeight: '700',
        color: '#2563eb',
    },
    mapHints: {
        position: 'absolute',
        top: 20,
        left: 0,
        right: 0,
        flexDirection: 'row',
        justifyContent: 'center',
        gap: 20,
        zIndex: 30,
    },
    hintItem: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 8,
        backgroundColor: 'rgba(0,0,0,0.7)',
        paddingHorizontal: 12,
        paddingVertical: 8,
        borderRadius: 20,
    },
    hintText: {
        color: 'white',
        fontSize: 12,
        fontWeight: '600',
    },
    heartBtn: {
        position: 'absolute',
        top: 10,
        right: 10,
        zIndex: 20,
        width: 28,
        height: 28,
        borderRadius: 14,
        backgroundColor: isDark ? '#1e293b' : 'white',
        alignItems: 'center',
        justifyContent: 'center',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 4,
        elevation: 3,
        borderWidth: 1,
        borderColor: isDark ? '#334155' : '#f1f5f9',
    },
    floatingFilterBtn: {
        position: 'absolute',
        bottom: 30,
        alignSelf: 'center',
        flexDirection: 'row',
        alignItems: 'center',
        gap: 10,
        backgroundColor: '#0f172a',
        paddingHorizontal: 24,
        paddingVertical: 14,
        borderRadius: 30,
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 10 },
        shadowOpacity: 0.4,
        shadowRadius: 20,
        elevation: 20,
        zIndex: 100,
        borderWidth: 1,
        borderColor: 'rgba(255,255,255,0.1)',
    },
    floatingFilterText: {
        color: 'white',
        fontSize: 15,
        fontWeight: '800',
        letterSpacing: 0.5,
    },
    floatingBadge: {
        backgroundColor: '#2563eb',
        width: 22,
        height: 22,
        borderRadius: 11,
        alignItems: 'center',
        justifyContent: 'center',
        marginLeft: 2,
    },
    floatingBadgeText: {
        color: 'white',
        fontSize: 11,
        fontWeight: '900',
    },
});
