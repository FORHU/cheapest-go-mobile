import React, { useState, useEffect } from 'react';
import { View, Text, Pressable, TextInput, ScrollView, StyleSheet, useColorScheme, ActivityIndicator } from 'react-native';
import { Plane, Calendar, Users, ArrowRight, ArrowUpDown, Plus, Trash2, Clock, TrendingUp, X, MapPin } from 'lucide-react-native';
import SearchModal from './SearchModal';
import CalendarPicker from './CalendarPicker';
import { useRouter } from 'expo-router';
import { autocompleteAirports, type Airport } from '../../lib/travel-api';
import { searchAirports } from '../../data/airports';
import { saveRecentFlightSearch, getRecentFlightSearches, RecentFlightSearch } from '../../lib/search-history';

interface FlightSearchModalProps {
    visible: boolean;
    onClose: () => void;
}

type TripType = 'round-trip' | 'one-way' | 'multi-city';

interface Segment {
    from: string;
    to: string;
    departure: Date | null;
}

interface FlightSearchState {
    tripType: TripType;
    from: string;
    to: string;
    departure: Date | null;
    returnDate: Date | null;
    adults: number;
    children: number;
    infants: number;
    cabinClass: string;
    multiCitySegments: Segment[];
}

const POPULAR_ROUTES = [
    { from: 'Manila (MNL)', to: 'Tokyo (NRT)' },
    { from: 'Manila (MNL)', to: 'Singapore (SIN)' },
    { from: 'Manila (MNL)', to: 'Bangkok (BKK)' },
    { from: 'Cebu (CEB)', to: 'Singapore (SIN)' },
];

