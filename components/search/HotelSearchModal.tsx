import * as Location from 'expo-location';
import { useRouter } from 'expo-router';
import {
    Building2,
    ChevronRight,
    Clock,
    MapPin,
    Moon,
    TrendingUp,
    Users,
    X,
} from 'lucide-react-native';
import React, { useEffect, useState } from 'react';
import {
    ActivityIndicator,
    Pressable,
    ScrollView,
    StyleSheet,
    Text,
    TextInput,
    useColorScheme,
    View
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useSettings } from '../../context/SettingsContext';
import { autocompleteDestinations, Destination } from '../../lib/api';
import { getRecentSearches, RecentSearch, saveRecentSearch } from '../../lib/search-history';
import CalendarPicker from './CalendarPicker';
import SearchModal from './SearchModal';

// ─── Popular destinations ──────────────────────────────────────────────────
const POPULAR_DESTINATIONS: Destination[] = [
    { type: 'city', title: 'Bangkok',        subtitle: 'Thailand',     id: 'ChIJ82ENKDJgHTERIEjiXbIAAQE', countryCode: 'TH' },
    { type: 'city', title: 'Baguio City',    subtitle: 'Philippines',  id: 'ChIJP_HeeWihkTMRwHU6vjT13o4', countryCode: 'PH' },
    { type: 'city', title: 'Singapore',      subtitle: 'Singapore',    id: 'ChIJdZOSAqgZ2jERMCXo9bBVMKE', countryCode: 'SG' },
    { type: 'city', title: 'Tokyo',          subtitle: 'Japan',        id: 'ChIJ51cu8IcbXWARiRtXIothAS4', countryCode: 'JP' },
    { type: 'city', title: 'Kuala Lumpur',   subtitle: 'Malaysia',     id: 'ChIJ-3ewCN0fMzYRpR50P1WnLNs', countryCode: 'MY' },
    { type: 'city', title: 'Cebu City',      subtitle: 'Philippines',  id: 'ChIJvRKrsd9RqTMRxBOZiPa5MsU', countryCode: 'PH' },
];

// ─── Children age options ──────────────────────────────────────────────────
const CHILD_AGES = [
    { label: '< 1 yr',  value: 0 },
    { label: '1 yr',    value: 1 },
    { label: '2 yrs',   value: 2 },
    { label: '3 yrs',   value: 3 },
    { label: '4 yrs',   value: 4 },
    { label: '5 yrs',   value: 5 },
    { label: '6 yrs',   value: 6 },
    { label: '7 yrs',   value: 7 },
    { label: '8 yrs',   value: 8 },
    { label: '9 yrs',   value: 9 },
    { label: '10 yrs',  value: 10 },
    { label: '11 yrs',  value: 11 },
    { label: '12 yrs',  value: 12 },
    { label: '13 yrs',  value: 13 },
    { label: '14 yrs',  value: 14 },
    { label: '15 yrs',  value: 15 },
    { label: '16 yrs',  value: 16 },
    { label: '17 yrs',  value: 17 },
];

interface HotelSearchModalProps {
    visible: boolean;
    onClose: () => void;
    initialParams?: any;
}

