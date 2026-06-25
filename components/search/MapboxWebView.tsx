// @ts-ignore – @rnmapbox/maps has no bundled TypeScript declarations
import Mapbox, { Camera, MapView, MarkerView } from '@rnmapbox/maps';
import { Layers } from 'lucide-react-native';
import { useEffect, useRef, useState } from 'react';
import { ActivityIndicator, Image, Pressable, StyleSheet, Text, View } from 'react-native';
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
const DEFAULT_CENTER: [number, number] = [120.596, 16.402];

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

    // Fit bounds to all hotels when they load (only when nothing is selected yet)
    useEffect(() => {
        if (!hotels.length || selectedHotelId) return;
        const lngs = hotels.map(h => h.longitude);
        const lats = hotels.map(h => h.latitude);
        const ne: [number, number] = [Math.max(...lngs), Math.max(...lats)];
        const sw: [number, number] = [Math.min(...lngs), Math.min(...lats)];
        cameraRef.current?.fitBounds(ne, sw, [80, 80, 80, 80], 1000);
    }, [hotels, selectedHotelId]);

    // Fly to hotel when selected via card swipe
    useEffect(() => {
        if (!flyToOnSelectId) return;
        const hotel = hotels.find(h => h.hotelId === flyToOnSelectId);
        if (hotel) {
            cameraRef.current?.flyTo([hotel.longitude, hotel.latitude], 8000);
        }
    }, [flyToOnSelectId, hotels]);

    // Fly to new search destination
    useEffect(() => {
        if (!center) return;
        cameraRef.current?.flyTo(center, 8000);
    }, [center]);

    // Render selected hotel last so it appears on top
    const sortedHotels = selectedHotelId
        ? [
            ...hotels.filter(h => h.hotelId !== selectedHotelId),
            ...hotels.filter(h => h.hotelId === selectedHotelId),
          ]
        : hotels;

    return (
        <View style={styles.container}>
            <MapView
                style={styles.map}
                styleURL={MAP_STYLES[styleKey]}
                onPress={() => onDeselect?.()}
                compassEnabled={false}
                logoEnabled={false}
                attributionEnabled={false}
                scaleBarEnabled={false}
                pitchEnabled={false}
                rotateEnabled={false}
                onDidFinishLoadingMap={() => setIsLoading(false)}
            >
                <Camera
                    ref={cameraRef}
                    defaultSettings={{
                        centerCoordinate: center ?? DEFAULT_CENTER,
                        zoomLevel: 12,
                    }}
                />

                {sortedHotels.map((hotel) => {
                    const isSelected = hotel.hotelId === selectedHotelId;
                    const originalIndex = hotels.indexOf(hotel);
                    const price = hotel.displayConvertedPrice || hotel.displayPrice || '???';
                    const imgs = Array.isArray(hotel.imageUrls) && hotel.imageUrls.length > 0
                        ? hotel.imageUrls.slice(0, 4)
                        : [hotel.thumbnailUrl || FALLBACK_IMG];
                    while (imgs.length < 4) imgs.push(imgs[0]);

                    return (
                        <MarkerView
                            key={hotel.hotelId}
                            id={hotel.hotelId}
                            coordinate={[hotel.longitude, hotel.latitude]}
                            anchor={{ x: 0.5, y: 1 }}
                        >
                            <Pressable onPress={() => onHotelSelect(hotel)} style={styles.markerWrapper}>
                                {isSelected && (
                                    <Pressable
                                        style={styles.popupCard}
                                        onPress={(e) => {
                                            e.stopPropagation();
                                            onHotelNavigate?.(hotel.hotelId);
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
                                    </Pressable>
                                )}
                                <View style={[styles.pill, isSelected && styles.pillSelected]}>
                                    <View style={[styles.pillNum, isSelected && styles.pillNumSelected]}>
                                        <Text style={[styles.pillNumText, isSelected && styles.pillNumTextSelected]}>
                                            {originalIndex + 1}
                                        </Text>
                                    </View>
                                    <Text style={[styles.pillPrice, isSelected && styles.pillPriceSelected]}>
                                        {currencySymbol}{price}
                                    </Text>
                                </View>
                                <View style={styles.pinContainer}>
                                    <View style={[styles.pinLine, isSelected && styles.pinLineSelected]} />
                                    <View style={[styles.pinDot, isSelected && styles.pinDotSelected]} />
                                </View>
                            </Pressable>
                        </MarkerView>
                    );
                })}
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
    popupCard: {
        width: 210,
        borderRadius: 14,
        overflow: 'hidden',
        marginBottom: 6,
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 12 },
        shadowOpacity: 0.28,
        shadowRadius: 28,
        elevation: 12,
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
        width: 6,
        height: 6,
        borderRadius: 3,
        backgroundColor: '#3b82f6',
        borderWidth: 1.5,
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