const FlightSearchModal: React.FC<FlightSearchModalProps> = ({ visible, onClose }) => {
    const colorScheme = useColorScheme();
    const isDark = colorScheme === 'dark';
    const router = useRouter();

    const [state, setState] = useState<FlightSearchState>({
        tripType: 'round-trip',
        from: '',
        to: '',
        departure: null,
        returnDate: null,
        adults: 1,
        children: 0,
        infants: 0,
        cabinClass: 'Economy',
        multiCitySegments: [
            { from: '', to: '', departure: null },
            { from: '', to: '', departure: null }
        ]
    });

    const [activeField, setActiveField] = useState<string | null>(null);
    const [suggestions, setSuggestions] = useState<Airport[]>([]);
    const [loadingSuggestions, setLoadingSuggestions] = useState(false);
    const [recentSearches, setRecentSearches] = useState<RecentFlightSearch[]>([]);
    const [errors, setErrors] = useState<{
        from?: string;
        to?: string;
        departure?: string;
        returnDate?: string;
        multiCity?: string;
    }>({});

    // Load recent searches on mount/open
    useEffect(() => {
        if (visible) {
            getRecentFlightSearches().then(setRecentSearches).catch(() => {});
        }
    }, [visible]);

    // Clear validation errors when the modal opens — done during render
    // (React's recommended alternative to a setState-in-effect).
    const [wasVisible, setWasVisible] = useState(visible);
    if (visible !== wasVisible) {
        setWasVisible(visible);
        if (visible) setErrors({});
    }

    // Autocomplete effect
    useEffect(() => {
        let query = '';
        if (activeField === 'from') {
            query = state.from;
        } else if (activeField === 'to') {
            query = state.to;
        } else if (activeField?.startsWith('from-')) {
            const idx = parseInt(activeField.split('-')[1]);
            query = state.multiCitySegments[idx]?.from || '';
        } else if (activeField?.startsWith('to-')) {
            const idx = parseInt(activeField.split('-')[1]);
            query = state.multiCitySegments[idx]?.to || '';
        }

        const valid = query.length >= 2 && !query.includes('(');

        // Both branches setState inside the timeout so it isn't a synchronous
        // setState in the effect body (React Compiler set-state-in-effect rule).
        const timeoutId = setTimeout(async () => {
            if (!valid) { setSuggestions([]); return; }
            setLoadingSuggestions(true);
            try {
                const results = await autocompleteAirports(query);
                setSuggestions(results);
            } catch (err) {
                console.warn('Autocomplete failed', err);
            } finally {
                setLoadingSuggestions(false);
            }
        }, valid ? 300 : 0);

        return () => clearTimeout(timeoutId);
    }, [state.from, state.to, state.multiCitySegments, activeField]);

    const handleSelectAirport = (airport: Airport) => {
        const formatted = `${airport.city} (${airport.iata})`;
        
        if (activeField === 'from') {
            setState(prev => ({ ...prev, from: formatted }));
            setErrors(err => ({ ...err, from: undefined }));
            setActiveField('to');
        } else if (activeField === 'to') {
            setState(prev => ({ ...prev, to: formatted }));
            setErrors(err => ({ ...err, to: undefined }));
            setActiveField(null);
        } else if (activeField?.startsWith('from-')) {
            const idx = parseInt(activeField.split('-')[1]);
            setState(prev => {
                const copy = [...prev.multiCitySegments];
                copy[idx] = { ...copy[idx], from: formatted };
                return { ...prev, multiCitySegments: copy };
            });
            setActiveField(`to-${idx}`);
        } else if (activeField?.startsWith('to-')) {
            const idx = parseInt(activeField.split('-')[1]);
            setState(prev => {
                const copy = [...prev.multiCitySegments];
                copy[idx] = { ...copy[idx], to: formatted };
                
                // Prefill next segment's origin with this segment's destination
                if (idx + 1 < copy.length && !copy[idx + 1].from) {
                    copy[idx + 1] = { ...copy[idx + 1], from: formatted };
                }
                
                return { ...prev, multiCitySegments: copy };
            });
            setActiveField(null);
        }
    };

    const handleSwap = () => {
        setState(prev => ({
            ...prev,
            from: prev.to,
            to: prev.from
        }));
        setErrors(err => ({ ...err, from: undefined, to: undefined }));
    };

    const handleSwapSegment = (idx: number) => {
        setState(prev => {
            const copy = [...prev.multiCitySegments];
            const temp = copy[idx].from;
            copy[idx] = {
                ...copy[idx],
                from: copy[idx].to,
                to: temp
            };
            return { ...prev, multiCitySegments: copy };
        });
    };

    const handleAddSegment = () => {
        if (state.multiCitySegments.length >= 4) return;
        setState(prev => {
            const lastSeg = prev.multiCitySegments[prev.multiCitySegments.length - 1];
            return {
                ...prev,
                multiCitySegments: [
                    ...prev.multiCitySegments,
                    { from: lastSeg?.to || '', to: '', departure: null }
                ]
            };
        });
    };

    const handleRemoveSegment = (idx: number) => {
        if (state.multiCitySegments.length <= 2) return;
        setState(prev => ({
            ...prev,
            multiCitySegments: prev.multiCitySegments.filter((_, i) => i !== idx)
        }));
    };

    const formatDateLocal = (d: Date) => {
        return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
    };

    const formatDateDisplay = (date: Date | null) => {
        if (!date) return 'Add date';
        return date.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });
    };

    const handleClearAll = () => {
        setState({
            tripType: 'round-trip',
            from: '',
            to: '',
            departure: null,
            returnDate: null,
            adults: 1,
            children: 0,
            infants: 0,
            cabinClass: 'Economy',
            multiCitySegments: [
                { from: '', to: '', departure: null },
                { from: '', to: '', departure: null }
            ]
        });
        setActiveField(null);
        setErrors({});
    };

    const hasValue = !!(
        state.from ||
        state.to ||
        state.departure ||
        state.returnDate ||
        state.adults !== 1 ||
        state.children > 0 ||
        state.infants > 0 ||
        state.multiCitySegments.some(s => s.from || s.to || s.departure)
    );

    const handleSearch = async () => {
        const getIata = (str: string) => {
            const match = str.match(/\(([A-Z]{3})\)/);
            if (match) return match[1];
            const clean = str.trim();
            if (clean.length === 3) return clean.toUpperCase();
            
            // Try to auto-resolve city or airport name from the local curated dataset!
            const found = searchAirports(clean);
            if (found && found.length > 0) {
                return found[0].iata;
            }
            return clean;
        };

        const newErrors: typeof errors = {};

        if (state.tripType === 'multi-city') {
            let valid = true;
            state.multiCitySegments.forEach((seg) => {
                if (!seg.from || !seg.to || !seg.departure) {
                    valid = false;
                }
            });

            if (!valid) {
                newErrors.multiCity = 'Please complete all flight segment details';
                setErrors(newErrors);
                return;
            }

            // Resolve and validate IATA codes for each segment
            let iataValid = true;
            const parsedSegments = state.multiCitySegments.map(seg => {
                const originIata = getIata(seg.from);
                const destIata = getIata(seg.to);
                if (originIata.length !== 3 || destIata.length !== 3) {
                    iataValid = false;
                }
                return {
                    origin: originIata,
                    destination: destIata,
                    departureDate: formatDateLocal(seg.departure!)
                };
            });

            if (!iataValid) {
                newErrors.multiCity = 'Please select valid airports from suggestions for all legs';
                setErrors(newErrors);
                return;
            }

            const firstSeg = state.multiCitySegments[0];
            const lastSeg = state.multiCitySegments[state.multiCitySegments.length - 1];

            const searchParams = {
                from: getIata(firstSeg.from),
                to: getIata(lastSeg.to),
                departure: formatDateLocal(firstSeg.departure!),
                adults: state.adults.toString(),
                children: state.children.toString(),
                infants: state.infants.toString(),
                cabin: state.cabinClass,
                tripType: state.tripType,
                multiCitySegments: JSON.stringify(parsedSegments)
            };

            await saveRecentFlightSearch({
                from: firstSeg.from,
                to: lastSeg.to,
                departure: formatDateLocal(firstSeg.departure!),
                passengers: state.adults + state.children + state.infants,
                adults: state.adults,
                children: state.children,
                infants: state.infants,
                cabinClass: state.cabinClass,
                tripType: state.tripType,
            });

            onClose();
            // @ts-ignore
            router.push({ pathname: '/flights', params: searchParams });

        } else {
            if (!state.from) newErrors.from = 'Please enter origin city';
            if (!state.to) newErrors.to = 'Please enter destination city';
            if (!state.departure) newErrors.departure = 'Please select departure date';
            if (state.tripType === 'round-trip' && !state.returnDate) {
                newErrors.returnDate = 'Please select return date';
            }

            // Resolve and validate IATA codes
            if (state.from && !newErrors.from) {
                const originIata = getIata(state.from);
                if (originIata.length !== 3) {
                    newErrors.from = 'Please select a valid airport from suggestions';
                }
            }

            if (state.to && !newErrors.to) {
                const destIata = getIata(state.to);
                if (destIata.length !== 3) {
                    newErrors.to = 'Please select a valid airport from suggestions';
                }
            }

            if (Object.keys(newErrors).length > 0) {
                setErrors(newErrors);
                // Expand first error field
                if (newErrors.from) setActiveField('from');
                else if (newErrors.to) setActiveField('to');
                else if (newErrors.departure) setActiveField('departure');
                else if (newErrors.returnDate) setActiveField('return');
                return;
            }

            const searchParams = {
                from: getIata(state.from),
                to: getIata(state.to),
                departure: formatDateLocal(state.departure!),
                returnDate: state.returnDate ? formatDateLocal(state.returnDate) : '',
                adults: state.adults.toString(),
                children: state.children.toString(),
                infants: state.infants.toString(),
                cabin: state.cabinClass,
                tripType: state.tripType
            };

            await saveRecentFlightSearch({
                from: state.from,
                to: state.to,
                departure: formatDateLocal(state.departure!),
                returnDate: state.returnDate ? formatDateLocal(state.returnDate) : undefined,
                passengers: state.adults + state.children + state.infants,
                adults: state.adults,
                children: state.children,
                infants: state.infants,
                cabinClass: state.cabinClass,
                tripType: state.tripType,
            });

            onClose();
            // @ts-ignore
            router.push({ pathname: '/flights', params: searchParams });
        }
    };

    const handleSelectRecent = (recent: RecentFlightSearch) => {
        if (recent.tripType === 'multi-city') {
            setState(prev => ({
                ...prev,
                tripType: 'multi-city',
                adults: recent.adults || 1,
                children: recent.children || 0,
                infants: recent.infants || 0,
                cabinClass: recent.cabinClass || 'Economy',
                multiCitySegments: [
                    { from: recent.from, to: recent.to, departure: new Date(recent.departure + 'T00:00:00') },
                    { from: recent.to, to: '', departure: null }
                ]
            }));
        } else {
            setState(prev => ({
                ...prev,
                tripType: recent.tripType,
                from: recent.from,
                to: recent.to,
                departure: new Date(recent.departure + 'T00:00:00'),
                returnDate: recent.returnDate ? new Date(recent.returnDate + 'T00:00:00') : null,
                adults: recent.adults || 1,
                children: recent.children || 0,
                infants: recent.infants || 0,
                cabinClass: recent.cabinClass || 'Economy',
            }));
        }
        setErrors({});
        setActiveField(null);
    };

    const cabinOptions = ['Economy', 'Premium Economy', 'Business', 'First'];
    const totalPassengers = state.adults + state.children + state.infants;

    const passengerSummary = [
        `${state.adults} Adult${state.adults > 1 ? 's' : ''}`,
        state.children > 0 ? `${state.children} Child${state.children > 1 ? 'ren' : ''}` : '',
        state.infants > 0 ? `${state.infants} Infant${state.infants > 1 ? 's' : ''}` : '',
    ].filter(Boolean).join(', ');

    const styles = getStyles(isDark);

    return (
        <SearchModal visible={visible} onClose={onClose} title="Search Flights">
            <ScrollView style={styles.scrollView} contentContainerStyle={styles.scrollContent} keyboardShouldPersistTaps="handled">
                
                {/* Clear All / Header row */}
                <View style={styles.headerRow}>
                    <Text style={styles.subtitle}>Discover premium routes</Text>
                    {hasValue && (
                        <Pressable onPress={handleClearAll} style={styles.clearButton}>
                            <X size={12} color={isDark ? '#94a3b8' : '#64748b'} />
                            <Text style={styles.clearText}>Clear all</Text>
                        </Pressable>
                    )}
                </View>

                {/* Trip Type Toggles */}
                <View style={styles.tripTypeRow}>
                    <Pressable
                        onPress={() => setState(prev => ({ ...prev, tripType: 'round-trip' }))}
                        style={[styles.tripTypeBtn, state.tripType === 'round-trip' && styles.tripTypeBtnActive]}
                    >
                        <Text style={[styles.tripTypeText, state.tripType === 'round-trip' && styles.tripTypeTextActive]}>
                            Round Trip
                        </Text>
                    </Pressable>
                    <Pressable
                        onPress={() => setState(prev => ({ ...prev, tripType: 'one-way', returnDate: null }))}
                        style={[styles.tripTypeBtn, state.tripType === 'one-way' && styles.tripTypeBtnActive]}
                    >
                        <Text style={[styles.tripTypeText, state.tripType === 'one-way' && styles.tripTypeTextActive]}>
                            One Way
                        </Text>
                    </Pressable>
                    <Pressable
                        onPress={() => setState(prev => ({ ...prev, tripType: 'multi-city' }))}
                        style={[styles.tripTypeBtn, state.tripType === 'multi-city' && styles.tripTypeBtnActive]}
                    >
                        <Text style={[styles.tripTypeText, state.tripType === 'multi-city' && styles.tripTypeTextActive]}>
                            Multi-City
                        </Text>
                    </Pressable>
                </View>

                {state.tripType === 'multi-city' ? (
                    /* ─── MULTI CITY UI ─── */
                    <View style={styles.multiCityContainer}>
                        {state.multiCitySegments.map((segment, idx) => (
                            <View key={idx} style={styles.segmentBlock}>
                                <View style={styles.segmentHeader}>
                                    <Text style={styles.segmentTitle}>Flight {idx + 1}</Text>
                                    {state.multiCitySegments.length > 2 && (
                                        <Pressable onPress={() => handleRemoveSegment(idx)} style={styles.removeBtn}>
                                            <Trash2 size={16} color="#f43f5e" />
                                        </Pressable>
                                    )}
                                </View>

                                {/* Combined Connected FROM/TO Card */}
                                <View style={[
                                    styles.connectedCard,
                                    (activeField === `from-${idx}` || activeField === `to-${idx}`) && styles.connectedCardActive
                                ]}>
                                    {/* Segment Origin */}
                                    <Pressable
                                        style={styles.connectedCardHalf}
                                        onPress={() => setActiveField(activeField === `from-${idx}` ? null : `from-${idx}`)}
                                    >
                                        {activeField === `from-${idx}` ? (
                                            <View style={styles.expandedField}>
                                                <Text style={styles.expandedTitle}>Departure airport?</Text>
                                                <View style={styles.inputRow}>
                                                    <Plane size={16} color="#2563eb" />
                                                    <TextInput
                                                        style={styles.textInput}
                                                        placeholder="Origin airport or city"
                                                        placeholderTextColor={isDark ? "#475569" : "#94a3b8"}
                                                        value={segment.from}
                                                        onChangeText={(text) => setState(prev => {
                                                            const copy = [...prev.multiCitySegments];
                                                            copy[idx] = { ...copy[idx], from: text };
                                                            return { ...prev, multiCitySegments: copy };
                                                        })}
                                                        autoFocus
                                                    />
                                                    {loadingSuggestions && <ActivityIndicator size="small" color="#2563eb" />}
                                                </View>
                                            </View>
                                        ) : (
                                            <View style={styles.collapsedConnectedHalf}>
                                                <View style={styles.labelRow}>
                                                    <Plane size={12} color={isDark ? "#475569" : "#94a3b8"} />
                                                    <Text style={styles.fieldLabel}>FROM</Text>
                                                </View>
                                                <Text style={[styles.fieldValue, !segment.from && styles.fieldPlaceholder]}>
                                                    {segment.from || 'Select origin'}
                                                </Text>
                                            </View>
                                        )}
                                    </Pressable>

                                    <View style={styles.horizontalDivider} />

                                    {/* Segment Destination */}
                                    <Pressable
                                        style={styles.connectedCardHalf}
                                        onPress={() => setActiveField(activeField === `to-${idx}` ? null : `to-${idx}`)}
                                    >
                                        {activeField === `to-${idx}` ? (
                                            <View style={styles.expandedField}>
                                                <Text style={styles.expandedTitle}>Arrival airport?</Text>
                                                <View style={styles.inputRow}>
                                                    <Plane size={16} color="#2563eb" style={{ transform: [{ rotate: '90deg' }] }} />
                                                    <TextInput
                                                        style={styles.textInput}
                                                        placeholder="Destination airport or city"
                                                        placeholderTextColor={isDark ? "#475569" : "#94a3b8"}
                                                        value={segment.to}
                                                        onChangeText={(text) => setState(prev => {
                                                            const copy = [...prev.multiCitySegments];
                                                            copy[idx] = { ...copy[idx], to: text };
                                                            return { ...prev, multiCitySegments: copy };
                                                        })}
                                                        autoFocus
                                                    />
                                                    {loadingSuggestions && <ActivityIndicator size="small" color="#2563eb" />}
                                                </View>
                                            </View>
                                        ) : (
                                            <View style={styles.collapsedConnectedHalf}>
                                                <View style={styles.labelRow}>
                                                    <Plane size={12} color={isDark ? "#475569" : "#94a3b8"} style={{ transform: [{ rotate: '90deg' }] }} />
                                                    <Text style={styles.fieldLabel}>TO</Text>
                                                </View>
                                                <Text style={[styles.fieldValue, !segment.to && styles.fieldPlaceholder]}>
                                                    {segment.to || 'Select destination'}
                                                </Text>
                                            </View>
                                        )}
                                    </Pressable>

                                    {/* Connected Swap Button */}
                                    {activeField !== `from-${idx}` && activeField !== `to-${idx}` && (
                                        <Pressable style={styles.swapCircle} onPress={() => handleSwapSegment(idx)}>
                                            <ArrowUpDown size={14} color="#ffffff" />
                                        </Pressable>
                                    )}
                                </View>

                                {/* Autocomplete overlay for Segment */}
                                {(activeField === `from-${idx}` || activeField === `to-${idx}`) && suggestions.length > 0 && (
                                    <View style={styles.suggestionsContainer}>
                                        {suggestions.map((item) => (
                                            <Pressable 
                                                key={item.iata} 
                                                style={styles.suggestionItem}
                                                onPress={() => handleSelectAirport(item)}
                                            >
                                                <MapPin size={16} color={isDark ? "#64748b" : "#94a3b8"} />
                                                <View style={styles.suggestionText}>
                                                    <Text style={styles.suggestionCity}>{item.city} ({item.iata})</Text>
                                                    <Text style={styles.suggestionName}>{item.name}</Text>
                                                </View>
                                            </Pressable>
                                        ))}
                                    </View>
                                )}

                                {/* Segment Departure Date */}
                                <Pressable
                                    style={[styles.fieldCard, activeField === `date-${idx}` && styles.fieldCardActive]}
                                    onPress={() => setActiveField(activeField === `date-${idx}` ? null : `date-${idx}`)}
                                >
                                    {activeField === `date-${idx}` ? (
                                        <View style={styles.expandedField}>
                                            <Text style={styles.expandedTitle}>Departure Date</Text>
                                            <CalendarPicker
                                                inline
                                                selectedDate={segment.departure}
                                                onSelect={(date) => {
                                                    setState(prev => {
                                                        const copy = [...prev.multiCitySegments];
                                                        copy[idx] = { ...copy[idx], departure: date };
                                                        return { ...prev, multiCitySegments: copy };
                                                    });
                                                    setActiveField(null);
                                                }}
                                                minDate={idx > 0 ? (state.multiCitySegments[idx - 1].departure || new Date()) : new Date()}
                                            />
                                        </View>
                                    ) : (
                                        <View style={styles.collapsedField}>
                                            <View style={styles.labelRow}>
                                                <Calendar size={12} color={isDark ? "#475569" : "#94a3b8"} />
                                                <Text style={styles.fieldLabel}>DEPARTURE DATE</Text>
                                            </View>
                                            <Text style={[styles.fieldValue, !segment.departure && styles.fieldPlaceholder]}>
                                                {formatDateDisplay(segment.departure)}
                                            </Text>
                                        </View>
                                    )}
                                </Pressable>
                            </View>
                        ))}

                        {errors.multiCity && <Text style={styles.errorText}>{errors.multiCity}</Text>}

                        {state.multiCitySegments.length < 4 && (
                            <Pressable style={styles.addFlightBtn} onPress={handleAddSegment}>
                                <Plus size={16} color="#2563eb" />
                                <Text style={styles.addFlightText}>Add Next Flight</Text>
                            </Pressable>
                        )}
                    </View>
                ) : (
                    /* ─── ROUND TRIP / ONE WAY UI ─── */
                    <View style={styles.simpleSearchContainer}>
                        {/* Connected Connected FROM/TO Card */}
                        <View style={[
                            styles.connectedCard,
                            (activeField === 'from' || activeField === 'to') && styles.connectedCardActive,
                            (!!errors.from || !!errors.to) && styles.connectedCardError
                        ]}>
                            {/* FROM Field */}
                            <Pressable
                                style={styles.connectedCardHalf}
                                onPress={() => setActiveField(activeField === 'from' ? null : 'from')}
                            >
                                {activeField === 'from' ? (
                                    <View style={styles.expandedField}>
                                        <Text style={styles.expandedTitle}>From where?</Text>
                                        <View style={styles.inputRow}>
                                            <Plane size={16} color="#2563eb" />
                                            <TextInput
                                                style={styles.textInput}
                                                placeholder="Origin airport or city"
                                                placeholderTextColor={isDark ? "#475569" : "#94a3b8"}
                                                value={state.from}
                                                onChangeText={(text) => {
                                                    setState(prev => ({ ...prev, from: text }));
                                                    setErrors(err => ({ ...err, from: undefined }));
                                                }}
                                                autoFocus
                                            />
                                            {loadingSuggestions && <ActivityIndicator size="small" color="#2563eb" />}
                                        </View>
                                    </View>
                                ) : (
                                    <View style={styles.collapsedConnectedHalf}>
                                        <View style={styles.labelRow}>
                                            <Plane size={12} color={isDark ? "#475569" : "#94a3b8"} />
                                            <Text style={styles.fieldLabel}>FROM</Text>
                                        </View>
                                        <Text style={[styles.fieldValue, !state.from && styles.fieldPlaceholder]}>
                                            {state.from || 'Select origin'}
                                        </Text>
                                    </View>
                                )}
                            </Pressable>

                            <View style={styles.horizontalDivider} />

                            {/* TO Field */}
                            <Pressable
                                style={styles.connectedCardHalf}
                                onPress={() => setActiveField(activeField === 'to' ? null : 'to')}
                            >
                                {activeField === 'to' ? (
                                    <View style={styles.expandedField}>
                                        <Text style={styles.expandedTitle}>Going to?</Text>
                                        <View style={styles.inputRow}>
                                            <Plane size={16} color="#2563eb" style={{ transform: [{ rotate: '90deg' }] }} />
                                            <TextInput
                                                style={styles.textInput}
                                                placeholder="Destination airport or city"
                                                placeholderTextColor={isDark ? "#475569" : "#94a3b8"}
                                                value={state.to}
                                                onChangeText={(text) => {
                                                    setState(prev => ({ ...prev, to: text }));
                                                    setErrors(err => ({ ...err, to: undefined }));
                                                }}
                                                autoFocus
                                            />
                                            {loadingSuggestions && <ActivityIndicator size="small" color="#2563eb" />}
                                        </View>
                                    </View>
                                ) : (
                                    <View style={styles.collapsedConnectedHalf}>
                                        <View style={styles.labelRow}>
                                            <Plane size={12} color={isDark ? "#475569" : "#94a3b8"} style={{ transform: [{ rotate: '90deg' }] }} />
                                            <Text style={styles.fieldLabel}>TO</Text>
                                        </View>
                                        <Text style={[styles.fieldValue, !state.to && styles.fieldPlaceholder]}>
                                            {state.to || 'Select destination'}
                                        </Text>
                                    </View>
                                )}
                            </Pressable>

                            {/* Connected Swap Button */}
                            {activeField !== 'from' && activeField !== 'to' && (
                                <Pressable style={styles.swapCircle} onPress={handleSwap}>
                                    <ArrowUpDown size={14} color="#ffffff" />
                                </Pressable>
                            )}
                        </View>

                        {errors.from && <Text style={styles.errorText}>{errors.from}</Text>}
                        {errors.to && <Text style={styles.errorText}>{errors.to}</Text>}

                        {/* Autocomplete Suggestions */}
                        {(activeField === 'from' || activeField === 'to') && suggestions.length > 0 && (
                            <View style={styles.suggestionsContainer}>
                                {suggestions.map((item) => (
                                    <Pressable 
                                        key={item.iata} 
                                        style={styles.suggestionItem}
                                        onPress={() => handleSelectAirport(item)}
                                    >
                                        <MapPin size={16} color={isDark ? "#64748b" : "#94a3b8"} />
                                        <View style={styles.suggestionText}>
                                            <Text style={styles.suggestionCity}>{item.city} ({item.iata})</Text>
                                            <Text style={styles.suggestionName}>{item.name}</Text>
                                        </View>
                                    </Pressable>
                                ))}
                            </View>
                        )}

                        {/* DEPARTURE */}
                        <Pressable
                            style={[
                                styles.fieldCard,
                                activeField === 'departure' && styles.fieldCardActive,
                                !!errors.departure && styles.fieldCardError
                            ]}
                            onPress={() => setActiveField(activeField === 'departure' ? null : 'departure')}
                        >
                            {activeField === 'departure' ? (
                                <View style={styles.expandedField}>
                                    <Text style={styles.expandedTitle}>Departure date</Text>
                                    <CalendarPicker
                                        inline
                                        selectedDate={state.departure}
                                        rangeStart={state.departure}
                                        rangeEnd={state.returnDate}
                                        onSelect={(date) => {
                                            setState(prev => ({ ...prev, departure: date }));
                                            setErrors(err => ({ ...err, departure: undefined }));
                                            if (state.tripType === 'round-trip') {
                                                setActiveField('return');
                                            } else {
                                                setActiveField(null);
                                            }
                                        }}
                                        minDate={new Date()}
                                    />
                                </View>
                            ) : (
                                <View style={styles.collapsedField}>
                                    <View style={styles.labelRow}>
                                        <Calendar size={12} color={isDark ? "#475569" : "#94a3b8"} />
                                        <Text style={styles.fieldLabel}>DEPARTURE</Text>
                                    </View>
                                    <Text style={[styles.fieldValue, !state.departure && styles.fieldPlaceholder]}>
                                        {formatDateDisplay(state.departure)}
                                    </Text>
                                </View>
                            )}
                        </Pressable>
                        {errors.departure && <Text style={styles.errorText}>{errors.departure}</Text>}

                        {/* RETURN */}
                        {state.tripType === 'round-trip' && (
                            <Pressable
                                style={[
                                    styles.fieldCard,
                                    activeField === 'return' && styles.fieldCardActive,
                                    !!errors.returnDate && styles.fieldCardError
                                ]}
                                onPress={() => setActiveField(activeField === 'return' ? null : 'return')}
                            >
                                {activeField === 'return' ? (
                                    <View style={styles.expandedField}>
                                        <Text style={styles.expandedTitle}>Return date</Text>
                                        <CalendarPicker
                                            inline
                                            selectedDate={state.returnDate}
                                            rangeStart={state.departure}
                                            rangeEnd={state.returnDate}
                                            onSelect={(date) => {
                                                if (state.departure && date < state.departure) {
                                                    setErrors(err => ({ ...err, returnDate: 'Return date must be after departure' }));
                                                    return;
                                                }
                                                setState(prev => ({ ...prev, returnDate: date }));
                                                setErrors(err => ({ ...err, returnDate: undefined }));
                                                setActiveField(null);
                                            }}
                                            minDate={state.departure || new Date()}
                                        />
                                    </View>
                                ) : (
                                    <View style={styles.collapsedField}>
                                        <View style={styles.labelRow}>
                                            <Calendar size={12} color={isDark ? "#475569" : "#94a3b8"} />
                                            <Text style={styles.fieldLabel}>RETURN</Text>
                                        </View>
                                        <Text style={[styles.fieldValue, !state.returnDate && styles.fieldPlaceholder]}>
                                            {formatDateDisplay(state.returnDate)}
                                        </Text>
                                    </View>
                                )}
                            </Pressable>
                        )}
                        {errors.returnDate && <Text style={styles.errorText}>{errors.returnDate}</Text>}
                    </View>
                )}

                {/* PASSENGERS & CABIN */}
                <Pressable
                    style={[styles.fieldCard, activeField === 'passengers' && styles.fieldCardActive]}
                    onPress={() => setActiveField(activeField === 'passengers' ? null : 'passengers')}
                >
                    {activeField === 'passengers' ? (
                        <View style={styles.expandedField}>
                            <Text style={styles.expandedTitle}>Passengers & Cabin</Text>
                            
                            {/* Adults */}
                            <View style={styles.counterRow}>
                                <View style={styles.counterLabelCol}>
                                    <Text style={styles.counterLabel}>Adults</Text>
                                    <Text style={styles.counterSubLabel}>Ages 12+</Text>
                                </View>
                                <View style={styles.counterControls}>
                                    <Pressable
                                        onPress={() => setState(prev => ({ ...prev, adults: Math.max(1, prev.adults - 1) }))}
                                        style={[styles.counterBtn, state.adults <= 1 && styles.counterBtnDisabled]}
                                        disabled={state.adults <= 1}
                                    >
                                        <Text style={styles.counterBtnText}>−</Text>
                                    </Pressable>
                                    <Text style={styles.counterValue}>{state.adults}</Text>
                                    <Pressable
                                        onPress={() => setState(prev => ({ ...prev, adults: Math.min(9, prev.adults + 1) }))}
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
                                    <Text style={styles.counterSubLabel}>Ages 2–11</Text>
                                </View>
                                <View style={styles.counterControls}>
                                    <Pressable
                                        onPress={() => setState(prev => ({ ...prev, children: Math.max(0, prev.children - 1) }))}
                                        style={[styles.counterBtn, state.children <= 0 && styles.counterBtnDisabled]}
                                        disabled={state.children <= 0}
                                    >
                                        <Text style={styles.counterBtnText}>−</Text>
                                    </Pressable>
                                    <Text style={styles.counterValue}>{state.children}</Text>
                                    <Pressable
                                        onPress={() => setState(prev => ({ ...prev, children: Math.min(9, prev.children + 1) }))}
                                        style={styles.counterBtn}
                                    >
                                        <Text style={styles.counterBtnText}>+</Text>
                                    </Pressable>
                                </View>
                            </View>

                            <View style={styles.counterDivider} />

                            {/* Infants */}
                            <View style={styles.counterRow}>
                                <View style={styles.counterLabelCol}>
                                    <Text style={styles.counterLabel}>Infants</Text>
                                    <Text style={styles.counterSubLabel}>Under 2 (on lap)</Text>
                                </View>
                                <View style={styles.counterControls}>
                                    <Pressable
                                        onPress={() => setState(prev => ({ ...prev, infants: Math.max(0, prev.infants - 1) }))}
                                        style={[styles.counterBtn, state.infants <= 0 && styles.counterBtnDisabled]}
                                        disabled={state.infants <= 0}
                                    >
                                        <Text style={styles.counterBtnText}>−</Text>
                                    </Pressable>
                                    <Text style={styles.counterValue}>{state.infants}</Text>
                                    <Pressable
                                        onPress={() => setState(prev => ({ ...prev, infants: Math.min(state.adults, prev.infants + 1) }))}
                                        style={styles.counterBtn}
                                    >
                                        <Text style={styles.counterBtnText}>+</Text>
                                    </Pressable>
                                </View>
                            </View>

                            <View style={styles.counterDivider} />

                            <View style={styles.cabinPicker}>
                                {cabinOptions.map((cabin) => (
                                    <Pressable
                                        key={cabin}
                                        onPress={() => setState(prev => ({ ...prev, cabinClass: cabin }))}
                                        style={[styles.cabinOption, state.cabinClass === cabin && styles.cabinOptionActive]}
                                    >
                                        <Text style={[styles.cabinOptionText, state.cabinClass === cabin && styles.cabinOptionTextActive]}>
                                            {cabin}
                                        </Text>
                                    </Pressable>
                                ))}
                            </View>
                        </View>
                    ) : (
                        <View style={styles.collapsedField}>
                            <View style={styles.labelRow}>
                                <Users size={12} color={isDark ? "#475569" : "#94a3b8"} />
                                <Text style={styles.fieldLabel}>PASSENGERS & CABIN</Text>
                            </View>
                            <Text style={styles.fieldValue}>
                                {totalPassengers} Traveler{totalPassengers !== 1 ? 's' : ''} ({passengerSummary}) • {state.cabinClass}
                            </Text>
                        </View>
                    )}
                </Pressable>

                {/* RECENT SEARCHES & POPULAR ROUTES */}
                {activeField === null && (
                    <View style={styles.historySection}>
                        {recentSearches.length > 0 ? (
                            <View style={styles.sectionBlock}>
                                <Text style={styles.sectionLabel}>Recent Searches</Text>
                                {recentSearches.slice(0, 3).map((recent) => (
                                    <Pressable
                                        key={recent.id}
                                        onPress={() => handleSelectRecent(recent)}
                                        style={styles.recentItem}
                                    >
                                        <Clock size={14} color={isDark ? '#64748b' : '#94a3b8'} style={styles.recentIcon} />
                                        <View style={styles.recentTextContainer}>
                                            <Text style={styles.recentRoute}>
                                                {recent.from.split(' ')[0]} ➔ {recent.to.split(' ')[0]}
                                            </Text>
                                            <Text style={styles.recentDetails}>
                                                {recent.tripType === 'multi-city' ? 'Multi-City' : recent.tripType === 'round-trip' ? 'Round-Trip' : 'One-Way'} • {recent.passengers} pax • {recent.cabinClass}
                                            </Text>
                                        </View>
                                        <ArrowRight size={14} color={isDark ? '#334155' : '#cbd5e1'} />
                                    </Pressable>
                                ))}
                            </View>
                        ) : (
                            <View style={styles.sectionBlock}>
                                <Text style={styles.sectionLabel}>Popular Routes</Text>
                                <View style={styles.popularGrid}>
                                    {POPULAR_ROUTES.map((route, i) => (
                                        <Pressable
                                            key={i}
                                            onPress={() => setState(prev => ({ ...prev, from: route.from, to: route.to }))}
                                            style={styles.popularItem}
                                        >
                                            <TrendingUp size={12} color="#2563eb" style={{ marginRight: 6 }} />
                                            <Text style={styles.popularText}>{route.from.split(' (')[0]} to {route.to.split(' (')[0]}</Text>
                                        </Pressable>
                                    ))}
                                </View>
                            </View>
                        )}
                    </View>
                )}
            </ScrollView>

            {/* Sticky Search Button Container */}
            <View style={styles.searchButtonContainer}>
                {/* Search Badge summary strip */}
                <View style={styles.searchSummaryBadge}>
                    <Text style={styles.searchSummaryText}>
                        {totalPassengers} passenger{totalPassengers !== 1 ? 's' : ''} • {state.cabinClass} {state.tripType === 'round-trip' ? '• Round-Trip' : state.tripType === 'multi-city' ? '• Multi-City' : '• One-Way'}
                    </Text>
                </View>
                <Pressable onPress={handleSearch} style={styles.searchButton}>
                    <Text style={styles.searchButtonText}>Search Flights</Text>
                    <ArrowRight size={18} color="white" />
                </Pressable>
            </View>
        </SearchModal>
    );
};