const HotelSearchModal: React.FC<HotelSearchModalProps> = ({ visible, onClose, initialParams }) => {
    const colorScheme = useColorScheme();
    const isDark      = colorScheme === 'dark';
    const insets      = useSafeAreaInsets();
    const router      = useRouter();
    const { currency } = useSettings();

    // ── Form state ─────────────────────────────────────────────────────────
    const [destination, setDestination]   = useState<Destination | null>(null);
    const [destQuery,   setDestQuery]     = useState('');
    const [checkIn,     setCheckIn]       = useState<Date | null>(null);
    const [checkOut,    setCheckOut]      = useState<Date | null>(null);
    const [adults,      setAdults]        = useState(2);
    const [children,    setChildren]      = useState(0);
    const [childrenAges, setChildrenAges] = useState<number[]>([]);
    const [rooms,       setRooms]         = useState(1);
    const [activeField, setActiveField]   = useState<string | null>(null);

    useEffect(() => {
        if (initialParams) {
            if (initialParams.destination) {
                setDestination({
                    type: 'city',
                    title: initialParams.destination,
                    subtitle: initialParams.countryCode || '',
                    id: initialParams.placeId || '',
                    countryCode: initialParams.countryCode || ''
                });
                setDestQuery(initialParams.destination);
            }
            if (initialParams.checkIn) setCheckIn(new Date(initialParams.checkIn));
            if (initialParams.checkOut) setCheckOut(new Date(initialParams.checkOut));
            if (initialParams.adults) setAdults(parseInt(initialParams.adults));
            if (initialParams.children) setChildren(parseInt(initialParams.children));
            if (initialParams.childrenAges) setChildrenAges(initialParams.childrenAges.split(',').map(Number));
            if (initialParams.rooms) setRooms(parseInt(initialParams.rooms));
        }
    }, [initialParams]);

    // ── Async state ────────────────────────────────────────────────────────
    const [suggestions,        setSuggestions]        = useState<Destination[]>([]);
    const [loadingAutocomplete, setLoadingAutocomplete] = useState(false);
    const [isSearching,        setIsSearching]        = useState(false);
    const [recentSearches,     setRecentSearches]     = useState<RecentSearch[]>([]);

    // ── Validation errors ──────────────────────────────────────────────────
    const [errors, setErrors] = useState<{ destination?: string; dates?: string }>({});
    const [hoverDate, setHoverDate] = useState<Date | null>(null);

    const styles = getStyles(isDark, insets.bottom);

    // ── Load recent searches on open ───────────────────────────────────────
    useEffect(() => {
        if (visible) {
            getRecentSearches().then(setRecentSearches).catch(() => {});
        }
    }, [visible]);

    const handleNearMe = async () => {
        try {
            setLoadingAutocomplete(true);
            const { status } = await Location.requestForegroundPermissionsAsync();
            if (status !== 'granted') {
                alert('Permission to access location was denied');
                return;
            }

            const loc = await Location.getCurrentPositionAsync({});
            const reverse = await Location.reverseGeocodeAsync({
                latitude: loc.coords.latitude,
                longitude: loc.coords.longitude
            });

            if (reverse && reverse.length > 0) {
                const place = reverse[0];
                const city = place.city || place.region || place.name || 'Current Location';
                const country = place.country || '';
                
                const nearMeDest: Destination = {
                    type: 'city',
                    title: city,
                    subtitle: country,
                    id: `near-me-${loc.coords.latitude}-${loc.coords.longitude}`,
                    countryCode: place.isoCountryCode || '',
                    latitude: loc.coords.latitude,
                    longitude: loc.coords.longitude
                };
                
                setDestination(nearMeDest);
                setDestQuery(city);
                setActiveField(null);
            }
        } catch (e) {
            console.error('Error getting location', e);
        } finally {
            setLoadingAutocomplete(false);
        }
    };

    // ── Debounced autocomplete ─────────────────────────────────────────────
    useEffect(() => {
        if (destQuery.length < 2) { setSuggestions([]); return; }
        const timer = setTimeout(async () => {
            setLoadingAutocomplete(true);
            try {
                const results = await autocompleteDestinations(destQuery);
                setSuggestions(results);
            } catch (e) {
                console.error(e);
            } finally {
                setLoadingAutocomplete(false);
            }
        }, 400);
        return () => clearTimeout(timer);
    }, [destQuery]);

    // ── Helpers ────────────────────────────────────────────────────────────
    const formatDateLocal = (d: Date) =>
        `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

    const formatDateShort = (date: Date | null) => {
        if (!date) return null;
        return date.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });
    };

    const formatDateRecentShort = (dateStr: string) => {
        const d = new Date(dateStr + 'T00:00:00');
        return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    };

    const nightCount = checkIn && checkOut
        ? Math.round((checkOut.getTime() - checkIn.getTime()) / (1000 * 60 * 60 * 24))
        : 0;

    const guestSummary = [
        `${adults} adult${adults !== 1 ? 's' : ''}`,
        children > 0 ? `${children} child${children !== 1 ? 'ren' : ''}` : '',
        `${rooms} room${rooms !== 1 ? 's' : ''}`,
    ].filter(Boolean).join(' · ');

    // Adjust children ages array when children count changes
    const handleSetChildren = (count: number) => {
        setChildren(count);
        setChildrenAges(prev => {
            if (count > prev.length) {
                return [...prev, ...Array(count - prev.length).fill(5)];
            }
            return prev.slice(0, count);
        });
    };

    const handleSelectDestination = (dest: Destination) => {
        setDestination(dest);
        setDestQuery(dest.title);
        setSuggestions([]);
        setErrors(e => ({ ...e, destination: undefined }));
        setActiveField('dates');
    };

    const handleSelectRecent = (recent: RecentSearch) => {
        setDestination({ type: 'city', title: recent.destination, subtitle: '', id: recent.placeId || '', countryCode: recent.countryCode || '' });
        setDestQuery(recent.destination);
        setCheckIn(new Date(recent.checkIn + 'T00:00:00'));
        setCheckOut(new Date(recent.checkOut + 'T00:00:00'));
        setAdults(recent.adults);
        setRooms(recent.rooms);
        setActiveField(null);
        setErrors({});
    };

    const handleClearAll = () => {
        setDestination(null);
        setDestQuery('');
        setCheckIn(null);
        setCheckOut(null);
        setAdults(2);
        setChildren(0);
        setChildrenAges([]);
        setRooms(1);
        setActiveField(null);
        setErrors({});
        setSuggestions([]);
    };

    const hasValue = !!(destination || destQuery || checkIn || checkOut || adults !== 2 || children > 0);

    // ── Validate and search ────────────────────────────────────────────────
    const handleSearch = async () => {
        const newErrors: typeof errors = {};
        const destValue = (destination?.title || destQuery).trim();
        if (!destValue) newErrors.destination = 'Please enter a destination';
        if (!checkIn || !checkOut) newErrors.dates = 'Please select your check-in and check-out dates';
        if (Object.keys(newErrors).length > 0) {
            setErrors(newErrors);
            // Auto-expand the first failing field
            if (newErrors.destination) setActiveField('where');
            else if (newErrors.dates) setActiveField('checkin');
            return;
        }

        setIsSearching(true);
        const params = {
            destination:     destValue,
            countryCode:     destination?.countryCode || '',
            placeId:         destination?.id || '',   // Mapbox ID (web autocomplete)
            destinationCode: destination?.code || '', // TGX code (TGX fallback)
            checkIn:         formatDateLocal(checkIn!),
            checkOut:        formatDateLocal(checkOut!),
            adults:          adults.toString(),
            children:        children.toString(),
            childrenAges:    childrenAges.join(','),
            rooms:           rooms.toString(),
            currency:        currency.code,
        };
        await saveRecentSearch({
            destination: destValue,
            countryCode: destination?.countryCode || '',
            placeId:     destination?.id || '',
            checkIn:     params.checkIn,
            checkOut:    params.checkOut,
            adults,
            rooms,
        });
        onClose();
        // @ts-ignore
        router.push({ pathname: '/search', params });
        setIsSearching(false);
    };

    // ── Derived display values ─────────────────────────────────────────────
    const checkInDisplay  = formatDateShort(checkIn);
    const checkOutDisplay = formatDateShort(checkOut);

    return (
        <SearchModal visible={visible} onClose={onClose} title="Search Hotels">
            <ScrollView
                style={styles.scrollView}
                contentContainerStyle={styles.scrollContent}
                keyboardShouldPersistTaps="handled"
            >
                {/* ── Subtitle + Clear ──────────────────────────────── */}
                <View style={styles.headerRow}>
                    <Text style={styles.subtitle}>Find your perfect stay</Text>
                    {hasValue && (
                        <Pressable onPress={handleClearAll} style={styles.clearButton}>
                            <X size={12} color={isDark ? '#94a3b8' : '#64748b'} />
                            <Text style={styles.clearText}>Clear all</Text>
                        </Pressable>
                    )}
                </View>

                {/* ══ WHERE ══════════════════════════════════════════ */}
                <Pressable
                    style={[
                        styles.fieldCard,
                        activeField === 'where' && styles.fieldCardActive,
                        !!errors.destination && styles.fieldCardError,
                    ]}
                    onPress={() => setActiveField(activeField === 'where' ? null : 'where')}
                >
                    {activeField === 'where' ? (
                        <View style={styles.expandedField}>
                            <Text style={styles.expandedTitle}>Where to?</Text>
                            <View style={styles.inputRow}>
                                <MapPin size={16} color="#3b82f6" />
                                <TextInput
                                    style={styles.textInput}
                                    placeholder="City, region or hotel"
                                    placeholderTextColor={isDark ? '#475569' : '#94a3b8'}
                                    value={destQuery}
                                    onChangeText={(text) => {
                                        setDestQuery(text);
                                        if (destination) setDestination(null);
                                        setErrors(e => ({ ...e, destination: undefined }));
                                    }}
                                    autoFocus
                                />
                                {loadingAutocomplete
                                    ? <ActivityIndicator size="small" color="#3b82f6" />
                                    : destQuery.length > 0 && (
                                        <Pressable onPress={() => {
                                            setDestQuery('');
                                            setDestination(null);
                                            setSuggestions([]);
                                        }}>
                                            <X size={16} color={isDark ? '#475569' : '#94a3b8'} />
                                        </Pressable>
                                    )
                                }
                            </View>

                            {/* Autocomplete suggestions */}
                            {suggestions.length > 0 && (
                                <View style={styles.suggestionsContainer}>
                                    {suggestions.map((item, i) => (
                                        <Pressable
                                            key={`${item.title}-${i}`}
                                            onPress={() => handleSelectDestination(item)}
                                            style={[styles.suggestionItem, i < suggestions.length - 1 && styles.suggestionBorder]}
                                        >
                                            <View style={styles.suggestionIcon}>
                                                <Building2 size={14} color={isDark ? '#64748b' : '#94a3b8'} />
                                            </View>
                                            <View style={styles.suggestionText}>
                                                <Text style={styles.suggestionTitle}>{item.title}</Text>
                                                <Text style={styles.suggestionSubtitle} numberOfLines={1}>{item.subtitle}</Text>
                                            </View>
                                            <ChevronRight size={14} color={isDark ? '#334155' : '#cbd5e1'} />
                                        </Pressable>
                                    ))}
                                </View>
                            )}

                            {destQuery.length === 0 && (
                                <>
                                    {/* Recent searches */}
                                    {recentSearches.length > 0 && (
                                        <View style={styles.sectionBlock}>
                                            <Text style={styles.sectionLabel}>Recent</Text>
                                            {recentSearches.slice(0, 4).map((r) => (
                                                <Pressable
                                                    key={r.id || `${r.destination}-${r.checkIn}`}
                                                    onPress={() => handleSelectRecent(r)}
                                                    style={styles.recentItem}
                                                >
                                                    <View style={styles.recentIcon}>
                                                        <Clock size={13} color={isDark ? '#64748b' : '#94a3b8'} />
                                                    </View>
                                                    <View style={styles.recentText}>
                                                        <Text style={styles.recentDestination}>{r.destination}</Text>
                                                        <Text style={styles.recentDetails}>
                                                            {formatDateRecentShort(r.checkIn)} – {formatDateRecentShort(r.checkOut)}
                                                            {'  ·  '}{r.adults} guest{r.adults !== 1 ? 's' : ''}
                                                            {'  ·  '}{r.rooms} room{r.rooms !== 1 ? 's' : ''}
                                                        </Text>
                                                    </View>
                                                    <ChevronRight size={13} color={isDark ? '#334155' : '#cbd5e1'} />
                                                </Pressable>
                                            ))}
                                        </View>
                                    )}

                                    {/* Popular destinations */}
                                    <View style={styles.sectionBlock}>
                                        <Text style={styles.sectionLabel}>Popular destinations</Text>
                                        <View style={styles.popularGrid}>
                                            {POPULAR_DESTINATIONS.map((dest) => (
                                                <Pressable
                                                    key={dest.id || dest.title}
                                                    onPress={() => handleSelectDestination(dest)}
                                                    style={styles.popularItem}
                                                >
                                                    <TrendingUp size={13} color="#3b82f6" />
                                                    <Text style={styles.popularItemText}>{dest.title}</Text>
                                                </Pressable>
                                            ))}
                                        </View>
                                    </View>
                                </>
                            )}
                        </View>
                    ) : (
                        <View style={styles.collapsedField}>
                            <View style={styles.fieldIconLabel}>
                                <MapPin size={14} color={isDark ? '#475569' : '#94a3b8'} />
                                <Text style={styles.fieldLabel}>DESTINATION</Text>
                            </View>
                            <Text
                                style={[styles.fieldValue, !(destination?.title || destQuery) && styles.fieldPlaceholder]}
                                numberOfLines={1}
                            >
                                {destination?.title || destQuery || 'Where are you going?'}
                            </Text>
                        </View>
                    )}
                </Pressable>
                {errors.destination && <Text style={styles.errorText}>{errors.destination}</Text>}

                {/* ══ DATES ═════════════════════════════════════════ */}
                <Pressable
                    style={[
                        styles.fieldCard,
                        (activeField === 'checkin' || activeField === 'checkout') && styles.fieldCardActive,
                        !!errors.dates && styles.fieldCardError,
                    ]}
                    onPress={() => setActiveField(
                        activeField === 'checkin' || activeField === 'checkout' ? null : 'checkin'
                    )}
                >
                    {activeField === 'checkin' || activeField === 'checkout' ? (
                        <View style={styles.expandedField}>
                            {/* Tab row */}
                            <View style={styles.dateTabRow}>
                                <Pressable
                                    style={[styles.dateTab, activeField === 'checkin' && styles.dateTabActive]}
                                    onPress={() => setActiveField('checkin')}
                                >
                                    <Text style={[styles.dateTabLabel, activeField === 'checkin' && styles.dateTabLabelActive]}>
                                        CHECK-IN
                                    </Text>
                                    <Text style={[
                                        styles.dateTabValue,
                                        activeField === 'checkin' && styles.dateTabValueActive,
                                    ]}>
                                        {checkInDisplay || 'Add date'}
                                    </Text>
                                </Pressable>
                                <View style={styles.dateTabDivider} />
                                <Pressable
                                    style={[styles.dateTab, activeField === 'checkout' && styles.dateTabActive]}
                                    onPress={() => setActiveField('checkout')}
                                >
                                    <Text style={[styles.dateTabLabel, activeField === 'checkout' && styles.dateTabLabelActive]}>
                                        CHECK-OUT
                                    </Text>
                                    <Text style={[
                                        styles.dateTabValue,
                                        activeField === 'checkout' && styles.dateTabValueActive,
                                    ]}>
                                        {checkOutDisplay || 'Add date'}
                                    </Text>
                                </Pressable>
                            </View>

                            {/* Night count badge */}
                            {nightCount > 0 && (
                                <View style={styles.nightBadge}>
                                    <Moon size={12} color="#3b82f6" />
                                    <Text style={styles.nightBadgeText}>
                                        {nightCount} night{nightCount !== 1 ? 's' : ''}
                                    </Text>
                                </View>
                            )}

                            {activeField === 'checkin' ? (
                                <CalendarPicker
                                    inline
                                    selectedDate={checkIn}
                                    rangeStart={checkIn}
                                    rangeEnd={checkOut}
                                    previewRangeEnd={hoverDate}
                                    onHover={setHoverDate}
                                    onSelect={(date) => {
                                        setCheckIn(date);
                                        if (checkOut && date >= checkOut) setCheckOut(null);
                                        setErrors(e => ({ ...e, dates: undefined }));
                                        setActiveField('checkout');
                                    }}
                                    minDate={new Date()}
                                />
                            ) : (
                                <CalendarPicker
                                    inline
                                    selectedDate={checkOut}
                                    rangeStart={checkIn}
                                    rangeEnd={checkOut}
                                    previewRangeEnd={hoverDate}
                                    onHover={setHoverDate}
                                    onSelect={(date) => {
                                        if (checkIn && date <= checkIn) {
                                            setErrors(e => ({ ...e, dates: 'Check-out must be after check-in' }));
                                            return;
                                        }
                                        setCheckOut(date);
                                        setHoverDate(null);
                                        setErrors(e => ({ ...e, dates: undefined }));
                                        setActiveField(null);
                                    }}
                                    minDate={checkIn || new Date()}
                                />
                            )}
                        </View>
                    ) : (
                        // Collapsed: show both dates side by side
                        <View style={styles.collapsedDatesRow}>
                            <View style={styles.collapsedDateHalf}>
                                <Text style={styles.fieldLabel}>CHECK-IN</Text>
                                <Text style={[styles.fieldValue, !checkInDisplay && styles.fieldPlaceholder]}>
                                    {checkInDisplay || 'Add date'}
                                </Text>
                            </View>
                            <View style={styles.dateArrow}>
                                {nightCount > 0 ? (
                                    <View style={styles.nightPill}>
                                        <Moon size={10} color={isDark ? '#93c5fd' : '#2563eb'} />
                                        <Text style={styles.nightPillText}>{nightCount}n</Text>
                                    </View>
                                ) : (
                                    <ChevronRight size={16} color={isDark ? '#334155' : '#cbd5e1'} />
                                )}
                            </View>
                            <View style={styles.collapsedDateHalf}>
                                <Text style={styles.fieldLabel}>CHECK-OUT</Text>
                                <Text style={[styles.fieldValue, !checkOutDisplay && styles.fieldPlaceholder]}>
                                    {checkOutDisplay || 'Add date'}
                                </Text>
                            </View>
                        </View>
                    )}
                </Pressable>
                {errors.dates && <Text style={styles.errorText}>{errors.dates}</Text>}

                {/* ══ GUESTS ════════════════════════════════════════ */}
                <Pressable
                    style={[styles.fieldCard, activeField === 'guests' && styles.fieldCardActive]}
                    onPress={() => setActiveField(activeField === 'guests' ? null : 'guests')}
                >
                    {activeField === 'guests' ? (
                        <View style={styles.expandedField}>
                            <Text style={styles.expandedTitle}>Who's coming?</Text>

                            {/* Adults */}
                            <View style={styles.counterRow}>
                                <View style={styles.counterLabelCol}>
                                    <Text style={styles.counterLabel}>Adults</Text>
                                    <Text style={styles.counterSubLabel}>Ages 18+</Text>
                                </View>
                                <View style={styles.counterControls}>
                                    <Pressable
                                        onPress={() => setAdults(Math.max(1, adults - 1))}
                                        style={[styles.counterBtn, adults <= 1 && styles.counterBtnDisabled]}
                                        disabled={adults <= 1}
                                    >
                                        <Text style={styles.counterBtnText}>−</Text>
                                    </Pressable>
                                    <Text style={styles.counterValue}>{adults}</Text>
                                    <Pressable
                                        onPress={() => setAdults(Math.min(10, adults + 1))}
                                        style={styles.counterBtn}
                                    >
                                        <Text style={styles.counterBtnText}>+</Text>
                                    </Pressable>
                                </View>
                            </View>

                            <View style={styles.counterDivider} />

                            {/* Children */}
                            <View style={styles.counterRow}>
                                <View style={styles.counterLabelCol}>
                                    <Text style={styles.counterLabel}>Children</Text>
                                    <Text style={styles.counterSubLabel}>Ages 0–17</Text>
                                </View>
                                <View style={styles.counterControls}>
                                    <Pressable
                                        onPress={() => handleSetChildren(Math.max(0, children - 1))}
                                        style={[styles.counterBtn, children <= 0 && styles.counterBtnDisabled]}
                                        disabled={children <= 0}
                                    >
                                        <Text style={styles.counterBtnText}>−</Text>
                                    </Pressable>
                                    <Text style={styles.counterValue}>{children}</Text>
                                    <Pressable
                                        onPress={() => handleSetChildren(Math.min(6, children + 1))}
                                        style={styles.counterBtn}
                                    >
                                        <Text style={styles.counterBtnText}>+</Text>
                                    </Pressable>
                                </View>
                            </View>

                            {/* Children age pickers */}
                            {children > 0 && (
                                <View style={styles.childAgesBlock}>
                                    <Text style={styles.childAgesTitle}>
                                        Age{children !== 1 ? 's' : ''} of {children !== 1 ? 'children' : 'child'} at check-in
                                    </Text>
                                    {childrenAges.map((age, idx) => (
                                        <View key={idx} style={styles.childAgeRow}>
                                            <Text style={styles.childAgeLabel}>Child {idx + 1}</Text>
                                            <ScrollView
                                                horizontal
                                                showsHorizontalScrollIndicator={false}
                                                contentContainerStyle={styles.ageChipsScroll}
                                            >
                                                {CHILD_AGES.map((opt) => (
                                                    <Pressable
                                                        key={opt.value}
                                                        onPress={() => {
                                                            const updated = [...childrenAges];
                                                            updated[idx] = opt.value;
                                                            setChildrenAges(updated);
                                                        }}
                                                        style={[
                                                            styles.ageChip,
                                                            age === opt.value && styles.ageChipSelected,
                                                        ]}
                                                    >
                                                        <Text style={[
                                                            styles.ageChipText,
                                                            age === opt.value && styles.ageChipTextSelected,
                                                        ]}>
                                                            {opt.label}
                                                        </Text>
                                                    </Pressable>
                                                ))}
                                            </ScrollView>
                                        </View>
                                    ))}
                                </View>
                            )}

                            <View style={styles.counterDivider} />

                            {/* Rooms */}
                            <View style={styles.counterRow}>
                                <View style={styles.counterLabelCol}>
                                    <Text style={styles.counterLabel}>Rooms</Text>
                                    <Text style={styles.counterSubLabel}>Number of rooms</Text>
                                </View>
                                <View style={styles.counterControls}>
                                    <Pressable
                                        onPress={() => setRooms(Math.max(1, rooms - 1))}
                                        style={[styles.counterBtn, rooms <= 1 && styles.counterBtnDisabled]}
                                        disabled={rooms <= 1}
                                    >
                                        <Text style={styles.counterBtnText}>−</Text>
                                    </Pressable>
                                    <Text style={styles.counterValue}>{rooms}</Text>
                                    <Pressable
                                        onPress={() => setRooms(Math.min(5, rooms + 1))}
                                        style={styles.counterBtn}
                                    >
                                        <Text style={styles.counterBtnText}>+</Text>
                                    </Pressable>
                                </View>
                            </View>
                        </View>
                    ) : (
                        <View style={styles.collapsedField}>
                            <View style={styles.fieldIconLabel}>
                                <Users size={14} color={isDark ? '#475569' : '#94a3b8'} />
                                <Text style={styles.fieldLabel}>GUESTS</Text>
                            </View>
                            <Text style={styles.fieldValue}>{guestSummary}</Text>
                        </View>
                    )}
                </Pressable>
            </ScrollView>

            {/* ── Sticky Search Button ─────────────────────────────── */}
            <View style={styles.searchButtonContainer}>
                {/* Search summary strip */}
                {nightCount > 0 && (
                    <View style={styles.searchSummaryRow}>
                        <View style={styles.searchSummaryPill}>
                            <Moon size={11} color={isDark ? '#93c5fd' : '#2563eb'} />
                            <Text style={styles.searchSummaryText}>
                                {nightCount} night{nightCount !== 1 ? 's' : ''}
                            </Text>
                        </View>
                        <View style={styles.searchSummaryDot} />
                        <Text style={styles.searchSummaryText}>{guestSummary}</Text>
                        <View style={styles.searchSummaryDot} />
                        <Text style={styles.searchSummaryText}>{currency.code}</Text>
                    </View>
                )}
                <Pressable
                    onPress={handleSearch}
                    style={[styles.searchButton, isSearching && styles.searchButtonDisabled]}
                    disabled={isSearching}
                >
                    {isSearching ? (
                        <ActivityIndicator size="small" color="white" />
                    ) : (
                        <Text style={styles.searchButtonText}>Search Hotels</Text>
                    )}
                </Pressable>
            </View>
        </SearchModal>
    );
};

const getStyles = (isDark: boolean, bottomInset: number = 0) => StyleSheet.create({
    scrollView:  { flex: 1 },
    scrollContent: { padding: 16, paddingBottom: 140, gap: 10 },

    // ── Header ───────────────────────────────────────────────────
    headerRow: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        paddingHorizontal: 4,
        paddingBottom: 4,
    },
    subtitle: {
        fontSize: 13,
        color: isDark ? '#64748b' : '#94a3b8',
        fontWeight: '500',
    },
    clearButton: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 4,
        paddingHorizontal: 10,
        paddingVertical: 5,
        borderRadius: 9999,
        backgroundColor: isDark ? '#1e293b' : '#f1f5f9',
    },
    clearText: {
        fontSize: 12,
        fontWeight: '500',
        color: isDark ? '#94a3b8' : '#64748b',
    },

    // ── Field cards ──────────────────────────────────────────────
    fieldCard: {
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        borderRadius: 16,
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 1 },
        shadowOpacity: isDark ? 0 : 0.04,
        shadowRadius: 3,
        elevation: isDark ? 0 : 2,
    },
    fieldCardActive: {
        borderColor: '#3b82f6',
        shadowColor: '#3b82f6',
        shadowOpacity: 0.12,
        shadowRadius: 6,
    },
    fieldCardError: {
        borderColor: '#ef4444',
    },
    nearMeBtn: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 12,
        paddingVertical: 12,
        paddingHorizontal: 16,
        backgroundColor: isDark ? 'rgba(37, 99, 235, 0.1)' : '#eff6ff',
        borderRadius: 12,
        marginTop: 12,
        marginBottom: 20,
        borderWidth: 1,
        borderColor: isDark ? 'rgba(37, 99, 235, 0.2)' : '#dbeafe',
    },
    nearMeIcon: {
        width: 32,
        height: 32,
        borderRadius: 16,
        backgroundColor: isDark ? '#1e293b' : '#ffffff',
        alignItems: 'center',
        justifyContent: 'center',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 4,
        elevation: 2,
    },
    nearMeText: {
        fontSize: 15,
        fontWeight: '700',
        color: '#2563eb',
    },
    errorText: {
        fontSize: 12,
        color: '#ef4444',
        paddingHorizontal: 4,
        marginTop: -4,
    },

    // ── Collapsed fields ─────────────────────────────────────────
    collapsedField: {
        paddingHorizontal: 16,
        paddingVertical: 14,
        minHeight: 68,
        justifyContent: 'center',
        gap: 4,
    },
    fieldIconLabel: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 6,
    },
    fieldLabel: {
        fontSize: 10,
        fontWeight: '600',
        color: isDark ? '#475569' : '#94a3b8',
        letterSpacing: 1.2,
    },
    fieldValue: {
        fontSize: 16,
        fontWeight: '600',
        color: isDark ? '#38bdf8' : '#1d4ed8',
    },
    fieldPlaceholder: {
        color: isDark ? '#334155' : '#cbd5e1',
        fontWeight: '400',
        fontSize: 15,
    },

    // ── Dates collapsed row ──────────────────────────────────────
    collapsedDatesRow: {
        flexDirection: 'row',
        alignItems: 'center',
        paddingHorizontal: 16,
        paddingVertical: 14,
        minHeight: 68,
    },
    collapsedDateHalf: { flex: 1, gap: 4 },
    dateArrow: { paddingHorizontal: 8, alignItems: 'center' },
    nightPill: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 3,
        backgroundColor: isDark ? '#1e3a5f' : '#dbeafe',
        paddingHorizontal: 7,
        paddingVertical: 3,
        borderRadius: 999,
    },
    nightPillText: {
        fontSize: 11,
        fontWeight: '700',
        color: isDark ? '#93c5fd' : '#2563eb',
    },

    // ── Expanded fields ──────────────────────────────────────────
    expandedField: { padding: 16 },
    expandedTitle: {
        fontSize: 17,
        fontWeight: '600',
        color: isDark ? '#ffffff' : '#0f172a',
        marginBottom: 14,
    },

    // ── Date tabs ────────────────────────────────────────────────
    dateTabRow: {
        flexDirection: 'row',
        marginBottom: 12,
        borderRadius: 12,
        overflow: 'hidden',
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
    },
    dateTab: {
        flex: 1,
        paddingHorizontal: 14,
        paddingVertical: 10,
        gap: 3,
        backgroundColor: isDark ? '#0f172a' : '#f8fafc',
    },
    dateTabActive: {
        backgroundColor: isDark ? '#1e293b' : '#eff6ff',
    },
    dateTabDivider: {
        width: 1,
        backgroundColor: isDark ? '#1e293b' : '#e2e8f0',
    },
    dateTabLabel: {
        fontSize: 9,
        fontWeight: '600',
        letterSpacing: 1.2,
        color: isDark ? '#475569' : '#94a3b8',
    },
    dateTabLabelActive: { color: '#3b82f6' },
    dateTabValue: {
        fontSize: 13,
        fontWeight: '600',
        color: isDark ? '#64748b' : '#94a3b8',
    },
    dateTabValueActive: {
        color: isDark ? '#ffffff' : '#0f172a',
    },
    nightBadge: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 5,
        alignSelf: 'center',
        backgroundColor: isDark ? '#1e3a5f' : '#dbeafe',
        paddingHorizontal: 12,
        paddingVertical: 5,
        borderRadius: 999,
        marginBottom: 12,
    },
    nightBadgeText: {
        fontSize: 12,
        fontWeight: '700',
        color: isDark ? '#93c5fd' : '#1d4ed8',
    },

    // ── Destination input ────────────────────────────────────────
    inputRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 10,
        backgroundColor: isDark ? '#1e293b' : '#f8fafc',
        borderRadius: 12,
        paddingHorizontal: 14,
        paddingVertical: 12,
        borderWidth: 1,
        borderColor: isDark ? '#334155' : '#e2e8f0',
    },
    textInput: {
        flex: 1,
        fontSize: 15,
        color: isDark ? '#ffffff' : '#0f172a',
        padding: 0,
    },

    // ── Autocomplete suggestions ─────────────────────────────────
    suggestionsContainer: {
        marginTop: 10,
        borderRadius: 12,
        backgroundColor: isDark ? '#1e293b' : '#ffffff',
        overflow: 'hidden',
        borderWidth: 1,
        borderColor: isDark ? '#334155' : '#e2e8f0',
    },
    suggestionItem: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 12,
        paddingHorizontal: 14,
        paddingVertical: 12,
    },
    suggestionBorder: {
        borderBottomWidth: 1,
        borderBottomColor: isDark ? '#0f172a' : '#f1f5f9',
    },
    suggestionIcon: {
        width: 32,
        height: 32,
        borderRadius: 8,
        backgroundColor: isDark ? '#0f172a' : '#f8fafc',
        alignItems: 'center',
        justifyContent: 'center',
    },
    suggestionText: { flex: 1 },
    suggestionTitle: {
        fontSize: 14,
        fontWeight: '600',
        color: isDark ? '#e2e8f0' : '#0f172a',
    },
    suggestionSubtitle: {
        fontSize: 12,
        color: isDark ? '#64748b' : '#94a3b8',
        marginTop: 1,
    },

    // ── Section blocks (recent / popular) ───────────────────────
    sectionBlock: { marginTop: 14 },
    sectionLabel: {
        fontSize: 11,
        fontWeight: '700',
        letterSpacing: 1,
        color: isDark ? '#475569' : '#94a3b8',
        marginBottom: 8,
        paddingHorizontal: 2,
    },

    // Recent searches
    recentItem: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 12,
        paddingVertical: 10,
        borderBottomWidth: 1,
        borderBottomColor: isDark ? '#1e293b' : '#f1f5f9',
    },
    recentIcon: {
        width: 30,
        height: 30,
        borderRadius: 8,
        backgroundColor: isDark ? '#1e293b' : '#f8fafc',
        alignItems: 'center',
        justifyContent: 'center',
    },
    recentText: { flex: 1 },
    recentDestination: {
        fontSize: 14,
        fontWeight: '600',
        color: isDark ? '#e2e8f0' : '#0f172a',
    },
    recentDetails: {
        fontSize: 11,
        color: isDark ? '#475569' : '#94a3b8',
        marginTop: 1,
    },

    // Popular destinations
    popularGrid: {
        flexDirection: 'row',
        flexWrap: 'wrap',
        gap: 8,
    },
    popularItem: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 6,
        paddingHorizontal: 12,
        paddingVertical: 8,
        borderRadius: 9999,
        backgroundColor: isDark ? '#1e293b' : '#eff6ff',
        borderWidth: 1,
        borderColor: isDark ? '#334155' : '#bfdbfe',
    },
    popularItemText: {
        fontSize: 13,
        fontWeight: '600',
        color: isDark ? '#93c5fd' : '#1d4ed8',
    },

    // ── Guest counters ───────────────────────────────────────────
    counterRow: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        paddingVertical: 4,
    },
    counterDivider: {
        height: 1,
        backgroundColor: isDark ? '#1e293b' : '#f1f5f9',
        marginVertical: 12,
    },
    counterLabelCol: { gap: 2 },
    counterLabel: {
        fontSize: 15,
        fontWeight: '600',
        color: isDark ? '#e2e8f0' : '#0f172a',
    },
    counterSubLabel: {
        fontSize: 12,
        color: isDark ? '#475569' : '#94a3b8',
    },
    counterControls: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 16,
    },
    counterBtn: {
        width: 38,
        height: 38,
        borderRadius: 19,
        borderWidth: 1.5,
        borderColor: isDark ? '#334155' : '#e2e8f0',
        backgroundColor: isDark ? '#1e293b' : '#ffffff',
        alignItems: 'center',
        justifyContent: 'center',
    },
    counterBtnDisabled: { opacity: 0.3 },
    counterBtnText: {
        fontSize: 20,
        lineHeight: 24,
        color: isDark ? '#e2e8f0' : '#0f172a',
        fontWeight: '300',
    },
    counterValue: {
        fontSize: 18,
        fontWeight: '600',
        color: isDark ? '#ffffff' : '#0f172a',
        minWidth: 24,
        textAlign: 'center',
    },

    // ── Children age pickers ─────────────────────────────────────
    childAgesBlock: {
        marginTop: 12,
        padding: 12,
        backgroundColor: isDark ? '#1e293b' : '#f8fafc',
        borderRadius: 12,
        gap: 10,
    },
    childAgesTitle: {
        fontSize: 12,
        fontWeight: '600',
        color: isDark ? '#94a3b8' : '#64748b',
    },
    childAgeRow: { gap: 6 },
    childAgeLabel: {
        fontSize: 12,
        fontWeight: '600',
        color: isDark ? '#64748b' : '#94a3b8',
    },
    ageChipsScroll: {
        gap: 6,
        paddingBottom: 2,
    },
    ageChip: {
        paddingHorizontal: 12,
        paddingVertical: 6,
        borderRadius: 999,
        borderWidth: 1,
        borderColor: isDark ? '#334155' : '#e2e8f0',
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
    },
    ageChipSelected: {
        backgroundColor: '#2563eb',
        borderColor: '#2563eb',
    },
    ageChipText: {
        fontSize: 12,
        fontWeight: '600',
        color: isDark ? '#94a3b8' : '#64748b',
    },
    ageChipTextSelected: {
        color: '#ffffff',
    },

    // ── Search button ────────────────────────────────────────────
    searchButtonContainer: {
        position: 'absolute',
        bottom: 0,
        left: 0,
        right: 0,
        padding: 16,
        paddingBottom: bottomInset + 16,
        backgroundColor: isDark ? 'rgba(2,6,23,0.97)' : 'rgba(255,255,255,0.97)',
        borderTopWidth: 1,
        borderTopColor: isDark ? '#1e293b' : '#f1f5f9',
        gap: 10,
    },
    searchSummaryRow: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 6,
        flexWrap: 'wrap',
    },
    searchSummaryPill: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 4,
    },
    searchSummaryDot: {
        width: 3,
        height: 3,
        borderRadius: 9999,
        backgroundColor: isDark ? '#334155' : '#cbd5e1',
    },
    searchSummaryText: {
        fontSize: 12,
        fontWeight: '500',
        color: isDark ? '#64748b' : '#94a3b8',
    },
    searchButton: {
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: '#2563eb',
        borderRadius: 14,
        height: 54,
        shadowColor: '#2563eb',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.35,
        shadowRadius: 12,
        elevation: 8,
    },
    searchButtonDisabled: { opacity: 0.7 },
    searchButtonText: {
        fontSize: 16,
        fontWeight: '700',
        color: '#ffffff',
        letterSpacing: 0.3,
    },
});

export default HotelSearchModal;
