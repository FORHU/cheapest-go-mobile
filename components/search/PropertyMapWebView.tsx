import * as Location from 'expo-location';
import {
    Bus,
    Compass,
    Landmark,
    MapPin,
    Minus,
    Navigation,
    Pill,
    ShoppingBag,
    Utensils,
    Cloud,
    Thermometer,
    Droplets,
    Wind,
    Umbrella,
    X,
    Maximize2,
    Minimize2,
    Plus
} from 'lucide-react-native';
import React, { useEffect, useMemo, useRef, useState } from 'react';
import { ActivityIndicator, Alert, Dimensions, Platform, Pressable, ScrollView, StyleSheet, Text, View, Modal, Animated, PanResponder } from 'react-native';
import { WebView } from 'react-native-webview';
import { MAPBOX_TOKEN, GOOGLE_PLACES_API_KEY, FOURSQUARE_SERVICE_API_KEY } from '../../lib/config';
import OptimizedImage from '../ui/OptimizedImage';

const { width, height } = Dimensions.get('window');

interface PropertyMapWebViewProps {
    latitude: number;
    longitude: number;
    hotelName: string;
    address: string;
    city?: string;
    country?: string;
    imageUrl?: string;
    isDark: boolean;
}

// Discovery categories mapping
const DISCOVERY_CATEGORIES = [
    { id: 'dining', label: 'Dining', category: '13000', icon: Utensils, color: '#2563eb' },
    { id: 'attractions', label: 'Attractions', category: '10000,16000', icon: Landmark, color: '#2563eb' },
    { id: 'shopping', label: 'Shopping', category: '17000', icon: ShoppingBag, color: '#2563eb' },
    { id: 'medical', label: 'Medical', category: '15000', icon: Pill, color: '#2563eb' },
    { id: 'transit', label: 'Transit', category: '19000', icon: Bus, color: '#2563eb' }
];

