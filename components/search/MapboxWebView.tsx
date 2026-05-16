import React, { useEffect, useRef, useMemo } from 'react';
import { View, StyleSheet, ActivityIndicator } from 'react-native';
import { WebView } from 'react-native-webview';
import { MAPBOX_TOKEN } from '../../lib/config';

interface MapboxWebViewProps {
    hotels: any[];
    selectedHotelId: string | null;
    onHotelSelect: (hotel: any) => void;
    isDark: boolean;
    center?: [number, number];
    currencySymbol: string;
}

export default function MapboxWebView({ hotels, selectedHotelId, onHotelSelect, isDark, center, currencySymbol }: MapboxWebViewProps) {
    const webViewRef = useRef<WebView>(null);
    const hasLoadedRef = useRef(false);

    const htmlContent = useMemo(() => {
        const styleUrl = 'mapbox://styles/mapbox/streets-v12';
        
        return `
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="utf-8">
                <meta name="viewport" content="initial-scale=1,maximum-scale=1,user-scalable=no">
                <link href="https://api.mapbox.com/mapbox-gl-js/v3.1.2/mapbox-gl.css" rel="stylesheet">
                <script src="https://api.mapbox.com/mapbox-gl-js/v3.1.2/mapbox-gl.js"></script>
                <style>
                    body { margin: 0; padding: 0; overflow: hidden; background: ${isDark ? '#020617' : '#f8fafc'}; }
                    #map { position: absolute; top: 0; bottom: 0; width: 100%; }
                    
                    .marker {
                        cursor: pointer;
                        transition: all 0.2s ease;
                        transform-origin: bottom center;
                    }
                    .marker-pill {
                        display: flex;
                        align-items: center;
                        background: white;
                        padding: 4px 10px 4px 4px;
                        border-radius: 24px;
                        border: 1px solid #e2e8f0;
                        box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);
                        gap: 6px;
                    }
                    .marker-icon {
                        width: 24px;
                        height: 24px;
                        background: #3b82f6;
                        border-radius: 50%;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        color: white;
                    }
                    .marker-price {
                        font-family: -apple-system, system-ui, sans-serif;
                        font-size: 13px;
                        font-weight: 800;
                        color: #1e293b;
                    }
                    .marker.selected {
                        z-index: 100 !important;
                    }
                    .marker.selected .marker-pill {
                        background: #2563eb;
                        border-color: #1d4ed8;
                        transform: scale(1.1) translateY(-5px);
                        box-shadow: 0 10px 15px -3px rgba(37, 99, 235, 0.4);
                    }
                    .marker.selected .marker-price {
                        color: white;
                    }
                    .marker.selected .marker-icon {
                        background: white;
                        color: #2563eb;
                    }

                    /* Pin Point Style */
                    .marker-pin-container {
                        display: flex;
                        flex-direction: column;
                        align-items: center;
                        margin-top: -1px;
                    }
                    .marker-pin-line {
                        width: 2px;
                        height: 8px;
                        background: #3b82f6;
                    }
                    .marker.selected .marker-pin-line {
                        background: #2563eb;
                        height: 12px;
                    }
                    .marker-pin-dot {
                        width: 6px;
                        height: 6px;
                        background: #3b82f6;
                        border-radius: 50%;
                        border: 1.5px solid white;
                        box-shadow: 0 2px 4px rgba(0,0,0,0.2);
                    }
                    .marker.selected .marker-pin-dot {
                        background: #2563eb;
                        transform: scale(1.2);
                    }

                    /* Preview Card Style */
                    .marker-card {
                        display: none;
                        position: absolute;
                        bottom: 100%;
                        left: 50%;
                        transform: translateX(-50%) translateY(-12px);
                        width: 200px;
                        background: ${isDark ? '#1e293b' : 'white'};
                        border-radius: 14px;
                        overflow: hidden;
                        box-shadow: 0 10px 25px -5px rgba(0,0,0,0.2);
                        border: 1px solid ${isDark ? '#334155' : '#e2e8f0'};
                        z-index: 200;
                        pointer-events: auto;
                    }
                    .marker.selected .marker-card {
                        display: block;
                        animation: markerPopup 0.25s cubic-bezier(0.175, 0.885, 0.32, 1.275);
                    }
                    .card-img {
                        width: 100%;
                        height: 100px;
                        object-fit: cover;
                        display: block;
                    }
                    .card-body {
                        padding: 10px;
                    }
                    .card-name {
                        font-family: sans-serif;
                        font-size: 13px;
                        font-weight: 700;
                        color: ${isDark ? '#f8fafc' : '#0f172a'};
                        margin-bottom: 4px;
                        white-space: nowrap;
                        overflow: hidden;
                        text-overflow: ellipsis;
                    }
                    .card-description {
                        font-family: sans-serif;
                        font-size: 11px;
                        color: ${isDark ? '#94a3b8' : '#64748b'};
                        line-height: 1.4;
                        display: -webkit-box;
                        -webkit-line-clamp: 2;
                        -webkit-box-orient: vertical;
                        overflow: hidden;
                    }

                    @keyframes markerPopup {
                        from { opacity: 0; transform: translateX(-50%) translateY(0) scale(0.9); }
                        to { opacity: 1; transform: translateX(-50%) translateY(-12px) scale(1); }
                    }

                    .layers-btn {
                        position: absolute; top: 16px; left: 16px; z-index: 10;
                        background: ${isDark ? '#1e293b' : 'white'};
                        color: ${isDark ? 'white' : '#1e293b'};
                        border: 1px solid ${isDark ? '#334155' : '#e2e8f0'};
                        border-radius: 50%; width: 44px; height: 44px; cursor: pointer;
                        box-shadow: 0 4px 12px rgba(0,0,0,0.15); display: flex; align-items: center; justify-content: center;
                    }
                    .layers-panel {
                        display: none; position: absolute; top: 70px; left: 20px; z-index: 10;
                        background: ${isDark ? '#1e293b' : 'white'};
                        border: 1px solid ${isDark ? '#334155' : '#e2e8f0'};
                        border-radius: 16px; padding: 8px; width: 150px;
                        box-shadow: 0 10px 15px rgba(0,0,0,0.1);
                    }
                    .layer-opt {
                        padding: 10px 14px; cursor: pointer; border-radius: 8px;
                        font-family: sans-serif; font-size: 13px; color: ${isDark ? '#cbd5e1' : '#475569'};
                    }
                    .layer-opt.active { background: #2563eb; color: white; }
                </style>
            </head>
            <body>
                <div id="map"></div>

                <div class="layers-btn" onclick="toggleLayers()">
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="12 2 2 7 12 12 22 7 12 2"></polygon><polyline points="2 17 12 22 22 17"></polyline><polyline points="2 12 12 17 22 12"></polyline></svg>
                </div>
                <div id="layers-panel" class="layers-panel">
                    <div class="layer-opt active" onclick="setStyle('streets-v12', this)">Standard</div>
                    <div class="layer-opt" onclick="setStyle('dark-v11', this)">Dark</div>
                    <div class="layer-opt" onclick="setStyle('satellite-streets-v12', this)">Satellite</div>
                    <div class="layer-opt" onclick="setStyle('outdoors-v12', this)">Outdoors</div>
                </div>

                <script>
                    function log(msg) {}

                    mapboxgl.accessToken = '${MAPBOX_TOKEN}';
                    const map = new mapboxgl.Map({
                        container: 'map',
                        style: '${styleUrl}',
                        center: ${JSON.stringify(center || [120.596, 16.402])},
                        zoom: 12,
                        pitch: 60,
                        bearing: -17.6,
                        antialias: true,
                        attributionControl: false
                    });

                    let markers = {};

                    function toggleLayers() {
                        const panel = document.getElementById('layers-panel');
                        panel.style.display = panel.style.display === 'block' ? 'none' : 'block';
                    }

                    function setStyle(style, el) {
                        map.setStyle('mapbox://styles/mapbox/' + style);
                        document.querySelectorAll('.layer-opt').forEach(opt => opt.classList.remove('active'));
                        el.classList.add('active');
                        toggleLayers();
                    }

                    let currentHotels = [];
                    let clusterLayerAdded = false;

                    function updateMarkers(hotelsData, selectedId, symbol) {
                        currentHotels = hotelsData;
                        
                        // Convert hotels to GeoJSON for clustering
                        const geojson = {
                            type: 'FeatureCollection',
                            features: hotelsData.map(h => ({
                                type: 'Feature',
                                properties: {
                                    hotelId: h.hotelId,
                                    name: h.name,
                                    price: h.displayPrice,
                                    thumbnail: h.thumbnailUrl,
                                    address: h.address || h.city,
                                    selected: h.hotelId === selectedId
                                },
                                geometry: {
                                    type: 'Point',
                                    coordinates: [h.longitude, h.latitude]
                                }
                            }))
                        };

                        if (map.getSource('hotels')) {
                            map.getSource('hotels').setData(geojson);
                        } else {
                            map.addSource('hotels', {
                                type: 'geojson',
                                data: geojson,
                                cluster: true,
                                clusterMaxZoom: 14,
                                clusterRadius: 50
                            });

                            // Cluster circles
                            map.addLayer({
                                id: 'clusters',
                                type: 'circle',
                                source: 'hotels',
                                filter: ['has', 'point_count'],
                                paint: {
                                    'circle-color': [
                                        'step',
                                        ['get', 'point_count'],
                                        '#3b82f6',
                                        5,
                                        '#2563eb',
                                        15,
                                        '#1d4ed8'
                                    ],
                                    'circle-radius': [
                                        'step',
                                        ['get', 'point_count'],
                                        20,
                                        5,
                                        30,
                                        15,
                                        40
                                    ],
                                    'circle-stroke-width': 2,
                                    'circle-stroke-color': '#fff'
                                }
                            });

                            // Cluster count labels
                            map.addLayer({
                                id: 'cluster-count',
                                type: 'symbol',
                                source: 'hotels',
                                filter: ['has', 'point_count'],
                                layout: {
                                    'text-field': '{point_count}',
                                    'text-font': ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
                                    'text-size': 14
                                },
                                paint: {
                                    'text-color': '#ffffff'
                                }
                            });

                            map.on('click', 'clusters', (e) => {
                                const features = map.queryRenderedFeatures(e.point, { layers: ['clusters'] });
                                const clusterId = features[0].properties.cluster_id;
                                map.getSource('hotels').getClusterExpansionZoom(clusterId, (err, zoom) => {
                                    if (err) return;
                                    map.easeTo({
                                        center: features[0].geometry.coordinates,
                                        zoom: zoom
                                    });
                                });
                            });

                            clusterLayerAdded = true;
                        }

                        // We still use HTML markers for individual hotels for better styling/interaction
                        // but we only show them when zoomed in or for unclustered points if we wanted.
                        // However, to satisfy "Show price badges for more hotels", we'll use a hybrid approach:
                        // Use Mapbox Symbol layer for price badges for better performance with many pins.
                        
                        // Sync HTML markers with current zoom/view
                        renderHtmlMarkers(hotelsData, selectedId, symbol);

                        const bounds = new mapboxgl.LngLatBounds();
                        let validCount = 0;
                        hotelsData.forEach(h => {
                            if (h.latitude && h.longitude) {
                                bounds.extend([h.longitude, h.latitude]);
                                validCount++;
                            }
                        });

                        if (validCount > 0 && !selectedId) {
                            map.fitBounds(bounds, { padding: 80, maxZoom: 15, duration: 1000 });
                        }
                    }

                    function renderHtmlMarkers(hotelsData, selectedId, symbol) {
                        // Remove old markers
                        const currentIds = new Set(hotelsData.map(h => h.hotelId));
                        Object.keys(markers).forEach(id => {
                            if (!currentIds.has(id)) {
                                markers[id].remove();
                                delete markers[id];
                            }
                        });

                        hotelsData.forEach(hotel => {
                            if (!markers[hotel.hotelId]) {
                                const el = document.createElement('div');
                                el.className = 'marker';
                                el.id = 'marker-' + hotel.hotelId;
                                
                                const price = hotel.displayPrice || '???';
                                el.innerHTML = \`
                                    <div class="marker-card">
                                        <img src="\${hotel.thumbnailUrl || 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=300&q=80'}" class="card-img" />
                                        <div class="card-body">
                                            <div class="card-name">\${hotel.name}</div>
                                            <div class="card-description">\${hotel.address || hotel.city || 'Beautiful property'}</div>
                                        </div>
                                    </div>
                                    <div class="marker-pill">
                                        <div class="marker-icon">
                                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                                                <path d="M5 20v-8a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v8"></path>
                                                <path d="M7 10V6a2 2 0 0 1 2-2h6a2 2 0 0 1 2 2v4"></path>
                                                <path d="M5 17h14"></path>
                                            </svg>
                                        </div>
                                         <span class="marker-price">\${symbol}\${price}</span>
                                    </div>
                                    <div class="marker-pin-container">
                                        <div class="marker-pin-line"></div>
                                        <div class="marker-pin-dot"></div>
                                    </div>
                                \`;

                                el.onclick = (e) => {
                                    e.stopPropagation();
                                    window.ReactNativeWebView.postMessage(JSON.stringify({
                                        type: 'HOTEL_SELECT',
                                        hotelId: hotel.hotelId
                                    }));
                                };

                                markers[hotel.hotelId] = new mapboxgl.Marker({ 
                                    element: el, 
                                    anchor: 'bottom' 
                                })
                                .setLngLat([hotel.longitude, hotel.latitude])
                                .addTo(map);
                            }

                            const mEl = markers[hotel.hotelId].getElement();
                            if (hotel.hotelId === selectedId) {
                                mEl.classList.add('selected');
                            } else {
                                mEl.classList.remove('selected');
                            }
                        });
                    }

                    function add3DBuildings() {
                        const layers = map.getStyle().layers;
                        const labelLayer = layers.find(l => l.type === 'symbol' && l.layout['text-field']);
                        const labelLayerId = labelLayer ? labelLayer.id : null;

                        if (map.getLayer('3d-buildings')) map.removeLayer('3d-buildings');

                        map.addLayer({
                            'id': '3d-buildings',
                            'source': 'composite',
                            'source-layer': 'building',
                            'filter': ['==', 'extrude', 'true'],
                            'type': 'fill-extrusion',
                            'minzoom': 14,
                            'paint': {
                                'fill-extrusion-color': '${isDark ? '#1e293b' : '#aaa'}',
                                'fill-extrusion-height': ['get', 'height'],
                                'fill-extrusion-base': ['get', 'min_height'],
                                'fill-extrusion-opacity': 0.6
                            }
                        }, labelLayerId);
                    }

                    map.on('load', () => {
                        add3DBuildings();
                        map.resize();
                        window.ReactNativeWebView.postMessage(JSON.stringify({ type: 'MAP_LOADED' }));
                    });

                    map.on('style.load', () => {
                        add3DBuildings();
                    });

                    // Handler for messages from React Native
                    function handleRNMessage(event) {
                        try {
                            const raw = event.data;
                            if (!raw || typeof raw !== 'string') return;
                            const data = JSON.parse(raw);
                            log('Received: ' + data.type);
                            if (data.type === 'SET_HOTELS') {
                                updateMarkers(data.hotels, data.selectedHotelId, data.currencySymbol);
                            } else if (data.type === 'FLY_TO') {
                                map.flyTo({ center: data.center, zoom: 14, duration: 1500 });
                            } else if (data.type === 'SELECT_HOTEL') {
                                const m = markers[data.hotelId];
                                if (m) {
                                    map.flyTo({ center: m.getLngLat(), zoom: 15, duration: 1000 });
                                    Object.keys(markers).forEach(id => {
                                        const el = markers[id].getElement();
                                        if (id === data.hotelId) el.classList.add('selected');
                                        else el.classList.remove('selected');
                                    });
                                }
                            }
                        } catch(e) {
                            // Ignore non-JSON messages (e.g. from Mapbox internals)
                        }
                    }

                    // Android WebView fires 'message' on document, iOS on window — listen on both
                    document.addEventListener('message', handleRNMessage);
                    window.addEventListener('message', handleRNMessage);
                </script>
            </body>
            </html>
        `;
    }, [isDark]);

    useEffect(() => {
        if (hasLoadedRef.current && webViewRef.current) {

            webViewRef.current.postMessage(JSON.stringify({
                type: 'SET_HOTELS',
                hotels,
                selectedHotelId,
                currencySymbol
            }));
        }
    }, [hotels]);

    useEffect(() => {
        if (hasLoadedRef.current && center && webViewRef.current) {
            webViewRef.current.postMessage(JSON.stringify({
                type: 'FLY_TO',
                center: center
            }));
        }
    }, [center]);

    useEffect(() => {
        if (hasLoadedRef.current && selectedHotelId && webViewRef.current) {
            webViewRef.current.postMessage(JSON.stringify({
                type: 'SELECT_HOTEL',
                hotelId: selectedHotelId
            }));
        }
    }, [selectedHotelId]);

    const onMessage = (event: any) => {
        try {
            const data = JSON.parse(event.nativeEvent.data);
            if (data.type === 'MAP_LOADED') {

                hasLoadedRef.current = true;
                
                // Send initial data
                if (hotels.length > 0) {
                    webViewRef.current?.postMessage(JSON.stringify({
                        type: 'SET_HOTELS',
                        hotels,
                        selectedHotelId,
                        currencySymbol
                    }));
                }
            } else if (data.type === 'HOTEL_SELECT') {
                const hotel = hotels.find(h => h.hotelId === data.hotelId);
                if (hotel) onHotelSelect(hotel);

            }
        } catch (e) {

        }
    };

    return (
        <View style={styles.container}>
            <WebView
                ref={webViewRef}
                originWhitelist={['*']}
                source={{ html: htmlContent }}
                onMessage={onMessage}
                style={styles.map}
                javaScriptEnabled={true}
                domStorageEnabled={true}
                startInLoadingState={true}
                renderLoading={() => (
                    <View style={styles.loading}>
                        <ActivityIndicator size="large" color="#2563eb" />
                    </View>
                )}
            />
        </View>
    );
}

const styles = StyleSheet.create({
    container: { flex: 1 },
    map: { flex: 1 },
    loading: {
        ...StyleSheet.absoluteFillObject,
        backgroundColor: 'rgba(255,255,255,0.8)',
        alignItems: 'center',
        justifyContent: 'center',
    }
});
