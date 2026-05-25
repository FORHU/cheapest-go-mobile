import { BlurView } from 'expo-blur';
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
    Heart, HelpCircle,
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
    User,
    Utensils, Waves,
    Wifi, Wind,
    XCircle
} from 'lucide-react-native';
import React, { useCallback, useEffect, useMemo, useState, useRef } from 'react';
import { ActivityIndicator, Alert, Dimensions, Image, LayoutAnimation, Platform, Pressable, ScrollView, StyleSheet, Text, UIManager, useColorScheme, View } from 'react-native';

import PropertyMapWebView from '../../../components/search/PropertyMapWebView';
import OptimizedImage from '../../../components/ui/OptimizedImage';
import StarRating from '../../../components/ui/StarRating';
import { useSettings } from '../../../context/SettingsContext';
import { getHotelDetails, getHotelReviews } from '../../../lib/api';

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



const ReviewItem = React.memo(({ review, isLast, styles }: any) => {
    const [expanded, setExpanded] = useState(false);
    const content = stripHtml(review.pros || review.headline || "Excellent stay, very friendly staff and great location.");
    const isLong = content.length > 120;

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
                <StarRating rating={review.averageScore || 10} size={14} />
            </View>
            <Text style={styles.reviewText} numberOfLines={expanded ? undefined : 3}>
                {content}
            </Text>
            {isLong && (
                <Pressable onPress={() => setExpanded(!expanded)} style={{ marginTop: 4 }}>
                    <Text style={styles.readMoreText}>{expanded ? 'Show less' : 'Read more'}</Text>
                </Pressable>
            )}
        </View>
    );
});

const RoomCard = React.memo(({ room, hotelThumbnail, detailRooms, currency, styles, onSelect }: any) => {
    // Resolve room image via mappedRoomId -> detailRooms
    const mappedRoomId = room.rates?.[0]?.mappedRoomId;
    const matchedRoom = mappedRoomId && detailRooms
        ? detailRooms.find((dr: any) => String(dr.id) === String(mappedRoomId))
        : null;

    // Get photo from matched detailRoom — photos are normalized to { url } objects by the edge function
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

    const price = Math.round(room.rates?.[0]?.retailRate?.total?.[0]?.amount || room.rates?.[0]?.retailRate?.total?.amount || room.rates?.[0]?.price?.amount || room.rates?.[0]?.price || 0);
    const roomName = room.rates?.[0]?.name || room.name || matchedRoom?.roomName || 'Room';
    const maxOccupancy = room.rates?.[0]?.maxOccupancy || room.maxOccupancy || matchedRoom?.maxOccupancy || 2;
    const boardName = room.rates?.[0]?.boardName;
    const offerId = room.rates?.[0]?.offerId || room.offerId;
    const refundableTag = room.rates?.[0]?.cancellationPolicies?.refundableTag || room.cancellationPolicies?.refundableTag;

    return (
        <View style={styles.roomCard}>
            <View style={styles.roomCardRow}>
                <OptimizedImage uri={roomImage} style={styles.roomImage} type="room" />
                <View style={styles.roomInfo}>
                    <Text style={styles.roomName} numberOfLines={2}>{roomName}</Text>
                    <Text style={styles.roomAmenityText}>Max {maxOccupancy} guests</Text>
                    {boardName && <Text style={styles.roomBoardText}>{boardName}</Text>}
                    {refundableTag === 'RFN' && (
                        <Text style={[styles.roomBoardText, { color: '#10b981' }]}>✓ Free cancellation</Text>
                    )}
                    <View style={styles.roomFooter}>
                        <View>
                            <Text style={styles.roomPrice}>{currency.symbol}{price}</Text>
                            <Text style={styles.perNight}>per night</Text>
                        </View>
                        <Pressable
                            style={styles.selectBtn}
                            onPress={() => onSelect?.({ offerId, roomName, price })}
                        >
                            <Text style={styles.selectBtnText}>Select</Text>
                        </Pressable>
                    </View>
                </View>
            </View>
        </View>
    );
});