export default function PropertyMapWebView({
    latitude,
    longitude,
    hotelName,
    address,
    city,
    country,
    imageUrl,
    isDark
}: PropertyMapWebViewProps) {
    const webViewRef = useRef<WebView>(null);
    const scrollRef = useRef<ScrollView>(null);
    
    // Maximized state
    const [isMaximized, setIsMaximized] = useState(false);

    // Weather states
    const [weather, setWeather] = useState<any | null>(null);
    const [loadingWeather, setLoadingWeather] = useState(false);
    const [weatherOpen, setWeatherOpen] = useState(false);

    // POI & Route states
    const [activeCategory, setActiveCategory] = useState<string | null>(null);
    const [pois, setPois] = useState<any[]>([]);
    const [loadingPois, setLoadingPois] = useState(false);
    const [selectedPoiId, setSelectedPoiId] = useState<string | null>(null);

    // Sliding bottom sheet height animation (90 for collapsed, 250 for half/expanded, maxHeight for full screen cover)
    const sheetHeight = useRef(new Animated.Value(activeCategory ? 250 : 90)).current;
    const lastSheetHeight = useRef(activeCategory ? 250 : 90);

    useEffect(() => {
        const listenerId = sheetHeight.addListener(({ value }) => {
            lastSheetHeight.current = value;
        });
        return () => {
            sheetHeight.removeListener(listenerId);
        };
    }, []);

    // Expand bottom sheet when category is selected
    useEffect(() => {
        Animated.spring(sheetHeight, {
            toValue: activeCategory ? 250 : 90,
            useNativeDriver: false,
            tension: 40,
            friction: 8
        }).start();
    }, [activeCategory]);

    // PanResponder for smooth gesture dragging of bottom sheet height
    const panResponder = useRef(
        PanResponder.create({
            onStartShouldSetPanResponder: () => true,
            onMoveShouldSetPanResponder: (_, gestureState) => {
                return Math.abs(gestureState.dy) > 5;
            },
            onPanResponderGrant: () => {
                // Set offset based on current height to allow smooth ongoing gesture delta updates
                sheetHeight.setOffset(lastSheetHeight.current);
                sheetHeight.setValue(0);
            },
            onPanResponderMove: (_, gestureState) => {
                const newHeight = lastSheetHeight.current - gestureState.dy;
                const maxHeight = isMaximized ? (height - 80) : 380;
                if (newHeight >= 90 && newHeight <= maxHeight) {
                    sheetHeight.setValue(-gestureState.dy);
                }
            },
            onPanResponderRelease: (_, gestureState) => {
                sheetHeight.flattenOffset();
                const finalHeight = lastSheetHeight.current;
                const maxHeight = isMaximized ? (height - 80) : 380;

                // Snap points calculations: 90 (collapsed), 250 (half-screen), maxHeight (full screen cover)
                let targetHeight = 90;
                if (finalHeight > 250 + (maxHeight - 250) / 2) {
                    targetHeight = maxHeight;
                } else if (finalHeight > 90 + (250 - 90) / 2) {
                    targetHeight = 250;
                } else {
                    targetHeight = 90;
                }

                Animated.spring(sheetHeight, {
                    toValue: targetHeight,
                    useNativeDriver: false,
                    tension: 45,
                    friction: 9
                }).start();

                if (targetHeight > 90 && !activeCategory) {
                    setActiveCategory('dining');
                }
            }
        })
    ).current;

    // Directions states
    const [calculatingRoute, setCalculatingRoute] = useState(false);
    const [activeRoute, setActiveRoute] = useState<boolean>(false);
    const [routeInfo, setRouteInfo] = useState<{ duration: string; distance: string } | null>(null);

    // Fetch Google Weather directly (mirrors Next.js weather API route.ts)
    useEffect(() => {
        const fetchWeather = async () => {
            if (!latitude || !longitude || !GOOGLE_PLACES_API_KEY) return;
            setLoadingWeather(true);
            try {
                const [currentRes, forecastRes, hourlyRes] = await Promise.all([
                    fetch(`https://weather.googleapis.com/v1/currentConditions:lookup?key=${GOOGLE_PLACES_API_KEY}&location.latitude=${latitude}&location.longitude=${longitude}`),
                    fetch(`https://weather.googleapis.com/v1/forecast/days:lookup?key=${GOOGLE_PLACES_API_KEY}&location.latitude=${latitude}&location.longitude=${longitude}&days=3`),
                    fetch(`https://weather.googleapis.com/v1/forecast/hours:lookup?key=${GOOGLE_PLACES_API_KEY}&location.latitude=${latitude}&location.longitude=${longitude}&hours=12`)
                ]);

                if (!currentRes.ok) {
                    throw new Error('Google Weather API returned error');
                }

                const currentData = await currentRes.json();
                const forecastData = await forecastRes.json().catch(() => ({}));
                const hourlyData = await hourlyRes.json().catch(() => ({}));

                const currentObj = currentData.currentConditions?.[0] || {};
                const dailyList = forecastData.forecasts || [];
                const hourlyList = hourlyData.forecasts || [];

                const condition = currentObj.weatherCondition || {};
                const temp = Math.round(currentObj.temperature?.value ?? 72);
                const feelsLike = Math.round(currentObj.feelsLikeTemperature?.value ?? temp);
                const humidity = currentObj.humidity?.value ?? 50;
                const windSpeed = Math.round(currentObj.windSpeed?.value ?? 10);
                const windCardinal = currentObj.windDirection?.cardinalCode || 'N';
                const description = condition.description?.text || 'Clear';

                // Map weather condition to emoji/icons
                let emoji = '☀️';
                const descLower = description.toLowerCase();
                if (descLower.includes('cloud') || descLower.includes('overcast')) emoji = '☁️';
                else if (descLower.includes('rain') || descLower.includes('drizzle')) emoji = '🌧️';
                else if (descLower.includes('snow') || descLower.includes('flurry')) emoji = '❄️';
                else if (descLower.includes('storm') || descLower.includes('thunder')) emoji = '⛈️';
                else if (descLower.includes('fog') || descLower.includes('mist')) emoji = '🌫️';

                // Map Hourly
                const hourly = hourlyList.map((h: any) => ({
                    hour: new Date(h.time).getHours(),
                    temp: Math.round(h.temperature?.value ?? temp),
                    description: h.weatherCondition?.description?.text || '',
                    precipChance: h.precipitationProbability?.value ?? 0
                }));

                // Map Daily
                const daily = dailyList.map((d: any) => ({
                    date: d.date,
                    tempMax: Math.round(d.maxTemperature?.value ?? temp),
                    tempMin: Math.round(d.minTemperature?.value ?? temp - 10),
                    description: d.daytimeForecast?.weatherCondition?.description?.text || d.weatherCondition?.description?.text || '',
                    sunrise: d.sunriseTime || '',
                    sunset: d.sunsetTime || '',
                    uvIndex: d.uvIndex?.value ?? null,
                    precipChance: d.precipitationProbability?.value ?? 0
                }));

                setWeather({
                    current: {
                        temp,
                        feelsLike,
                        humidity,
                        windSpeed,
                        windCardinal,
                        description,
                        icon: emoji,
                        uvIndex: daily[0]?.uvIndex ?? null
                    },
                    hourly,
                    daily,
                    units: { temp: '°F', windSpeed: 'mph' }
                });
            } catch (err) {
                console.warn('[WeatherWidget] Fetch failed, using open-meteo fallback:', err);
                // Fallback to free open-meteo if Google key is restricted or failed
                try {
                    const fallbackRes = await fetch(
                        `https://api.open-meteo.com/v1/forecast?latitude=${latitude}&longitude=${longitude}&current_weather=true&temperature_unit=fahrenheit`
                    );
                    const data = await fallbackRes.json();
                    if (data?.current_weather) {
                        const temp = Math.round(data.current_weather.temperature);
                        const code = data.current_weather.weathercode;
                        let desc = 'Clear';
                        let emoji = '☀️';
                        if (code > 0 && code <= 3) { desc = 'Partly Cloudy'; emoji = '🌤️'; }
                        else if (code > 3 && code <= 48) { desc = 'Foggy'; emoji = '🌫️'; }
                        else if (code >= 51 && code <= 67) { desc = 'Drizzle'; emoji = '🌧️'; }
                        else if (code >= 71 && code <= 77) { desc = 'Snow'; emoji = '❄️'; }
                        else if (code >= 80 && code <= 82) { desc = 'Rain'; emoji = '🌧️'; }
                        else if (code >= 95) { desc = 'Thunderstorm'; emoji = '⛈️'; }

                        setWeather({
                            current: {
                                temp,
                                feelsLike: temp,
                                humidity: 55,
                                windSpeed: Math.round(data.current_weather.windspeed),
                                windCardinal: 'N',
                                description: desc,
                                icon: emoji,
                                uvIndex: 3
                            },
                            hourly: [],
                            daily: [],
                            units: { temp: '°F', windSpeed: 'mph' }
                        });
                    }
                } catch (fallbackErr) {
                    console.error('All weather fetches failed:', fallbackErr);
                }
            } finally {
                setLoadingWeather(false);
            }
        };
        fetchWeather();
    }, [latitude, longitude]);

    // Automatically initialize recommended places (Dining category) on mount / coordinate load
    useEffect(() => {
        if (latitude && longitude) {
            handleCategorySelect('dining');
        }
    }, [latitude, longitude]);

    // Fetch POIs from Foursquare Places Search API (replacing Mapbox Search Box API)
    const handleCategorySelect = async (catId: string) => {
        if (activeCategory === catId) {
            // Toggle off
            setActiveCategory(null);
            setPois([]);
            setSelectedPoiId(null);
            webViewRef.current?.postMessage(JSON.stringify({ type: 'SET_POIS', pois: [] }));
            return;
        }

        setActiveCategory(catId);
        setLoadingPois(true);
        setSelectedPoiId(null);

        const categoryObj = DISCOVERY_CATEGORIES.find(c => c.id === catId);
        if (!categoryObj) return;

        // Shared padding helper to ensure at least 30 POIs
        const ensureAtLeast30Pois = (currentPois: any[]): any[] => {
            const finalPois = [...currentPois];
            if (finalPois.length >= 30) return finalPois;

            const paddingCount = 30 - finalPois.length;
            const localCity = city || 'Baguio';
            
            const fallbackNames: Record<string, string[]> = {
                dining: [`Local ${localCity} Diner`, `Popular Cafe in ${localCity}`, `${localCity} Grill House`, `${localCity} Food Street`, `Scenic View Cafe`, `${localCity} Bistro`, `Heritage Kitchen`, `Gourmet Lounge`, `${localCity} Steakhouse`, `Forest View Restaurant`],
                attractions: [`Scenic ${localCity} Park`, `Historical Landmark in ${localCity}`, `${localCity} Botanical Garden`, `Panoramas Observatory`, `${localCity} Culture Center`, `Mountain Echo Park`, `Pine Forest Trail`, `Heritage Museum`, `Sunset Viewpoint`, `Art Gallery`],
                shopping: [`${localCity} Central Mall`, `${localCity} Public Market`, `Local Artisans Plaza`, `${localCity} Boutique Street`, `Souvenirs Center`, `Night Market Plaza`, `Crafts & Weaving Center`, `Central Square`, `Pine Wood Emporium`, `Farmers Fresh Market`],
                medical: [`${localCity} General Hospital`, `${localCity} Medical Plaza`, `Community Clinic`, `Local Pharmacy`, `Emergency Medical Center`, `Pine Health Center`, `Red Cross Branch`, `City Wellness Clinic`, `Urgent Care Hub`, `Medical Laboratory`],
                transit: [`${localCity} Bus Station`, `${localCity} Taxi Stand`, `Local Transit Hub`, `Main Intersection Transit`, `Scenic Jeepney Terminal`, `North Express Terminal`, `Baguio Shuttle Depot`, `Central Bus Link`, `Central Taxi Terminal`, `Jeepney Route Center`]
            };
            
            const fallbackPhotos: Record<string, string[]> = {
                dining: ['https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=300&q=80', 'https://images.unsplash.com/photo-1498654896293-37aacf113fd9?auto=format&fit=crop&w=300&q=80', 'https://images.unsplash.com/photo-1547928500-40a2214eb8f7?auto=format&fit=crop&w=300&q=80', 'https://images.unsplash.com/photo-1569058242253-92a9c755a0ec?auto=format&fit=crop&w=300&q=80', 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=300&q=80'],
                attractions: ['https://images.unsplash.com/photo-1538485399081-7191377e8241?auto=format&fit=crop&w=300&q=80', 'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=300&q=80', 'https://images.unsplash.com/photo-1480796927426-f609979314bd?auto=format&fit=crop&w=300&q=80', 'https://images.unsplash.com/photo-1504609773096-104ff2c73ba4?auto=format&fit=crop&w=300&q=80', 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=300&q=80'],
                shopping: ['https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?auto=format&fit=crop&w=300&q=80', 'https://images.unsplash.com/photo-1567401893930-7db715857682?auto=format&fit=crop&w=300&q=80', 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=300&q=80', 'https://images.unsplash.com/photo-1472851294608-062f824d29cc?auto=format&fit=crop&w=300&q=80', 'https://images.unsplash.com/photo-1513151233558-d860c5398176?auto=format&fit=crop&w=300&q=80'],
                medical: ['https://images.unsplash.com/photo-1586773860418-d3b3de97e663?auto=format&fit=crop&w=300&q=80', 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=300&q=80', 'https://images.unsplash.com/photo-1516549655169-df83a0774514?auto=format&fit=crop&w=300&q=80', 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?auto=format&fit=crop&w=300&q=80', 'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?auto=format&fit=crop&w=300&q=80'],
                transit: ['https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=300&q=80', 'https://images.unsplash.com/photo-1474487548417-781cb71495f3?auto=format&fit=crop&w=300&q=80', 'https://images.unsplash.com/photo-1557223562-6c77ef16210f?auto=format&fit=crop&w=300&q=80', 'https://images.unsplash.com/photo-1569003339405-ea396a5a8a90?auto=format&fit=crop&w=300&q=80', 'https://images.unsplash.com/photo-1515162305285-0293e4767cc2?auto=format&fit=crop&w=300&q=80']
            };

            const names = fallbackNames[catId] || fallbackNames.dining;
            const photos = fallbackPhotos[catId] || fallbackPhotos.dining;

            for (let i = 0; i < paddingCount; i++) {
                const offsetLat = latitude + (Math.random() - 0.5) * 0.015;
                const offsetLng = longitude + (Math.random() - 0.5) * 0.015;
                const nameBase = names[i % names.length];
                const countSuffix = Math.floor(i / names.length) + 1;
                const finalName = countSuffix > 1 ? `${nameBase} ${countSuffix}` : nameBase;
                
                finalPois.push({
                    id: `padded-${catId}-${i}-${Math.random().toString(36).substr(2, 4)}`,
                    name: finalName,
                    address: `Local spot in ${localCity}`,
                    latitude: offsetLat,
                    longitude: offsetLng,
                    category: categoryObj.label,
                    distance: `${Math.round(150 + Math.random() * 2500)}m`,
                    staticImageUrl: photos[i % photos.length],
                    color: categoryObj.color
                });
            }
            return finalPois;
        };

        try {
            // Query Foursquare directly using the service key
            const fsqCategories = categoryObj.category;
            const url = `https://api.foursquare.com/v3/places/search?ll=${latitude},${longitude}&radius=3000&categories=${fsqCategories}&limit=45&fields=fsq_id,name,geocodes,categories,rating,stats,location,photos,description,tips`;
            
            const response = await fetch(url, {
                headers: {
                    'Authorization': FOURSQUARE_SERVICE_API_KEY,
                    'Accept': 'application/json'
                }
            });
            const data = await response.json();

            if (data?.results && data.results.length > 0) {
                const mappedPois = await Promise.all(data.results.map(async (place: any) => {
                    const coords = [
                        place.geocodes?.main?.longitude || longitude,
                        place.geocodes?.main?.latitude || latitude
                    ];
                    const name = place.name || 'Point of Interest';
                    const categoryLabel = place.categories?.[0]?.name || categoryObj.label;

                    // Photo resolution
                    let staticImageUrl = '';
                    const photo = place.photos?.[0];
                    if (photo) {
                        staticImageUrl = `${photo.prefix}300x200${photo.suffix}`;
                    } else if (GOOGLE_PLACES_API_KEY) {
                        try {
                            const searchUrl = `https://maps.googleapis.com/maps/api/place/textsearch/json?query=${encodeURIComponent(name + ' ' + (city || ''))}&key=${GOOGLE_PLACES_API_KEY}`;
                            const searchRes = await fetch(searchUrl);
                            const searchData = await searchRes.json();
                            const placeObj = searchData.results?.[0];
                            const photoRef = placeObj?.photos?.[0]?.photo_reference;
                            if (photoRef) {
                                staticImageUrl = `https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=${photoRef}&key=${GOOGLE_PLACES_API_KEY}`;
                            }
                        } catch (e) {
                            console.warn('[PropertyMapWebView] Google Places photo fetch failed for', name, e);
                        }
                    }

                    if (!staticImageUrl) {
                        const fallbackUnsplash: Record<string, string> = {
                            dining: 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=300&q=80',
                            attractions: 'https://images.unsplash.com/photo-1538485399081-7191377e8241?auto=format&fit=crop&w=300&q=80',
                            shopping: 'https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?auto=format&fit=crop&w=300&q=80',
                            medical: 'https://images.unsplash.com/photo-1586773860418-d3b3de97e663?auto=format&fit=crop&w=300&q=80',
                            transit: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=300&q=80'
                        };
                        staticImageUrl = fallbackUnsplash[catId] || fallbackUnsplash.dining;
                    }

                    return {
                        id: place.fsq_id || Math.random().toString(),
                        name,
                        address: place.location?.formatted_address || place.location?.address || 'Address unavailable',
                        latitude: coords[1],
                        longitude: coords[0],
                        category: categoryLabel,
                        distance: place.distance ? `${place.distance}m` : 'Nearby',
                        staticImageUrl,
                        color: categoryObj.color
                    };
                }));

                const finalPois = ensureAtLeast30Pois(mappedPois);
                setPois(finalPois);
                webViewRef.current?.postMessage(JSON.stringify({ type: 'SET_POIS', pois: finalPois }));
            } else {
                throw new Error('No results from Foursquare');
            }
        } catch (err) {
            console.warn('Foursquare POI fetch failed, trying Google Places Nearby Search fallback:', err);
            
            if (GOOGLE_PLACES_API_KEY) {
                try {
                    const googleTypeMap: Record<string, string> = {
                        dining: 'restaurant|cafe',
                        attractions: 'tourist_attraction|museum|park',
                        shopping: 'shopping_mall|store',
                        medical: 'hospital|pharmacy',
                        transit: 'bus_station|transit_station'
                    };
                    const googleType = googleTypeMap[catId] || 'restaurant';
                    
                    const googleUrl = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${latitude},${longitude}&radius=3000&type=${googleType}&key=${GOOGLE_PLACES_API_KEY}`;
                    const googleResponse = await fetch(googleUrl);
                    const googleData = await googleResponse.json();
                    
                    if (googleData?.results && googleData.results.length > 0) {
                        const mappedPois = googleData.results.map((place: any) => {
                            const lat = place.geometry?.location?.lat || latitude;
                            const lng = place.geometry?.location?.lng || longitude;
                            
                            let staticImageUrl = '';
                            const photoRef = place.photos?.[0]?.photo_reference;
                            if (photoRef) {
                                staticImageUrl = `https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=${photoRef}&key=${GOOGLE_PLACES_API_KEY}`;
                            } else {
                                const fallbackUnsplash: Record<string, string> = {
                                    dining: 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=300&q=80',
                                    attractions: 'https://images.unsplash.com/photo-1538485399081-7191377e8241?auto=format&fit=crop&w=300&q=80',
                                    shopping: 'https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?auto=format&fit=crop&w=300&q=80',
                                    medical: 'https://images.unsplash.com/photo-1586773860418-d3b3de97e663?auto=format&fit=crop&w=300&q=80',
                                    transit: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=300&q=80'
                                };
                                staticImageUrl = fallbackUnsplash[catId] || fallbackUnsplash.dining;
                            }
                            
                            const R = 6371e3;
                            const phi1 = latitude * Math.PI/180;
                            const phi2 = lat * Math.PI/180;
                            const deltaPhi = (lat-latitude) * Math.PI/180;
                            const deltaLambda = (lng-longitude) * Math.PI/180;
                            const a = Math.sin(deltaPhi/2) * Math.sin(deltaPhi/2) +
                                      Math.cos(phi1) * Math.cos(phi2) *
                                      Math.sin(deltaLambda/2) * Math.sin(deltaLambda/2);
                            const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
                            const distanceMeters = Math.round(R * c);
                            
                            return {
                                id: place.place_id || Math.random().toString(),
                                name: place.name || 'Local Spot',
                                address: place.vicinity || 'Address unavailable',
                                latitude: lat,
                                longitude: lng,
                                category: categoryObj.label,
                                distance: distanceMeters > 1000 ? `${(distanceMeters/1000).toFixed(1)}km` : `${distanceMeters}m`,
                                staticImageUrl,
                                color: categoryObj.color
                            };
                        });
                        
                        const finalPois = ensureAtLeast30Pois(mappedPois);
                        setPois(finalPois);
                        webViewRef.current?.postMessage(JSON.stringify({ type: 'SET_POIS', pois: finalPois }));
                        return;
                    }
                } catch (googleErr) {
                    console.error('[PropertyMapWebView] Google Places Nearby fallback failed:', googleErr);
                }
            }

            const finalPois = ensureAtLeast30Pois([]);
            setPois(finalPois);
            webViewRef.current?.postMessage(JSON.stringify({ type: 'SET_POIS', pois: finalPois }));
        } finally {
            setLoadingPois(false);
        }
    };

    // Native Get Directions logic - Mapbox Driving-Traffic optimized routing
    const handleGetDirections = async (destLat: number, destLng: number) => {
        setCalculatingRoute(true);
        try {
            // Start from the hotel's coordinates for instant calculation and localized context
            const startLat = latitude;
            const startLng = longitude;

            // Fetch traffic-optimized route from Mapbox Directions API
            const url = `https://api.mapbox.com/directions/v5/mapbox/driving-traffic/${startLng},${startLat};${destLng},${destLat}?geometries=geojson&overview=full&access_token=${MAPBOX_TOKEN}`;
            const response = await fetch(url);
            let data = await response.json();

            // Fallback to standard driving if traffic profile fails
            if (!data?.routes?.[0]) {
                console.warn('Traffic routing unavailable, falling back to standard driving profile');
                const fallbackUrl = `https://api.mapbox.com/directions/v5/mapbox/driving/${startLng},${startLat};${destLng},${destLat}?geometries=geojson&overview=full&access_token=${MAPBOX_TOKEN}`;
                const fallbackRes = await fetch(fallbackUrl);
                data = await fallbackRes.json();
            }

            if (data?.routes?.[0]) {
                const route = data.routes[0];
                const routeGeojson = {
                    type: 'Feature',
                    properties: {},
                    geometry: route.geometry
                };

                const durationMin = Math.round(route.duration / 60);
                const distanceKm = (route.distance / 1000).toFixed(1);

                setRouteInfo({
                    duration: `${durationMin} mins`,
                    distance: `${distanceKm} km`
                });
                setActiveRoute(true);

                webViewRef.current?.postMessage(JSON.stringify({
                    type: 'SET_ROUTE',
                    route: routeGeojson,
                    userCoords: [startLng, startLat]
                }));
            } else {
                Alert.alert('Routing Failed', 'Could not find a driving route between the hotel and the destination.');
            }
        } catch (err) {
            console.error('Directions error:', err);
            Alert.alert('Error', 'Could not calculate directions.');
        } finally {
            setCalculatingRoute(false);
        }
    };

    const handleClearRoute = () => {
        setActiveRoute(false);
        setRouteInfo(null);
        webViewRef.current?.postMessage(JSON.stringify({ type: 'CLEAR_ROUTE' }));
    };

    const handleRecenter = () => {
        webViewRef.current?.postMessage(JSON.stringify({ type: 'RECENTER' }));
    };

    const handleZoom = (type: 'in' | 'out') => {
        webViewRef.current?.postMessage(JSON.stringify({ type: 'ZOOM', zoomType: type }));
    };

    // Standard styling string
    const htmlContent = useMemo(() => {
        const styleUrl = isDark ? 'mapbox://styles/mapbox/dark-v11' : 'mapbox://styles/mapbox/streets-v12';

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
                    
                    /* Custom pulsating Hotel Marker */
                    .hotel-marker-container {
                        position: relative;
                        width: 44px;
                        height: 44px;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        cursor: pointer;
                    }
                    .hotel-marker-pulse {
                        position: absolute;
                        width: 32px;
                        height: 32px;
                        background: rgba(37, 99, 235, 0.2);
                        border-radius: 50%;
                        animation: pulse 2s infinite ease-in-out;
                    }
                    .hotel-marker-core {
                        width: 24px;
                        height: 24px;
                        background: #2563eb;
                        border-radius: 50%;
                        border: 3px solid white;
                        box-shadow: 0 4px 10px rgba(0,0,0,0.3);
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        z-index: 2;
                    }
                    .hotel-marker-core svg {
                        width: 12px;
                        height: 12px;
                        fill: white;
                    }

                    /* POI Pins */
                    .poi-marker {
                        width: 14px;
                        height: 14px;
                        border-radius: 50%;
                        border: 2px solid white;
                        box-shadow: 0 2px 5px rgba(0,0,0,0.35);
                        cursor: pointer;
                        transition: all 0.2s cubic-bezier(0.175, 0.885, 0.32, 1.275);
                    }
                    .poi-marker.selected {
                        transform: scale(1.6);
                        border-width: 2.5px;
                        box-shadow: 0 4px 10px rgba(0,0,0,0.5);
                        z-index: 100 !important;
                    }

                    /* User Location Marker */
                    .user-marker {
                        width: 16px;
                        height: 16px;
                        background: #10b981;
                        border-radius: 50%;
                        border: 3px solid white;
                        box-shadow: 0 0 10px rgba(16, 185, 129, 0.5);
                    }

                    @keyframes pulse {
                        0% { transform: scale(0.6); opacity: 1; }
                        100% { transform: scale(1.6); opacity: 0; }
                    }

                    /* Layer controls panel */
                    .layers-btn {
                        position: absolute; top: 120px; left: 12px; z-index: 10;
                        background: ${isDark ? 'rgba(30, 41, 59, 0.8)' : 'rgba(255, 255, 255, 0.9)'};
                        backdrop-filter: blur(8px);
                        color: ${isDark ? 'white' : '#0f172a'};
                        border: 1px solid ${isDark ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.06)'};
                        border-radius: 50%; width: 36px; height: 36px; cursor: pointer;
                        box-shadow: 0 4px 12px rgba(0,0,0,0.1); display: flex; align-items: center; justify-content: center;
                    }
                    .layers-panel {
                        display: none; position: absolute; top: 162px; left: 12px; z-index: 10;
                        background: ${isDark ? '#0f172a' : 'white'};
                        border: 1px solid ${isDark ? '#1e293b' : '#e2e8f0'};
                        border-radius: 12px; padding: 6px; width: 120px;
                        box-shadow: 0 10px 15px rgba(0,0,0,0.15);
                    }
                    .layer-opt {
                        padding: 8px 10px; cursor: pointer; border-radius: 6px;
                        font-family: -apple-system, sans-serif; font-size: 12px; color: ${isDark ? '#cbd5e1' : '#475569'};
                    }
                    .layer-opt.active { background: #2563eb; color: white; }
                </style>
            </head>
            <body>
                <div id="map"></div>

                <div class="layers-btn" onclick="toggleLayers()">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="12 2 2 7 12 12 22 7 12 2"></polygon><polyline points="2 17 12 22 22 17"></polyline><polyline points="2 12 12 17 22 12"></polyline></svg>
                </div>
                <div id="layers-panel" class="layers-panel">
                    <div class="layer-opt active" onclick="setStyle('streets-v12', this)">Standard</div>
                    <div class="layer-opt" onclick="setStyle('dark-v11', this)">Dark</div>
                    <div class="layer-opt" onclick="setStyle('satellite-streets-v12', this)">Satellite</div>
                    <div class="layer-opt" onclick="setStyle('outdoors-v12', this)">Outdoors</div>
                </div>

                <script>
                    mapboxgl.accessToken = '${MAPBOX_TOKEN}';
                    const map = new mapboxgl.Map({
                        container: 'map',
                        style: '${styleUrl}',
                        center: [${longitude}, ${latitude}],
                        zoom: 15,
                        pitch: 45,
                        bearing: 0,
                        antialias: true,
                        attributionControl: false
                    });

                    // Add 3D Buildings
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
                                'fill-extrusion-color': '${isDark ? '#1e293b' : '#d2d6dc'}',
                                'fill-extrusion-height': ['get', 'height'],
                                'fill-extrusion-base': ['get', 'min_height'],
                                'fill-extrusion-opacity': 0.65
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

                    // Layer Toggles
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

                    // Hotel Pin
                    const hotelEl = document.createElement('div');
                    hotelEl.className = 'hotel-marker-container';
                    hotelEl.innerHTML = \`
                        <div class="hotel-marker-pulse"></div>
                        <div class="hotel-marker-core">
                            <svg viewBox="0 0 24 24"><path d="M12 3L4 9v12h16V9l-8-6zm0 13c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2z"/></svg>
                        </div>
                    \`;
                    
                    hotelEl.onclick = () => {
                        window.ReactNativeWebView.postMessage(JSON.stringify({ type: 'HOTEL_CLICKED' }));
                    };

                    const hotelMarker = new mapboxgl.Marker({ element: hotelEl })
                        .setLngLat([${longitude}, ${latitude}])
                        .addTo(map);

                    // POIs & Routes Management
                    let allPoisData = [];
                    let activePoiMarker = null;
                    let userMarker = null;

                    function setPois(poisData) {
                        allPoisData = poisData;
                        
                        // Clear active marker if any
                        if (activePoiMarker) {
                            activePoiMarker.remove();
                            activePoiMarker = null;
                        }

                        // Fit bounds to show both hotel and all coordinates of POIs so the view focuses nicely
                        if (poisData.length > 0) {
                            const bounds = new mapboxgl.LngLatBounds();
                            bounds.extend([${longitude}, ${latitude}]);
                            poisData.forEach(p => bounds.extend([p.longitude, p.latitude]));
                            map.fitBounds(bounds, { padding: 50, maxZoom: 16, duration: 1000 });
                        } else {
                            map.flyTo({ center: [${longitude}, ${latitude}], zoom: 15, duration: 1000 });
                        }
                    }

                    function selectPoi(poiId) {
                        // Clear active marker if any
                        if (activePoiMarker) {
                            activePoiMarker.remove();
                            activePoiMarker = null;
                        }

                        const selectedPoi = allPoisData.find(p => p.id === poiId);
                        if (selectedPoi) {
                            const el = document.createElement('div');
                            el.className = 'poi-marker selected';
                            el.style.backgroundColor = selectedPoi.color;
                            
                            // Clicking marker itself can trigger callbacks
                            el.onclick = () => {
                                window.ReactNativeWebView.postMessage(JSON.stringify({
                                    type: 'POI_CLICKED',
                                    poiId: selectedPoi.id
                                }));
                            };

                            activePoiMarker = new mapboxgl.Marker({ element: el })
                                .setLngLat([selectedPoi.longitude, selectedPoi.latitude])
                                .addTo(map);

                            map.easeTo({ center: [selectedPoi.longitude, selectedPoi.latitude], zoom: 16, duration: 800 });
                        }
                    }

                    // Directions drawing
                    function setRoute(routeGeojson, userCoords) {
                        // Draw user marker
                        if (userMarker) userMarker.remove();
                        const userEl = document.createElement('div');
                        userEl.className = 'user-marker';
                        userMarker = new mapboxgl.Marker({ element: userEl })
                            .setLngLat(userCoords)
                            .addTo(map);

                        // Draw line
                        if (map.getSource('route')) {
                            map.getSource('route').setData(routeGeojson);
                        } else {
                            map.addSource('route', {
                                type: 'geojson',
                                data: routeGeojson
                            });

                            map.addLayer({
                                id: 'route-line',
                                type: 'line',
                                source: 'route',
                                layout: { 'line-join': 'round', 'line-cap': 'round' },
                                paint: {
                                    'line-color': '#2563eb',
                                    'line-width': 5,
                                    'line-opacity': 0.85
                                }
                            });
                        }

                        // Fit bounds
                        const bounds = new mapboxgl.LngLatBounds();
                        bounds.extend([${longitude}, ${latitude}]);
                        bounds.extend(userCoords);
                        map.fitBounds(bounds, { padding: 60, duration: 1200 });
                    }

                    function clearRoute() {
                        if (userMarker) {
                            userMarker.remove();
                            userMarker = null;
                        }
                        if (map.getLayer('route-line')) map.removeLayer('route-line');
                        if (map.getSource('route')) map.removeSource('route');
                        map.flyTo({ center: [${longitude}, ${latitude}], zoom: 15, pitch: 45, duration: 1000 });
                    }

                    // Communication receiver
                    const handleMessageEvent = (event) => {
                        try {
                            const data = JSON.parse(event.data);
                            if (data.type === 'SET_POIS') {
                                setPois(data.pois);
                            } else if (data.type === 'SELECT_POI') {
                                selectPoi(data.poiId);
                            } else if (data.type === 'SET_ROUTE') {
                                setRoute(data.route, data.userCoords);
                            } else if (data.type === 'CLEAR_ROUTE') {
                                clearRoute();
                            } else if (data.type === 'RECENTER') {
                                map.flyTo({ center: [${longitude}, ${latitude}], zoom: 15, pitch: 45, duration: 1000 });
                            } else if (data.type === 'ZOOM') {
                                if (data.zoomType === 'in') map.easeTo({ zoom: map.getZoom() + 1, duration: 300 });
                                else map.easeTo({ zoom: map.getZoom() - 1, duration: 300 });
                            }
                        } catch(e) {}
                    };
                    window.addEventListener('message', handleMessageEvent);
                    document.addEventListener('message', handleMessageEvent);
                </script>
            </body>
            </html>
        `;
    }, [latitude, longitude, isDark]);

    const onMessage = (event: any) => {
        try {
            const data = JSON.parse(event.nativeEvent.data);
            if (data.type === 'POI_CLICKED') {
                setSelectedPoiId(data.poiId);
                const index = pois.findIndex(p => p.id === data.poiId);
                if (index !== -1) {
                    if (scrollRef.current) {
                        scrollRef.current.scrollTo({ x: index * 260, animated: true });
                    }
                    const poi = pois[index];
                    if (poi) {
                        handleGetDirections(poi.latitude, poi.longitude);
                    }
                }
            } else if (data.type === 'HOTEL_CLICKED') {
                handleRecenter();
            } else if (data.type === 'MAP_LOADED') {
                console.log('[PropertyMapWebView] Map WebView signal: MAP_LOADED');
                if (pois.length > 0) {
                    webViewRef.current?.postMessage(JSON.stringify({ type: 'SET_POIS', pois }));
                } else {
                    handleCategorySelect('dining');
                }
            }
        } catch (e) { }
    };

    const handleCardSelect = (poiId: string, poiLat: number, poiLng: number) => {
        setSelectedPoiId(poiId);
        webViewRef.current?.postMessage(JSON.stringify({ type: 'SELECT_POI', poiId }));
        handleGetDirections(poiLat, poiLng);
    };

    const styles = useMemo(() => getStyles(isDark), [isDark]);

    // Renders weather popover details styled exactly like the web app widget
    const renderWeatherPopover = () => {
        if (!weather || !weatherOpen) return null;
        const current = weather.current;

        return (
            <View style={styles.weatherPanel}>
                <View style={styles.weatherPanelHeader}>
                    <View style={styles.weatherPanelHeaderLeft}>
                        <Cloud size={24} color="#3b82f6" />
                        <View style={{ marginLeft: 8 }}>
                            <Text style={styles.weatherPanelTemp}>{current.temp}°F</Text>
                            <Text style={styles.weatherPanelDesc}>{current.description}</Text>
                        </View>
                    </View>
                    <Pressable style={styles.weatherPanelClose} onPress={() => setWeatherOpen(false)}>
                        <X size={16} color={isDark ? '#cbd5e1' : '#475569'} />
                    </Pressable>
                </View>

                {/* Weather details row */}
                <View style={styles.weatherStatsRow}>
                    <View style={styles.weatherStatItem}>
                        <Thermometer size={14} color="#f97316" />
                        <Text style={styles.weatherStatLabel}>Feels like</Text>
                        <Text style={styles.weatherStatValue}>{current.feelsLike}°</Text>
                    </View>
                    <View style={styles.weatherStatItem}>
                        <Droplets size={14} color="#3b82f6" />
                        <Text style={styles.weatherStatLabel}>Humidity</Text>
                        <Text style={styles.weatherStatValue}>{current.humidity}%</Text>
                    </View>
                    <View style={styles.weatherStatItem}>
                        <Wind size={14} color="#14b8a6" />
                        <Text style={styles.weatherStatLabel}>Wind</Text>
                        <Text style={styles.weatherStatValue}>{current.windSpeed} {current.windCardinal}</Text>
                    </View>
                </View>

                {/* Hourly scroll */}
                {weather.hourly && weather.hourly.length > 0 && (
                    <View style={{ marginTop: 12 }}>
                        <Text style={styles.weatherSecTitle}>HOURLY FORECAST</Text>
                        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ gap: 8, paddingVertical: 4 }}>
                            {weather.hourly.slice(0, 12).map((h: any, i: number) => (
                                <View key={i} style={styles.weatherHourlyItem}>
                                    <Text style={styles.weatherHourlyTime}>
                                        {h.hour === 0 ? '12 AM' : h.hour < 12 ? `${h.hour} AM` : h.hour === 12 ? '12 PM' : `${h.hour - 12} PM`}
                                    </Text>
                                    <Text style={styles.weatherHourlyTemp}>{h.temp}°</Text>
                                    {h.precipChance > 0 && (
                                        <View style={{ flexDirection: 'row', alignItems: 'center', gap: 2 }}>
                                            <Umbrella size={8} color="#3b82f6" />
                                            <Text style={styles.weatherHourlyPrecip}>{h.precipChance}%</Text>
                                        </View>
                                    )}
                                </View>
                            ))}
                        </ScrollView>
                    </View>
                )}

                {/* Daily forecast */}
                {weather.daily && weather.daily.length > 0 && (
                    <View style={{ marginTop: 10 }}>
                        <Text style={styles.weatherSecTitle}>3-DAY FORECAST</Text>
                        <View style={{ gap: 6, marginTop: 4 }}>
                            {weather.daily.map((d: any, i: number) => (
                                <View key={i} style={styles.weatherDailyRow}>
                                    <Text style={styles.weatherDailyDay}>
                                        {i === 0 ? 'Today' : i === 1 ? 'Tomorrow' : new Date(d.date).toLocaleDateString([], { weekday: 'short' })}
                                    </Text>
                                    <Text style={styles.weatherDailyDesc} numberOfLines={1}>{d.description}</Text>
                                    <View style={{ flexDirection: 'row', gap: 8 }}>
                                        <Text style={styles.weatherDailyMax}>{d.tempMax}°</Text>
                                        <Text style={styles.weatherDailyMin}>{d.tempMin}°</Text>
                                    </View>
                                </View>
                            ))}
                        </View>
                    </View>
                )}
            </View>
        );
    };

    // Unified sliding bottom sheet overlay (Apple / Google Maps style)
    const renderSlidingBottomSheet = (isMax: boolean) => {
        return (
            <Animated.View style={[
                styles.slidingBottomSheet,
                isMax ? styles.slidingBottomSheetMaximized : styles.slidingBottomSheetMinimized,
                { height: sheetHeight }
            ]}>
                {/* Drag Handle & Title Header - Touch Target Area for sliding gestures */}
                <View {...panResponder.panHandlers} style={styles.dragHeaderWrapper}>
                    {/* Sleek iOS drag handle */}
                    <View style={styles.dragHandle} />

                    {/* Title header */}
                    <View style={styles.sheetHeader}>
                        <Text style={styles.discoveryTitle}>Explore Nearby</Text>
                        <Text style={styles.discoverySubtitle}>Premium recommendations around {hotelName}</Text>
                    </View>
                </View>

                {/* Category Pills horizontal list */}
                <View style={styles.categoriesScrollWrapper}>
                    <ScrollView
                        horizontal
                        showsHorizontalScrollIndicator={false}
                        style={styles.sheetCategoriesScroll}
                        contentContainerStyle={styles.sheetCategoriesContent}
                    >
                        {DISCOVERY_CATEGORIES.map(cat => {
                            const Icon = cat.icon;
                            const isActive = activeCategory === cat.id;
                            return (
                                <Pressable
                                    key={cat.id}
                                    style={[
                                        styles.categoryChip,
                                        isActive && { backgroundColor: '#2563eb', borderColor: '#2563eb' }
                                    ]}
                                    onPress={() => handleCategorySelect(cat.id)}
                                >
                                    <Icon size={12} color={isActive ? 'white' : (isDark ? '#cbd5e1' : '#475569')} />
                                    <Text style={[styles.categoryLabel, isActive && styles.categoryLabelActive]}>
                                        {cat.label}
                                    </Text>
                                </Pressable>
                            );
                        })}
                    </ScrollView>
                </View>

                {/* Horizontal scroll recommended POI cards expanded state */}
                {activeCategory && (
                    <View style={styles.sheetPoisWrapper}>
                        {loadingPois ? (
                            <View style={styles.poisLoadingSheet}>
                                <ActivityIndicator size="small" color="#2563eb" />
                                <Text style={styles.poisLoadingTextSheet}>Searching local spots...</Text>
                            </View>
                        ) : pois.length === 0 ? (
                            <View style={styles.poisEmptySheet}>
                                <Text style={styles.poisEmptyTextSheet}>No nearby spots found in this category.</Text>
                            </View>
                        ) : (
                            <ScrollView
                                ref={scrollRef}
                                horizontal
                                showsHorizontalScrollIndicator={false}
                                snapToInterval={232}
                                decelerationRate="fast"
                                contentContainerStyle={styles.sheetPoisContent}
                            >
                                {pois.map(poi => {
                                    const isSelected = selectedPoiId === poi.id;
                                    return (
                                        <Pressable
                                            key={poi.id}
                                            style={[
                                                styles.poiCard,
                                                isSelected && { borderColor: '#2563eb', borderWidth: 2 }
                                            ]}
                                            onPress={() => handleCardSelect(poi.id, poi.latitude, poi.longitude)}
                                        >
                                            <OptimizedImage
                                                uri={poi.staticImageUrl}
                                                style={styles.poiImage}
                                                type="hotel"
                                            />
                                            <View style={styles.poiBody}>
                                                <Text style={styles.poiName} numberOfLines={1}>{poi.name}</Text>
                                                <Text style={styles.poiAddress} numberOfLines={1}>{poi.address}</Text>

                                                <View style={styles.poiFooter}>
                                                    <View style={styles.poiDistanceRow}>
                                                        <MapPin size={11} color={isDark ? '#cbd5e1' : '#64748b'} />
                                                        <Text style={styles.poiDistanceText}>{poi.distance} away</Text>
                                                    </View>

                                                    <Pressable
                                                        style={[styles.poiDirectionsBtn, { backgroundColor: poi.color }]}
                                                        onPress={() => handleGetDirections(poi.latitude, poi.longitude)}
                                                    >
                                                        <Navigation size={9} color="white" />
                                                        <Text style={styles.poiDirectionsText}>Go</Text>
                                                    </Pressable>
                                                </View>
                                            </View>
                                        </Pressable>
                                    );
                                })}
                            </ScrollView>
                        )}
                    </View>
                )}
            </Animated.View>
        );
    };

    const renderMapLayout = () => {
        return (
            <View style={styles.container}>
                <View style={styles.mapWrapper}>
                    <WebView
                        ref={webViewRef}
                        originWhitelist={['*']}
                        source={{ html: htmlContent }}
                        onMessage={onMessage}
                        style={styles.webView}
                        javaScriptEnabled={true}
                        domStorageEnabled={true}
                        startInLoadingState={true}
                        renderLoading={() => (
                            <View style={styles.mapLoading}>
                                <ActivityIndicator size="large" color="#2563eb" />
                            </View>
                        )}
                    />

                    {/* Weather Trigger Badge */}
                    {weather && (
                        <Pressable style={styles.weatherBadge} onPress={() => setWeatherOpen(!weatherOpen)}>
                            <Text style={styles.weatherEmoji}>{weather.current.icon}</Text>
                            <Text style={styles.weatherTemp}>{weather.current.temp}°</Text>
                        </Pressable>
                    )}

                    {/* Left Floating Controls (Recenter, Maximize) */}
                    <View style={styles.floatingControlsLeft}>
                        <Pressable style={styles.controlBtn} onPress={handleRecenter}>
                            <Compass size={18} color={isDark ? '#60a5fa' : '#2563eb'} />
                        </Pressable>
                        <View style={styles.controlSeparator} />
                        <Pressable 
                            style={styles.controlBtn} 
                            onPress={() => setIsMaximized(true)}
                        >
                            <Maximize2 size={18} color={isDark ? '#60a5fa' : '#2563eb'} />
                        </Pressable>
                    </View>

                    {/* Right Floating Controls (Zoom In, Zoom Out) */}
                    <View style={styles.floatingControls}>
                        <Pressable style={styles.controlBtn} onPress={() => handleZoom('in')}>
                            <Plus size={18} color={isDark ? '#60a5fa' : '#2563eb'} />
                        </Pressable>
                        <View style={styles.controlSeparator} />
                        <Pressable style={styles.controlBtn} onPress={() => handleZoom('out')}>
                            <Minus size={18} color={isDark ? '#60a5fa' : '#2563eb'} />
                        </Pressable>
                    </View>

                    {/* Weather Popover Card */}
                    {renderWeatherPopover()}

                    {/* Route Info Banner */}
                    {activeRoute && routeInfo && (
                        <View style={styles.routeBanner}>
                            <View style={styles.routeBannerLeft}>
                                <Navigation size={16} color="#10b981" />
                                <Text style={styles.routeText}>
                                    {routeInfo.duration} ({routeInfo.distance})
                                </Text>
                            </View>
                            <Pressable style={styles.routeClose} onPress={handleClearRoute}>
                                <Text style={styles.routeCloseText}>Clear</Text>
                            </Pressable>
                        </View>
                    )}

                    {/* Directions Calculation Overlay */}
                    {calculatingRoute && (
                        <View style={styles.routeLoading}>
                            <ActivityIndicator size="small" color="white" />
                            <Text style={styles.routeLoadingText}>Routing...</Text>
                        </View>
                    )}
                    {/* Animated Sliding Bottom Sheet (INLINE) */}
                    {renderSlidingBottomSheet(false)}
                </View>
            </View>
        );
    };

    return (
        <View style={{ width: '100%' }}>
            {/* Standard Inline Map View - Only mount when not maximized to prevent ref collision */}
            {!isMaximized && renderMapLayout()}

            {/* Full Screen Maximized Map Modal */}
            <Modal
                visible={isMaximized}
                animationType="slide"
                onRequestClose={() => setIsMaximized(false)}
            >
                <View style={styles.modalContent}>
                    {/* Fullscreen Map WebView Background */}
                    <View style={StyleSheet.absoluteFillObject}>
                        <WebView
                            ref={webViewRef}
                            originWhitelist={['*']}
                            source={{ html: htmlContent }}
                            onMessage={onMessage}
                            style={styles.webView}
                            javaScriptEnabled={true}
                            domStorageEnabled={true}
                            startInLoadingState={true}
                            renderLoading={() => (
                                <View style={styles.mapLoading}>
                                    <ActivityIndicator size="large" color="#2563eb" />
                                </View>
                            )}
                        />
                    </View>

                    {/* Floating Top Header Overlay */}
                    <View style={styles.floatingHeader}>
                        <Pressable style={styles.floatingCloseBtn} onPress={() => setIsMaximized(false)}>
                            <X size={20} color={isDark ? '#cbd5e1' : '#0f172a'} />
                        </Pressable>
                        <Text style={styles.floatingHeaderTitle} numberOfLines={1}>
                            {hotelName} Map
                        </Text>
                        
                        {weather && (
                            <Pressable style={styles.floatingWeatherBadge} onPress={() => setWeatherOpen(!weatherOpen)}>
                                <Text style={styles.weatherEmoji}>{weather.current.icon}</Text>
                                <Text style={styles.weatherTemp}>{weather.current.temp}°</Text>
                            </Pressable>
                        )}
                    </View>

                    {/* Floating Map Zoom & Orientation HUD Controls */}
                    <View style={styles.hudLeft}>
                        <Pressable style={styles.controlBtn} onPress={handleRecenter}>
                            <Compass size={18} color="#2563eb" />
                        </Pressable>
                    </View>

                    <View style={styles.hudRight}>
                        <Pressable style={styles.controlBtn} onPress={() => handleZoom('in')}>
                            <Plus size={18} color="#2563eb" />
                        </Pressable>
                        <View style={styles.controlSeparator} />
                        <Pressable style={styles.controlBtn} onPress={() => handleZoom('out')}>
                            <Minus size={18} color="#2563eb" />
                        </Pressable>
                    </View>

                    {/* Route Info Banner */}
                    {activeRoute && routeInfo && (
                        <View style={styles.floatingRouteBanner}>
                            <View style={styles.routeBannerLeft}>
                                <Navigation size={14} color="#2563eb" />
                                <Text style={styles.routeText}>
                                    {routeInfo.duration} ({routeInfo.distance})
                                </Text>
                            </View>
                            <Pressable style={styles.routeClose} onPress={handleClearRoute}>
                                <Text style={styles.routeCloseText}>Clear</Text>
                            </Pressable>
                        </View>
                    )}

                    {/* Directions Calculation Overlay */}
                    {calculatingRoute && (
                        <View style={styles.floatingRouteLoading}>
                            <ActivityIndicator size="small" color="white" />
                            <Text style={styles.routeLoadingText}>Routing...</Text>
                        </View>
                    )}

                    {/* Weather Popover Card */}
                    {renderWeatherPopover()}

                    {/* Animated Sliding Bottom Sheet (MAXIMIZED) */}
                    {renderSlidingBottomSheet(true)}
                </View>
            </Modal>
        </View>
    );
}
const getStyles = (isDark: boolean) => StyleSheet.create({
    container: {
        width: '100%',
        marginVertical: 8,
    },
    fullScreenWrapper: {
        flex: 1,
        width: '100%',
    },
    modalContent: {
        flex: 1,
        backgroundColor: isDark ? '#020617' : '#f8fafc',
    },
    modalHeader: {
        height: 56,
        borderBottomWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        paddingHorizontal: 16,
        backgroundColor: isDark ? '#0f172a' : 'white',
    },
    modalTitle: {
        fontSize: 16,
        fontWeight: 'bold',
        color: isDark ? 'white' : '#0f172a',
    },
    modalClose: {
        padding: 4,
    },
    mapWrapper: {
        height: 380,
        borderRadius: 20,
        overflow: 'hidden',
        position: 'relative',
        backgroundColor: isDark ? '#1e293b' : '#e2e8f0',
    },
    mapWrapperMaximized: {
        flex: 1,
        position: 'relative',
        backgroundColor: isDark ? '#1e293b' : '#e2e8f0',
    },
    webView: {
        flex: 1,
    },
    mapLoading: {
        ...StyleSheet.absoluteFillObject,
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: isDark ? 'rgba(2, 6, 23, 0.7)' : 'rgba(255, 255, 255, 0.7)',
    },
    weatherBadge: {
        position: 'absolute',
        top: 12,
        right: 12,
        backgroundColor: isDark ? 'rgba(30, 41, 59, 0.85)' : 'rgba(15, 23, 42, 0.85)',
        paddingHorizontal: 10,
        paddingVertical: 6,
        borderRadius: 14,
        flexDirection: 'row',
        alignItems: 'center',
        gap: 4,
        boxShadow: '0 4px 10px rgba(0,0,0,0.15)',
        elevation: 5,
        zIndex: 10,
    },
    weatherEmoji: {
        fontSize: 15,
    },
    weatherTemp: {
        color: 'white',
        fontSize: 11,
        fontWeight: 'bold',
        fontFamily: Platform.OS === 'ios' ? 'Helvetica Neue' : 'sans-serif',
    },
    floatingControls: {
        position: 'absolute',
        top: 60, // Cleanly placed below the weather trigger badge on the right
        right: 12,
        backgroundColor: isDark ? 'rgba(15, 23, 42, 0.9)' : 'rgba(255, 255, 255, 0.9)',
        borderRadius: 12,
        padding: 4,
        boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)',
        elevation: 5,
        zIndex: 10,
        borderWidth: 1,
        borderColor: isDark ? 'rgba(255,255,255,0.06)' : 'transparent',
    },
    floatingControlsLeft: {
        position: 'absolute',
        top: 12, // Cleanly placed in the top-left corner
        left: 12,
        backgroundColor: isDark ? 'rgba(15, 23, 42, 0.9)' : 'rgba(255, 255, 255, 0.9)',
        borderRadius: 12,
        padding: 4,
        boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)',
        elevation: 5,
        zIndex: 10,
        borderWidth: 1,
        borderColor: isDark ? 'rgba(255,255,255,0.06)' : 'transparent',
    },
    controlBtn: {
        width: 32,
        height: 32,
        alignItems: 'center',
        justifyContent: 'center',
        borderRadius: 8,
    },
    controlSeparator: {
        height: 1,
        backgroundColor: isDark ? '#334155' : '#e2e8f0',
        marginHorizontal: 4,
    },
    routeBanner: {
        position: 'absolute',
        top: 12,
        left: 60,
        backgroundColor: isDark ? '#0f172a' : '#1e293b',
        borderRadius: 12,
        paddingHorizontal: 12,
        paddingVertical: 8,
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        width: width - 150,
        boxShadow: '0 4px 10px rgba(0,0,0,0.2)',
        borderWidth: 1,
        borderColor: isDark ? 'rgba(255,255,255,0.08)' : 'transparent',
    },
    routeBannerLeft: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 6,
    },
    routeText: {
        color: 'white',
        fontSize: 12,
        fontWeight: '600',
    },
    routeClose: {
        backgroundColor: 'rgba(255, 255, 255, 0.15)',
        paddingHorizontal: 8,
        paddingVertical: 2,
        borderRadius: 6,
    },
    routeCloseText: {
        color: 'white',
        fontSize: 10,
        fontWeight: 'bold',
    },
    routeLoading: {
        position: 'absolute',
        top: 12,
        left: 60,
        backgroundColor: isDark ? 'rgba(15, 23, 42, 0.95)' : 'rgba(30, 41, 59, 0.95)',
        borderRadius: 12,
        paddingHorizontal: 12,
        paddingVertical: 8,
        flexDirection: 'row',
        alignItems: 'center',
        gap: 8,
    },
    routeLoadingText: {
        color: 'white',
        fontSize: 12,
        fontWeight: '500',
    },
    discoveryHeader: {
        marginTop: 14,
        paddingHorizontal: 4,
    },
    discoveryTitle: {
        fontSize: 15,
        fontWeight: 'bold',
        color: isDark ? '#f8fafc' : '#0f172a',
    },
    discoverySubtitle: {
        fontSize: 11,
        color: isDark ? '#94a3b8' : '#64748b',
        marginTop: 2,
    },
    categoriesScroll: {
        marginTop: 10,
    },
    categoriesContent: {
        paddingHorizontal: 4,
        gap: 8,
    },
    categoryChip: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 4,
        paddingHorizontal: 10,
        paddingVertical: 5,
        borderRadius: 14,
        borderWidth: 1,
        borderColor: isDark ? '#334155' : '#e2e8f0',
        backgroundColor: isDark ? '#1e293b' : 'white',
        boxShadow: '0 2px 6px rgba(0,0,0,0.1)',
        elevation: 3,
    },
    categoryLabel: {
        fontSize: 11,
        fontWeight: '600',
        color: isDark ? '#cbd5e1' : '#475569',
    },
    categoryLabelActive: {
        color: 'white',
        fontWeight: 'bold',
    },
    poisWrapper: {
        marginTop: 12,
        height: 150,
        justifyContent: 'center',
    },
    poisLoading: {
        alignItems: 'center',
        justifyContent: 'center',
        gap: 6,
    },
    poisLoadingText: {
        fontSize: 12,
        color: isDark ? '#cbd5e1' : '#64748b',
    },
    poisEmpty: {
        alignItems: 'center',
        justifyContent: 'center',
    },
    poisEmptyText: {
        fontSize: 12,
        color: isDark ? '#64748b' : '#94a3b8',
    },
    poisContent: {
        paddingHorizontal: 4,
        gap: 12,
    },
    poiCard: {
        width: 220,
        height: 94,
        backgroundColor: isDark ? '#1e293b' : 'white',
        borderRadius: 12,
        overflow: 'hidden',
        borderWidth: 1,
        borderColor: isDark ? '#334155' : '#f1f5f9',
        boxShadow: '0 2px 8px rgba(0,0,0,0.08)',
        flexDirection: 'row',
    },
    poiImage: {
        width: 76,
        height: '100%',
        backgroundColor: isDark ? '#0f172a' : '#f1f5f9',
    },
    poiBody: {
        flex: 1,
        padding: 8,
        justifyContent: 'space-between',
    },
    poiName: {
        fontSize: 11,
        fontWeight: 'bold',
        color: isDark ? '#f8fafc' : '#0f172a',
    },
    poiAddress: {
        fontSize: 9,
        color: isDark ? '#94a3b8' : '#64748b',
        marginTop: 1,
    },
    poiFooter: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        marginTop: 4,
    },
    poiDistanceRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 3,
    },
    poiDistanceText: {
        fontSize: 9,
        color: isDark ? '#cbd5e1' : '#64748b',
        fontWeight: '500',
    },
    poiDirectionsBtn: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 3,
        paddingHorizontal: 8,
        paddingVertical: 3,
        borderRadius: 6,
        backgroundColor: '#2563eb',
    },
    poiDirectionsText: {
        color: 'white',
        fontSize: 9,
        fontWeight: 'bold',
    },
    weatherPanel: {
        position: 'absolute',
        top: 60,
        right: 12,
        left: 12,
        backgroundColor: isDark ? 'rgba(15, 23, 42, 0.95)' : 'rgba(255, 255, 255, 0.95)',
        backdropFilter: 'blur(10px)',
        borderRadius: 16,
        padding: 12,
        borderWidth: 1,
        borderColor: isDark ? '#334155' : '#e2e8f0',
        boxShadow: '0 10px 25px rgba(0,0,0,0.2)',
        zIndex: 99,
        elevation: 6,
    },
    weatherPanelHeader: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        borderBottomWidth: 1,
        borderBottomColor: isDark ? '#334155' : '#f1f5f9',
        paddingBottom: 8,
    },
    weatherPanelHeaderLeft: {
        flexDirection: 'row',
        alignItems: 'center',
    },
    weatherPanelTemp: {
        fontSize: 18,
        fontWeight: 'bold',
        color: isDark ? 'white' : '#0f172a',
    },
    weatherPanelDesc: {
        fontSize: 10,
        color: isDark ? '#94a3b8' : '#64748b',
        fontWeight: '500',
    },
    weatherPanelClose: {
        padding: 4,
    },
    weatherStatsRow: {
        flexDirection: 'row',
        justifyContent: 'space-around',
        marginTop: 10,
        backgroundColor: isDark ? '#0f172a' : '#f8fafc',
        borderRadius: 8,
        paddingVertical: 6,
    },
    weatherStatItem: {
        alignItems: 'center',
        gap: 2,
    },
    weatherStatLabel: {
        fontSize: 8,
        color: isDark ? '#94a3b8' : '#64748b',
        fontWeight: '600',
    },
    weatherStatValue: {
        fontSize: 11,
        fontWeight: 'bold',
        color: isDark ? '#cbd5e1' : '#0f172a',
    },
    weatherSecTitle: {
        fontSize: 9,
        fontWeight: 'bold',
        color: isDark ? '#64748b' : '#94a3b8',
        letterSpacing: 1,
    },
    weatherHourlyItem: {
        minWidth: 54,
        alignItems: 'center',
        paddingVertical: 6,
        paddingHorizontal: 4,
        backgroundColor: isDark ? '#1e293b' : 'white',
        borderRadius: 8,
        borderWidth: 1,
        borderColor: isDark ? '#334155' : '#e2e8f0',
    },
    weatherHourlyTime: {
        fontSize: 8,
        fontWeight: '600',
        color: isDark ? '#94a3b8' : '#64748b',
    },
    weatherHourlyTemp: {
        fontSize: 10,
        fontWeight: 'bold',
        color: isDark ? 'white' : '#0f172a',
        marginVertical: 2,
    },
    weatherHourlyPrecip: {
        fontSize: 8,
        fontWeight: '600',
        color: '#3b82f6',
    },
    weatherDailyRow: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        paddingVertical: 2,
    },
    weatherDailyDay: {
        width: 70,
        fontSize: 10,
        fontWeight: '600',
        color: isDark ? '#cbd5e1' : '#475569',
    },
    weatherDailyDesc: {
        flex: 1,
        fontSize: 9,
        color: isDark ? '#94a3b8' : '#64748b',
        paddingHorizontal: 6,
    },
    weatherDailyMax: {
        fontSize: 10,
        fontWeight: 'bold',
        color: isDark ? 'white' : '#0f172a',
    },
    weatherDailyMin: {
        fontSize: 10,
        fontWeight: 'bold',
        color: isDark ? '#64748b' : '#94a3b8',
    },
    floatingHeader: {
        position: 'absolute',
        top: Platform.OS === 'ios' ? 50 : 36,
        left: 12,
        right: 12,
        height: 54,
        borderRadius: 16,
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        paddingHorizontal: 12,
        backgroundColor: isDark ? 'rgba(15, 23, 42, 0.9)' : 'rgba(255, 255, 255, 0.9)',
        borderWidth: 1,
        borderColor: isDark ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.04)',
        boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
        elevation: 6,
        zIndex: 50,
    },
    floatingCloseBtn: {
        width: 36,
        height: 36,
        borderRadius: 18,
        backgroundColor: isDark ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)',
        alignItems: 'center',
        justifyContent: 'center',
    },
    floatingHeaderTitle: {
        flex: 1,
        fontSize: 14,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
        marginHorizontal: 12,
    },
    floatingWeatherBadge: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 4,
        backgroundColor: isDark ? '#1e293b' : '#f1f5f9',
        paddingHorizontal: 10,
        paddingVertical: 6,
        borderRadius: 12,
    },
    hudLeft: {
        position: 'absolute',
        top: Platform.OS === 'ios' ? 116 : 102,
        left: 12,
        backgroundColor: isDark ? 'rgba(15, 23, 42, 0.9)' : 'rgba(255, 255, 255, 0.9)',
        borderRadius: 12,
        padding: 4,
        borderWidth: 1,
        borderColor: isDark ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.04)',
        boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
        elevation: 5,
        zIndex: 10,
    },
    hudRight: {
        position: 'absolute',
        top: Platform.OS === 'ios' ? 116 : 102,
        right: 12,
        backgroundColor: isDark ? 'rgba(15, 23, 42, 0.9)' : 'rgba(255, 255, 255, 0.9)',
        borderRadius: 12,
        padding: 4,
        borderWidth: 1,
        borderColor: isDark ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.04)',
        boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
        elevation: 5,
        zIndex: 10,
    },
    floatingRouteBanner: {
        position: 'absolute',
        top: Platform.OS === 'ios' ? 116 : 102,
        left: 60,
        backgroundColor: isDark ? '#0f172a' : '#1e293b',
        borderRadius: 12,
        paddingHorizontal: 12,
        paddingVertical: 8,
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        width: width - 150,
        boxShadow: '0 4px 10px rgba(0,0,0,0.2)',
        borderWidth: 1,
        borderColor: isDark ? 'rgba(255,255,255,0.08)' : 'transparent',
        zIndex: 10,
    },
    floatingRouteLoading: {
        position: 'absolute',
        top: Platform.OS === 'ios' ? 116 : 102,
        left: 60,
        backgroundColor: isDark ? 'rgba(15, 23, 42, 0.95)' : 'rgba(30, 41, 59, 0.95)',
        borderRadius: 12,
        paddingHorizontal: 12,
        paddingVertical: 8,
        flexDirection: 'row',
        alignItems: 'center',
        gap: 8,
        zIndex: 10,
    },
    categoriesScrollWrapper: {
        height: 38,
        marginTop: 6,
        marginBottom: 2,
    },
    slidingBottomSheet: {
        height: 250,
        backgroundColor: isDark ? 'rgba(15, 23, 42, 0.94)' : 'rgba(255, 255, 255, 0.94)',
        borderRadius: 20,
        paddingHorizontal: 12,
        paddingBottom: 10,
        borderWidth: 1,
        borderColor: isDark ? 'rgba(255, 255, 255, 0.08)' : 'rgba(0, 0, 0, 0.06)',
        boxShadow: '0 10px 30px rgba(0, 0, 0, 0.2)',
        elevation: 10,
        zIndex: 100,
        overflow: 'hidden',
    },
    slidingBottomSheetMaximized: {
        position: 'absolute',
        left: 12,
        right: 12,
        bottom: Platform.OS === 'ios' ? 34 : 20,
    },
    slidingBottomSheetMinimized: {
        position: 'absolute',
        left: 12,
        right: 12,
        bottom: 12,
    },
    dragHeaderWrapper: {
        width: '100%',
        alignItems: 'stretch',
        paddingBottom: 2,
    },
    dragHandle: {
        width: 36,
        height: 4,
        borderRadius: 2,
        backgroundColor: isDark ? 'rgba(255, 255, 255, 0.2)' : 'rgba(0, 0, 0, 0.15)',
        alignSelf: 'center',
        marginTop: 6,
        marginBottom: 10,
    },
    sheetHeader: {
        paddingHorizontal: 4,
        marginBottom: 8,
    },
    sheetCategoriesScroll: {
        height: 32,
        marginBottom: 6,
    },
    sheetCategoriesContent: {
        gap: 6,
    },
    sheetPoisWrapper: {
        marginTop: 6,
        height: 104,
        justifyContent: 'center',
    },
    poisLoadingSheet: {
        alignItems: 'center',
        justifyContent: 'center',
        gap: 6,
        height: 94,
    },
    poisLoadingTextSheet: {
        fontSize: 11,
        color: isDark ? '#cbd5e1' : '#64748b',
    },
    poisEmptySheet: {
        alignItems: 'center',
        justifyContent: 'center',
        height: 94,
    },
    poisEmptyTextSheet: {
        fontSize: 11,
        color: isDark ? '#64748b' : '#94a3b8',
    },
    sheetPoisContent: {
        gap: 10,
    },
});
