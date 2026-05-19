import React, { useState, useRef, useEffect } from 'react';
import { View, Text, Pressable, StyleSheet, useColorScheme, Image, Alert, Animated, LayoutAnimation, Platform, UIManager, Easing } from 'react-native';
import { Plane, ChevronDown, ChevronUp, Shield, Luggage, Users, TrendingDown, Zap, Bell } from 'lucide-react-native';
import { FlightOffer, FlightSegmentDetail, formatTime, formatDuration, stopsLabel, providerLabel } from '../../lib/flight-types';

// Enable LayoutAnimation on Android
if (Platform.OS === 'android' && UIManager.setLayoutAnimationEnabledExperimental) {
    UIManager.setLayoutAnimationEnabledExperimental(true);
}

interface FlightCardProps {
    offer: FlightOffer;
    onSelect?: (offer: FlightOffer) => void;
    currencySymbol?: string;
    isCheapest?: boolean;
    isFastest?: boolean;
}

// ─── Airline Logo ─────────────────────────────────────────────────────

function AirlineLogo({ code, name, isDark }: { code: string; name?: string; isDark: boolean }) {
    const [failed, setFailed] = useState(false);
    const iata = (code || '').toUpperCase().slice(0, 3);
    const initials = iata.slice(0, 2) || (name || '??').slice(0, 2).toUpperCase();

    if (iata && !failed) {
        return (
            <View style={[logoStyles.container, { borderColor: isDark ? '#334155' : '#e2e8f0' }]}>
                <Image
                    source={{ uri: `https://pics.avs.io/60/60/${iata}.png` }}
                    style={logoStyles.image}
                    onError={() => setFailed(true)}
                />
            </View>
        );
    }

    return (
        <View style={[logoStyles.fallback, { backgroundColor: '#334155' }]}>
            <Text style={logoStyles.initials}>{initials}</Text>
        </View>
    );
}

// ─── Segment Row ──────────────────────────────────────────────────────

function SegmentRow({ segment, isDark, isLast }: { segment: FlightSegmentDetail; isDark: boolean; isLast: boolean }) {
    return (
        <View style={segmentStyles.wrapper}>
            {/* Left timeline line */}
            <View style={segmentStyles.timelineCol}>
                <View style={[segmentStyles.dot, { borderColor: '#6366f1' }]} />
                {!isLast && <View style={[segmentStyles.line, { backgroundColor: isDark ? '#334155' : '#e2e8f0' }]} />}
            </View>

            <View style={[segmentStyles.content, !isLast && segmentStyles.contentBorder, { borderColor: isDark ? '#1e293b' : '#f1f5f9' }]}>
                {/* Airline + flight info */}
                <View style={segmentStyles.infoRow}>
                    <AirlineLogo code={segment.airline.code} name={segment.airline.name} isDark={isDark} />
                    <View style={{ flex: 1 }}>
                        <Text style={[segmentStyles.airlineName, { color: isDark ? '#e2e8f0' : '#0f172a' }]}>
                            {segment.airline.name}
                        </Text>
                        <Text style={[segmentStyles.meta, { color: isDark ? '#64748b' : '#94a3b8' }]}>
                            {segment.flightNumber}{segment.aircraft ? ` · ${segment.aircraft}` : ''}
                        </Text>
                    </View>
                </View>

                {/* Route */}
                <View style={segmentStyles.routeRow}>
                    <View style={segmentStyles.timeCol}>
                        <Text style={[segmentStyles.time, { color: isDark ? '#ffffff' : '#0f172a' }]}>
                            {formatTime(segment.departure.time)}
                        </Text>
                        <Text style={[segmentStyles.airport, { color: isDark ? '#94a3b8' : '#64748b' }]}>
                            {segment.departure.airport}
                        </Text>
                    </View>
                    <View style={segmentStyles.durationCol}>
                        <Text style={[segmentStyles.duration, { color: isDark ? '#64748b' : '#94a3b8' }]}>
                            {formatDuration(segment.duration)}
                        </Text>
                        <View style={segmentStyles.lineRow}>
                            <View style={[segmentStyles.routeLine, { backgroundColor: isDark ? '#334155' : '#e2e8f0' }]} />
                            <Plane size={9} color="#6366f1" style={{ transform: [{ rotate: '90deg' }] }} />
                        </View>
                    </View>
                    <View style={[segmentStyles.timeCol, { alignItems: 'flex-end' }]}>
                        <Text style={[segmentStyles.time, { color: isDark ? '#ffffff' : '#0f172a' }]}>
                            {formatTime(segment.arrival.time)}
                        </Text>
                        <Text style={[segmentStyles.airport, { color: isDark ? '#94a3b8' : '#64748b' }]}>
                            {segment.arrival.airport}
                        </Text>
                    </View>
                </View>
            </View>
        </View>
    );
}

