/**
 * Hotel search and booking API client.
 * All calls go through the web backend — no direct Supabase edge function calls.
 */

import { searchAirports } from '../data/airports';

const WEB_API_BASE = process.env.EXPO_PUBLIC_WEB_API_URL ?? 'https://cheapestgo.com';
const INVOKE_TIMEOUT_MS = 30_000;

async function webInvoke<T = any>(path: string, body?: any): Promise<T> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), INVOKE_TIMEOUT_MS);
    try {
        const res = await fetch(`${WEB_API_BASE}${path}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            credentials: 'include',
            body: body !== undefined ? JSON.stringify(body) : undefined,
            signal: controller.signal,
        });
        clearTimeout(timer);
        if (!res.ok) {
            const text = await res.text();
            let msg = `${path} failed (HTTP ${res.status})`;
            try { const j = JSON.parse(text); if (j.error) msg = j.error; } catch {}
            throw new Error(msg);
        }
        return res.json() as Promise<T>;
    } catch (err: any) {
        clearTimeout(timer);
        if (err.name === 'AbortError') throw new Error('Request timed out. Please check your connection.');
        throw err;
    }
}

// ─── Hotel Search APIs ───

export interface Destination {
    type: 'city' | 'country' | 'history';
    title: string;
    subtitle: string;
    countryCode?: string;
    id?: string;
    code?: string;
    latitude?: number;
    longitude?: number;
}

const countryMap: Record<string, string> = {
    'Philippines': 'PH', 'Thailand': 'TH', 'Japan': 'JP', 'Korea': 'KR', 'South Korea': 'KR',
    'United States': 'US', 'USA': 'US', 'United Kingdom': 'GB', 'UK': 'GB', 'Vietnam': 'VN',
    'Singapore': 'SG', 'Malaysia': 'MY', 'Indonesia': 'ID', 'France': 'FR', 'Germany': 'DE',
    'Italy': 'IT', 'Spain': 'ES', 'Australia': 'AU', 'Canada': 'CA', 'China': 'CN'
};

const DESTINATION_KEYWORD_ALIASES: Record<string, string> = {
    'beijing airport': 'Beijing',
    'beijing capital airport': 'Beijing',
    'beijing city': 'Beijing',
    'beijing downtown': 'Beijing',
    'hk': 'Hong Kong',
    'hongkong': 'Hong Kong',
    'hong kong airport': 'Hong Kong',
    'new york city': 'New York',
    'new york': 'New York',
    'nyc': 'New York',
    'los angeles': 'Los Angeles',
    'la': 'Los Angeles',
    'sao paulo': 'São Paulo',
    'saopaulo': 'São Paulo',
    'saint petersburg': 'St. Petersburg',
    'san francisco': 'San Francisco',
    'sf': 'San Francisco',
    'sfo': 'San Francisco',
    'london airport': 'London',
    'tokyo airport': 'Tokyo',
};

function normalizeDestinationKeyword(keyword: string): string {
    if (!keyword) return '';
    const cleaned = keyword.trim().replace(/\s+/g, ' ');
    const alias = DESTINATION_KEYWORD_ALIASES[cleaned.toLowerCase()];
    if (alias) return alias;
    return cleaned;
}

function getCountryCodeFromAddress(address: string): string {
    if (!address) return '';
    const parts = address.split(',').map(p => p.trim());
    const lastPart = parts[parts.length - 1];
    return countryMap[lastPart] || '';
}

// Calls the web server's /api/autocomplete which proxies Mapbox server-side.
// Direct Mapbox calls from the device fail because the token is domain-restricted.
async function mapboxDestinations(query: string): Promise<Destination[]> {
    try {
        const res = await fetch(`${WEB_API_BASE}/api/autocomplete`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ query }),
        });
        if (!res.ok) return [];
        const json = await res.json();
        // Production returns { success, data: [...] }; dev returns [] directly
        const features: any[] = Array.isArray(json) ? json : (json.data ?? []);
        return features
            .map(f => ({
                type: (f.type || 'city') as Destination['type'],
                title: f.title || '',
                subtitle: f.subtitle || '',
                countryCode: f.countryCode || '',
                id: f.id,
                code: f.code,
            } as Destination))
            .filter(d => !!d.title);
    } catch {
        return [];
    }
}

export async function autocompleteDestinations(keyword: string): Promise<Destination[]> {
    const normalizedKeyword = normalizeDestinationKeyword(keyword);
    if (!normalizedKeyword || normalizedKeyword.length < 2) return [];

    // Run Mapbox and TGX in parallel — Mapbox wins if it returns results.
    // Mapbox IDs go as placeId; TGX codes go as destinationCode.
    const mapboxPromise = mapboxDestinations(normalizedKeyword);

    const tgxPromise = webInvoke<{ data?: any[] }>('/api/fn/travelgatex-destinations', { keyword: normalizedKeyword })
        .then(result =>
            (result?.data ?? []).map((item: any) => ({
                type: (item.type || 'city') as Destination['type'],
                title: item.label || item.name || item.code || '',
                subtitle: '',
                countryCode: '',
                code: item.code,
            } as Destination))
        )
        .catch(() => [] as Destination[]);

    const [mapboxResults, tgxResults] = await Promise.all([mapboxPromise, tgxPromise]);
    return mapboxResults.length > 0 ? mapboxResults : tgxResults;
}

export interface HotelSearchParams {
    destination: string;
    countryCode?: string;
    placeId?: string;         // Mapbox place ID (from web autocomplete)
    destinationCode?: string; // TGX destination code (from TGX autocomplete fallback)
    checkIn: string; // YYYY-MM-DD
    checkOut: string;
    adults: number;
    children: number;
    childrenAges?: string; // Comma-separated ages
    rooms: number;
    currency?: string;
}

export async function searchHotels(params: HotelSearchParams) {
    let { destination, countryCode, placeId, destinationCode } = params;
    const normalizedDestination = normalizeDestinationKeyword(destination);
    if (normalizedDestination && normalizedDestination !== destination) {
        destination = normalizedDestination;
    }

    // If we're missing both countryCode and placeId, try to resolve via autocomplete first
    // This handles cases where the user types and hits search without selecting a suggestion.
    if (!placeId && !countryCode && destination) {
        try {
            const suggestions = await autocompleteDestinations(destination);
            const exactMatch = suggestions.find(s => s.title.toLowerCase() === destination.toLowerCase() && !!s.id);
            if (exactMatch) {
                placeId = exactMatch.id;
                countryCode = exactMatch.countryCode || getCountryCodeFromAddress(exactMatch.subtitle || exactMatch.title || '');
            }
        } catch (err) {
            // Silently fail, we'll try with just the name
        }
    }

    const result = await webInvoke('/api/fn/travelgatex-search', {
        cityName: destination,
        placeId: placeId || undefined,             // Mapbox ID → geocoding lookup
        destinationCode: destinationCode || undefined, // TGX code → direct lookup
        countryCode: countryCode || undefined,
        checkin: params.checkIn,
        checkout: params.checkOut,
        adults: params.adults,
        children: params.children,
        rooms: params.rooms,
        currency: params.currency || 'USD',
        limit: 100,
        offset: 0,
    });

    // Standardize lat/lng to top level to maintain 100% backwards compatibility
    if (result && Array.isArray(result.data)) {
        result.data = result.data.map((hotel: any) => {
            const lat = hotel.latitude || hotel.coordinates?.lat || (hotel.details && (hotel.details.latitude || hotel.details.location?.latitude)) || 0;
            const lng = hotel.longitude || hotel.coordinates?.lng || (hotel.details && (hotel.details.longitude || hotel.details.location?.longitude)) || 0;
            return {
                ...hotel,
                latitude: Number(lat),
                longitude: Number(lng),
                lat: Number(lat),
                lng: Number(lng),
            };
        });
    }

    return result;
}

export async function getHotelDetails(hotelId: string, options: any = {}) {
    const { checkIn, checkOut, adults, children, rooms, currency } = options;
    const result = await webInvoke('/api/fn/travelgatex-search', {
        hotelCode: hotelId,
        checkin: checkIn,
        checkout: checkOut,
        adults: adults || 2,
        children: children || 0,
        rooms: rooms || 1,
        currency: currency || 'USD'
    });

    const hotel = result?.data || null;
    if (hotel) {
        const lat = hotel.latitude || hotel.coordinates?.lat || (hotel.details && (hotel.details.latitude || hotel.details.location?.latitude)) || 0;
        const lng = hotel.longitude || hotel.coordinates?.lng || (hotel.details && (hotel.details.longitude || hotel.details.location?.longitude)) || 0;
        return {
            ...hotel,
            latitude: Number(lat),
            longitude: Number(lng),
            lat: Number(lat),
            lng: Number(lng),
        };
    }
    return null;
}

export async function getHotelReviews(hotelId: string, limit: number = 20) {
    // Generate realistic mock reviews based on the hotelId
    const firstNames = [
        'John', 'Maria', 'Sarah', 'Alex', 'David', 'Emma', 'Sofia', 'Michael', 'Chloe', 'James',
        'Daniel', 'Olivia', 'Matthew', 'Isabella', 'Ethan', 'Mia', 'Lucas', 'Charlotte', 'Joseph', 'Amelia',
        'William', 'Harper', 'Ryan', 'Evelyn', 'Andrew', 'Abigail', 'Jack', 'Emily', 'Benjamin', 'Elizabeth',
        'Nicholas', 'Sofia', 'Tyler', 'Avery', 'Brandon', 'Ella', 'Zachary', 'Madison', 'David', 'Scarlett'
    ];
    const lastNames = [
        'Smith', 'Santos', 'Tan', 'Johnson', 'Rodriguez', 'Lee', 'Kim', 'Brown', 'Davis', 'Wilson',
        'Martinez', 'Anderson', 'Taylor', 'Thomas', 'Hernandez', 'Moore', 'Martin', 'Jackson', 'Thompson', 'White',
        'Lopez', 'Lee', 'Gonzalez', 'Harris', 'Clark', 'Lewis', 'Robinson', 'Walker', 'Perez', 'Hall',
        'Young', 'Allen', 'Sanchez', 'Wright', 'King', 'Scott', 'Green', 'Baker', 'Adams', 'Nelson'
    ];
    const headlines = [
        "Incredible stay! The view was absolutely spectacular and the staff went above and beyond.",
        "Beautiful property and perfect location. Will definitely book again next time!",
        "Very clean and modern room, highly recommended for families and couples.",
        "Excellent hospitality, extremely comfy bed, and a superb breakfast selection.",
        "A truly premium experience. Every detail was perfect, from check-in to check-out.",
        "Fantastic value for money. Outstanding service and extremely friendly staff.",
        "Wonderful experience! The amenities were top-notch and the room was exceptionally clean.",
        "Great location close to everything. Very comfortable rooms and delicious food.",
        "Highly recommended stay. We loved the peaceful atmosphere and beautiful design.",
        "An absolute gem! The staff treated us like royalty. We had an amazing time.",
        "Spotless rooms, very convenient location, and a great selection at breakfast.",
        "Perfect business trip stay. Fast Wi-Fi, comfortable workspace, and quiet rooms.",
        "Lovely boutique feel. The service was personalized and extremely warm.",
        "Exceeded all expectations. Exceptional quality and super friendly customer service.",
        "Very comfortable and modern amenities. Will recommend to all my friends!"
    ];
    
    const reviews = [];
    const count = limit;
    for (let i = 0; i < count; i++) {
        // Generate stable seed based on hotelId and index
        let hash = 0;
        const seedStr = `${hotelId}-${i}`;
        for (let j = 0; j < seedStr.length; j++) {
            hash = seedStr.charCodeAt(j) + ((hash << 5) - hash);
        }
        const idx = Math.abs(hash);
        
        const name = `${firstNames[idx % firstNames.length]} ${lastNames[(idx >> 1) % lastNames.length]}`;
        const headline = headlines[idx % headlines.length];
        const date = new Date(Date.now() - (idx % 30) * 24 * 60 * 60 * 1000).toISOString();
        const score = 8.5 + (idx % 15) / 10; // score between 8.5 and 10.0
        
        reviews.push({
            name,
            date,
            averageScore: Math.round(score),
            headline,
            pros: headline,
        });
    }
    return reviews;
}

// ─── Booking APIs ───

export interface PrebookParams {
    offerId: string;
    currency?: string;
    adults?: number;
    children?: number;
    roomName?: string;
}

export interface PrebookResponse {
    prebookId: string;
    price?: number;
    currency?: string;
    cancellationPolicies?: {
        cancelPolicyInfos?: Array<{
            cancelTime: string;
            amount: number;
            currency: string;
            type: string;
        }>;
        hotelRemarks?: string[];
        refundableTag?: string;
    };
    roomSubstituted?: boolean;
    substitutedRoomName?: string;
}

export async function prebookRoom(params: PrebookParams): Promise<PrebookResponse> {
    const result = await webInvoke<{ success: boolean; data?: any; error?: string }>(
        '/api/booking/prebook',
        {
            offerId: params.offerId,
            currency: params.currency,
            adults: params.adults,
            children: params.children,
            roomName: params.roomName,
        },
    );
    if (!result.success || !result.data) {
        throw new Error(result.error || 'Prebook failed — room may no longer be available.');
    }
    const d = result.data;
    return {
        prebookId: d.prebookId,
        price: d.price?.total ?? (typeof d.price === 'number' ? d.price : undefined),
        currency: d.currency,
        cancellationPolicies: d.cancellationPolicies,
        roomSubstituted: d.roomSubstituted,
        substitutedRoomName: d.substitutedRoomName,
    };
}

export async function validatePromoCode(code: string, price: number): Promise<any> {
    const result = await webInvoke<{ success: boolean; data?: any; error?: string }>(
        '/api/voucher/validate',
        { code, bookingPrice: price },
    );
    if (!result.success) throw new Error(result.error || 'Failed to validate promo code');
    return result.data;
}

export async function getHotelFacilities(): Promise<any[]> {
    return [];
}

// ─── Flight Search APIs ───

export interface Airport {
    iata: string;
    name: string;
    city: string;
    country: string;
    countryCode: string;
}

export interface FlightSearchParams {
    origin: string;
    destination: string;
    departureDate: string;
    returnDate?: string;
    adults: number;
    children?: number;
    infants?: number;
    cabinClass?: string;
    tripType: 'one-way' | 'round-trip' | 'multi-city';
    multiCitySegments?: Array<{ origin: string; destination: string; departureDate: string }>;
}

export async function searchFlights(params: FlightSearchParams) {
    let segments = [
        {
            origin: params.origin.toUpperCase(),
            destination: params.destination.toUpperCase(),
            departureDate: params.departureDate,
        },
    ];

    if (params.tripType === 'round-trip' && params.returnDate) {
        segments.push({
            origin: params.destination.toUpperCase(),
            destination: params.origin.toUpperCase(),
            departureDate: params.returnDate,
        });
    } else if (params.tripType === 'multi-city' && params.multiCitySegments) {
        segments = params.multiCitySegments.map(s => ({
            origin: s.origin.toUpperCase(),
            destination: s.destination.toUpperCase(),
            departureDate: s.departureDate,
        }));
    }

    // Call the web app's search route — has validation, rate limiting, and
    // runs Duffel + Mystifly in parallel with proper 15s timeouts.
    const BASE = process.env.EXPO_PUBLIC_WEB_API_URL ?? 'https://cheapestgo.com';
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 30_000);

    try {
        const res = await fetch(`${BASE}/api/flights/search`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                segments,
                passengers: {
                    adults: params.adults,
                    children: params.children || 0,
                    infants: params.infants || 0,
                },
                cabinClass: params.cabinClass?.toLowerCase().replace(' ', '_') || 'economy',
                tripType: params.tripType,
            }),
            signal: controller.signal,
        });
        clearTimeout(timer);
        if (!res.ok) {
            const err = await res.json().catch(() => ({}));
            throw new Error(err.error ?? `Search failed (HTTP ${res.status})`);
        }
        return res.json();
    } catch (err: any) {
        clearTimeout(timer);
        if (err.name === 'AbortError') throw new Error('Search timed out. Please check your connection and try again.');
        throw err;
    }
}

export async function autocompleteAirports(keyword: string): Promise<Airport[]> {
    if (!keyword || keyword.length < 2) return [];
    try {
        const { webSearchAirports } = await import('./booking-api');
        const results = await webSearchAirports(keyword);
        if (results.length > 0) return results;
        // Fallback to local list if web API is unavailable
        return searchAirports(keyword);
    } catch (err) {
        // Always fall back to local list — flights must work offline too
        try { return searchAirports(keyword); } catch { return []; }
    }
}
