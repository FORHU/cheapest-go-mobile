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
        // Defensive parse: a 200 with an empty/HTML body (gateway hiccup) would make
        // res.json() throw a cryptic "Unexpected end of input" / "Unexpected character".
        const text = await res.text();
        if (!text.trim()) throw new Error(`${path} returned an empty response. Please try again.`);
        try {
            return JSON.parse(text) as T;
        } catch {
            throw new Error(`${path} returned an unexpected response. Please try again.`);
        }
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
        } catch {
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
    const { checkIn, checkOut, adults, children, childrenAges, rooms, currency } = options;
    const result = await webInvoke('/api/fn/travelgatex-search', {
        hotelCode: hotelId,
        checkin: checkIn,
        checkout: checkOut,
        adults: Number(adults) || 2,
        children: Number(children) || 0,
        childrenAges: childrenAges || undefined,
        rooms: Number(rooms) || 1,
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

const MOBILE_API_KEY = process.env.EXPO_PUBLIC_MOBILE_API_KEY ?? '';

/**
 * Fetches verified per-guest reviews for a hotel.
 *
 * These are real reviews sourced from ETG/Ratehawk: the web backend runs a cron
 * job that caches the supplier's review dump in its DB, and `/api/mobile/hotel-reviews`
 * serves that cache keyed by `hotelCode`. The response objects already match the shape
 * the reviews UI expects (name, date, averageScore, pros/headline, avatar/userImage),
 * so no mapping is needed here.
 *
 * Reviews are a soft dependency: the hotel page fetches them alongside hotel details in
 * a `Promise.all`, so any failure (network, auth, empty cache) must resolve to `[]` rather
 * than reject — a reviews outage should never take down the hotel page, and we never fall
 * back to fabricated entries (see CONTEXT.md: "verified review").
 */
export async function getHotelReviews(hotelId: string, limit: number = 20): Promise<any[]> {
    if (!hotelId) return [];

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), INVOKE_TIMEOUT_MS);
    try {
        const res = await fetch(`${WEB_API_BASE}/api/mobile/hotel-reviews`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                // CSRF bypass for same-site custom-header requests; see booking-api.ts.
                'X-Requested-By': 'cheapestgo-client',
                'X-Mobile-Api-Key': MOBILE_API_KEY,
            },
            credentials: 'include',
            body: JSON.stringify({ hotelCode: hotelId, limit }),
            signal: controller.signal,
        });
        clearTimeout(timer);
        if (!res.ok) return [];

        const text = await res.text();
        if (!text.trim()) return [];
        let json: any;
        try { json = JSON.parse(text); } catch { return []; }

        // Accept { data: [...] }, { reviews: [...] }, or a bare array.
        const reviews: any[] = Array.isArray(json)
            ? json
            : (json.data ?? json.reviews ?? []);
        if (!Array.isArray(reviews)) return [];
        return reviews.slice(0, limit);
    } catch {
        clearTimeout(timer);
        // Aborts, timeouts, and network errors all degrade to "no reviews".
        return [];
    }
}

// ─── Booking APIs ───

export interface PrebookParams {
    offerId: string;
    currency?: string;
    adults?: number;
    children?: number;
    roomName?: string;
}

export interface Surcharge {
    chargeType: string;
    mandatory: boolean;
    price: { net: number; gross: number; currency: string };
}

export interface PrebookResponse {
    prebookId: string;
    /** Tax-inclusive grand total (gross), in `currency`. */
    price?: number;
    /** Room net price before taxes & fees, in `currency`. */
    subtotal?: number;
    /** Taxes & fees (gross − net), in `currency`. */
    taxes?: number;
    /** Mandatory/optional surcharges the supplier itemised, in `currency`. */
    surcharges?: Surcharge[];
    currency?: string;
    cancellationPolicies?: {
        cancelPolicyInfos?: {
            cancelTime: string;
            amount: number;
            currency: string;
            type: string;
        }[];
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
    // The prebook route returns price as { subtotal, taxes, total }; older shapes may
    // send a bare number. Normalise both into the flat fields the checkout renders.
    const priceObj = d.price && typeof d.price === 'object' ? d.price : null;
    const total = priceObj?.total ?? (typeof d.price === 'number' ? d.price : undefined);
    return {
        prebookId: d.prebookId,
        price: total,
        subtotal: priceObj?.subtotal,
        taxes: priceObj?.taxes,
        surcharges: Array.isArray(d.surcharges) ? d.surcharges : [],
        currency: d.currency,
        cancellationPolicies: d.cancellationPolicies,
        roomSubstituted: d.roomSubstituted,
        substitutedRoomName: d.substitutedRoomName,
    };
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
    multiCitySegments?: { origin: string; destination: string; departureDate: string }[];
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
    } catch {
        // Always fall back to local list — flights must work offline too
        try { return searchAirports(keyword); } catch { return []; }
    }
}