// ─── Flight Card ──────────────────────────────────────────────────────

export default function FlightCard({ offer, onSelect, currencySymbol, isCheapest, isFastest }: FlightCardProps) {
    const colorScheme = useColorScheme();
    const isDark = colorScheme === 'dark';
    const [expanded, setExpanded] = useState(false);
    const [contentHeight, setContentHeight] = useState(0);
    const slideAnim = useRef(new Animated.Value(0)).current;
    const animatedHeight = useRef(new Animated.Value(0)).current;

    const primary = offer.segments[0];
    const last = offer.segments[offer.segments.length - 1];
    const hasMultipleSegments = offer.segments.length > 1;

    // Group segments by leg
    const legGroups: { [key: number]: FlightSegmentDetail[] } = {};
    offer.segments.forEach((seg) => {
        const groupIndex = seg.segmentIndex ?? 0;
        if (!legGroups[groupIndex]) legGroups[groupIndex] = [];
        legGroups[groupIndex].push(seg);
    });
    const routeIndices = Object.keys(legGroups).map(Number).sort((a, b) => a - b);

    const isRefundable = offer.farePolicy ? offer.farePolicy.isRefundable : offer.refundable;
    const penalty = offer.farePolicy?.refundPenaltyAmount;

    // Smooth timing-driven slide animation handler
    useEffect(() => {
        Animated.parallel([
            Animated.timing(animatedHeight, {
                toValue: expanded ? contentHeight : 0,
                duration: 350,
                easing: Easing.bezier(0.25, 1, 0.5, 1),
                useNativeDriver: false,
            }),
            Animated.timing(slideAnim, {
                toValue: expanded ? 1 : 0,
                duration: 350,
                easing: Easing.bezier(0.25, 1, 0.5, 1),
                useNativeDriver: true,
            }),
        ]).start();
    }, [expanded, contentHeight]);

    const handleToggleExpand = () => {
        setExpanded(v => !v);
    };

    const handlePriceAlert = () => {
        Alert.alert(
            'Price Alert Set',
            "We'll notify you if the price drops for this flight.",
            [{ text: 'OK' }]
        );
    };

    const chevronRotation = slideAnim.interpolate({
        inputRange: [0, 1],
        outputRange: ['0deg', '180deg'],
    });

    return (
        <Pressable
            onPress={() => hasMultipleSegments && handleToggleExpand()}
            style={[cardStyles.container, {
                backgroundColor: isDark ? '#0f172a' : '#ffffff',
                borderColor: isDark ? '#1e293b' : '#e2e8f0',
            }]}
        >
            {/* Best value badges */}
            {(isCheapest || isFastest) && (
                <View style={cardStyles.badgesRow}>
                    {isCheapest && (
                        <View style={cardStyles.cheapestBadge}>
                            <TrendingDown size={9} color="#16a34a" />
                            <Text style={cardStyles.cheapestBadgeText}>Cheapest</Text>
                        </View>
                    )}
                    {isFastest && (
                        <View style={cardStyles.fastestBadge}>
                            <Zap size={9} color="#d97706" />
                            <Text style={cardStyles.fastestBadgeText}>Fastest</Text>
                        </View>
                    )}
                </View>
            )}

            {/* ── Main card body ── */}
            <View style={cardStyles.body}>
                {/* Airline logo + name */}
                <View style={cardStyles.airlineCol}>
                    <AirlineLogo code={primary.airline.code} name={primary.airline.name} isDark={isDark} />
                    <Text style={[cardStyles.airlineName, { color: isDark ? '#60a5fa' : '#2563eb' }]} numberOfLines={1}>
                        {primary.airline.name}
                    </Text>
                    <Text style={[cardStyles.flightNo, { color: isDark ? '#475569' : '#94a3b8' }]} numberOfLines={1}>
                        {primary.flightNumber}{hasMultipleSegments ? ` +${offer.segments.length - 1}` : ''}
                    </Text>
                </View>

                {/* Route timeline */}
                <View style={cardStyles.routeCol}>
                    {/* Times */}
                    <View style={cardStyles.timesRow}>
                        <View style={cardStyles.timeBlock}>
                            <Text style={[cardStyles.timeText, { color: isDark ? '#ffffff' : '#0f172a' }]}>
                                {formatTime(primary.departure.time)}
                            </Text>
                            <Text style={[cardStyles.iataText, { color: isDark ? '#64748b' : '#94a3b8' }]}>
                                {primary.departure.airport}
                            </Text>
                        </View>

                        <View style={cardStyles.durationBlock}>
                            <Text style={[cardStyles.durationText, { color: isDark ? '#64748b' : '#94a3b8' }]}>
                                {formatDuration(offer.totalDuration)}
                            </Text>
                            <View style={cardStyles.lineRow}>
                                <View style={[cardStyles.routeLine, { backgroundColor: isDark ? '#334155' : '#e2e8f0' }]} />
                                <Plane size={10} color="#6366f1" style={{ transform: [{ rotate: '90deg' }] }} />
                                <View style={[cardStyles.routeLine, { backgroundColor: isDark ? '#334155' : '#e2e8f0' }]} />
                            </View>
                            <Text style={[cardStyles.stopsText, { color: offer.totalStops === 0 ? '#10b981' : '#f59e0b' }]}>
                                {stopsLabel(offer.totalStops)}
                            </Text>
                        </View>

                        <View style={[cardStyles.timeBlock, { alignItems: 'flex-end' }]}>
                            <Text style={[cardStyles.timeText, { color: isDark ? '#ffffff' : '#0f172a' }]}>
                                {formatTime(last.arrival.time)}
                            </Text>
                            <Text style={[cardStyles.iataText, { color: isDark ? '#64748b' : '#94a3b8' }]}>
                                {last.arrival.airport}
                            </Text>
                        </View>
                    </View>

                    {/* Tags */}
                    <View style={cardStyles.tagsRow}>
                        {isRefundable && penalty === 0 ? (
                            <View style={[cardStyles.badge, { backgroundColor: isDark ? 'rgba(16,185,129,0.1)' : '#ecfdf5', borderColor: isDark ? '#065f46' : '#a7f3d0' }]}>
                                <Shield size={9} color={isDark ? '#34d399' : '#059669'} />
                                <Text style={[cardStyles.badgeText, { color: isDark ? '#34d399' : '#059669' }]}>Free cancel</Text>
                            </View>
                        ) : isRefundable ? (
                            <View style={[cardStyles.badge, { backgroundColor: isDark ? 'rgba(245,158,11,0.1)' : '#fffbeb', borderColor: isDark ? '#92400e' : '#fde68a' }]}>
                                <Text style={[cardStyles.badgeText, { color: isDark ? '#fbbf24' : '#b45309' }]}>Refundable</Text>
                            </View>
                        ) : (
                            <View style={[cardStyles.badge, { backgroundColor: isDark ? '#1e293b' : '#f1f5f9', borderColor: isDark ? '#334155' : '#e2e8f0' }]}>
                                <Text style={[cardStyles.badgeText, { color: isDark ? '#475569' : '#94a3b8' }]}>Non-refundable</Text>
                            </View>
                        )}

                        {offer.baggage && (
                            <View style={[cardStyles.badge, { backgroundColor: isDark ? '#1e293b' : '#f1f5f9', borderColor: isDark ? '#334155' : '#e2e8f0' }]}>
                                <Luggage size={9} color={isDark ? '#94a3b8' : '#64748b'} />
                                <Text style={[cardStyles.badgeText, { color: isDark ? '#94a3b8' : '#64748b' }]}>
                                    {Number(offer.baggage.checkedBags || 0) > 0 ? `${offer.baggage.checkedBags} bag` : 'No bag'}
                                </Text>
                            </View>
                        )}

                        <View style={[cardStyles.badge, { backgroundColor: isDark ? '#1e293b' : '#f1f5f9', borderColor: isDark ? '#334155' : '#e2e8f0' }]}>
                            <Text style={[cardStyles.badgeText, { color: isDark ? '#94a3b8' : '#64748b', textTransform: 'capitalize' }]}>
                                {(primary.cabinClass || 'economy').replace('_', ' ')}
                            </Text>
                        </View>

                        <View style={[cardStyles.badge, { backgroundColor: isDark ? 'rgba(37,99,235,0.1)' : '#eff6ff', borderColor: isDark ? '#1e40af' : '#bfdbfe' }]}>
                            <Text style={[cardStyles.badgeText, { color: isDark ? '#60a5fa' : '#2563eb' }]}>
                                {providerLabel(offer.provider)}
                            </Text>
                        </View>

                        {offer.seatsRemaining != null && offer.seatsRemaining > 0 && offer.seatsRemaining <= 6 && (
                            <View style={[cardStyles.badge, {
                                backgroundColor: offer.seatsRemaining <= 3 ? (isDark ? 'rgba(239,68,68,0.1)' : '#fef2f2') : (isDark ? 'rgba(245,158,11,0.1)' : '#fffbeb'),
                                borderColor: offer.seatsRemaining <= 3 ? (isDark ? '#7f1d1d' : '#fecaca') : (isDark ? '#92400e' : '#fde68a'),
                            }]}>
                                <Users size={9} color={offer.seatsRemaining <= 3 ? '#ef4444' : '#f59e0b'} />
                                <Text style={[cardStyles.badgeText, { color: offer.seatsRemaining <= 3 ? (isDark ? '#f87171' : '#ef4444') : (isDark ? '#fbbf24' : '#f59e0b') }]}>
                                    {offer.seatsRemaining <= 3 ? `Only ${offer.seatsRemaining} left!` : `${offer.seatsRemaining} seats`}
                                </Text>
                            </View>
                        )}
                    </View>
                </View>
            </View>

            {/* ── Footer: price + select + bell ── */}
            <View style={[cardStyles.footer, { borderTopColor: isDark ? '#1e293b' : '#f1f5f9' }]}>
                <View style={cardStyles.priceBlock}>
                    <Text style={[cardStyles.priceText, { color: isDark ? '#38bdf8' : '#2563eb' }]}>
                        <Text style={cardStyles.currencySymbol}>{currencySymbol || offer.price.currency} </Text>
                        {Math.round(offer.price.pricePerAdult).toLocaleString()}
                    </Text>
                    <Text style={[cardStyles.taxesNote, { color: isDark ? '#475569' : '#94a3b8' }]}>
                        /person · incl. taxes
                    </Text>
                </View>

                <View style={cardStyles.footerActions}>
                    <Pressable onPress={handlePriceAlert} style={[cardStyles.bellButton, { backgroundColor: isDark ? '#1e293b' : '#f1f5f9' }]} hitSlop={8}>
                        <Bell size={14} color={isDark ? '#475569' : '#94a3b8'} />
                    </Pressable>
                    <Pressable
                        style={cardStyles.selectButton}
                        onPress={(e) => { e.stopPropagation?.(); onSelect?.(offer); }}
                    >
                        <Text style={cardStyles.selectButtonText}>Select</Text>
                    </Pressable>
                </View>
            </View>

            {/* ── Animated segment drawer ── */}
            {hasMultipleSegments && (
                <>
                    {/* Expand toggle row */}
                    <Pressable
                        onPress={handleToggleExpand}
                        style={[cardStyles.expandRow, { borderTopColor: isDark ? '#1e293b' : '#f1f5f9' }]}
                    >
                        <Text style={cardStyles.expandText}>
                            {expanded ? 'Hide segments' : 'Show all segments'}
                        </Text>
                        <Animated.View style={{ transform: [{ rotate: chevronRotation }] }}>
                            <ChevronDown size={14} color="#6366f1" />
                        </Animated.View>
                    </Pressable>

                    <Animated.View style={{ height: animatedHeight, overflow: 'hidden' }}>
                        <View
                            onLayout={(e) => {
                                const newHeight = e.nativeEvent.layout.height;
                                if (newHeight > 0 && newHeight !== contentHeight) {
                                    setContentHeight(newHeight);
                                }
                            }}
                            style={[cardStyles.segmentInner, { borderTopColor: isDark ? '#1e293b' : '#f1f5f9' }]}
                        >
                            {routeIndices.map((idx, routeIndex) => {
                                const legSegments = legGroups[idx];
                                if (!legSegments?.length) return null;
                                const label = routeIndices.length === 2
                                    ? (routeIndex === 0 ? 'Outbound' : 'Return')
                                    : `Leg ${routeIndex + 1}`;
                                return (
                                    <View key={idx} style={cardStyles.legGroup}>
                                        {routeIndices.length > 1 && (
                                            <Text style={[cardStyles.legLabel, { color: isDark ? '#64748b' : '#94a3b8' }]}>
                                                {label}
                                            </Text>
                                        )}
                                        {legSegments.map((seg, i) => (
                                            <SegmentRow
                                                key={`${idx}-${i}`}
                                                segment={seg}
                                                isDark={isDark}
                                                isLast={i === legSegments.length - 1}
                                            />
                                        ))}
                                    </View>
                                );
                            })}
                        </View>
                    </Animated.View>
                </>
            )}
        </Pressable>
    );
}