const GalleryImage = React.memo(({ uri, width }: { uri: string, width: number }) => {
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

    const [loading, setLoading] = useState(true);
    const [hotel, setHotel] = useState<any>(null);
    const [reviews, setReviews] = useState<any[]>([]);
    const [activeImageIndex, setActiveImageIndex] = useState(0);
    const [isDescriptionExpanded, setIsDescriptionExpanded] = useState(false);
    const [isFacilitiesExpanded, setIsFacilitiesExpanded] = useState(false);
    const [isPoliciesExpanded, setIsPoliciesExpanded] = useState(false);
    const [visibleReviewsCount, setVisibleReviewsCount] = useState(5);
    
    const galleryScrollRef = useRef<ScrollView>(null);

    const styles = useMemo(() => getStyles(isDark), [isDark]);

    // Merge hotelFacilities (full list from API) with facilities
    const allFacilities = useMemo(() => {
        return hotel?.hotelFacilities?.length > 0
            ? hotel.hotelFacilities
            : hotel?.facilities || [];
    }, [hotel]);

    const handleRoomSelect = useCallback(({ offerId, roomName, price }: any) => {
        router.push({
            pathname: '/checkout',
            params: {
                offerId,
                roomName,
                roomPrice: String(price),
                hotelName: hotel?.name || '',
                hotelImage: hotel?.thumbnailUrl || '',
                checkIn: params.checkIn as string || '',
                checkOut: params.checkOut as string || '',
                adults: params.adults as string || '2',
            },
        });
    }, [hotel, params, router]);

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
            } catch (err) {
                console.error('Failed to fetch hotel details:', err);
            } finally {
                setLoading(false);
            }
        };

        if (params.id) {
            fetchData();
        }
    }, [params.id]);

    if (loading) {
        return (
            <View style={styles.loadingContainer}>
                <ActivityIndicator size="large" color="#2563eb" />
            </View>
        );
    }

    if (!hotel) {
        return (
            <View style={styles.errorContainer}>
                <Text style={styles.errorText}>Hotel details not found.</Text>
                <Pressable onPress={() => router.back()} style={styles.backBtnLabel}>
                    <Text style={styles.backBtnLabelText}>Go Back</Text>
                </Pressable>
            </View>
        );
    }

    const rawImages = hotel.images || hotel.details?.hotelImages || hotel.details?.images || [];
    const validImages = Array.isArray(rawImages)
        ? rawImages.map((img: any) => typeof img === 'string' ? img : (img.url || img.urlHd || img.hdUrl || img.image || '')).filter((url: string) => url.trim().length > 0)
        : [];

    if (hotel.thumbnailUrl && !validImages.includes(hotel.thumbnailUrl)) {
        validImages.unshift(hotel.thumbnailUrl);
    }

    const hotelImages = validImages.length > 0
        ? validImages
        : [hotel.thumbnailUrl || 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=800&q=80'];

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
                        <Pressable onPress={() => router.back()} style={styles.roundBtn}>
                            <ChevronLeft size={24} color={isDark ? "#60a5fa" : "#2563eb"} />
                        </Pressable>
                        <View style={styles.headerRight}>
                            <Pressable style={styles.roundBtn}>
                                <Share2 size={20} color={isDark ? "#60a5fa" : "#2563eb"} />
                            </Pressable>
                            <Pressable style={styles.roundBtn}>
                                <Heart size={20} color={isDark ? "#f87171" : "#ef4444"} fill={false ? "#ef4444" : "transparent"} />
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

                    {/* Quick Info */}
                    <View style={styles.infoGrid}>
                        <View style={[styles.infoItem, !hotel.facilities?.some((f: any) => (f.name || f).toLowerCase().includes('wifi')) && { opacity: 0.3 }]}>
                            <Wifi size={20} color={isDark ? "#3b82f6" : "#2563eb"} />
                            <Text style={styles.infoLabel}>Free Wifi</Text>
                        </View>
                        <View style={[styles.infoItem, !hotel.facilities?.some((f: any) => (f.name || f).toLowerCase().includes('breakfast')) && { opacity: 0.3 }]}>
                            <Coffee size={20} color={isDark ? "#3b82f6" : "#2563eb"} />
                            <Text style={styles.infoLabel}>Breakfast</Text>
                        </View>
                        <View style={[styles.infoItem, !hotel.facilities?.some((f: any) => (f.name || f).toLowerCase().includes('air conditioning')) && { opacity: 0.3 }]}>
                            <Wind size={20} color={isDark ? "#3b82f6" : "#2563eb"} />
                            <Text style={styles.infoLabel}>AC</Text>
                        </View>
                        <View style={[styles.infoItem, !hotel.facilities?.some((f: any) => (f.name || f).toLowerCase().includes('tv')) && { opacity: 0.3 }]}>
                            <Tv size={20} color={isDark ? "#3b82f6" : "#2563eb"} />
                            <Text style={styles.infoLabel}>TV</Text>
                        </View>
                    </View>

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

                    {/* Property policies */}
                    <View style={styles.section}>
                        <Text style={styles.sectionTitle}>Property policies</Text>

                        {/* Check-in / Check-out time cards */}
                        <View style={styles.policyTimeRow}>
                            <View style={styles.policyTimeCard}>
                                <LogIn size={15} color="#3b82f6" />
                                <Text style={styles.policyTimeCardLabel}>Check-in</Text>
                                <Text style={styles.policyTimeValue}>
                                    {hotel.checkInTime || hotel.details?.checkIn?.schedule?.[0]?.startTime || '3:00 PM'}
                                </Text>
                                <Text style={styles.policyTimeSub}>Earliest arrival</Text>
                            </View>
                            <View style={styles.policyTimeCard}>
                                <LogOut size={15} color="#3b82f6" />
                                <Text style={styles.policyTimeCardLabel}>Check-out</Text>
                                <Text style={styles.policyTimeValue}>
                                    {hotel.checkOutTime || hotel.details?.checkOut?.schedule?.[0]?.startTime || '11:00 AM'}
                                </Text>
                                <Text style={styles.policyTimeSub}>Latest departure</Text>
                            </View>
                        </View>

                        {/* Cancellation policy */}
                        {hotel.cancellationPolicies && (
                            hotel.cancellationPolicies.refundableTag === 'RFN' ? (
                                <View style={[styles.policyAlertCard, styles.policyAlertGreen]}>
                                    <CheckCircle size={18} color="#059669" />
                                    <View style={{ flex: 1 }}>
                                        <Text style={[styles.policyAlertTitle, { color: '#059669' }]}>Free cancellation</Text>
                                        <Text style={[styles.policyAlertText, { color: isDark ? '#6ee7b7' : '#065f46' }]}>
                                            This booking can be cancelled at no charge.
                                        </Text>
                                    </View>
                                </View>
                            ) : (
                                <View style={[styles.policyAlertCard, styles.policyAlertAmber]}>
                                    <AlertTriangle size={18} color="#d97706" />
                                    <View style={{ flex: 1 }}>
                                        <Text style={[styles.policyAlertTitle, { color: '#d97706' }]}>Non-refundable booking</Text>
                                        <Text style={[styles.policyAlertText, { color: isDark ? '#fbbf24' : '#92400e' }]}>
                                            This rate cannot be cancelled or modified after booking.
                                        </Text>
                                    </View>
                                </View>
                            )
                        )}

                        {/* Important instructions */}
                        {(hotel.hotelImportantInformation || hotel.details?.importantInformation || hotel.details?.checkIn?.instructions) && (
                            <View style={[styles.policyAlertCard, { borderColor: isDark ? '#1e293b' : '#e2e8f0', backgroundColor: isDark ? '#0f172a' : '#f8fafc' }]}>
                                <Info size={18} color="#64748b" />
                                <Text style={[styles.policyAlertText, { flex: 1, color: isDark ? '#94a3b8' : '#475569' }]}>
                                    {cleanDescription(hotel.hotelImportantInformation || hotel.details?.importantInformation || hotel.details?.checkIn?.instructions?.[0]?.text || '')}
                                </Text>
                            </View>
                        )}
                    </View>

                    {/* House rules */}
                    <View style={styles.section}>
                        <Text style={styles.sectionTitle}>House rules</Text>
                        {([
                            { Icon: ShieldCheck, text: 'Valid photo ID matching the reservation name required at check-in.' },
                            { Icon: User, text: 'Minimum check-in age is 18–21. Contact the front desk in advance.' },
                            {
                                Icon: allFacilities.some((f: any) => (typeof f === 'string' ? f : f.name || '').toLowerCase().includes('pet')) ? Check : XCircle,
                                text: allFacilities.some((f: any) => (typeof f === 'string' ? f : f.name || '').toLowerCase().includes('pet'))
                                    ? 'Pets are allowed on request. Charges may apply.'
                                    : 'Pets are not permitted on the property.',
                            },
                            { Icon: CigaretteOff, text: 'This is a strictly non-smoking property.' },
                        ] as { Icon: any; text: string }[]).map(({ Icon, text }, i) => (
                            <View key={i} style={styles.houseRuleCard}>
                                <Icon size={18} color={isDark ? '#94a3b8' : '#64748b'} />
                                <Text style={styles.houseRuleText}>{text}</Text>
                            </View>
                        ))}
                    </View>

                    {/* Facilities / Amenities Section */}
                    {allFacilities.length > 0 && (
                        <View style={styles.section}>
                            <Text style={styles.sectionTitle}>Amenities & Facilities</Text>
                            <View style={styles.facilitiesList}>
                                {allFacilities.slice(0, isFacilitiesExpanded ? undefined : 12).map((facility: any, i: number) => {
                                    const name = typeof facility === 'string' ? facility : (facility.name || facility.label || '');
                                    if (!name) return null;
                                    return (
                                        <View key={i} style={styles.facilityItem}>
                                            {getAmenityIcon(name, 14, '#3b82f6')}
                                            <Text style={styles.facilityText} numberOfLines={1}>{name}</Text>
                                        </View>
                                    );
                                })}
                            </View>
                            {allFacilities.length > 12 && (
                                <Pressable
                                    style={styles.viewMoreBtn}
                                    onPress={() => {
                                        LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
                                        setIsFacilitiesExpanded(!isFacilitiesExpanded);
                                    }}
                                >
                                    <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                                        <Text style={styles.viewMoreText}>
                                            {isFacilitiesExpanded ? 'Show less' : `View all ${allFacilities.length} amenities`}
                                        </Text>
                                        {isFacilitiesExpanded
                                            ? <ChevronUp size={16} color={isDark ? '#e2e8f0' : '#475569'} />
                                            : <ChevronDown size={16} color={isDark ? '#e2e8f0' : '#475569'} />
                                        }
                                    </View>
                                </Pressable>
                            )}
                        </View>
                    )}

                    {/* Location / Where you'll be */}
                    {(() => {
                        // Resolve coordinates from various possible API response shapes (top level, nested details, location, or coordinates object)
                        const lat = hotel.latitude || hotel.details?.latitude || hotel.details?.location?.latitude || hotel.coordinates?.lat || 0;
                        const lng = hotel.longitude || hotel.details?.longitude || hotel.details?.location?.longitude || hotel.coordinates?.lng || 0;
                        console.log(`[PropertyDetails] Coordinates for ${hotel.name}: lat=${lat}, lng=${lng}`);
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

                    {/* Room Options */}
                    <View style={styles.section}>
                        <Text style={styles.sectionTitle}>Available Rooms</Text>
                        {(hotel.roomTypes || []).map((room: any, i: number) => (
                            <RoomCard
                                key={i}
                                room={room}
                                hotelThumbnail={hotel.thumbnailUrl}
                                detailRooms={hotel.detailRooms}
                                currency={currency}
                                styles={styles}
                                onSelect={handleRoomSelect}
                            />
                        ))}
                    </View>
                    {/* Reviews Section */}
                    {reviews.length > 0 && (
                        <View style={styles.section}>
                            <View style={styles.sectionHeader}>
                                <Text style={styles.sectionTitle}>Guest Reviews ({reviews.length})</Text>
                            </View>
                            {reviews.slice(0, visibleReviewsCount).map((review: any, i: number) => (
                                <ReviewItem key={i} review={review} isLast={i === Math.min(reviews.length - 1, visibleReviewsCount - 1)} styles={styles} />
                            ))}
                            {reviews.length > 5 && (
                                <View style={{ alignItems: 'center', marginTop: 16 }}>
                                    <View style={{ flexDirection: 'row', gap: 24, justifyContent: 'center' }}>
                                        {visibleReviewsCount < reviews.length && (
                                            <Pressable
                                                style={{ paddingVertical: 8, flexDirection: 'row', alignItems: 'center', gap: 6 }}
                                                onPress={() => {
                                                    LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
                                                    setVisibleReviewsCount(prev => Math.min(reviews.length, prev + 5));
                                                }}
                                            >
                                                <Text style={{ color: '#2563eb', fontWeight: '600', fontSize: 15 }}>Show More</Text>
                                                <ChevronDown size={16} color="#2563eb" />
                                            </Pressable>
                                        )}
                                        {visibleReviewsCount > 5 && (
                                            <Pressable
                                                style={{ paddingVertical: 8, flexDirection: 'row', alignItems: 'center', gap: 6 }}
                                                onPress={() => {
                                                    LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
                                                    setVisibleReviewsCount(5);
                                                }}
                                            >
                                                <Text style={{ color: '#2563eb', fontWeight: '600', fontSize: 15 }}>Show Less</Text>
                                                <ChevronUp size={16} color="#2563eb" />
                                            </Pressable>
                                        )}
                                    </View>
                                    <Text style={{ 
                                        color: isDark ? '#64748b' : '#94a3b8', 
                                        fontSize: 13, 
                                        marginTop: 4, 
                                        fontWeight: '500' 
                                    }}>
                                        {Math.min(visibleReviewsCount, reviews.length)} out of {reviews.length}
                                    </Text>
                                </View>
                            )}
                        </View>
                    )}
                </View>
            </ScrollView>

            {/* Bottom Sticky Booking Bar */}
            <BlurView intensity={80} tint={isDark ? "dark" : "light"} style={styles.bookingBar}>
                <View>
                    <Text style={styles.bookingPrice}>From {currency.symbol}{Math.round(hotel.price?.amount || hotel.roomTypes?.[0]?.rates?.[0]?.retailRate?.total?.[0]?.amount || 0)}</Text>
                    <Text style={styles.bookingDates}>{params.checkIn} - {params.checkOut}</Text>
                </View>
                <Pressable style={styles.bookBtn} onPress={() => {
                    const firstRoom = hotel.roomTypes?.[0];
                    const rate = firstRoom?.rates?.[0];
                    if (rate?.offerId) {
                        router.push({
                            pathname: '/checkout',
                            params: {
                                offerId: rate.offerId,
                                roomName: rate.name || firstRoom?.name || 'Room',
                                roomPrice: String(Math.round(rate.retailRate?.total?.[0]?.amount || rate.retailRate?.total?.amount || rate.price?.amount || rate.price || 0)),
                                hotelName: hotel.name,
                                hotelImage: hotel.thumbnailUrl || '',
                                checkIn: params.checkIn as string || '',
                                checkOut: params.checkOut as string || '',
                                adults: params.adults as string || '2',
                            },
                        });
                    } else {
                        Alert.alert('No Rooms', 'Please select a room from the list above.');
                    }
                }}>
                    <Text style={styles.bookBtnText}>Book Now</Text>
                </Pressable>
            </BlurView>
        </View>
    );
}

const getStyles = (isDark: boolean) => StyleSheet.create({
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
    infoGrid: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        padding: 16,
        borderRadius: 20,
        marginBottom: 24,
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
    },
    infoItem: {
        flex: 1,
        alignItems: 'center',
        gap: 6,
    },
    infoLabel: {
        fontSize: 12,
        color: isDark ? '#94a3b8' : '#64748b',
    },
    section: {
        marginBottom: 32,
    },
    sectionHeader: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: 16,
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
    viewMoreBtn: {
        marginTop: 16,
        padding: 12,
        borderRadius: 12,
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
        alignItems: 'center',
    },
    viewMoreText: {
        color: isDark ? '#e2e8f0' : '#475569',
        fontWeight: '600',
        fontSize: 13,
    },
    roomCard: {
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        borderRadius: 16,
        marginBottom: 12,
        overflow: 'hidden',
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
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
        paddingVertical: 16,
    },
    reviewDivider: {
        borderBottomWidth: 1,
        borderBottomColor: isDark ? '#1e293b' : '#e2e8f0',
    },
    reviewHeader: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        marginBottom: 12,
    },
    reviewerAvatar: {
        width: 40,
        height: 40,
        borderRadius: 20,
        backgroundColor: isDark ? '#1e293b' : '#e2e8f0',
        alignItems: 'center',
        justifyContent: 'center',
        marginRight: 12,
        overflow: 'hidden',
    },
    reviewerAvatarImage: {
        width: '100%',
        height: '100%',
    },
    avatarText: {
        fontSize: 16,
        fontWeight: '700',
        color: isDark ? '#94a3b8' : '#64748b',
    },
    reviewerInfo: {
        flex: 1,
    },
    reviewerName: {
        fontSize: 15,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
    },
    reviewDate: {
        fontSize: 12,
        color: isDark ? '#64748b' : '#94a3b8',
    },
    reviewScore: {
        width: 32,
        height: 32,
        borderRadius: 8,
        alignItems: 'center',
        justifyContent: 'center',
    },
    reviewScoreText: {
        color: 'white',
        fontSize: 14,
        fontWeight: 'bold',
    },
    reviewText: {
        fontSize: 14,
        lineHeight: 20,
        color: isDark ? '#cbd5e1' : '#475569',
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
        paddingHorizontal: 24,
        paddingTop: 16,
        paddingBottom: Platform.OS === 'ios' ? 40 : 20,
        borderTopWidth: 1,
        borderTopColor: isDark ? '#1e293b' : '#e2e8f0',
    },
    bookingPrice: {
        fontSize: 20,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
    },
    bookingDates: {
        fontSize: 12,
        color: isDark ? '#64748b' : '#94a3b8',
    },
    bookBtn: {
        backgroundColor: '#2563eb',
        paddingHorizontal: 24,
        paddingVertical: 14,
        borderRadius: 16,
        shadowColor: '#2563eb',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.3,
        shadowRadius: 8,
        elevation: 6,
    },
    bookBtnText: {
        color: 'white',
        fontWeight: '700',
        fontSize: 16,
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
        borderRadius: 16,
        padding: 16,
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
        gap: 2,
    },
    policyTimeCardLabel: {
        fontSize: 11,
        color: '#3b82f6',
        fontWeight: '600',
        textTransform: 'uppercase',
        letterSpacing: 0.5,
        marginTop: 6,
        marginBottom: 2,
    },
    policyTimeValue: {
        fontSize: 22,
        fontWeight: '800',
        color: isDark ? '#ffffff' : '#0f172a',
    },
    policyTimeSub: {
        fontSize: 12,
        color: isDark ? '#475569' : '#94a3b8',
        marginTop: 2,
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
        alignItems: 'center',
        gap: 14,
        padding: 14,
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        borderRadius: 14,
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
        marginBottom: 8,
    },
    houseRuleText: {
        flex: 1,
        fontSize: 14,
        color: isDark ? '#cbd5e1' : '#475569',
        lineHeight: 20,
    },
});
