import { useLocalSearchParams, useRouter } from 'expo-router';
import { ArrowDownUp, Car, ChevronLeft, Heart, List, Map as MapIcon, MapPin, MousePointer2, Move, Search, SlidersHorizontal, Star, UtensilsCrossed, Wifi, Wind, X } from 'lucide-react-native';
import React, { memo, useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { ActivityIndicator, Dimensions, FlatList, Pressable, ScrollView, StyleSheet, Text, TextInput, useColorScheme, View } from 'react-native';
import FilterModal from '../../components/search/FilterModal';
import HotelSearchModal from '../../components/search/HotelSearchModal';
import MapboxWebView from '../../components/search/MapboxWebView';
import StarRating from '../../components/ui/StarRating';
import { useSettings } from '../../context/SettingsContext';
import { searchHotels } from '../../lib/travel-api';
import { MAPBOX_TOKEN } from '../../lib/config';
import { convertCurrency } from '../../lib/currency';
import { getFavorites, toggleFavorite } from '../../lib/favorites';

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

// Extract the actual currency the API returned the price in.
// Mirrors the same data paths as getDisplayPrice so they always agree.
const getPriceCurrency = (hotel: any): string => {
    // Direct currency field on the hotel object
    if (typeof hotel.currency === 'string' && hotel.currency.length >= 3)
        return hotel.currency.toUpperCase();

    // Price object with currency
    if (hotel.price?.currency && typeof hotel.price.currency === 'string')
        return hotel.price.currency.toUpperCase();

    // LiteAPI standard: roomTypes[0].rates[0].retailRate.total[0].currency
    if (hotel.roomTypes?.length > 0) {
        const total = hotel.roomTypes[0]?.rates?.[0]?.retailRate?.total;
        if (Array.isArray(total) && total[0]?.currency)
            return String(total[0].currency).toUpperCase();
        if (total && typeof total === 'object' && 'currency' in total)
            return String((total as any).currency).toUpperCase();
    }

    // Backend defaults to KRW when no currency param is honoured
    return 'KRW';
};

const getPriceColor = (_price: any) => '#2563eb';


import OptimizedImage from '../../components/ui/OptimizedImage';

const ImageWithSkeleton = ({ uri, style }: { uri: string, style: any }) => {
    return <OptimizedImage uri={uri} style={style} type="hotel" />;
};

const CARD_WIDTH = 270;
const CARD_GAP = 12;

type HotelCardProps = {
    hotel: any;
    index: number;
    isSelected: boolean;
    isDark: boolean;
    currencySymbol: string;
    isFavorite: boolean;
    onSelect: (hotel: any) => void;
    onNavigate: (hotel: any) => void;
    onToggleFav: (id: string, hotel?: any) => void;
    styles: any;
};

const HotelMapCard = memo(({ hotel, index, isSelected, currencySymbol, isFavorite, onSelect, onNavigate, onToggleFav, styles }: HotelCardProps) => {
    const score = hotel.reviewRating || hotel.rating;
    const ratingLabel = score >= 9 ? 'Excellent' : score >= 8 ? 'Very Good' : score >= 7 ? 'Good' : 'Fair';
    const fallback = 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=300&q=80';
    return (
        <Pressable
            style={[styles.hotelCard, isSelected && styles.hotelCardSelected]}
            onPress={() => onSelect(hotel)}
        >
            <View style={{ position: 'relative' }}>
                <ImageWithSkeleton
                    uri={hotel.thumbnailUrl || fallback}
                    style={styles.hotelCardImage}
                />
                <View style={styles.rankBadge}>
                    <Text style={styles.rankBadgeText}>{index + 1}</Text>
                </View>
                {hotel.refundable && (
                    <View style={styles.freeCancelBadge}>
                        <Text style={styles.freeCancelText}>Free cancel</Text>
                    </View>
                )}
            </View>

            <Pressable
                style={styles.heartBtn}
                onPress={() => onToggleFav(hotel.hotelId, hotel)}
            >
                <Heart
                    size={14}
                    color={isFavorite ? '#ef4444' : '#64748b'}
                    fill={isFavorite ? '#ef4444' : 'transparent'}
                />
            </Pressable>

            <View style={styles.hotelCardContent}>
                <Text style={styles.hotelName} numberOfLines={2}>{hotel.name}</Text>

                <View style={styles.hotelRatingRow}>
                    {score > 0 && (
                        <View style={styles.reviewBadge}>
                            <Text style={styles.reviewBadgeScore}>{score.toFixed(1)}</Text>
                            <Text style={styles.reviewBadgeLabel}>{ratingLabel}</Text>
                        </View>
                    )}
                    {hotel.starRating > 0 && (
                        <StarRating rating={hotel.starRating} size={10} color="#2563eb" />
                    )}
                </View>

                <View style={styles.hotelPriceRow}>
                    <View>
                        <Text style={[styles.hotelPrice, { color: getPriceColor(hotel.displayConvertedPrice) }]}>
                            {currencySymbol}{hotel.displayConvertedPrice ?? hotel.displayPrice}
                        </Text>
                        <Text style={styles.hotelPerNight}>per night</Text>
                    </View>
                    <Pressable style={styles.cardViewBtn} onPress={() => onNavigate(hotel)}>
                        <Text style={styles.cardViewBtnText}>View Deal</Text>
                    </Pressable>
                </View>
            </View>
        </Pressable>
    );
});

const getAmenities = (hotel: any): { icon: any; label: string }[] => {
    const facilities: any[] = hotel.facilities || [];
    const str = facilities.map((f: any) => (f.name || f.label || '').toLowerCase()).join('|');
    const result: { icon: any; label: string }[] = [];
    if (str.includes('wifi') || str.includes('wi-fi') || str.includes('internet') || str.includes('wireless'))
        result.push({ icon: Wifi, label: 'Wi-Fi' });
    if (str.includes('air cond') || str.includes('aircond') || str.includes(' ac ') || str.includes('climate'))
        result.push({ icon: Wind, label: 'AC' });
    if (str.includes('breakfast') || str.includes('bfast'))
        result.push({ icon: UtensilsCrossed, label: 'Bfast' });
    if (str.includes('park'))
        result.push({ icon: Car, label: 'Park' });
    return result.slice(0, 2);
};

type HotelListCardProps = {
    hotel: any;
    isDark: boolean;
    currencySymbol: string;
    isFavorite: boolean;
    onNavigate: (hotel: any) => void;
    onToggleFav: (id: string, hotel?: any) => void;
    styles: any;
};

const HotelListCard = memo(({ hotel, isDark, currencySymbol, isFavorite, onNavigate, onToggleFav, styles }: HotelListCardProps) => {
    const score = hotel.reviewRating || hotel.rating || 0;
    const ratingLabel = score >= 9 ? 'Excellent' : score >= 8 ? 'Very Good' : score >= 7 ? 'Good' : score >= 6 ? 'Okay' : 'Fair';
    const amenities = getAmenities(hotel);
    const mutedColor = isDark ? '#64748b' : '#94a3b8';

    return (
        <Pressable style={styles.listCard} onPress={() => onNavigate(hotel)}>
            {/* Heart */}
            <Pressable style={styles.heartBtn} onPress={() => onToggleFav(hotel.hotelId, hotel)}>
                <Heart
                    size={14}
                    color={isFavorite ? '#ef4444' : isDark ? '#64748b' : '#94a3b8'}
                    fill={isFavorite ? '#ef4444' : 'transparent'}
                />
            </Pressable>

            {/* Image column */}
            <View style={styles.listImageCol}>
                <ImageWithSkeleton
                    uri={hotel.thumbnailUrl || 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=300&q=80'}
                    style={styles.listImage}
                />
                {hotel.refundable && (
                    <View style={styles.discountBadge}>
                        <Text style={styles.discountText}>Free cancel</Text>
                    </View>
                )}
            </View>

            {/* Details column */}
            <View style={styles.listDetails}>
                <Text style={styles.listHotelName} numberOfLines={2}>{hotel.name}</Text>
                <View style={styles.listLocationRow}>
                    <MapPin size={11} color={mutedColor} />
                    <Text style={styles.listLocationText} numberOfLines={1}>
                        {hotel.address || hotel.city || 'Location unavailable'}
                    </Text>
                </View>

                {/* Rating badge + amenities */}
                <View style={styles.listRatingRow}>
                    {score > 0 && (
                        <View style={styles.reviewBadge}>
                            <Star size={9} color="#fff" fill="#fff" />
                            <Text style={styles.reviewBadgeScore}>{score.toFixed(1)}</Text>
                            <Text style={styles.reviewBadgeLabel}>{ratingLabel}</Text>
                        </View>
                    )}
                    {amenities.map(({ icon: Icon, label }) => (
                        <React.Fragment key={label}>
                            <Text style={styles.amenitySep}>·</Text>
                            <Icon size={10} color={mutedColor} />
                            <Text style={styles.amenityText}>{label}</Text>
                        </React.Fragment>
                    ))}
                </View>

                <View style={styles.listFooterRow}>
                    <View>
                        <Text style={styles.listPriceText}>{currencySymbol}{hotel.displayConvertedPrice ?? hotel.displayPrice}</Text>
                        <Text style={styles.listPerNightText}>per night</Text>
                    </View>
                    <View style={styles.viewBtn}>
                        <Text style={styles.viewBtnText}>View</Text>
                    </View>
                </View>
            </View>
        </Pressable>
    );
});

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
    const cardsFlatListRef = useRef<FlatList>(null);
    const isInternalScroll = useRef(false);
    const lastScrolledIndex = useRef(-1);
    const CARD_SNAP = CARD_WIDTH + CARD_GAP;
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
    const [flyToHotelId, setFlyToHotelId] = useState<string | null>(null);
    const [mapCenter, setMapCenter] = useState<[number, number] | undefined>(undefined);

    const styles = useMemo(() => getStyles(isDark), [isDark]);

    useEffect(() => {
        getFavorites().then(setFavorites);
        
        // Hide map hints after 4 seconds
        const timer = setTimeout(() => setShowMapHints(false), 4000);
        return () => clearTimeout(timer);
    }, []);

    useEffect(() => {
        const destination = params.destination as string | undefined;
        if (destination && destination !== localDestination) {
            setLocalDestination(destination);
        }
    }, [params.destination]);

    useEffect(() => {
        const viewModeParam = params.viewMode as string | undefined;
        if (viewModeParam === 'map') {
            setViewMode('map');
        } else if (viewModeParam === 'list') {
            setViewMode('list');
        }
    }, [params.viewMode]);

    useEffect(() => {
        const fetchResults = async () => {
            if (isFetching.current) return;
            isFetching.current = true;
            
            setLoading(true);
            setError(null);
            try {

                const results = await searchHotels({
                    destination:     params.destination as string,
                    countryCode:     params.countryCode as string,
                    placeId:         params.placeId as string,
                    destinationCode: params.destinationCode as string,
                    checkIn:         params.checkIn as string,
                    checkOut:        params.checkOut as string,
                    adults:          parseInt(params.adults as string || '2'),
                    children:        parseInt(params.children as string || '0'),
                    childrenAges:    params.childrenAges as string,
                    rooms:           parseInt(params.rooms as string || '1'),
                    currency:        'USD',
                });
                
                const hotelData = results?.data || [];

                
                // Transform data into a standardized format and filter out low-quality results
                const standardizedData = hotelData
                    .map((h: any) => {
                        const lat = h.latitude || h.details?.latitude || h.details?.location?.latitude || h.lat || h.location?.lat || 0;
                        const lng = h.longitude || h.details?.longitude || h.details?.location?.longitude || h.lng || h.location?.lng || 0;
                        const name = h.name || h.hotelName || h.propertyName;
                        const price = getDisplayPrice(h);
                        const priceCurrency = getPriceCurrency(h);
                        
                        // Only return standardized object if we have a name and a valid location
                        if (!name || lat === 0 || lng === 0) return null;

                        const thumbUrl = h.thumbnailUrl || h.details?.main_photo || (h.details?.hotel_images_photos?.[0]?.url) || h.image || (Array.isArray(h.images) ? h.images[0] : undefined) || h.mainPhotoUrl;
                        const imgFallback = 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=300&q=80';
                        const imageUrls: string[] = [];
                        const addUrl = (u: any) => { if (u && typeof u === 'string' && !imageUrls.includes(u)) imageUrls.push(u); };
                        const isExterior = (p: any) => {
                            const type = String(p?.type || p?.tag || p?.category || p?.imageTypeId || p?.photo_type || '').toLowerCase();
                            return type === '1' || type.includes('exterior') || type.includes('building') || type.includes('facade') || type.includes('front');
                        };
                        if (h.details?.hotel_images_photos) {
                            const allPhotos = h.details.hotel_images_photos;
                            const roomPhotos = allPhotos.filter((p: any) => !isExterior(p));
                            // If type info exists and filters down to room photos, use those; otherwise skip the first photo (typically building exterior)
                            const photosToUse = roomPhotos.length >= 2 ? roomPhotos : allPhotos.slice(1);
                            photosToUse.forEach((p: any) => addUrl(p?.url));
                        }
                        if (Array.isArray(h.images)) {
                            // Skip first image — it's usually the same exterior photo as the thumbnail
                            h.images.slice(1).forEach((img: any) => addUrl(typeof img === 'string' ? img : img?.url));
                        }
                        // Fallback chain if no interior photos were found
                        if (imageUrls.length === 0 && h.details?.hotel_images_photos?.[0]?.url) addUrl(h.details.hotel_images_photos[0].url);
                        if (imageUrls.length === 0) addUrl(thumbUrl);
                        if (imageUrls.length === 0) imageUrls.push(imgFallback);
                        while (imageUrls.length < 4) imageUrls.push(imageUrls[0]);

                        return {
                            ...h,
                            name: name,
                            latitude: parseFloat(lat.toString()),
                            longitude: parseFloat(lng.toString()),
                            displayPrice: price,
                            priceCurrency: priceCurrency,
                            thumbnailUrl: thumbUrl,
                            imageUrls: imageUrls.slice(0, 4),
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
    }, [params.destination, params.placeId, params.countryCode, params.checkIn, params.checkOut, params.adults, params.children, params.childrenAges, params.rooms]);

    const toggleFav = useCallback(async (id: string, hotelData?: any) => {
        const added = await toggleFavorite(id, hotelData);
        setFavorites(prev => added ? [...prev, id] : prev.filter(fid => fid !== id));
    }, []);

    const navigateToHotel = useCallback((hotel: any) => {
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
    }, [params.checkIn, params.checkOut, params.adults, params.rooms, currency.code]);

    const handleHotelSelect = useCallback((hotel: any) => {
        setSelectedHotel(hotel);
        setFlyToHotelId(hotel.hotelId);
    }, []);

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

        // 5. Sorting — uses USD prices from API for consistent comparison
        result.sort((a, b) => {
            const priceA = a.displayPrice === '???' ? 0 : Number(a.displayPrice);
            const priceB = b.displayPrice === '???' ? 0 : Number(b.displayPrice);

            if (sortBy === 'price_low') return (priceA || Infinity) - (priceB || Infinity);
            if (sortBy === 'price_high') return priceB - priceA;
            if (sortBy === 'rating') return (b.reviewRating || b.starRating || 0) - (a.reviewRating || a.starRating || 0);
            if (sortBy === 'name') return a.name.localeCompare(b.name);
            return 0;
        });

        // 6. Add displayConvertedPrice for rendering — converts from the actual API price currency
        const withDisplay = result.map(h => {
            if (h.displayPrice === '???') return { ...h, displayConvertedPrice: '???' };
            const from = h.priceCurrency || 'KRW';
            const convertedAmount = Math.round(convertCurrency(Number(h.displayPrice), from, currency.code));
            return { ...h, displayConvertedPrice: convertedAmount.toLocaleString() };
        });

        setHotels(withDisplay);
        if (withDisplay.length > 0 && (!selectedHotel || !withDisplay.find(h => h.hotelId === selectedHotel.hotelId))) {
            setSelectedHotel(withDisplay[0]);
        }
        setDisplayLimit(10);
    }, [rawHotels, filters, sortBy, currency]);

    useEffect(() => {
        if (selectedHotel && viewMode === 'map' && cardsFlatListRef.current) {
            const index = hotels.findIndex(h => h.hotelId === selectedHotel.hotelId);
            if (index !== -1 && index !== lastScrolledIndex.current) {
                isInternalScroll.current = true;
                lastScrolledIndex.current = index;
                cardsFlatListRef.current.scrollToIndex({ index, animated: true, viewPosition: 0.5 });
                setTimeout(() => { isInternalScroll.current = false; }, 300);
            }
        }
    }, [selectedHotel, viewMode]);

    const handleApplyFilters = useCallback((newFilters: any) => {
        setFilters(newFilters);
    }, []);

    const activeFilterCount = (filters.starRating.length > 0 ? 1 : 0) + 
                             (filters.facilities.length > 0 ? 1 : 0) + 
                             (filters.minRating > 0 ? 1 : 0) + 
                             (filters.hotelName ? 1 : 0);

    const SortChips = () => {
        const sortOptions = [
            { id: 'price_low', label: 'Price: Low', icon: <ArrowDownUp size={12} color={sortBy === 'price_low' ? '#fff' : (isDark ? '#8896AA' : '#64748b')} /> },
            { id: 'rating', label: 'Rating', icon: <Star size={12} color={sortBy === 'rating' ? '#fff' : (isDark ? '#8896AA' : '#64748b')} fill={sortBy === 'rating' ? '#fff' : 'transparent'} /> },
        ];
        const filterOptions = [
            { id: 'type', label: 'Type', onPress: () => setIsFilterVisible(true) },
            { id: 'duration', label: 'Duration', onPress: () => setIsSearchModalVisible(true) },
            { id: 'amenities', label: 'Amenities', onPress: () => setIsFilterVisible(true) },
        ];
        return (
            <ScrollView
                horizontal
                showsHorizontalScrollIndicator={false}
                style={styles.sortChipsContainer}
                contentContainerStyle={styles.sortChipsContent}
                nestedScrollEnabled
                overScrollMode="never"
            >
                {sortOptions.map(opt => {
                    const isActive = sortBy === opt.id;
                    return (
                        <Pressable
                            key={opt.id}
                            style={[styles.sortChip, isActive && styles.sortChipActive]}
                            onPress={() => setSortBy(opt.id as any)}
                        >
                            {opt.icon ? <View style={styles.sortChipIcon}>{opt.icon}</View> : null}
                            <Text style={[styles.sortChipText, isActive && styles.sortChipTextActive]}>{opt.label}</Text>
                        </Pressable>
                    );
                })}
                {filterOptions.map(opt => (
                    <Pressable key={opt.id} style={styles.sortChip} onPress={opt.onPress}>
                        <Text style={styles.sortChipText}>{opt.label}</Text>
                    </Pressable>
                ))}
                {activeFilterCount > 0 && (
                    <Pressable style={[styles.sortChip, styles.sortChipActive]} onPress={() => setIsFilterVisible(true)}>
                        <Text style={styles.sortChipTextActive}>{activeFilterCount} active</Text>
                        <View style={styles.sortChipIconRight}>
                            <X size={12} color="#fff" />
                        </View>
                    </Pressable>
                )}
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
                        returnKeyType="search"
                        onSubmitEditing={async () => {
                            const destination = localDestination.trim();
                            if (!destination) return;
                            router.setParams({ destination, placeId: '', countryCode: '' });
                            try {
                                const url = `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodeURIComponent(destination)}.json?access_token=${MAPBOX_TOKEN}&types=place,district,region,country&limit=1`;
                                const resp = await fetch(url);
                                const data = await resp.json();
                                if (data.features?.length > 0) {
                                    const [lng, lat] = data.features[0].center;
                                    setMapCenter([lng, lat]);
                                }
                            } catch (_) {
                                // Geocoding failed — fitBounds from hotel results will center the map
                            }
                        }}
                    />
                </View>
                <Pressable style={styles.filterBtn} onPress={() => setIsFilterVisible(true)}>
                    <SlidersHorizontal size={18} color={isDark ? '#ffffff' : '#0f172a'} />
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
                        {/* Sub-header: results count + view toggle */}
                        <View style={styles.subHeader}>
                            <Text style={styles.resultsCountText}>
                                {hotels.length} hotels found
                            </Text>
                            <View style={styles.actions}>
                                <Pressable
                                    style={[styles.viewToggle, viewMode === 'list' && styles.viewToggleActive]}
                                    onPress={() => setViewMode('list')}
                                >
                                    <List size={18} color={viewMode === 'list' ? 'white' : (isDark ? '#8896AA' : '#64748b')} />
                                </Pressable>
                                <Pressable
                                    style={[styles.viewToggle, viewMode === 'map' && styles.viewToggleActive]}
                                    onPress={() => setViewMode('map')}
                                >
                                    <MapIcon size={18} color={viewMode === 'map' ? 'white' : (isDark ? '#8896AA' : '#64748b')} />
                                </Pressable>
                            </View>
                        </View>

                        {/* Sort / Filter chips */}
                        <SortChips />

                        {viewMode === 'map' ? (
                            <View style={styles.mapContainer}>
                                <MapboxWebView
                                    hotels={hotels}
                                    selectedHotelId={selectedHotel?.hotelId}
                                    flyToOnSelectId={flyToHotelId}
                                    onHotelSelect={handleHotelSelect}
                                    onHotelNavigate={(id) => {
                                        const h = hotels.find(x => x.hotelId === id);
                                        if (h) navigateToHotel(h);
                                    }}
                                    onDeselect={() => setSelectedHotel(null)}
                                    isDark={isDark}
                                    center={mapCenter}
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
                                    <View style={styles.floatingCards} renderToHardwareTextureAndroid={true}>
                                        <FlatList
                                            ref={cardsFlatListRef}
                                            horizontal
                                            data={hotels}
                                            keyExtractor={(item) => item.hotelId}
                                            showsHorizontalScrollIndicator={false}
                                            contentContainerStyle={styles.cardsScroll}
                                            snapToInterval={CARD_SNAP}
                                            decelerationRate="fast"
                                            initialNumToRender={5}
                                            maxToRenderPerBatch={5}
                                            windowSize={11}
                                            getItemLayout={(_, index) => ({
                                                length: CARD_SNAP,
                                                offset: CARD_SNAP * index,
                                                index,
                                            })}
                                            onScrollToIndexFailed={(info) => {
                                                setTimeout(() => {
                                                    cardsFlatListRef.current?.scrollToIndex({ index: info.index, animated: true });
                                                }, 100);
                                            }}
                                            onMomentumScrollEnd={(e) => {
                                                if (isInternalScroll.current) return;
                                                const x = e.nativeEvent.contentOffset.x;
                                                const index = Math.round(x / CARD_SNAP);
                                                if (index !== lastScrolledIndex.current && hotels[index]) {
                                                    lastScrolledIndex.current = index;
                                                    if (selectedHotel?.hotelId !== hotels[index].hotelId) {
                                                        // Only update visual selection — do NOT set flyToHotelId
                                                        // so the map stays where it is during carousel swipes
                                                        setSelectedHotel(hotels[index]);
                                                    }
                                                }
                                            }}
                                            onScrollBeginDrag={() => { isInternalScroll.current = false; }}
                                            renderItem={({ item: hotel, index }) => (
                                                <HotelMapCard
                                                    hotel={hotel}
                                                    index={index}
                                                    isSelected={selectedHotel?.hotelId === hotel.hotelId}
                                                    isDark={isDark}
                                                    currencySymbol={currency.symbol}
                                                    isFavorite={favorites.includes(hotel.hotelId)}
                                                    onSelect={handleHotelSelect}
                                                    onNavigate={navigateToHotel}
                                                    onToggleFav={toggleFav}
                                                    styles={styles}
                                                />
                                            )}
                                        />

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
                            <FlatList
                                data={hotels}
                                keyExtractor={(item) => item.hotelId}
                                contentContainerStyle={styles.listContent}
                                initialNumToRender={6}
                                maxToRenderPerBatch={6}
                                windowSize={5}
                                removeClippedSubviews={true}
                                getItemLayout={(_, index) => ({
                                    length: 154,
                                    offset: 154 * index,
                                    index,
                                })}
                                ListEmptyComponent={
                                    <View style={styles.emptyContainer}>
                                        <Text style={styles.emptyText}>No hotels found for this search.</Text>
                                    </View>
                                }
                                renderItem={({ item: hotel }) => (
                                    <HotelListCard
                                        hotel={hotel}
                                        isDark={isDark}
                                        currencySymbol={currency.symbol}
                                        isFavorite={favorites.includes(hotel.hotelId)}
                                        onNavigate={navigateToHotel}
                                        onToggleFav={toggleFav}
                                        styles={styles}
                                    />
                                )}
                            />
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
        paddingHorizontal: 16,
        paddingVertical: 10,
        backgroundColor: isDark ? '#0B1018' : '#f8fafc',
    },
    resultsCountText: {
        fontSize: 13,
        fontWeight: '600',
        color: isDark ? '#8896AA' : '#64748b',
    },
    actions: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 6,
    },
    viewToggle: {
        width: 36,
        height: 36,
        borderRadius: 10,
        backgroundColor: isDark ? '#141C2A' : '#ffffff',
        alignItems: 'center',
        justifyContent: 'center',
        borderWidth: 1,
        borderColor: isDark ? '#1F2D3D' : '#e2e8f0',
    },
    viewToggleActive: {
        backgroundColor: '#2563eb',
        borderColor: '#2563eb',
    },
    sortChipsContainer: {
        backgroundColor: isDark ? '#0B1018' : '#f8fafc',
        borderBottomWidth: 1,
        borderBottomColor: isDark ? '#1F2D3D' : '#e2e8f0',
        flexGrow: 0,
        // Fix: allow the first and last chips to fully show their shadow/border
        // without being clipped by the ScrollView container edge on Android
        overflow: 'visible',
    },
    sortChipsContent: {
        flexDirection: 'row',
        alignItems: 'center',
        paddingLeft: 16,
        paddingRight: 24,
        paddingTop: 10,
        paddingBottom: 12,
    },
    sortChip: {
        flexDirection: 'row',
        alignItems: 'center',
        minWidth: 0,
        minHeight: 36,
        marginRight: 8,
        paddingHorizontal: 16,
        paddingVertical: 10,
        borderRadius: 20,
        backgroundColor: isDark ? '#1e293b' : '#FFFFFF',
        borderWidth: 1,
        borderColor: isDark ? '#334155' : '#E2E8F0',
    },
    sortChipIcon: {
        marginRight: 8,
        alignItems: 'center',
        justifyContent: 'center',
    },
    sortChipIconRight: {
        marginLeft: 6,
        alignItems: 'center',
        justifyContent: 'center',
    },
    sortChipActive: {
        backgroundColor: '#2563eb',
        borderColor: '#2563eb',
    },
    sortChipText: {
        fontSize: 13,
        lineHeight: 18,
        includeFontPadding: false,
        textAlignVertical: 'center',
        fontWeight: '600',
        color: isDark ? '#94a3b8' : '#64748b',
        flexShrink: 1,
        minWidth: 0,
    },
    sortChipTextActive: {
        fontSize: 13,
        lineHeight: 18,
        includeFontPadding: false,
        textAlignVertical: 'center',
        fontWeight: '600',
        color: '#ffffff',
        flexShrink: 1,
        minWidth: 0,
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
        bottom: 20,
        left: 0,
        right: 0,
        zIndex: 20,
    },
    cardsScroll: {
        paddingHorizontal: 16,
        paddingBottom: 4,
        gap: 12,
    },
    hotelCard: {
        width: 270,
        height: 110,
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        borderRadius: 16,
        overflow: 'hidden',
        flexDirection: 'row',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 8 },
        shadowOpacity: 0.2,
        shadowRadius: 16,
        elevation: 12,
    },
    hotelCardSelected: {
        borderColor: '#2563eb',
        borderWidth: 2,
    },
    hotelCardImage: {
        width: 110,
        height: 110,
        backgroundColor: isDark ? '#1e293b' : '#f1f5f9',
    },
    rankBadge: {
        position: 'absolute',
        top: 8,
        left: 8,
        zIndex: 10,
        width: 24,
        height: 24,
        borderRadius: 7,
        backgroundColor: '#2563eb',
        alignItems: 'center',
        justifyContent: 'center',
    },
    rankBadgeText: {
        color: '#ffffff',
        fontSize: 12,
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
        padding: 8,
        justifyContent: 'space-between',
    },
    hotelName: {
        fontSize: 12,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
        marginBottom: 2,
        paddingRight: 24,
        lineHeight: 16,
    },
    hotelRatingRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 4,
        flexWrap: 'wrap',
        marginBottom: 4,
    },
    reviewBadge: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 3,
        paddingHorizontal: 5,
        paddingVertical: 2,
        borderRadius: 5,
        backgroundColor: '#2563eb',
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
        borderRadius: 10,
    },
    cardViewBtnText: {
        color: '#ffffff',
        fontSize: 11,
        fontWeight: '700',
    },
    listImageCol: {
        width: 130,
        position: 'relative',
    },
    discountBadge: {
        position: 'absolute',
        bottom: 8,
        left: 8,
        backgroundColor: 'rgba(34,197,94,0.9)',
        paddingHorizontal: 6,
        paddingVertical: 2,
        borderRadius: 4,
    },
    discountText: {
        color: '#ffffff',
        fontSize: 10,
        fontWeight: '700',
    },
    listRatingRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 6,
        flexWrap: 'wrap',
        marginBottom: 8,
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
        padding: 12,
        paddingBottom: 24,
    },
    listCard: {
        flexDirection: 'row',
        marginBottom: 12,
        backgroundColor: isDark ? '#141C2A' : '#ffffff',
        borderRadius: 16,
        borderWidth: 1,
        borderColor: isDark ? '#1F2D3D' : '#e2e8f0',
        overflow: 'hidden',
    },
    listImage: {
        width: 130,
        height: 140,
        backgroundColor: isDark ? '#1F2D3D' : '#f1f5f9',
    },
    listDetails: {
        flex: 1,
        padding: 12,
        paddingRight: 36,
        justifyContent: 'space-between',
    },
    listHotelName: {
        fontSize: 14,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
        marginBottom: 4,
        lineHeight: 19,
    },
    listLocationRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 4,
        marginBottom: 8,
    },
    listLocationText: {
        fontSize: 11,
        color: isDark ? '#64748b' : '#94a3b8',
        flex: 1,
    },
    listFooterRow: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'flex-end',
    },
    listPriceText: {
        fontSize: 15,
        fontWeight: '700',
        color: '#3B82F6',
    },
    listPerNightText: {
        fontSize: 10,
        color: isDark ? '#64748b' : '#94a3b8',
    },
    viewBtn: {
        backgroundColor: '#2563eb',
        paddingHorizontal: 14,
        paddingVertical: 8,
        borderRadius: 10,
    },
    viewBtnText: {
        fontSize: 12,
        fontWeight: '700',
        color: '#ffffff',
    },
    amenitySep: {
        fontSize: 11,
        color: isDark ? '#3D4D5E' : '#cbd5e1',
    },
    amenityText: {
        fontSize: 11,
        color: isDark ? '#64748b' : '#94a3b8',
        fontWeight: '500',
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
    filterChipsContainer: {
        flexGrow: 0,
    },
    filterChipsContent: {
        paddingHorizontal: 16,
        gap: 8,
    },
    filterChip: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 6,
        paddingHorizontal: 12,
        paddingVertical: 6,
        backgroundColor: isDark ? '#141C2A' : '#f1f5f9',
        borderRadius: 20,
        borderWidth: 1,
        borderColor: '#2563eb',
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
        backgroundColor: isDark ? '#1F2D3D' : 'white',
        alignItems: 'center',
        justifyContent: 'center',
        borderWidth: 1,
        borderColor: isDark ? '#1F2D3D' : '#e2e8f0',
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