// ─── Logo Styles ──────────────────────────────────────────────────────

const logoStyles = StyleSheet.create({
    container: {
        width: 44,
        height: 44,
        borderRadius: 10,
        borderWidth: 1,
        backgroundColor: '#ffffff',
        alignItems: 'center',
        justifyContent: 'center',
        overflow: 'hidden',
    },
    image: {
        width: 36,
        height: 36,
        resizeMode: 'contain',
    },
    fallback: {
        width: 44,
        height: 44,
        borderRadius: 10,
        alignItems: 'center',
        justifyContent: 'center',
    },
    initials: {
        fontSize: 14,
        fontWeight: '700',
        color: '#ffffff',
    },
});

// ─── Segment Styles ───────────────────────────────────────────────────

const segmentStyles = StyleSheet.create({
    wrapper: {
        flexDirection: 'row',
        gap: 10,
        minHeight: 60,
    },
    timelineCol: {
        width: 16,
        alignItems: 'center',
        paddingTop: 6,
    },
    dot: {
        width: 8,
        height: 8,
        borderRadius: 4,
        borderWidth: 2,
        backgroundColor: 'transparent',
    },
    line: {
        flex: 1,
        width: 1.5,
        marginTop: 3,
    },
    content: {
        flex: 1,
        paddingBottom: 12,
    },
    contentBorder: {
        borderBottomWidth: 1,
    },
    infoRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 8,
        marginBottom: 6,
    },
    airlineName: {
        fontSize: 12,
        fontWeight: '600',
    },
    meta: {
        fontSize: 10,
        marginTop: 1,
    },
    routeRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 6,
    },
    timeCol: {
        minWidth: 40,
    },
    time: {
        fontSize: 13,
        fontWeight: '600',
    },
    airport: {
        fontSize: 10,
        marginTop: 1,
    },
    durationCol: {
        flex: 1,
        alignItems: 'center',
    },
    duration: {
        fontSize: 10,
        marginBottom: 2,
    },
    lineRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 2,
        width: '100%',
    },
    routeLine: {
        flex: 1,
        height: 1,
    },
});

