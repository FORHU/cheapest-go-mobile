import { Image as ExpoImage } from 'expo-image';
import { useLocalSearchParams, useRouter } from 'expo-router';
import {
    AirVent,
    AlertTriangle,
    ArrowUp,
    Baby,
    Bath,
    Bed,
    Briefcase,
    Car,
    Check,
    CheckCircle,
    ChevronDown,
    ChevronLeft,
    ChevronRight,
    ChevronUp,
    Cigarette, CigaretteOff,
    Clock,
    Coffee,
    ConciergeBell,
    Dumbbell,
    Heart,
    Info,
    Key,
    Languages,
    LogIn, LogOut,
    MapPin,
    Martini,
    Phone,
    Scissors,
    Share2,
    ShieldCheck,
    ShoppingBag,
    Sparkles,
    Trees,
    Tv,
    Utensils, Waves,
    Wifi, Wind
} from 'lucide-react-native';
import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { ActivityIndicator, Alert, Dimensions, Image, LayoutAnimation, Platform, Pressable, ScrollView, Share, StyleSheet, Text, UIManager, useColorScheme, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { isFavorite as checkIsFavorite, toggleFavorite as persistToggleFavorite } from '../../../lib/favorites';

import PropertyMapWebView from '../../../components/search/PropertyMapWebView';
import OptimizedImage from '../../../components/ui/OptimizedImage';
import StarRating from '../../../components/ui/StarRating';
import { useSettings } from '../../../context/SettingsContext';
import { convertCurrency } from '../../../lib/currency';
import { getHotelDetails, getHotelReviews } from '../../../lib/travel-api';

// Enable LayoutAnimation on Android
if (Platform.OS === 'android' && UIManager.setLayoutAnimationEnabledExperimental) {
    UIManager.setLayoutAnimationEnabledExperimental(true);
}

const { width } = Dimensions.get('window');

const stripHtml = (html: string) => {
    if (!html) return '';
    return html.replace(/<[^>]*>?/gm, '').replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&');
};

const cleanDescription = (text: string) => {
    if (!text) return '';
    return stripHtml(text)
        .replace(/[«»]/g, '')
        .replace(/\.,/g, '. ')
        .replace(/\s{2,}/g, ' ')
        .trim();
};

const AMENITY_COLORS: { test: (n: string) => boolean; light: { bg: string; text: string }; dark: { bg: string; text: string } }[] = [
    { test: n => n.includes('wifi') || n.includes('wi-fi') || n.includes('internet'), light: { bg: '#dbeafe', text: '#1d4ed8' }, dark: { bg: '#1e3a5f', text: '#93c5fd' } },
    { test: n => n.includes('breakfast') || (n.includes('coffee') && !n.includes('maker')) || n.includes('half board') || n.includes('full board'), light: { bg: '#fef3c7', text: '#b45309' }, dark: { bg: '#431407', text: '#fcd34d' } },
    { test: n => n.includes('pool') || n.includes('swim') || n.includes('beach'), light: { bg: '#cffafe', text: '#0e7490' }, dark: { bg: '#164e63', text: '#67e8f9' } },
    { test: n => n.includes('gym') || n.includes('fitness') || n.includes('exercise'), light: { bg: '#dcfce7', text: '#15803d' }, dark: { bg: '#14532d', text: '#86efac' } },
    { test: n => n.includes('spa') || n.includes('massage') || n.includes('sauna') || n.includes('jacuzzi'), light: { bg: '#fae8ff', text: '#a21caf' }, dark: { bg: '#4a044e', text: '#e879f9' } },
    { test: n => n.includes('bar') || n.includes('lounge') || n.includes('pub') || n.includes('drink'), light: { bg: '#fff7ed', text: '#c2410c' }, dark: { bg: '#431407', text: '#fb923c' } },
    { test: n => n.includes('parking') || n.includes('garage') || n.includes('valet'), light: { bg: '#f1f5f9', text: '#475569' }, dark: { bg: '#1e293b', text: '#94a3b8' } },
    { test: n => n.includes('restaurant') || n.includes('dining') || n.includes('food'), light: { bg: '#fef9c3', text: '#a16207' }, dark: { bg: '#422006', text: '#fde047' } },
    { test: n => n.includes('air cond') || n.includes('aircon') || n.includes('ac ') || n === 'ac' || n.includes('climate'), light: { bg: '#e0f2fe', text: '#0369a1' }, dark: { bg: '#0c4a6e', text: '#7dd3fc' } },
    { test: n => n.includes('pet'), light: { bg: '#fce7f3', text: '#9d174d' }, dark: { bg: '#4a044e', text: '#f9a8d4' } },
    { test: n => n.includes('24') || n.includes('reception') || n.includes('front desk'), light: { bg: '#ede9fe', text: '#6d28d9' }, dark: { bg: '#2e1065', text: '#c4b5fd' } },
];

function getAmenityPillColors(name: string, isDark: boolean) {
    const lower = name.toLowerCase();
    const match = AMENITY_COLORS.find(c => c.test(lower));
    if (match) return isDark ? match.dark : match.light;
    return isDark ? { bg: '#1e293b', text: '#94a3b8' } : { bg: '#f1f5f9', text: '#475569' };
}

const getAmenityIcon = (name: string, size: number = 16, color: string = '#10b981') => {
    const lower = name.toLowerCase();
    let IconComponent = Check;

    // Wifi & Internet
    if (lower.includes('wifi') || lower.includes('internet') || lower.includes('lan')) IconComponent = Wifi;
    // Food & Dining
    else if (lower.includes('breakfast') || lower.includes('coffee') || lower.includes('tea')) IconComponent = Coffee;
    else if (lower.includes('restaurant') || lower.includes('din') || lower.includes('tableware') || lower.includes('food')) IconComponent = Utensils;
    else if (lower.includes('bar') || lower.includes('loung') || lower.includes('pub') || lower.includes('drink')) IconComponent = Martini;
    // AC & Ventilation
    else if (lower.includes('ac ') || lower.includes('air cond') || lower.includes('ventilation') || lower.includes('airvent')) IconComponent = AirVent;
    else if (lower.includes('fan') || lower.includes('wind') || lower.includes('cooling')) IconComponent = Wind;
    // Entertainment & Tech
    else if (lower.includes('tv') || lower.includes('television') || lower.includes('satellite') || lower.includes('cable')) IconComponent = Tv;
    // Transport & Parking
    else if (lower.includes('garage') || lower.includes('valet')) IconComponent = Key;
    else if (lower.includes('parking') || lower.includes('car') || lower.includes('vehicle') || lower.includes('surcharge')) IconComponent = Car;
    // Pool & Spa
    else if (lower.includes('pool') || lower.includes('swim') || lower.includes('beach')) IconComponent = Waves;
    else if (lower.includes('gym') || lower.includes('fitness') || lower.includes('exercise')) IconComponent = Dumbbell;
    else if (lower.includes('spa') || lower.includes('mass') || lower.includes('jacuzzi') || lower.includes('sauna')) IconComponent = Sparkles;
    // Bathroom
    else if (lower.includes('bath') || lower.includes('shower') || lower.includes('toiletries')) IconComponent = Bath;
    // Reception & Service
    else if (lower.includes('front desk') || lower.includes('reception') || lower.includes('concierge') || lower.includes('bell')) IconComponent = ConciergeBell;
    else if (lower.includes('room service') || lower.includes('housekeeping')) IconComponent = Clock;
    else if (lower.includes('laundry') || lower.includes('dry clean') || lower.includes('iron')) IconComponent = Sparkles;
    else if (lower.includes('elevator') || lower.includes('lift')) IconComponent = ArrowUp;
    else if (lower.includes('phone') || lower.includes('call')) IconComponent = Phone;
    else if (lower.includes('language') || lower.includes('multilingual')) IconComponent = Languages;
    // Safety & Security
    else if (lower.includes('24-hour security') || lower.includes('security guard') || lower.includes('secur')) IconComponent = ShieldCheck;
    else if (lower.includes('safe') || lower.includes('lock')) IconComponent = Key;
    else if (lower.includes('fire extinguisher') || lower.includes('first aid') || lower.includes('thermometer') || lower.includes('medical') || lower.includes('doctor')) IconComponent = ShieldCheck;
    else if (lower.includes('smoke alarm') || lower.includes('fire alarm') || lower.includes('carbon monoxide')) IconComponent = AirVent;
    // Cleaning & Hygiene
    else if (lower.includes('disinfect') || lower.includes('sanit') || lower.includes('clean') || lower.includes('hygiene') || lower.includes('steril')) IconComponent = Sparkles;
    // Distancing & Guidelines
    else if (lower.includes('distancing') || lower.includes('mask') || lower.includes('barrier') || lower.includes('screen') || lower.includes('guideline')) IconComponent = Info;
    // Smoking Policy
    else if (lower.includes('non-smoking') || lower.includes('no smoking') || lower.includes('smoke-free')) IconComponent = CigaretteOff;
    else if (lower.includes('smoking area') || lower.includes('designated smoking')) IconComponent = Cigarette;
    // Kids & Family
    else if (lower.includes('family') || lower.includes('kid') || lower.includes('baby') || lower.includes('child')) IconComponent = Baby;
    // Business
    else if (lower.includes('meeting') || lower.includes('business') || lower.includes('conference')) IconComponent = Briefcase;
    // Outdoors
    else if (lower.includes('garden') || lower.includes('terrace') || lower.includes('patio') || lower.includes('yard')) IconComponent = Trees;
    else if (lower.includes('shop') || lower.includes('market') || lower.includes('boutique')) IconComponent = ShoppingBag;
    else if (lower.includes('hair') || lower.includes('salon') || lower.includes('beauty')) IconComponent = Scissors;
    // General Rooms
    else if (lower.includes('room') || lower.includes('suite') || lower.includes('bed')) IconComponent = Bed;

    return <IconComponent size={size} color={color} />;
};



const normalizeRoomOptions = (hotel: any) => {
    if (!hotel) return [];

    const rawRooms = hotel.roomTypes || hotel.details?.roomTypes || hotel.details?.rooms || hotel.rooms || [];
    const rooms = Array.isArray(rawRooms) ? rawRooms : [rawRooms];

    return rooms
        .map((room: any, index: number) => {
            const rawRates = room.rates || room.rate || [];
            const rates = Array.isArray(rawRates) ? rawRates : rawRates ? [rawRates] : [];
            const roomId = room.roomId || room.id || room.code || room.roomTypeId || rates[0]?.offerId || `room-${index}`;
            return {
                ...room,
                rates,
                selectorId: roomId,
            };
        })
        .filter((room: any) => room.rates.length > 0);
};

const getPolicyTime = (value: any) => {
    if (!value) return null;
    if (typeof value === 'string') return value;
    if (Array.isArray(value?.schedule) && value.schedule.length > 0) {
        return value.schedule[0]?.startTime || value.schedule[0]?.time || null;
    }
    return value.startTime || value.time || value.text || null;
};

const getPolicyDescription = (value: any) => {
    if (!value) return null;
    if (typeof value === 'string') return value;
    if (Array.isArray(value?.instructions) && value.instructions.length > 0) {
        return value.instructions.map((item: any) => item?.text || item).filter(Boolean).join('\n');
    }
    return value.description || value.text || null;
};

const ReviewItem = React.memo(function ReviewItem({ review, isLast, styles }: any) {
    const [expanded, setExpanded] = useState(false);
    const content = stripHtml(review.pros || review.headline || "Excellent stay, very friendly staff and great location.");
    const isLong = content.length > 100;

    return (
        <View style={[styles.reviewItem, !isLast && styles.reviewDivider]}>
            <View style={styles.reviewHeader}>
                <View style={styles.reviewerAvatar}>
                    {review.avatar || review.userImage ? (
                        <Image source={{ uri: review.avatar || review.userImage }} style={styles.reviewerAvatarImage} />
                    ) : (
                        <Text style={styles.avatarText}>{review.name?.[0] || 'V'}</Text>
                    )}
                </View>
                <View style={styles.reviewerInfo}>
                    <Text style={styles.reviewerName}>{review.name || 'Verified Traveler'}</Text>
                    <Text style={styles.reviewDate}>{new Date(review.date).toLocaleDateString()}</Text>
                </View>
                <StarRating rating={review.averageScore || 10} size={12} />
            </View>
            <Text style={styles.reviewText} numberOfLines={expanded ? undefined : 2}>
                {content}
            </Text>
            {isLong && (
                <Pressable onPress={() => setExpanded(!expanded)} style={{ marginTop: 2 }}>
                    <Text style={styles.readMoreText}>{expanded ? 'Show less' : 'Read more'}</Text>
                </Pressable>
            )}
        </View>
    );
});

const RoomCard = React.memo(function RoomCard({ room, hotelThumbnail, detailRooms, currency, fromCurrency, styles, onSelect, isSelected }: any) {
    const mappedRoomId = room.rates?.[0]?.mappedRoomId;
    const matchedRoom = mappedRoomId && detailRooms
        ? detailRooms.find((dr: any) => String(dr.id) === String(mappedRoomId))
        : null;

    let roomImage = hotelThumbnail;
    if (matchedRoom?.photos?.length > 0) {
        const photo = matchedRoom.photos[0];
        roomImage = typeof photo === 'string' ? photo : (photo.url || photo.urlHd || photo.hd_url || photo.hdUrl || photo.thumbnail);
    } else if (room.roomPhotos?.[0]) {
        roomImage = room.roomPhotos[0];
    } else if (room.images?.[0]) {
        const img = room.images[0];
        roomImage = typeof img === 'string' ? img : (img.url || img.urlHd || img);
    } else if (room.photos?.[0]) {
        const p = room.photos[0];
        roomImage = typeof p === 'string' ? p : (p.url || p);
    }

    const rawPrice = Math.round(
        room.rates?.[0]?.retailRate?.total?.[0]?.amount ||
        room.rates?.[0]?.retailRate?.total?.amount ||
        room.rates?.[0]?.price?.amount ||
        room.rates?.[0]?.price || 0
    );
    // Read the actual currency the supplier returned the price in.
    // TravelgateX stores it in retailRate.total[0].currency — it is often PHP/KRW
    // even when USD was requested, because OTV suppliers quote in their native currency.
    const rateCurrency = (
        room.rates?.[0]?.retailRate?.total?.[0]?.currency ||
        room.rates?.[0]?.retailRate?.total?.currency ||
        room.rates?.[0]?.currency ||
        fromCurrency ||
        'USD'
    ).toUpperCase();
    const price = rateCurrency !== currency.code.toUpperCase()
        ? Math.round(convertCurrency(rawPrice, rateCurrency, currency.code))
        : rawPrice;
    const roomName = room.rates?.[0]?.name || room.roomName || room.name || room.description || matchedRoom?.roomName || 'Room';
    const maxOccupancy = room.rates?.[0]?.maxOccupancy || room.maxOccupancy || matchedRoom?.maxOccupancy || 2;
    const boardName = room.rates?.[0]?.boardName;
    const refundableTag = room.rates?.[0]?.cancellationPolicies?.refundableTag || room.cancellationPolicies?.refundableTag;
    const isRefundable = refundableTag === 'RFN';
    const hasBreakfast = boardName && (
        boardName.toLowerCase().includes('breakfast') ||
        boardName.toLowerCase().includes('bb') ||
        boardName.toLowerCase() === 'half board' ||
        boardName.toLowerCase() === 'full board' ||
        boardName.toLowerCase() === 'all inclusive'
    );

    return (
        <Pressable
            style={[styles.roomCard, isSelected && styles.roomCardSelected]}
            onPress={() => onSelect?.(room)}
        >
            <View style={styles.roomCardRow}>
                <OptimizedImage uri={roomImage} style={styles.roomImage} type="room" />
                <View style={styles.roomInfo}>
                    <Text style={styles.roomName} numberOfLines={2}>{roomName}</Text>

                    <View style={styles.roomBadgeRow}>
                        <View style={styles.roomBadgeSmall}>
                            <Text style={styles.roomBadgeSmallText}>👥 {maxOccupancy}</Text>
                        </View>
                        {isRefundable && (
                            <View style={[styles.roomBadgeSmall, styles.roomBadgeGreen]}>
                                <Text style={[styles.roomBadgeSmallText, { color: '#059669' }]}>✓ Free cancel</Text>
                            </View>
                        )}
                        {!isRefundable && refundableTag === 'NRFN' && (
                            <View style={[styles.roomBadgeSmall, styles.roomBadgeAmber]}>
                                <Text style={[styles.roomBadgeSmallText, { color: '#d97706' }]}>Non-refundable</Text>
                            </View>
                        )}
                        {hasBreakfast && (
                            <View style={[styles.roomBadgeSmall, styles.roomBadgeBlue]}>
                                <Text style={[styles.roomBadgeSmallText, { color: '#2563eb' }]}>🍳 Breakfast</Text>
                            </View>
                        )}
                    </View>

                    {boardName && !hasBreakfast && (
                        <Text style={styles.roomBoardText} numberOfLines={1}>{boardName}</Text>
                    )}

                    <View style={styles.roomFooter}>
                        <View>
                            <Text style={styles.roomPrice}>{currency.symbol}{price.toLocaleString()}</Text>
                            <Text style={styles.perNight}>per night</Text>
                        </View>
                        <View style={[styles.selectBtn, isSelected && styles.selectBtnSelected]}>
                            <Text style={styles.selectBtnText}>{isSelected ? 'Selected' : 'Select'}</Text>
                        </View>
                    </View>
                </View>
            </View>
        </Pressable>
    );
});

const FaqSection = React.memo(function FaqSection({ faqs, styles, isDark }: { faqs: { q: string; a: string }[]; styles: any; isDark: boolean }) {
    const [openIndex, setOpenIndex] = useState<number | null>(null);
    if (!faqs.length) return null;
    return (
        <View style={styles.section}>
            <Text style={styles.sectionTitle}>Frequently Asked Questions</Text>
            {faqs.map(({ q, a }, i) => (
                <Pressable
                    key={i}
                    style={[styles.faqItem, i < faqs.length - 1 && styles.faqDivider]}
                    onPress={() => setOpenIndex(openIndex === i ? null : i)}
                >
                    <View style={styles.faqRow}>
                        <Text style={styles.faqQuestion} numberOfLines={openIndex === i ? undefined : 2}>{q}</Text>
                        {openIndex === i
                            ? <ChevronUp size={16} color="#2563eb" />
                            : <ChevronDown size={16} color={isDark ? '#475569' : '#94a3b8'} />}
                    </View>
                    {openIndex === i && (
                        <Text style={styles.faqAnswer}>{a}</Text>
                    )}
                </Pressable>
            ))}
        </View>
    );
});

const GalleryImage = React.memo(function GalleryImage({ uri, width }: { uri: string, width: number }) {
    return (
        <View style={{ width, height: 350, backgroundColor: '#0f172a' }}>
            <ExpoImage
                source={{ uri }}
                style={{ width, height: 350 }}
                contentFit="cover"
                cachePolicy="disk"
                placeholder={{ blurhash: 'L15#hiof00of~qfQIUay00fQ-;fQ' }}
                placeholderContentFit="cover"
                transition={300}
            />
        </View>
    );
});

export default function HotelDetailsScreen() {
    const params = useLocalSearchParams();
    const router = useRouter();
    const colorScheme = useColorScheme();
    const isDark = colorScheme === 'dark';
    const { currency } = useSettings();
    const insets = useSafeAreaInsets();
    const styles = getStyles(isDark, insets.bottom);
    const galleryScrollRef = useRef<ScrollView>(null);

    const [loading, setLoading] = useState(true);
    const [hotel, setHotel] = useState<any>(null);
    const [reviews, setReviews] = useState<any[]>([]);
    const [activeImageIndex, setActiveImageIndex] = useState(0);
    const [isDescriptionExpanded, setIsDescriptionExpanded] = useState(false);
    const [visibleReviewsCount, setVisibleReviewsCount] = useState(3);
    const [selectedRoom, setSelectedRoom] = useState<any>(null);
    const [isFacilitiesExpanded, setIsFacilitiesExpanded] = useState(false);
    const [isPolicyExpanded, setIsPolicyExpanded] = useState(false);
    const [roomPage, setRoomPage] = useState(1);

    const handleShare = useCallback(() => {
        if (!hotel) return;
        Share.share({
            title: hotel.name || 'Hotel',
            message: `Check out ${hotel.name || 'this hotel'}${hotel.address ? ` at ${hotel.address}` : ''}`,
        }).catch((err: any) => {
            Alert.alert('Unable to share', err?.message || 'Please try again.');
        });
    }, [hotel]);

    const toggleFavorite = useCallback(async () => {
        if (!hotel?.hotelId) return;
        const added = await persistToggleFavorite(hotel.hotelId, hotel);
        setIsFavorite(added);
    }, [hotel]);

    // Merge hotelFacilities (full list from API) with facilities
    const allFacilities = useMemo(() => {
        if (hotel?.hotelFacilities?.length > 0) return hotel.hotelFacilities;
        if (hotel?.facilities?.length > 0) return hotel.facilities;
        if (hotel?.details?.amenities?.length > 0) return hotel.details.amenities;
        return hotel?.details?.facilities || [];
    }, [hotel]);

    const checkInTime = useMemo(() => {
        return hotel?.checkInTime
            || hotel?.checkinTime
            || hotel?.checkin
            || hotel?.check_in
            || getPolicyTime(hotel?.details?.checkIn)
            || getPolicyTime(hotel?.details?.checkin)
            || getPolicyTime(hotel?.details?.policies?.checkIn)
            || getPolicyTime(hotel?.policies?.checkIn)
            || hotel?.policy?.checkIn
            || hotel?.otherPolicy?.checkIn
            || null;
    }, [hotel]);

    const checkOutTime = useMemo(() => {
        return hotel?.checkOutTime
            || hotel?.checkoutTime
            || hotel?.checkout
            || hotel?.check_out
            || getPolicyTime(hotel?.details?.checkOut)
            || getPolicyTime(hotel?.details?.checkout)
            || getPolicyTime(hotel?.details?.policies?.checkOut)
            || getPolicyTime(hotel?.policies?.checkOut)
            || hotel?.policy?.checkOut
            || hotel?.otherPolicy?.checkOut
            || null;
    }, [hotel]);

    const policyInstructions = useMemo(() => {
        const raw = hotel?.hotelImportantInformation
            || getPolicyDescription(hotel?.details?.importantInformation)
            || getPolicyDescription(hotel?.details?.checkIn?.instructions)
            || getPolicyDescription(hotel?.details?.policies?.general)
            || getPolicyDescription(hotel?.details?.policies);
        return cleanDescription(raw || '');
    }, [hotel]);

    const handleRoomSelect = useCallback((room: any) => {
        setSelectedRoom((prev: any) =>
            prev?.selectorId === room.selectorId ? null : room
        );
    }, []);

    const handleBookNow = useCallback(() => {
        if (!selectedRoom) {
            Alert.alert('Select a room', 'Please choose a room from the list before continuing.');
            return;
        }
        const rate = selectedRoom.rates?.[0];

        // TGX edge function sets offerId at the room level, not inside rates[].
        // Fall back through all possible locations before giving up.
        const offerId =
            selectedRoom.offerId ||
            rate?.offerId ||
            (rate?._tgx?.optionId ? `TGX:${rate._tgx.optionId}` : null) ||
            (rate?._tgx?.token ? `TGX:${rate._tgx.token}` : null);

        if (!offerId) {
            Alert.alert('Room unavailable', 'This room cannot be booked right now. Please select a different room.');
            return;
        }
        const room = selectedRoom;

        const rateCcy = (
            rate?.retailRate?.total?.[0]?.currency ||
            rate?.retailRate?.total?.currency ||
            rate?.currency ||
            params.currency ||
            'USD'
        ).toUpperCase();
        const rawAmt = Math.round(
            rate?.retailRate?.total?.[0]?.amount ||
            rate?.retailRate?.total?.amount ||
            rate?.price?.amount ||
            rate?.price || 0
        );
        const displayAmt = rateCcy !== currency.code.toUpperCase()
            ? Math.round(convertCurrency(rawAmt, rateCcy, currency.code))
            : rawAmt;

        router.push({
            pathname: '/checkout',
            params: {
                offerId,
                roomName: rate.name || room.name || room.description || room.roomName || 'Room',
                roomPrice: String(displayAmt),
                roomCurrency: currency.code,
                hotelName: hotel?.name || '',
                hotelImage: hotel?.thumbnailUrl || '',
                checkIn: params.checkIn as string || '',
                checkOut: params.checkOut as string || '',
                adults: params.adults as string || '2',
            },
        });
    }, [hotel, params, router, selectedRoom, currency.code]);

    const [isFavorite, setIsFavorite] = useState(false);

    useEffect(() => {
        if (hotel?.hotelId) {
            checkIsFavorite(hotel.hotelId).then(setIsFavorite);
        }
    }, [hotel?.hotelId]);

    const availableRooms = useMemo(() => normalizeRoomOptions(hotel), [hotel]);

    const ROOMS_PER_PAGE = 10;
    const totalRoomPages = Math.max(1, Math.ceil(availableRooms.length / ROOMS_PER_PAGE));
    // Clamp current page if the room list shrinks (e.g. new search results).
    const currentRoomPage = Math.min(roomPage, totalRoomPages);
    const paginatedRooms = useMemo(
        () => availableRooms.slice((currentRoomPage - 1) * ROOMS_PER_PAGE, currentRoomPage * ROOMS_PER_PAGE),
        [availableRooms, currentRoomPage],
    );

    useEffect(() => {
        const fetchData = async () => {
            setLoading(true);
            try {
                const [details, reviewData] = await Promise.all([
                    getHotelDetails(params.id as string, {
                        checkIn: params.checkIn,
                        checkOut: params.checkOut,
                        adults: params.adults,
                        rooms: params.rooms,
                        currency: params.currency
                    }),
                    getHotelReviews(params.id as string, 100)
                ]);
                setHotel(details);
                setReviews(reviewData);
                setRoomPage(1);
            } catch (err) {
                console.error('[HotelDetails] Error:', err);
            } finally {
                setLoading(false);
            }
        };

        if (params.id) {
            fetchData();
        }
    }, [params.id, params.adults, params.checkIn, params.checkOut, params.currency, params.rooms]);

    if (loading) {
        return (
            <View style={styles.loadingContainer}>
                <ActivityIndicator size="large" color="#2563eb" />
            </View>
        );
    }

    const goBackToMapSearch = () => {
        router.push({
            pathname: '/(tabs)/search',
            params: {
                viewMode: 'map',
                destination: params.destination as string || '',
                placeId: params.placeId as string || '',
                countryCode: params.countryCode as string || '',
                checkIn: params.checkIn as string || '',
                checkOut: params.checkOut as string || '',
                adults: params.adults as string || '2',
                children: params.children as string || '0',
                childrenAges: params.childrenAges as string || '',
                rooms: params.rooms as string || '1',
            },
        });
    };

    if (!hotel) {
        return (
            <View style={styles.errorContainer}>
                <Text style={styles.errorText}>Hotel details not found.</Text>
                <Pressable onPress={goBackToMapSearch} style={styles.backBtnLabel}>
                    <Text style={styles.backBtnLabelText}>Go Back</Text>
                </Pressable>
            </View>
        );
    }

    const rawImages = hotel.images || hotel.details?.hotelImages || hotel.details?.images || [];
    const validImages = Array.isArray(rawImages)
        ? rawImages.map((img: any) => typeof img === 'string' ? img : (img.url || img.urlHd || img.hdUrl || img.image || '')).filter((url: string) => url.trim().length > 0)
        : [];

    const hotelThumbnail = hotel.thumbnailUrl || hotel.image || '';
    if (hotelThumbnail && !validImages.includes(hotelThumbnail)) {
        validImages.unshift(hotelThumbnail);
    }

    const hotelImages = validImages.length > 0
        ? validImages
        : [hotelThumbnail || 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=800&q=80'];

    return (
        <View style={styles.container}>
            <ScrollView style={styles.scrollView} contentContainerStyle={{ paddingBottom: 140 }} bounces={false} showsVerticalScrollIndicator={false}>
                {/* Image Gallery */}
                <View style={styles.imageContainer}>
                    <ScrollView
                        ref={galleryScrollRef}
                        key={hotelImages.length}
                        horizontal
                        pagingEnabled
                        removeClippedSubviews={Platform.OS === 'android'} // Memory optimization for Android offscreen items
                        showsHorizontalScrollIndicator={false}
                        onMomentumScrollEnd={(e) => {
                            const x = e.nativeEvent.contentOffset.x;
                            const idx = Math.round(x / width);
                            setActiveImageIndex(idx);
                        }}
                    >
                        {hotelImages.map((img: string) => (
                            <GalleryImage key={img} uri={img} width={width} />
                        ))}
                    </ScrollView>
                    <View style={styles.imageDots}>
                        {hotelImages.slice(0, 10).map((_: any, i: number) => (
                            <View key={i} style={[styles.dot, activeImageIndex === i && styles.dotActive]} />
                        ))}
                    </View>

                    {/* Left & Right Sliding Arrows */}
                    {hotelImages.length > 1 && activeImageIndex > 0 && (
                        <Pressable
                            style={[styles.sliderArrow, styles.sliderArrowLeft]}
                            onPress={() => {
                                const prevIdx = activeImageIndex - 1;
                                galleryScrollRef.current?.scrollTo({ x: prevIdx * width, animated: true });
                                setActiveImageIndex(prevIdx);
                            }}
                        >
                            <ChevronLeft size={20} color="white" />
                        </Pressable>
                    )}
                    {hotelImages.length > 1 && activeImageIndex < hotelImages.length - 1 && (
                        <Pressable
                            style={[styles.sliderArrow, styles.sliderArrowRight]}
                            onPress={() => {
                                const nextIdx = activeImageIndex + 1;
                                galleryScrollRef.current?.scrollTo({ x: nextIdx * width, animated: true });
                                setActiveImageIndex(nextIdx);
                            }}
                        >
                            <ChevronRight size={20} color="white" />
                        </Pressable>
                    )}

                    {/* Dynamic Image Slide Counter */}
                    <View style={styles.imageCounter}>
                        <Text style={styles.imageCounterText}>
                            {activeImageIndex + 1} / {hotelImages.length}
                        </Text>
                    </View>

                    {/* Floating Header Actions */}
                    <View style={styles.floatingHeader}>
                        <Pressable onPress={goBackToMapSearch} style={styles.roundBtn}>
                            <ChevronLeft size={24} color={isDark ? "#60a5fa" : "#2563eb"} />
                        </Pressable>
                        <View style={styles.headerRight}>
                            <Pressable style={styles.roundBtn} onPress={handleShare}>
                                <Share2 size={20} color={isDark ? "#60a5fa" : "#2563eb"} />
                            </Pressable>
                            <Pressable style={styles.roundBtn} onPress={toggleFavorite}>
                                <Heart
                                    size={20}
                                    color={isFavorite ? '#ef4444' : (isDark ? '#60a5fa' : '#2563eb')}
                                    fill={isFavorite ? '#ef4444' : 'transparent'}
                                />
                            </Pressable>
                        </View>
                    </View>
                </View>

                <View style={styles.content}>
                    {/* Hotel Title & Rating */}
                    <View style={styles.titleSection}>
                        <Text style={styles.hotelName}>{hotel.name}</Text>
                        <View style={styles.ratingRow}>
                            <StarRating rating={hotel.reviewRating || hotel.starRating || 0} size={20} />
                            <View>
                                <Text style={styles.reviewCount}>{hotel.reviewsCount || reviews.length || 0} verified reviews</Text>
                            </View>
                        </View>
                        <View style={styles.locationRow}>
                            <MapPin size={16} color="#64748b" />
                            <Text style={styles.addressText}>{hotel.address}, {hotel.city}</Text>
                        </View>
                    </View>

                    {/* Quick Info pills */}
                    {(() => {
                        const checks = [
                            { icon: Wifi, label: 'Free Wi-Fi', match: (n: string) => n.includes('wifi') || n.includes('wi-fi') || n.includes('wi_fi') || n.includes('internet') },
                            { icon: Coffee, label: 'Breakfast', match: (n: string) => n.includes('breakfast') || n.includes('coffee') },
                            { icon: Wind, label: 'AC', match: (n: string) => n.includes('air cond') || n.includes('air_cond') || n.includes('conditioning') || n.includes('aircon') || n.includes('climate') || n === 'ac' },
                            { icon: Tv, label: 'TV', match: (n: string) => n.includes('tv') || n.includes('television') || n.includes('satellite') || n.includes('cable') },
                        ];
                        return (
                            <ScrollView
                                horizontal
                                showsHorizontalScrollIndicator={false}
                                style={styles.infoPillRow}
                                contentContainerStyle={styles.infoPillRowContent}
                            >
                                {checks.map(({ icon: Icon, label, match }) => {
                                    const active = allFacilities.some((f: any) => match((typeof f === 'string' ? f : f.name || '').toLowerCase()));
                                    return (
                                        <View
                                            key={label}
                                            style={[
                                                styles.infoPill,
                                                active ? styles.infoPillActive : styles.infoPillInactive,
                                            ]}
                                        >
                                            <Icon
                                                size={13}
                                                color={isDark ? '#3b82f6' : '#2563eb'}
                                            />
                                            <Text style={[
                                                styles.infoPillText,
                                                active ? styles.infoPillTextActive : styles.infoPillTextInactive,
                                            ]}>
                                                {label}
                                            </Text>
                                        </View>
                                    );
                                })}
                            </ScrollView>
                        );
                    })()}

                    {/* Description */}
                    <View style={styles.section}>
                        <Text style={styles.sectionTitle}>About this property</Text>
                        <Text style={styles.descriptionText} numberOfLines={isDescriptionExpanded ? undefined : 5}>
                            {cleanDescription(hotel.description || hotel.details?.description || hotel.details?.hotelDescription) || "Experience luxury and comfort in the heart of the city. This property offers modern amenities, exceptional service, and a convenient location near major attractions."}
                        </Text>
                        <Pressable style={styles.readMore} onPress={() => {
                            LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
                            setIsDescriptionExpanded(!isDescriptionExpanded);
                        }}>
                            <Text style={styles.readMoreText}>{isDescriptionExpanded ? 'Show less' : 'Read more'}</Text>
                        </Pressable>
                    </View>

                    {/* ── Room Options / Selector ── */}
                    <View style={styles.section}>
                        <View style={styles.sectionHeaderRow}>
                            <Text style={[styles.sectionTitle, { marginBottom: 0 }]}>Select Your Room</Text>
                            {availableRooms.length > 0 && (
                                <View style={styles.amenityCountBadge}>
                                    <Text style={styles.amenityCountText}>{availableRooms.length}</Text>
                                </View>
                            )}
                        </View>
                        {availableRooms.length === 0 ? (
                            <View style={styles.noRoomsBox}>
                                <Text style={styles.noRoomsText}>No available rooms were found for these dates.</Text>
                                <Text style={styles.noRoomsHint}>Try adjusting your check-in/out dates or guest count.</Text>
                            </View>
                        ) : paginatedRooms.map((room: any, i: number) => {
                            const absoluteIndex = (currentRoomPage - 1) * ROOMS_PER_PAGE + i;
                            return (
                                <RoomCard
                                    key={room.selectorId || absoluteIndex}
                                    room={room}
                                    hotelThumbnail={hotelImages[absoluteIndex % Math.max(hotelImages.length, 1)] || hotelThumbnail}
                                    detailRooms={hotel.detailRooms}
                                    currency={currency}
                                    fromCurrency={params.currency as string || 'USD'}
                                    styles={styles}
                                    isSelected={selectedRoom?.selectorId === room.selectorId}
                                    onSelect={() => handleRoomSelect(room)}
                                />
                            );
                        })}

                        {totalRoomPages > 1 && (
                            <View style={styles.roomPagination}>
                                <Pressable
                                    style={[styles.roomPageBtn, currentRoomPage === 1 && styles.roomPageBtnDisabled]}
                                    disabled={currentRoomPage === 1}
                                    onPress={() => setRoomPage(p => Math.max(1, p - 1))}
                                >
                                    <ChevronLeft size={18} color={currentRoomPage === 1 ? (isDark ? '#475569' : '#cbd5e1') : '#3b82f6'} />
                                </Pressable>

                                <Text style={styles.roomPageInfo}>
                                    Page {currentRoomPage} of {totalRoomPages}
                                </Text>

                                <Pressable
                                    style={[styles.roomPageBtn, currentRoomPage === totalRoomPages && styles.roomPageBtnDisabled]}
                                    disabled={currentRoomPage === totalRoomPages}
                                    onPress={() => setRoomPage(p => Math.min(totalRoomPages, p + 1))}
                                >
                                    <ChevronRight size={18} color={currentRoomPage === totalRoomPages ? (isDark ? '#475569' : '#cbd5e1') : '#3b82f6'} />
                                </Pressable>
                            </View>
                        )}
                    </View>

                    {/* Property policies */}
                    <View style={styles.section}>
                        <Text style={styles.sectionTitle}>Property policies</Text>

                        {/* Check-in / Check-out — compact inline row */}
                        <View style={styles.policyTimeRow}>
                            <View style={styles.policyTimeCard}>
                                <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6, marginBottom: 4 }}>
                                    <LogIn size={13} color="#3b82f6" />
                                    <Text style={styles.policyTimeCardLabel}>Check-in</Text>
                                </View>
                                <Text style={[styles.policyTimeValue, !checkInTime && { fontSize: 13, color: isDark ? '#475569' : '#94a3b8' }]}>
                                    {checkInTime || 'Not specified'}
                                </Text>
                                <Text style={styles.policyTimeSub}>Earliest arrival</Text>
                            </View>
                            <View style={styles.policyTimeCard}>
                                <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6, marginBottom: 4 }}>
                                    <LogOut size={13} color="#3b82f6" />
                                    <Text style={styles.policyTimeCardLabel}>Check-out</Text>
                                </View>
                                <Text style={[styles.policyTimeValue, !checkOutTime && { fontSize: 13, color: isDark ? '#475569' : '#94a3b8' }]}>
                                    {checkOutTime || 'Not specified'}
                                </Text>
                                <Text style={styles.policyTimeSub}>Latest departure</Text>
                            </View>
                        </View>

                        {/* Cancellation policy — prefer selected room's rate, fall back to hotel level */}
                        {(() => {
                            const tag =
                                selectedRoom?.rates?.[0]?.cancellationPolicies?.refundableTag ||
                                selectedRoom?.cancellationPolicies?.refundableTag ||
                                hotel?.cancellationPolicies?.refundableTag;
                            const penalties = selectedRoom?.rates?.[0]?.cancellationPolicies?.cancelPolicyInfos ||
                                hotel?.cancellationPolicies?.cancelPolicyInfos || [];
                            if (!tag) return null;
                            const isRefundable = tag === 'RFN';
                            const firstPenalty = penalties[0];
                            return isRefundable ? (
                                <View style={[styles.policyAlertCard, styles.policyAlertGreen]}>
                                    <CheckCircle size={18} color="#059669" />
                                    <View style={{ flex: 1 }}>
                                        <Text style={[styles.policyAlertTitle, { color: '#059669' }]}>Free cancellation</Text>
                                        <Text style={[styles.policyAlertText, { color: isDark ? '#6ee7b7' : '#065f46' }]}>
                                            {firstPenalty?.cancelTime
                                                ? `Cancel free before ${new Date(firstPenalty.cancelTime).toLocaleDateString()}.`
                                                : 'This booking can be cancelled at no charge.'}
                                        </Text>
                                    </View>
                                </View>
                            ) : (
                                <View style={[styles.policyAlertCard, styles.policyAlertAmber]}>
                                    <AlertTriangle size={18} color="#d97706" />
                                    <View style={{ flex: 1 }}>
                                        <Text style={[styles.policyAlertTitle, { color: '#d97706' }]}>Non-refundable</Text>
                                        <Text style={[styles.policyAlertText, { color: isDark ? '#fbbf24' : '#92400e' }]}>
                                            {firstPenalty?.amount
                                                ? `Cancellation fee: ${currency.symbol}${Math.round(firstPenalty.amount)}.`
                                                : 'This rate cannot be cancelled or modified after booking.'}
                                        </Text>
                                    </View>
                                </View>
                            );
                        })()}

                        {/* Important instructions */}
                        {policyInstructions && (
                            <View style={[styles.policyAlertCard, { borderColor: isDark ? '#1e293b' : '#e2e8f0', backgroundColor: isDark ? '#0f172a' : '#f8fafc' }]}>
                                <Info size={18} color="#64748b" style={{ marginTop: 2 }} />
                                <View style={{ flex: 1 }}>
                                    <Text
                                        style={[styles.policyAlertText, { color: isDark ? '#94a3b8' : '#475569' }]}
                                        numberOfLines={isPolicyExpanded ? undefined : 3}
                                    >
                                        {policyInstructions}
                                    </Text>
                                    {policyInstructions.length > 120 && (
                                        <Pressable onPress={() => setIsPolicyExpanded(!isPolicyExpanded)} style={{ marginTop: 4 }}>
                                            <Text style={styles.readMoreText}>{isPolicyExpanded ? 'Show less' : 'Read more'}</Text>
                                        </Pressable>
                                    )}
                                </View>
                            </View>
                        )}
                    </View>

                    {/* Facilities / Amenities Section */}
                    <View style={styles.section}>
                        <View style={styles.sectionHeaderRow}>
                            <Text style={[styles.sectionTitle, { marginBottom: 0 }]}>Amenities & Facilities</Text>
                            {allFacilities.length > 0 && (
                                <View style={styles.amenityCountBadge}>
                                    <Text style={styles.amenityCountText}>{allFacilities.length}</Text>
                                </View>
                            )}
                        </View>
                        {allFacilities.length === 0 ? (
                            <View style={styles.noAmenitiesBox}>
                                <Text style={styles.noAmenitiesText}>No amenities listed for this property.</Text>
                            </View>
                        ) : (
                            <>
                                <View style={styles.amenityPillsWrap}>
                                    {allFacilities
                                        .slice(0, isFacilitiesExpanded ? undefined : 12)
                                        .map((facility: any, i: number) => {
                                            const name = typeof facility === 'string' ? facility : (facility.name || facility.label || '');
                                            if (!name) return null;
                                            const colors = getAmenityPillColors(name, isDark);
                                            return (
                                                <View key={i} style={[styles.amenityPill, { backgroundColor: colors.bg }]}>
                                                    {getAmenityIcon(name, 13, colors.text)}
                                                    <Text style={[styles.amenityPillText, { color: colors.text }]} numberOfLines={1}>{name}</Text>
                                                </View>
                                            );
                                        })}
                                </View>
                                {allFacilities.length > 12 && (
                                    <Pressable
                                        style={styles.seeMoreBtn}
                                        onPress={() => {
                                            LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
                                            setIsFacilitiesExpanded(!isFacilitiesExpanded);
                                        }}
                                    >
                                        <Text style={styles.seeMoreText}>
                                            {isFacilitiesExpanded ? 'Show less' : `See all ${allFacilities.length} amenities`}
                                        </Text>
                                        {isFacilitiesExpanded
                                            ? <ChevronUp size={14} color="#2563eb" />
                                            : <ChevronDown size={14} color="#2563eb" />}
                                    </Pressable>
                                )}
                            </>
                        )}
                    </View>

                    {/* Location / Where you'll be */}
                    {(() => {
                        const lat = hotel.latitude || hotel.details?.latitude || hotel.details?.location?.latitude || hotel.coordinates?.lat || 0;
                        const lng = hotel.longitude || hotel.details?.longitude || hotel.details?.location?.longitude || hotel.coordinates?.lng || 0;
                        if (!lat || !lng) return null;
                        return (
                            <View style={styles.section}>
                                <Text style={styles.sectionTitle}>Where you'll be</Text>
                                <View style={[styles.locationRow, { paddingHorizontal: 0, marginTop: 4, marginBottom: 12 }]}>
                                    <MapPin size={16} color="#64748b" />
                                    <Text style={styles.addressText} numberOfLines={2}>
                                        {hotel.address || 'Address unavailable'}{hotel.city ? `, ${hotel.city}` : ''}
                                    </Text>
                                </View>
                                <PropertyMapWebView
                                    latitude={Number(lat)}
                                    longitude={Number(lng)}
                                    hotelName={hotel.name}
                                    address={hotel.address}
                                    city={hotel.city}
                                    isDark={isDark}
                                />
                            </View>
                        );
                    })()}
                    {/* Reviews Section */}
                    {reviews.length > 0 && (
                        <View style={styles.section}>
                            <View style={styles.sectionHeader}>
                                <Text style={styles.sectionTitle}>Guest Reviews</Text>
                                <View style={styles.amenityCountBadge}>
                                    <Text style={styles.amenityCountText}>{reviews.length}</Text>
                                </View>
                            </View>
                            {reviews.slice(0, visibleReviewsCount).map((review: any, i: number) => (
                                <ReviewItem key={i} review={review} isLast={i === Math.min(reviews.length - 1, visibleReviewsCount - 1)} styles={styles} />
                            ))}
                            {reviews.length > 3 && (
                                <View style={styles.reviewPagination}>
                                    {visibleReviewsCount < reviews.length && (
                                        <Pressable
                                            style={styles.reviewPaginationBtn}
                                            onPress={() => {
                                                LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
                                                setVisibleReviewsCount(prev => Math.min(reviews.length, prev + 3));
                                            }}
                                        >
                                            <Text style={styles.reviewPaginationText}>Show more</Text>
                                            <ChevronDown size={14} color="#2563eb" />
                                        </Pressable>
                                    )}
                                    {visibleReviewsCount > 3 && (
                                        <Pressable
                                            style={styles.reviewPaginationBtn}
                                            onPress={() => {
                                                LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
                                                setVisibleReviewsCount(3);
                                            }}
                                        >
                                            <Text style={styles.reviewPaginationText}>Show less</Text>
                                            <ChevronUp size={14} color="#2563eb" />
                                        </Pressable>
                                    )}
                                </View>
                            )}
                        </View>
                    )}
                    {/* FAQ Section */}
                    {(() => {
                        const hasPets = allFacilities.some((f: any) => (typeof f === 'string' ? f : f.name || '').toLowerCase().includes('pet'));
                        const hasWifi = allFacilities.some((f: any) => { const n = (typeof f === 'string' ? f : f.name || '').toLowerCase(); return n.includes('wifi') || n.includes('wi-fi') || n.includes('internet'); });
                        const hasParking = allFacilities.some((f: any) => (typeof f === 'string' ? f : f.name || '').toLowerCase().includes('parking'));
                        const hasBreakfastFacility = allFacilities.some((f: any) => (typeof f === 'string' ? f : f.name || '').toLowerCase().includes('breakfast'));
                        const hasPool = allFacilities.some((f: any) => (typeof f === 'string' ? f : f.name || '').toLowerCase().includes('pool'));
                        const hasSmoking = allFacilities.some((f: any) => { const n = (typeof f === 'string' ? f : f.name || '').toLowerCase(); return n.includes('smoking area') || n.includes('designated smoking'); });

                        const faqItems = [
                            checkInTime || checkOutTime ? {
                                q: 'What are the check-in and check-out times?',
                                a: [checkInTime && `Check-in from ${checkInTime}.`, checkOutTime && `Check-out by ${checkOutTime}.`].filter(Boolean).join(' ') || 'Please contact the property for check-in/out times.',
                            } : null,
                            {
                                q: 'Is free Wi-Fi available?',
                                a: hasWifi ? 'Yes, free Wi-Fi is available at this property.' : 'Wi-Fi availability has not been confirmed. Please contact the property.',
                            },
                            {
                                q: 'Is breakfast included?',
                                a: hasBreakfastFacility ? 'Breakfast is available at this property. Check room rates for inclusion details.' : 'Breakfast is not listed as an included facility. It may be available for an extra charge.',
                            },
                            {
                                q: 'Is parking available?',
                                a: hasParking ? 'Parking is available at this property. Charges may apply.' : 'On-site parking is not listed. Please contact the property for nearby parking options.',
                            },
                            {
                                q: 'Are pets allowed?',
                                a: hasPets ? 'Pets are welcome on request. Additional charges may apply.' : 'Pets are not permitted at this property.',
                            },
                            {
                                q: 'Is there a swimming pool?',
                                a: hasPool ? 'Yes, this property has a swimming pool.' : 'This property does not list a swimming pool.',
                            },
                            {
                                q: 'Is this a non-smoking property?',
                                a: hasSmoking ? 'Designated smoking areas are available on the premises.' : 'This is a non-smoking property. Smoking is not permitted indoors.',
                            },
                            policyInstructions ? { q: 'Are there any special instructions for guests?', a: policyInstructions } : null,
                        ].filter(Boolean) as { q: string; a: string }[];

                        return (
                            <FaqSection faqs={faqItems} styles={styles} isDark={isDark} />
                        );
                    })()}
                </View>
            </ScrollView>

            {/* Bottom Sticky Booking Bar — solid, opaque */}
            <View style={styles.bookingBar}>
                <View style={{ flex: 1, marginRight: 12 }}>
                    {selectedRoom ? (() => {
                        const rateCcy = (
                            selectedRoom.rates?.[0]?.retailRate?.total?.[0]?.currency ||
                            selectedRoom.rates?.[0]?.retailRate?.total?.currency ||
                            selectedRoom.rates?.[0]?.currency ||
                            params.currency ||
                            'USD'
                        ).toUpperCase();
                        const rawAmt = Math.round(
                            selectedRoom.rates?.[0]?.retailRate?.total?.[0]?.amount ||
                            selectedRoom.rates?.[0]?.retailRate?.total?.amount ||
                            selectedRoom.rates?.[0]?.price?.amount ||
                            selectedRoom.rates?.[0]?.price || 0
                        );
                        const displayAmt = rateCcy !== currency.code.toUpperCase()
                            ? Math.round(convertCurrency(rawAmt, rateCcy, currency.code))
                            : rawAmt;
                        return (
                            <>
                                <Text style={styles.bookingPrice}>
                                    {currency.symbol}{displayAmt.toLocaleString()}
                                    <Text style={styles.bookingPriceSuffix}> / night</Text>
                                </Text>
                                <Text style={styles.bookingDates} numberOfLines={1}>
                                    {selectedRoom.rates?.[0]?.name || selectedRoom.roomName || selectedRoom.name || 'Room'} • {params.checkIn} → {params.checkOut}
                                </Text>
                            </>
                        );
                    })() : (
                        <>
                            <Text style={styles.bookingPricePlaceholder}>
                                Select a room to book
                            </Text>
                            <Text style={styles.bookingDates}>{params.checkIn} → {params.checkOut}</Text>
                        </>
                    )}
                </View>
                <Pressable
                    style={[styles.bookBtn, !selectedRoom && styles.bookBtnDisabled]}
                    onPress={handleBookNow}
                    disabled={!selectedRoom}
                >
                    <Text style={styles.bookBtnText}>Book Now</Text>
                </Pressable>
            </View>
        </View>
    );
}

