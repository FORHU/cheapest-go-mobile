import Mapbox, { Camera, CircleLayer, MapView, MarkerView, ShapeSource } from '@rnmapbox/maps';
import { Layers, X } from 'lucide-react-native';
import { memo, useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { ActivityIndicator, Dimensions, Image, Pressable, StyleSheet, Text, View } from 'react-native';
import { MAPBOX_TOKEN } from '../../lib/config';

Mapbox.setAccessToken(MAPBOX_TOKEN);

const MAP_STYLES = {
    dark: 'mapbox://styles/mapbox/dark-v11',
    streets: 'mapbox://styles/mapbox/streets-v12',
    satellite: 'mapbox://styles/mapbox/satellite-streets-v12',
    outdoors: 'mapbox://styles/mapbox/outdoors-v12',
} as const;

type StyleKey = keyof typeof MAP_STYLES;

interface MapboxWebViewProps {
    hotels: any[];
    selectedHotelId: string | null;
    flyToOnSelectId?: string | null;
    onHotelSelect: (hotel: any) => void;
    onHotelNavigate?: (hotelId: string) => void;
    onDeselect?: () => void;
    isDark: boolean;
    center?: [number, number];
    currencySymbol: string;
}

const FALLBACK_IMG = 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=300&q=80';
// Neutral world-view fallback, used only when neither an explicit destination
// center nor any hotel coordinates are available yet (so a stale fallback never
// pins the map to a specific city like Baguio).
const DEFAULT_CENTER: [number, number] = [0, 20];

// Max price pills (MarkerViews) rendered at once. Kept well under rnmapbox's ~100
// view-annotation ceiling so pills appear instantly and never drop out during zoom.
const MAX_PILLS = 60;

// Approximate on-screen footprint of the focused hotel's popup card, which is
// bottom-anchored at its pin: it fans out to each side and stretches upward (north).
// rnmapbox gives no reliable paint order between MarkerViews, so instead of fighting
// z-index we clear the space — while a card is open we drop any *other* pill whose
// coordinate falls inside this box, so none can render over the card. Their location
// dots (the GL CircleLayer) stay, so surrounding hotels remain visible.
const CARD_HALF_W_PX = 115; // half card width + a little slack for the pill
const CARD_UP_PX = 200;     // card height above the pin (images + pill + margins)
const CARD_DOWN_PX = 18;    // small pad below the pin for neighbours' own pills

const WINDOW = Dimensions.get('window');

// A non-selected hotel pill. Rendered only for hotels currently on screen (capped),
// so the live MarkerView count stays well under the ~100 where they start dropping
// out during zoom — these appear instantly. Pill + connector line; the location dot
// is the GL CircleLayer below it.
const PillMarker = memo(function PillMarker({
    hotel,
    number,
    currencySymbol,
    onSelect,
}: {
    hotel: any;
    number: number;
    currencySymbol: string;
    onSelect: (hotel: any) => void;
}) {
    const price = hotel.displayConvertedPrice || hotel.displayPrice || '???';
    return (
        <MarkerView
            coordinate={[hotel.longitude, hotel.latitude]}
            anchor={{ x: 0.5, y: 1 }}
            allowOverlap
        >
            <Pressable onPress={() => onSelect(hotel)} style={styles.markerWrapper}>
                <View style={styles.pill}>
                    <View style={styles.pillNum}>
                        <Text style={styles.pillNumText}>{number}</Text>
                    </View>
                    <Text style={styles.pillPrice}>{currencySymbol}{price}</Text>
                </View>
                <View style={styles.pinContainer}>
                    <View style={styles.pinLine} />
                </View>
            </Pressable>
        </MarkerView>
    );
});

// The focused hotel keeps a real MarkerView (just one — far under MarkerView's ~100
// limit) so it can show the rich popup card and the highlighted blue pill.
const SelectedMarker = memo(function SelectedMarker({
    hotel,
    number,
    currencySymbol,
    onSelect,
    onNavigate,
    onClose,
}: {
    hotel: any;
    number: number;
    currencySymbol: string;
    onSelect: (hotel: any) => void;
    onNavigate?: (hotelId: string) => void;
    onClose?: () => void;
}) {
    const price = hotel.displayConvertedPrice || hotel.displayPrice || '???';
    const imgs = Array.isArray(hotel.imageUrls) && hotel.imageUrls.length > 0
        ? hotel.imageUrls.slice(0, 4)
        : [hotel.thumbnailUrl || FALLBACK_IMG];
    while (imgs.length < 4) imgs.push(imgs[0]);

    return (
        <MarkerView
            coordinate={[hotel.longitude, hotel.latitude]}
            anchor={{ x: 0.5, y: 1 }}
            allowOverlap
        >
            <Pressable onPress={() => onSelect(hotel)} style={[styles.markerWrapper, styles.markerWrapperSelected]}>
                <Pressable
                    style={styles.popupCard}
                    onPress={(e) => {
                        e.stopPropagation();
                        onNavigate?.(hotel.hotelId);
                    }}
                >
                    <View style={styles.imgGrid}>
                        {imgs.map((url: string, i: number) => (
                            <Image
                                key={i}
                                source={{ uri: url }}
                                style={styles.gridImg}
                                resizeMode="cover"
                            />
                        ))}
                    </View>
                    {/* Close button — the card now stays open until the user taps this. */}
                    <Pressable
                        style={styles.closeBtn}
                        hitSlop={10}
                        onPress={(e) => {
                            e.stopPropagation();
                            onClose?.();
                        }}
                    >
                        <X size={15} color="#fff" strokeWidth={2.5} />
                    </Pressable>
                </Pressable>
                <View style={[styles.pill, styles.pillSelected]}>
                    <View style={[styles.pillNum, styles.pillNumSelected]}>
                        <Text style={[styles.pillNumText, styles.pillNumTextSelected]}>
                            {number}
                        </Text>
                    </View>
                    <Text style={[styles.pillPrice, styles.pillPriceSelected]}>
                        {currencySymbol}{price}
                    </Text>
                </View>
                <View style={styles.pinContainer}>
                    <View style={[styles.pinLine, styles.pinLineSelected]} />
                    <View style={[styles.pinDot, styles.pinDotSelected]} />
                </View>
            </Pressable>
        </MarkerView>
    );
});

export default function MapboxWebView({
    hotels,
    selectedHotelId,
    flyToOnSelectId,
    onHotelSelect,
    onHotelNavigate,
    onDeselect,
    isDark,
    center,
    currencySymbol,
}: MapboxWebViewProps) {
    const cameraRef = useRef<Camera>(null);
    const [styleKey, setStyleKey] = useState<StyleKey>('dark');
    const [showLayers, setShowLayers] = useState(false);
    const [isLoading, setIsLoading] = useState(true);
    // Latest settled map viewport — drives which hotels get a price pill.
    const [visibleBounds, setVisibleBounds] = useState<{ ne: [number, number]; sw: [number, number] } | null>(null);
    // Actual on-screen size of the map view — used with visibleBounds to convert the
    // popup card's pixel footprint into a geographic box for pill suppression.
    const [mapSize, setMapSize] = useState<{ w: number; h: number }>({ w: WINDOW.width, h: WINDOW.height });

    // Center of the loaded hotels — used so the map opens directly on the searched
    // city instead of the hardcoded default while the destination geocode resolves.
    const hotelsCenter = useMemo<[number, number] | null>(() => {
        const lngs = hotels.map(h => h.longitude).filter((n: number) => Number.isFinite(n) && n !== 0);
        const lats = hotels.map(h => h.latitude).filter((n: number) => Number.isFinite(n) && n !== 0);
        if (!lngs.length || !lats.length) return null;
        return [
            (Math.min(...lngs) + Math.max(...lngs)) / 2,
            (Math.min(...lats) + Math.max(...lats)) / 2,
        ];
    }, [hotels]);

    // Resolved fresh each render so the Camera follows the searched destination as
    // soon as the geocode (or hotel centroid) resolves, instead of being frozen to
    // whatever fallback existed at mount: explicit destination → hotel centroid → default.
    const resolvedCenter = center ?? hotelsCenter ?? DEFAULT_CENTER;
    const hasRealCenter = Boolean(center ?? hotelsCenter);

    // Keep the map centered on the search destination — on load and whenever the
    // destination or result set changes — unless a hotel is currently focused.
    // Falls back to framing all hotels only when no destination point is provided.
    useEffect(() => {
        if (selectedHotelId) return;
        if (center) {
            cameraRef.current?.flyTo(center, 2000);
        } else if (hotels.length) {
            const lngs = hotels.map(h => h.longitude);
            const lats = hotels.map(h => h.latitude);
            const ne: [number, number] = [Math.max(...lngs), Math.max(...lats)];
            const sw: [number, number] = [Math.min(...lngs), Math.min(...lats)];
            cameraRef.current?.fitBounds(ne, sw, [80, 80, 80, 80], 250);
        }
    }, [center, hotels, selectedHotelId]);

    // Pan to a hotel when focused via card swipe. Uses a flat easeTo pan (no flyTo
    // zoom-out/zoom-in swoop) at a short duration so it feels snappy, not slow.
    useEffect(() => {
        if (!flyToOnSelectId) return;
        const hotel = hotels.find(h => h.hotelId === flyToOnSelectId);
        if (hotel) {
            cameraRef.current?.setCamera({
                centerCoordinate: [hotel.longitude, hotel.latitude],
                animationMode: 'easeTo',
                animationDuration: 500,
            });
        }
    }, [flyToOnSelectId, hotels]);

    // Hotels whose preview card is currently open on the map. Independent of the parent's
    // single "focused" hotel: opening another card adds to this set rather than replacing,
    // so multiple cards can stay open until the user closes each with its X button.
    const [openIds, setOpenIds] = useState<string[]>([]);

    // Tapping a hotel marker (price pill or location dot) opens its card AND focuses it in
    // the parent (fly-to + carousel sync). Carousel swipes call onHotelSelect directly and
    // never reach here, so browsing the carousel moves the camera without piling up cards.
    const handleMarkerSelect = useCallback((hotel: any) => {
        setOpenIds(prev => (prev.includes(hotel.hotelId) ? prev : [...prev, hotel.hotelId]));
        onHotelSelect(hotel);
    }, [onHotelSelect]);

    // Drop cards for hotels no longer in the result set (e.g. after a new search).
    useEffect(() => {
        setOpenIds(prev => {
            const next = prev.filter(id => hotels.some(h => h.hotelId === id));
            return next.length === prev.length ? prev : next;
        });
    }, [hotels]);

    // Close a single card. If it was the parent's focused hotel, clear that selection too.
    const closeCard = useCallback((id: string) => {
        setOpenIds(prev => prev.filter(x => x !== id));
        if (id === selectedHotelId) onDeselect?.();
    }, [selectedHotelId, onDeselect]);

    // Rank (1-based, by the parent's sort order) + display price for every hotel.
    const ranked = useMemo(() =>
        hotels.map((hotel, i) => ({
            hotel,
            number: i + 1,
            price: hotel.displayConvertedPrice || hotel.displayPrice || '???',
        })),
        [hotels],
    );

    // Hotels with an open preview card, resolved to their ranked entry (stale ids pruned).
    const openHotels = useMemo(
        () => openIds
            .map(id => ranked.find(r => r.hotel.hotelId === id))
            .filter((r): r is { hotel: any; number: number; price: string } => Boolean(r)),
        [openIds, ranked],
    );

    // Location dots for every hotel — kept visible even while cards are open so the
    // surrounding hotels stay on the map. Hotels with an open card are excluded because
    // their SelectedMarker already draws its own highlighted pin dot at that coordinate.
    const featureCollection = useMemo(() => ({
        type: 'FeatureCollection' as const,
        features: ranked
            .filter(r => !openIds.includes(r.hotel.hotelId))
            .map(r => ({
                type: 'Feature' as const,
                id: r.hotel.hotelId,
                geometry: { type: 'Point' as const, coordinates: [r.hotel.longitude, r.hotel.latitude] },
                properties: { hotelId: r.hotel.hotelId },
            })),
    }), [ranked, openIds]);

    // Price pills for on-screen hotels (capped). Hotels with an open card are excluded
    // because their SelectedMarker renders its own highlighted pill. Additionally, we drop
    // any *other* pill whose coordinate falls under an open card's on-screen footprint —
    // since rnmapbox can't guarantee a card paints above neighbouring MarkerViews, we clear
    // the space so none can cover it.
    // Before the first settle (visibleBounds null) show the first N so pills are instant.
    const visiblePills = useMemo(() => {
        const others = ranked.filter(r => !openIds.includes(r.hotel.hotelId));
        if (!visibleBounds) return others.slice(0, MAX_PILLS);
        const { ne, sw } = visibleBounds;

        // One geographic box per open card, derived from the card's pixel footprint.
        const degPerPxLng = (ne[0] - sw[0]) / mapSize.w;
        const degPerPxLat = (ne[1] - sw[1]) / mapSize.h; // lat grows upward (north)
        const cardBoxes = openHotels.map(r => {
            const sLng = r.hotel.longitude;
            const sLat = r.hotel.latitude;
            return {
                west: sLng - CARD_HALF_W_PX * degPerPxLng,
                east: sLng + CARD_HALF_W_PX * degPerPxLng,
                south: sLat - CARD_DOWN_PX * degPerPxLat,
                north: sLat + CARD_UP_PX * degPerPxLat,
            };
        });

        return others
            .filter(r => {
                const lng = r.hotel.longitude;
                const lat = r.hotel.latitude;
                if (lng < sw[0] || lng > ne[0] || lat < sw[1] || lat > ne[1]) return false;
                const underACard = cardBoxes.some(b =>
                    lng >= b.west && lng <= b.east && lat >= b.south && lat <= b.north);
                return !underACard;
            })
            .slice(0, MAX_PILLS);
    }, [ranked, openIds, visibleBounds, openHotels, mapSize]);

    return (
        <View style={styles.container}>
            <MapView
                style={styles.map}
                onLayout={(e) => {
                    const { width, height } = e.nativeEvent.layout;
                    if (width && height) setMapSize({ w: width, h: height });
                }}
                styleURL={MAP_STYLES[styleKey]}
                compassEnabled={false}
                logoEnabled={false}
                attributionEnabled={false}
                scaleBarEnabled={false}
                pitchEnabled={false}
                rotateEnabled={false}
                onDidFinishLoadingMap={() => setIsLoading(false)}
                onMapIdle={(state) => {
                    const b = state?.properties?.bounds;
                    if (b?.ne && b?.sw) {
                        setVisibleBounds({ ne: b.ne as [number, number], sw: b.sw as [number, number] });
                    }
                }}
            >
                <Camera
                    ref={cameraRef}
                    defaultSettings={{
                        centerCoordinate: resolvedCenter,
                        zoomLevel: hasRealCenter ? 12 : 2,
                    }}
                />

                {/* Every hotel's exact location as a GL dot — instant, and never vanishes on
                    zoom. Tapping a dot selects that hotel (useful for ones past the pill cap). */}
                <ShapeSource
                    id="hotelMarkers"
                    shape={featureCollection}
                    onPress={(e) => {
                        const feature = e.features?.[0] as any;
                        const id = feature?.properties?.hotelId ?? feature?.id;
                        const hotel = hotels.find(h => h.hotelId === id);
                        if (hotel) handleMarkerSelect(hotel);
                    }}
                >
                    <CircleLayer
                        id="hotelDots"
                        style={{
                            circleRadius: 2.5,
                            circleColor: '#3b82f6',
                            circleStrokeWidth: 1,
                            circleStrokeColor: '#ffffff',
                        }}
                    />
                </ShapeSource>

                {/* Price pills for on-screen hotels only (capped) — real views, so they
                    appear instantly and stay pixel-exact. Off-screen hotels show just a dot. */}
                {visiblePills.map(r => (
                    <PillMarker
                        key={r.hotel.hotelId}
                        hotel={r.hotel}
                        number={r.number}
                        currencySymbol={currencySymbol}
                        onSelect={handleMarkerSelect}
                    />
                ))}

                {/* Open cards: one MarkerView each with the rich popup + blue pill. They stay
                    open until the user closes each with its X — opening another just adds one. */}
                {openHotels.map(r => (
                    <SelectedMarker
                        key={r.hotel.hotelId}
                        hotel={r.hotel}
                        number={r.number}
                        currencySymbol={currencySymbol}
                        onSelect={handleMarkerSelect}
                        onNavigate={onHotelNavigate}
                        onClose={() => closeCard(r.hotel.hotelId)}
                    />
                ))}
            </MapView>

            {/* Layer toggle */}
            <Pressable
                style={[
                    styles.layersBtn,
                    {
                        backgroundColor: isDark ? '#1e293b' : 'white',
                        borderColor: isDark ? '#334155' : '#e2e8f0',
                    },
                ]}
                onPress={() => setShowLayers(v => !v)}
            >
                <Layers size={20} color={isDark ? 'white' : '#1e293b'} />
            </Pressable>

            {showLayers && (
                <View
                    style={[
                        styles.layersPanel,
                        {
                            backgroundColor: isDark ? '#1e293b' : 'white',
                            borderColor: isDark ? '#334155' : '#e2e8f0',
                        },
                    ]}
                >
                    {(['streets', 'dark', 'satellite', 'outdoors'] as StyleKey[]).map(key => (
                        <Pressable
                            key={key}
                            style={[styles.layerOpt, styleKey === key && styles.layerOptActive]}
                            onPress={() => { setStyleKey(key); setShowLayers(false); }}
                        >
                            <Text
                                style={[
                                    styles.layerOptText,
                                    { color: isDark ? '#cbd5e1' : '#475569' },
                                    styleKey === key && styles.layerOptTextActive,
                                ]}
                            >
                                {key === 'streets' ? 'Standard' : key === 'dark' ? 'Dark' : key === 'satellite' ? 'Satellite' : 'Outdoors'}
                            </Text>
                        </Pressable>
                    ))}
                </View>
            )}

            {isLoading && (
                <View style={styles.loading}>
                    <ActivityIndicator size="large" color="#2563eb" />
                </View>
            )}
        </View>
    );
}

const styles = StyleSheet.create({
    container: { flex: 1 },
    map: { flex: 1 },
    loading: {
        position: 'absolute', left: 0, right: 0, top: 0, bottom: 0,
        backgroundColor: 'rgba(255,255,255,0.8)',
        alignItems: 'center',
        justifyContent: 'center',
    },
    markerWrapper: {
        alignItems: 'center',
    },
   
    markerWrapperSelected: {
        zIndex: 1999,
        elevation: 24,
    },
    popupCard: {
        width: 210,
        borderRadius: 14,
        overflow: 'hidden',
        marginBottom: 6,
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 12 },
        shadowOpacity: 0.28,
        shadowRadius: 28,
        elevation: 24,
        zIndex: 1999,
    },
    closeBtn: {
        position: 'absolute',
        top: 6,
        right: 6,
        width: 26,
        height: 26,
        borderRadius: 13,
        backgroundColor: 'rgba(15,23,42,0.65)',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 2,
    },
    imgGrid: {
        flexDirection: 'row',
        flexWrap: 'wrap',
        width: 210,
        height: 150,
        gap: 2,
    },
    gridImg: {
        width: 103,
        height: 74,
        backgroundColor: '#f1f5f9',
    },
    pill: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: 'white',
        paddingVertical: 3,
        paddingLeft: 3,
        paddingRight: 7,
        borderRadius: 20,
        borderWidth: 1,
        borderColor: '#e2e8f0',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 3 },
        shadowOpacity: 0.12,
        shadowRadius: 5,
        elevation: 3,
        gap: 4,
    },
    pillSelected: {
        backgroundColor: '#2563eb',
        borderColor: '#1d4ed8',
        shadowColor: '#2563eb',
        shadowOpacity: 0.4,
        shadowRadius: 12,
        elevation: 8,
    },
    pillNum: {
        width: 16,
        height: 16,
        borderRadius: 8,
        backgroundColor: '#3b82f6',
        alignItems: 'center',
        justifyContent: 'center',
    },
    pillNumSelected: {
        backgroundColor: 'white',
    },
    pillNumText: {
        color: 'white',
        fontSize: 9,
        fontWeight: '800',
    },
    pillNumTextSelected: {
        color: '#2563eb',
    },
    pillPrice: {
        fontSize: 11,
        fontWeight: '800',
        color: '#1e293b',
    },
    pillPriceSelected: {
        color: 'white',
    },
    pinContainer: {
        alignItems: 'center',
    },
    pinLine: {
        width: 2,
        height: 8,
        backgroundColor: '#3b82f6',
    },
    pinLineSelected: {
        backgroundColor: '#2563eb',
        height: 12,
    },
    pinDot: {
        width: 5,
        height: 5,
        borderRadius: 2.5,
        backgroundColor: '#3b82f6',
        borderWidth: 1,
        borderColor: 'white',
    },
    pinDotSelected: {
        backgroundColor: '#2563eb',
    },
    layersBtn: {
        position: 'absolute',
        top: 16,
        left: 16,
        width: 44,
        height: 44,
        borderRadius: 22,
        borderWidth: 1,
        alignItems: 'center',
        justifyContent: 'center',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.15,
        shadowRadius: 12,
        elevation: 4,
    },
    layersPanel: {
        position: 'absolute',
        top: 70,
        left: 20,
        borderRadius: 16,
        borderWidth: 1,
        padding: 8,
        width: 150,
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 10 },
        shadowOpacity: 0.1,
        shadowRadius: 15,
        elevation: 5,
    },
    layerOpt: {
        paddingVertical: 10,
        paddingHorizontal: 14,
        borderRadius: 8,
    },
    layerOptActive: {
        backgroundColor: '#2563eb',
    },
    layerOptText: {
        fontSize: 13,
    },
    layerOptTextActive: {
        color: 'white',
    },
});