// ─── Card Styles ──────────────────────────────────────────────────────

const cardStyles = StyleSheet.create({
    container: {
        borderRadius: 14,
        borderWidth: 1,
        marginBottom: 10,
        overflow: 'hidden',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 1 },
        shadowOpacity: 0.04,
        shadowRadius: 6,
        elevation: 2,
    },
    badgesRow: {
        flexDirection: 'row',
        gap: 5,
        paddingHorizontal: 12,
        paddingTop: 8,
        paddingBottom: 0,
    },
    cheapestBadge: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 3,
        paddingHorizontal: 7,
        paddingVertical: 2,
        borderRadius: 20,
        backgroundColor: 'rgba(22,163,74,0.12)',
    },
    cheapestBadgeText: {
        fontSize: 9,
        fontWeight: '700',
        color: '#16a34a',
        textTransform: 'uppercase',
        letterSpacing: 0.4,
    },
    fastestBadge: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 3,
        paddingHorizontal: 7,
        paddingVertical: 2,
        borderRadius: 20,
        backgroundColor: 'rgba(217,119,6,0.12)',
    },
    fastestBadgeText: {
        fontSize: 9,
        fontWeight: '700',
        color: '#d97706',
        textTransform: 'uppercase',
        letterSpacing: 0.4,
    },
    // ── Horizontal card body: logo col + route col ──
    body: {
        flexDirection: 'row',
        alignItems: 'flex-start',
        paddingHorizontal: 12,
        paddingTop: 10,
        paddingBottom: 4,
        gap: 10,
    },
    airlineCol: {
        width: 52,
        alignItems: 'center',
        gap: 3,
    },
    airlineName: {
        fontSize: 9,
        fontWeight: '600',
        textAlign: 'center',
    },
    flightNo: {
        fontSize: 9,
        textAlign: 'center',
    },
    routeCol: {
        flex: 1,
    },
    timesRow: {
        flexDirection: 'row',
        alignItems: 'center',
        marginBottom: 8,
    },
    timeBlock: {
        minWidth: 44,
    },
    timeText: {
        fontSize: 17,
        fontWeight: '700',
        letterSpacing: -0.3,
    },
    iataText: {
        fontSize: 10,
        marginTop: 1,
        fontWeight: '500',
    },
    durationBlock: {
        flex: 1,
        alignItems: 'center',
        paddingHorizontal: 6,
    },
    durationText: {
        fontSize: 10,
        marginBottom: 3,
    },
    lineRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 2,
        width: '100%',
    },
    routeLine: {
        flex: 1,
        height: 1.5,
        borderRadius: 1,
    },
    stopsText: {
        fontSize: 10,
        fontWeight: '600',
        marginTop: 3,
    },
    tagsRow: {
        flexDirection: 'row',
        flexWrap: 'wrap',
        gap: 4,
        marginBottom: 4,
    },
    badge: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 3,
        paddingHorizontal: 5,
        paddingVertical: 2,
        borderRadius: 5,
        borderWidth: 1,
    },
    badgeText: {
        fontSize: 9,
        fontWeight: '500',
    },
    // ── Footer ──
    footer: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        paddingHorizontal: 12,
        paddingVertical: 10,
        borderTopWidth: 1,
    },
    priceBlock: {},
    priceText: {
        fontSize: 19,
        fontWeight: '800',
        letterSpacing: -0.5,
    },
    currencySymbol: {
        fontSize: 13,
        fontWeight: '600',
    },
    taxesNote: {
        fontSize: 9,
        marginTop: 1,
    },
    footerActions: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 8,
    },
    bellButton: {
        width: 32,
        height: 32,
        borderRadius: 8,
        alignItems: 'center',
        justifyContent: 'center',
    },
    selectButton: {
        paddingHorizontal: 18,
        paddingVertical: 9,
        backgroundColor: '#2563eb',
        borderRadius: 9,
    },
    selectButtonText: {
        fontSize: 13,
        fontWeight: '700',
        color: '#ffffff',
    },
    // ── Segment drawer ──
    expandRow: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 5,
        paddingVertical: 7,
        borderTopWidth: 1,
    },
    expandText: {
        fontSize: 11,
        color: '#6366f1',
        fontWeight: '600',
    },
    segmentInner: {
        paddingHorizontal: 12,
        paddingBottom: 10,
        paddingTop: 4,
        borderTopWidth: 1,
    },
    legGroup: {
        marginTop: 4,
    },
    legLabel: {
        fontSize: 9,
        fontWeight: '700',
        letterSpacing: 1,
        textTransform: 'uppercase',
        marginBottom: 6,
    },
});