const getStyles = (isDark: boolean, _bottomInset: number = 0) => StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: isDark ? '#020617' : '#f8fafc',
    },
    loadingContainer: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
    },
    errorContainer: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        padding: 20,
    },
    errorText: {
        fontSize: 16,
        color: isDark ? '#64748b' : '#94a3b8',
        marginBottom: 20,
    },
    backBtnLabel: {
        paddingHorizontal: 20,
        paddingVertical: 10,
        backgroundColor: '#2563eb',
        borderRadius: 8,
    },
    backBtnLabelText: {
        color: 'white',
        fontWeight: '600',
    },
    scrollView: {
        flex: 1,
    },
    imageContainer: {
        height: 350,
        position: 'relative',
    },
    headerImage: {
        width: width,
        height: 350,
    },
    imageDots: {
        position: 'absolute',
        bottom: 40,
        flexDirection: 'row',
        width: '100%',
        justifyContent: 'center',
        gap: 6,
        zIndex: 10,
    },
    dot: {
        width: 8,
        height: 8,
        borderRadius: 4,
        backgroundColor: 'rgba(255,255,255,0.4)',
        borderWidth: 1,
        borderColor: 'rgba(255,255,255,0.2)',
    },
    dotActive: {
        width: 10,
        height: 10,
        borderRadius: 5,
        backgroundColor: 'white',
        transform: [{ scale: 1.2 }],
    },
    floatingHeader: {
        position: 'absolute',
        top: Platform.OS === 'ios' ? 60 : 40,
        left: 0,
        right: 0,
        flexDirection: 'row',
        justifyContent: 'space-between',
        paddingHorizontal: 20,
    },
    headerRight: {
        flexDirection: 'row',
        gap: 12,
    },
    roundBtn: {
        width: 44,
        height: 44,
        borderRadius: 22,
        backgroundColor: 'rgba(255,255,255,0.9)',
        alignItems: 'center',
        justifyContent: 'center',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 4,
        elevation: 3,
    },
    content: {
        padding: 20,
        borderTopLeftRadius: 30,
        borderTopRightRadius: 30,
        backgroundColor: isDark ? '#020617' : '#f8fafc',
        marginTop: -30,
    },
    titleSection: {
        marginBottom: 24,
    },
    hotelName: {
        fontSize: 24,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
        marginBottom: 8,
    },
    ratingRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 12,
        marginBottom: 8,
    },

    ratingLabel: {
        fontSize: 16,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
    },
    reviewCount: {
        fontSize: 13,
        color: isDark ? '#64748b' : '#94a3b8',
    },
    locationRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 4,
    },
    addressText: {
        fontSize: 14,
        color: isDark ? '#94a3b8' : '#64748b',
        flex: 1,
    },
    infoPillRow: {
        marginBottom: 24,
    },
    infoPillRowContent: {
        flexDirection: 'row',
        gap: 8,
        paddingRight: 4,
    },
    infoPill: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 6,
        paddingHorizontal: 13,
        paddingVertical: 8,
        borderRadius: 20,
        borderWidth: 1,
    },
    infoPillActive: {
        backgroundColor: 'transparent',
        borderColor: isDark ? '#3b82f6' : '#2563eb',
    },
    infoPillInactive: {
        backgroundColor: 'transparent',
        borderColor: isDark ? '#3b82f6' : '#2563eb',
        opacity: 0.35,
    },
    infoPillText: {
        fontSize: 13,
        fontWeight: '600',
    },
    infoPillTextActive: {
        color: isDark ? '#3b82f6' : '#2563eb',
    },
    infoPillTextInactive: {
        color: isDark ? '#3b82f6' : '#2563eb',
    },
    section: {
        marginBottom: 32,
    },
    sectionHeader: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 10,
        marginBottom: 12,
    },
    sectionTitle: {
        fontSize: 18,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
        marginBottom: 12,
    },
    viewAllText: {
        color: '#2563eb',
        fontWeight: '600',
        fontSize: 14,
    },
    descriptionText: {
        fontSize: 15,
        lineHeight: 22,
        color: isDark ? '#94a3b8' : '#475569',
    },
    readMore: {
        marginTop: 8,
    },
    readMoreText: {
        color: '#2563eb',
        fontWeight: '600',
    },
    facilitiesList: {
        flexDirection: 'row',
        flexWrap: 'wrap',
        gap: 8,
    },
    facilityItem: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 6,
        backgroundColor: isDark ? '#1e293b' : '#f1f5f9',
        borderRadius: 20,
        paddingHorizontal: 12,
        paddingVertical: 8,
        borderWidth: 1,
        borderColor: isDark ? '#334155' : '#e2e8f0',
    },
    facilityText: {
        fontSize: 13,
        color: isDark ? '#cbd5e1' : '#475569',
        fontWeight: '500',
    },
    sectionHeaderRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 10,
        marginBottom: 14,
    },
    amenityCountBadge: {
        backgroundColor: '#2563eb',
        paddingHorizontal: 8,
        paddingVertical: 2,
        borderRadius: 10,
    },
    amenityCountText: {
        color: '#ffffff',
        fontSize: 12,
        fontWeight: '700',
    },
    facilitiesGrid: {
        flexDirection: 'row',
        flexWrap: 'wrap',
        gap: 8,
    },
    facilityGridItem: {
        width: (width - 40 - 8) / 2,
        flexDirection: 'row',
        alignItems: 'center',
        gap: 8,
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        borderRadius: 12,
        padding: 10,
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
    },
    facilityIconBox: {
        width: 34,
        height: 34,
        borderRadius: 9,
        backgroundColor: isDark ? '#172554' : '#dbeafe',
        alignItems: 'center',
        justifyContent: 'center',
        flexShrink: 0,
    },
    facilityGridText: {
        flex: 1,
        fontSize: 12,
        color: isDark ? '#cbd5e1' : '#475569',
        fontWeight: '500',
        lineHeight: 16,
    },
    seeMoreBtn: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 6,
        marginTop: 14,
        paddingVertical: 10,
        paddingHorizontal: 16,
        borderRadius: 12,
        borderWidth: 1,
        borderColor: isDark ? '#1e3a5f' : '#bfdbfe',
        backgroundColor: isDark ? '#172554' : '#eff6ff',
    },
    seeMoreText: {
        fontSize: 13,
        fontWeight: '700',
        color: '#2563eb',
    },
    roomBadgeRow: {
        flexDirection: 'row',
        flexWrap: 'wrap',
        gap: 4,
        marginVertical: 4,
    },
    roomBadgeSmall: {
        paddingHorizontal: 7,
        paddingVertical: 3,
        borderRadius: 6,
        backgroundColor: isDark ? '#1e293b' : '#f1f5f9',
    },
    roomBadgeGreen: {
        backgroundColor: isDark ? '#064e3b33' : '#d1fae5',
    },
    roomBadgeAmber: {
        backgroundColor: isDark ? '#78350f33' : '#fef3c7',
    },
    roomBadgeBlue: {
        backgroundColor: isDark ? '#1e3a5f33' : '#dbeafe',
    },
    roomBadgeSmallText: {
        fontSize: 10,
        fontWeight: '600',
        color: isDark ? '#94a3b8' : '#64748b',
    },
    noRoomsBox: {
        padding: 20,
        borderRadius: 14,
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
        backgroundColor: isDark ? '#0f172a' : '#f8fafc',
        alignItems: 'center',
    },
    noRoomsHint: {
        fontSize: 12,
        color: isDark ? '#475569' : '#94a3b8',
        marginTop: 4,
        textAlign: 'center',
    },
    roomPagination: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 16,
        marginTop: 4,
        marginBottom: 4,
    },
    roomPageBtn: {
        width: 40,
        height: 40,
        borderRadius: 12,
        alignItems: 'center',
        justifyContent: 'center',
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
    },
    roomPageBtnDisabled: {
        opacity: 0.5,
    },
    roomPageInfo: {
        fontSize: 13,
        fontWeight: '600',
        color: isDark ? '#cbd5e1' : '#475569',
        minWidth: 110,
        textAlign: 'center',
    },
    roomCard: {
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        borderRadius: 16,
        marginBottom: 12,
        overflow: 'hidden',
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
    },
    roomCardSelected: {
        borderColor: '#2563eb',
        shadowColor: '#2563eb',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.2,
        shadowRadius: 10,
        elevation: 5,
    },
    selectBtnSelected: {
        backgroundColor: '#1d4ed8',
    },
    noRoomsText: {
        color: isDark ? '#94a3b8' : '#64748b',
        fontSize: 14,
        marginTop: 8,
    },
    roomCardRow: {
        flexDirection: 'row',
    },
    roomImage: {
        width: 140,
        height: 150,
        borderTopLeftRadius: 16,
        borderBottomLeftRadius: 16,
        backgroundColor: isDark ? '#1e293b' : '#f1f5f9',
    },
    roomInfo: {
        flex: 1,
        padding: 12,
        justifyContent: 'space-between',
    },
    roomName: {
        fontSize: 14,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
        marginBottom: 4,
    },
    roomAmenityText: {
        fontSize: 12,
        color: isDark ? '#64748b' : '#94a3b8',
        marginBottom: 2,
    },
    roomBoardText: {
        fontSize: 11,
        color: '#10b981',
        fontWeight: '600',
        marginBottom: 4,
    },
    roomFooter: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginTop: 4,
    },
    roomPrice: {
        fontSize: 18,
        fontWeight: '800',
        color: '#2563eb',
    },
    perNight: {
        fontSize: 12,
        color: isDark ? '#64748b' : '#94a3b8',
    },
    selectBtn: {
        backgroundColor: '#2563eb',
        paddingHorizontal: 16,
        paddingVertical: 8,
        borderRadius: 10,
    },
    selectBtnText: {
        color: 'white',
        fontWeight: '700',
        fontSize: 12,
    },
    reviewItem: {
        paddingVertical: 10,
    },
    reviewDivider: {
        borderBottomWidth: 1,
        borderBottomColor: isDark ? '#1e293b' : '#f1f5f9',
    },
    reviewHeader: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: 6,
    },
    reviewerAvatar: {
        width: 30,
        height: 30,
        borderRadius: 15,
        backgroundColor: isDark ? '#1e293b' : '#e2e8f0',
        alignItems: 'center',
        justifyContent: 'center',
        marginRight: 8,
        overflow: 'hidden',
    },
    reviewerAvatarImage: {
        width: '100%',
        height: '100%',
    },
    avatarText: {
        fontSize: 12,
        fontWeight: '700',
        color: isDark ? '#94a3b8' : '#64748b',
    },
    reviewerInfo: {
        flex: 1,
    },
    reviewerName: {
        fontSize: 13,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
    },
    reviewDate: {
        fontSize: 11,
        color: isDark ? '#64748b' : '#94a3b8',
    },
    reviewScore: {
        width: 28,
        height: 28,
        borderRadius: 7,
        alignItems: 'center',
        justifyContent: 'center',
    },
    reviewScoreText: {
        color: 'white',
        fontSize: 12,
        fontWeight: 'bold',
    },
    reviewText: {
        fontSize: 13,
        lineHeight: 18,
        color: isDark ? '#cbd5e1' : '#475569',
    },
    reviewPagination: {
        flexDirection: 'row',
        justifyContent: 'center',
        gap: 16,
        marginTop: 10,
        paddingTop: 10,
        borderTopWidth: 1,
        borderTopColor: isDark ? '#1e293b' : '#f1f5f9',
    },
    reviewPaginationBtn: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 4,
        paddingVertical: 6,
        paddingHorizontal: 12,
        borderRadius: 8,
        backgroundColor: isDark ? '#172554' : '#eff6ff',
    },
    reviewPaginationText: {
        fontSize: 13,
        fontWeight: '600',
        color: '#2563eb',
    },
    policyItem: {
        flexDirection: 'row',
        gap: 16,
        marginBottom: 16,
    },
    policyContent: {
        flex: 1,
    },
    policyLabel: {
        fontSize: 14,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
        marginBottom: 2,
    },
    policyValue: {
        fontSize: 13,
        color: isDark ? '#94a3b8' : '#64748b',
        lineHeight: 18,
    },
    policyBadge: {
        alignSelf: 'flex-start',
        paddingHorizontal: 10,
        paddingVertical: 4,
        borderRadius: 12,
        marginVertical: 4,
    },
    policyRefundable: {
        backgroundColor: isDark ? '#064e3b44' : '#d1fae5',
    },
    policyNonRefundable: {
        backgroundColor: isDark ? '#78350f44' : '#fef3c7',
    },
    policyBadgeText: {
        fontSize: 12,
        fontWeight: '700',
    },
    bookingBar: {
        position: 'absolute',
        bottom: 0,
        left: 0,
        right: 0,
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        paddingHorizontal: 16,
        paddingTop: 10,
        paddingBottom: 10,
        borderTopWidth: 1,
        borderTopColor: isDark ? '#1e293b' : '#dbeafe',
        backgroundColor: isDark ? '#0c1a3a' : '#ffffff',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: -2 },
        shadowOpacity: isDark ? 0.3 : 0.08,
        shadowRadius: 6,
        elevation: 10,
    },
    bookingPrice: {
        fontSize: 16,
        fontWeight: '800',
        color: isDark ? '#60a5fa' : '#2563eb',
    },
    bookingPriceSuffix: {
        fontSize: 11,
        fontWeight: '500',
        color: isDark ? '#3b82f6' : '#3b82f6',
    },
    bookingPricePlaceholder: {
        fontSize: 13,
        fontWeight: '600',
        color: isDark ? '#3b82f6' : '#2563eb',
    },
    bookingDates: {
        fontSize: 10,
        color: isDark ? '#4e7dd4' : '#3b82f6',
        marginTop: 1,
    },
    bookBtn: {
        backgroundColor: '#2563eb',
        paddingHorizontal: 20,
        paddingVertical: 10,
        borderRadius: 12,
        shadowColor: '#2563eb',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.3,
        shadowRadius: 8,
        elevation: 6,
    },
    bookBtnDisabled: {
        backgroundColor: '#64748b',
        shadowOpacity: 0,
        elevation: 0,
    },
    bookBtnText: {
        color: 'white',
        fontWeight: '700',
        fontSize: 14,
    },
    sliderArrow: {
        position: 'absolute',
        top: 350 / 2 - 18,
        width: 36,
        height: 36,
        borderRadius: 18,
        backgroundColor: 'rgba(15, 23, 42, 0.6)',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 10,
    },
    sliderArrowLeft: {
        left: 12,
    },
    sliderArrowRight: {
        right: 12,
    },
    imageCounter: {
        position: 'absolute',
        bottom: 40,
        right: 12,
        backgroundColor: 'rgba(15, 23, 42, 0.75)',
        paddingHorizontal: 10,
        paddingVertical: 4,
        borderRadius: 12,
        zIndex: 10,
    },
    imageCounterText: {
        color: 'white',
        fontSize: 11,
        fontWeight: 'bold',
    },
    policyTimeRow: {
        flexDirection: 'row',
        gap: 12,
        marginBottom: 12,
    },
    policyTimeCard: {
        flex: 1,
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        borderRadius: 12,
        padding: 12,
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
    },
    policyTimeCardLabel: {
        fontSize: 10,
        color: '#3b82f6',
        fontWeight: '700',
        textTransform: 'uppercase',
        letterSpacing: 0.5,
    },
    policyTimeValue: {
        fontSize: 17,
        fontWeight: '800',
        color: isDark ? '#ffffff' : '#0f172a',
    },
    policyTimeSub: {
        fontSize: 11,
        color: isDark ? '#475569' : '#94a3b8',
        marginTop: 1,
    },
    policyAlertCard: {
        flexDirection: 'row',
        gap: 12,
        alignItems: 'flex-start',
        padding: 14,
        borderRadius: 14,
        borderWidth: 1,
        marginBottom: 12,
    },
    policyAlertAmber: {
        backgroundColor: isDark ? 'rgba(120, 53, 15, 0.3)' : '#fffbeb',
        borderColor: isDark ? 'rgba(180, 83, 9, 0.5)' : '#fde68a',
    },
    policyAlertGreen: {
        backgroundColor: isDark ? 'rgba(6, 78, 59, 0.3)' : '#ecfdf5',
        borderColor: isDark ? 'rgba(5, 150, 105, 0.5)' : '#a7f3d0',
    },
    policyAlertTitle: {
        fontSize: 14,
        fontWeight: '700',
        marginBottom: 2,
    },
    policyAlertText: {
        fontSize: 13,
        lineHeight: 18,
    },
    houseRuleCard: {
        flexDirection: 'row',
        alignItems: 'flex-start',
        gap: 12,
        paddingVertical: 10,
        paddingHorizontal: 12,
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        borderRadius: 12,
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
        marginBottom: 6,
    },
    houseRuleText: {
        flex: 1,
        fontSize: 13,
        color: isDark ? '#cbd5e1' : '#475569',
        lineHeight: 18,
    },
    houseRuleRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 10,
        paddingVertical: 8,
        borderBottomWidth: 1,
        borderBottomColor: isDark ? '#1e293b' : '#f1f5f9',
    },
    houseRuleIconWrap: {
        width: 26,
        height: 26,
        borderRadius: 8,
        backgroundColor: isDark ? '#1e293b' : '#f1f5f9',
        alignItems: 'center',
        justifyContent: 'center',
        flexShrink: 0,
    },
    houseRuleRowText: {
        flex: 1,
        fontSize: 13,
        color: isDark ? '#94a3b8' : '#475569',
    },
    amenityPillsWrap: {
        flexDirection: 'row',
        flexWrap: 'wrap',
        gap: 8,
    },
    amenityPill: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 5,
        paddingHorizontal: 11,
        paddingVertical: 6,
        borderRadius: 20,
    },
    amenityPillText: {
        fontSize: 12,
        fontWeight: '600',
    },
    noAmenitiesBox: {
        paddingVertical: 16,
        paddingHorizontal: 12,
        borderRadius: 12,
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
        backgroundColor: isDark ? '#0f172a' : '#f8fafc',
        alignItems: 'center',
    },
    noAmenitiesText: {
        fontSize: 13,
        color: isDark ? '#475569' : '#94a3b8',
    },
    faqItem: {
        paddingVertical: 12,
    },
    faqDivider: {
        borderBottomWidth: 1,
        borderBottomColor: isDark ? '#1e293b' : '#f1f5f9',
    },
    faqRow: {
        flexDirection: 'row',
        alignItems: 'flex-start',
        justifyContent: 'space-between',
        gap: 12,
    },
    faqQuestion: {
        flex: 1,
        fontSize: 14,
        fontWeight: '600',
        color: isDark ? '#e2e8f0' : '#0f172a',
        lineHeight: 20,
    },
    faqAnswer: {
        marginTop: 8,
        fontSize: 13,
        color: isDark ? '#94a3b8' : '#475569',
        lineHeight: 20,
    },
});