const getStyles = (isDark: boolean) => StyleSheet.create({
    scrollView: { flex: 1 },
    scrollContent: { padding: 16, paddingBottom: 150, gap: 10 },
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
    tripTypeRow: {
        flexDirection: 'row', 
        alignSelf: 'center', 
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        borderRadius: 9999, 
        padding: 4, 
        borderWidth: 1, 
        borderColor: isDark ? '#1e293b' : '#e2e8f0', 
        marginBottom: 8,
        width: '100%',
        justifyContent: 'space-between'
    },
    tripTypeBtn: { flex: 1, paddingVertical: 8, alignItems: 'center', borderRadius: 9999 },
    tripTypeBtnActive: { backgroundColor: '#2563eb' },
    tripTypeText: { fontSize: 13, fontWeight: '500', color: isDark ? '#64748b' : '#94a3b8' },
    tripTypeTextActive: { color: '#ffffff', fontWeight: '600' },
    
    // Connected Origin/Destination Container Card
    connectedCard: {
        backgroundColor: isDark ? '#0f172a' : '#ffffff', 
        borderRadius: 16, 
        borderWidth: 1, 
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 1 },
        shadowOpacity: isDark ? 0 : 0.05,
        shadowRadius: 2,
        elevation: isDark ? 0 : 1,
        position: 'relative'
    },
    connectedCardActive: { borderColor: '#2563eb' },
    connectedCardError: { borderColor: '#ef4444' },
    simpleSearchContainer: { gap: 10 },
    connectedCardHalf: { minHeight: 64, justifyContent: 'center' },
    collapsedConnectedHalf: { paddingHorizontal: 16, paddingVertical: 12 },
    horizontalDivider: { height: 1, backgroundColor: isDark ? '#1e293b' : '#e2e8f0', marginHorizontal: 16 },
    
    // Floating Swap Button
    swapCircle: {
        position: 'absolute',
        right: 16,
        top: '50%',
        marginTop: -16,
        width: 32,
        height: 32,
        borderRadius: 16,
        backgroundColor: '#2563eb',
        alignItems: 'center',
        justifyContent: 'center',
        borderWidth: 2,
        borderColor: isDark ? '#0f172a' : '#ffffff',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 2,
        elevation: 3,
        zIndex: 10
    },

    fieldCard: { 
        backgroundColor: isDark ? '#0f172a' : '#ffffff', 
        borderRadius: 16, 
        borderWidth: 1, 
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 1 },
        shadowOpacity: isDark ? 0 : 0.05,
        shadowRadius: 2,
        elevation: isDark ? 0 : 1,
    },
    fieldCardActive: { borderColor: '#2563eb' },
    fieldCardError: { borderColor: '#ef4444' },
    collapsedField: { paddingHorizontal: 16, paddingVertical: 14, minHeight: 64, justifyContent: 'center' },
    labelRow: { flexDirection: 'row', alignItems: 'center', gap: 6, marginBottom: 2 },
    fieldLabel: { 
        fontSize: 10, 
        fontWeight: '600', 
        color: isDark ? '#64748b' : '#94a3b8', 
        letterSpacing: 1.2 
    },
    fieldValue: { 
        fontSize: 15, 
        fontWeight: '600', 
        color: isDark ? '#ffffff' : '#0f172a', 
        marginTop: 2 
    },
    fieldPlaceholder: {
        color: isDark ? '#475569' : '#94a3b8',
        fontWeight: '400',
    },
    expandedField: { padding: 16 },
    expandedTitle: { 
        fontSize: 16, 
        fontWeight: '700', 
        color: isDark ? '#ffffff' : '#0f172a', 
        marginBottom: 12 
    },
    inputRow: { 
        flexDirection: 'row', 
        alignItems: 'center', 
        gap: 12, 
        backgroundColor: isDark ? '#1e293b' : '#f8fafc', 
        borderRadius: 12, 
        paddingHorizontal: 12, 
        paddingVertical: 12,
        borderWidth: 1,
        borderColor: isDark ? '#334155' : '#e2e8f0',
    },
    textInput: { 
        flex: 1, 
        fontSize: 15, 
        color: isDark ? '#ffffff' : '#0f172a', 
        padding: 0 
    },
    
    // Autocomplete overlay
    suggestionsContainer: { 
        marginTop: 4, 
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        borderRadius: 12,
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
        overflow: 'hidden'
    },
    suggestionItem: { 
        flexDirection: 'row', 
        alignItems: 'center', 
        gap: 12, 
        padding: 14, 
        borderBottomWidth: 1, 
        borderBottomColor: isDark ? '#1e293b' : '#f1f5f9' 
    },
    suggestionText: { flex: 1 },
    suggestionCity: { fontSize: 14, fontWeight: '600', color: isDark ? '#ffffff' : '#0f172a' },
    suggestionName: { fontSize: 12, color: isDark ? '#64748b' : '#94a3b8', marginTop: 2 },
    
    errorText: {
        fontSize: 12,
        color: '#ef4444',
        fontWeight: '500',
        paddingLeft: 4,
        marginTop: -4,
    },

    // Passengers Counter Rows
    counterRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingVertical: 8 },
    counterLabelCol: { flex: 1 },
    counterLabel: { fontSize: 15, fontWeight: '600', color: isDark ? '#ffffff' : '#0f172a' },
    counterSubLabel: { fontSize: 12, color: isDark ? '#64748b' : '#94a3b8', marginTop: 2 },
    counterControls: { flexDirection: 'row', alignItems: 'center', gap: 14 },
    counterBtn: {
        width: 36, 
        height: 36, 
        borderRadius: 18, 
        borderWidth: 1, 
        borderColor: isDark ? '#334155' : '#e2e8f0',
        backgroundColor: isDark ? '#1e293b' : '#ffffff', 
        alignItems: 'center', 
        justifyContent: 'center',
    },
    counterBtnDisabled: {
        opacity: 0.3
    },
    counterBtnText: { fontSize: 18, fontWeight: '600', color: isDark ? '#e2e8f0' : '#0f172a' },
    counterValue: { fontSize: 16, fontWeight: '600', color: isDark ? '#ffffff' : '#0f172a', minWidth: 24, textAlign: 'center' },
    counterDivider: { height: 1, backgroundColor: isDark ? '#1e293b' : '#e2e8f0', marginVertical: 8 },
    
    cabinPicker: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 12 },
    cabinOption: {
        paddingHorizontal: 14, 
        paddingVertical: 8, 
        borderRadius: 9999,
        backgroundColor: isDark ? '#1e293b' : '#f8fafc', 
        borderWidth: 1, 
        borderColor: isDark ? '#334155' : '#e2e8f0',
    },
    cabinOptionActive: { backgroundColor: '#2563eb', borderColor: '#2563eb' },
    cabinOptionText: { fontSize: 12, fontWeight: '500', color: isDark ? '#94a3b8' : '#64748b' },
    cabinOptionTextActive: { color: '#ffffff', fontWeight: '600' },

    // History and Fallbacks
    historySection: { marginTop: 12 },
    sectionBlock: { gap: 8 },
    sectionLabel: { fontSize: 12, fontWeight: '600', color: isDark ? '#64748b' : '#94a3b8', letterSpacing: 1.2, textTransform: 'uppercase', marginBottom: 4 },
    recentItem: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        borderRadius: 14,
        padding: 12,
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
    },
    recentIcon: { marginRight: 12 },
    recentTextContainer: { flex: 1 },
    recentRoute: { fontSize: 14, fontWeight: '600', color: isDark ? '#ffffff' : '#0f172a' },
    recentDetails: { fontSize: 12, color: isDark ? '#64748b' : '#94a3b8', marginTop: 2 },
    
    popularGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
    popularItem: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        paddingHorizontal: 12,
        paddingVertical: 8,
        borderRadius: 9999,
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
    },
    popularText: { fontSize: 13, color: isDark ? '#cbd5e1' : '#475569', fontWeight: '500' },

    // Multi-city segment controls
    multiCityContainer: { gap: 12 },
    segmentBlock: {
        backgroundColor: isDark ? 'rgba(30, 41, 59, 0.3)' : 'rgba(241, 245, 249, 0.4)',
        borderRadius: 16,
        padding: 12,
        gap: 10,
        borderWidth: 1,
        borderColor: isDark ? 'rgba(30, 41, 59, 0.5)' : '#e2e8f0',
    },
    segmentHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 4 },
    segmentTitle: { fontSize: 14, fontWeight: '700', color: isDark ? '#ffffff' : '#0f172a' },
    removeBtn: { padding: 4 },
    addFlightBtn: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 8,
        paddingVertical: 12,
        borderRadius: 12,
        borderWidth: 1.5,
        borderColor: '#2563eb',
        borderStyle: 'dashed',
        backgroundColor: isDark ? 'rgba(37, 99, 235, 0.05)' : 'rgba(37, 99, 235, 0.02)',
        marginTop: 4
    },
    addFlightText: { fontSize: 14, fontWeight: '600', color: '#2563eb' },

    // Bottom Sticky Search Button
    searchButtonContainer: {
        position: 'absolute', 
        bottom: 0, 
        left: 0, 
        right: 0,
        padding: 16, 
        paddingBottom: 32,
        backgroundColor: isDark ? '#020617' : '#ffffff',
        borderTopWidth: 1,
        borderTopColor: isDark ? '#1e293b' : '#e2e8f0',
    },
    searchSummaryBadge: {
        alignItems: 'center',
        marginBottom: 10,
    },
    searchSummaryText: {
        fontSize: 12,
        color: isDark ? '#64748b' : '#94a3b8',
        fontWeight: '500',
    },
    searchButton: {
        flexDirection: 'row', 
        alignItems: 'center', 
        justifyContent: 'center', 
        gap: 8,
        backgroundColor: '#2563eb', 
        borderRadius: 14, 
        height: 52,
        shadowColor: '#2563eb', 
        shadowOffset: { width: 0, height: 4 }, 
        shadowOpacity: 0.3, 
        shadowRadius: 12, 
        elevation: 8,
    },
    searchButtonText: { fontSize: 16, fontWeight: '600', color: '#ffffff' },
});

export default FlightSearchModal;
