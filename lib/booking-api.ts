/**
 * HTTP client for cheapestgo.com web API routes.
 *
 * Replaces direct Supabase edge function calls for the flight booking flow.
 * Non-booking routes (bags, seat-map, offer-refresh) need no auth.
 * Booking routes (book, confirm) use X-Mobile-Api-Key.
 */

import { FlightOffer } from './flight-types';

const BASE = process.env.EXPO_PUBLIC_WEB_API_URL ?? 'https://cheapestgo.com';
const MOBILE_KEY = process.env.EXPO_PUBLIC_MOBILE_API_KEY ?? '';
const TIMEOUT_MS = 30_000;

// ─── Core fetch helper ────────────────────────────────────────────────────────

/**
 * Reads a response body as JSON, defensively.
 *
 * The booking endpoints can occasionally return a non-JSON body — an HTML error
 * page (gateway 502/504, body starts with "<") or an empty body (a function killed
 * mid-flight). A raw `res.json()` surfaces those as cryptic "Unexpected character: <"
 * / "Unexpected end of input" parse errors. Instead, read the text first and map a
 * non-JSON/empty body to a clear, status-aware error so callers see what happened.
 */
async function readJsonResponse(res: Response): Promise<any> {
    const text = await res.text();
    if (!text.trim()) {
        const err: any = new Error(
            res.ok
                ? 'The server returned an empty response. Please try again.'
                : `Server error (HTTP ${res.status}). Please try again in a moment.`,
        );
        err.status = res.status;
        throw err;
    }
    try {
        return JSON.parse(text);
    } catch {
        const err: any = new Error(
            res.ok
                ? 'The server returned an unexpected response. Please try again.'
                : `Server error (HTTP ${res.status}). Please try again in a moment.`,
        );
        err.status = res.status;
        throw err;
    }
}

async function post<T = any>(
    path: string,
    body: unknown,
    opts?: { auth?: boolean; signal?: AbortSignal }
): Promise<T> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);

    try {
        // 'cheapestgo-client' bypasses the web app's CSRF origin check for
        // same-site custom-header requests; see src/lib/server/csrf.ts.
        const headers: Record<string, string> = {
            'Content-Type': 'application/json',
            'X-Requested-By': 'cheapestgo-client',
        };
        if (opts?.auth) {
            headers['X-Mobile-Api-Key'] = MOBILE_KEY;
            // Session cookie is sent automatically by the native HTTP client.
        }

        const res = await fetch(`${BASE}${path}`, {
            method: 'POST',
            headers,
            credentials: 'include',
            body: JSON.stringify(body),
            signal: opts?.signal ?? controller.signal,
        });

        clearTimeout(timer);
        const data = await readJsonResponse(res);

        // Surface server error messages
        if (!res.ok || data.success === false) {
            const msg = data.error ?? `HTTP ${res.status}`;
            const err: any = new Error(msg);
            err.status = res.status;
            err.code = data.code;
            err.priceChanged = data.priceChanged;
            err.newPrice = data.newPrice;
            throw err;
        }

        return data as T;
    } catch (err: any) {
        clearTimeout(timer);
        if (err.name === 'AbortError') throw new Error('Request timed out. Please check your connection and try again.');
        throw err;
    }
}

// ─── Flight Search ────────────────────────────────────────────────────────────

export interface WebSearchParams {
    segments: Array<{ origin: string; destination: string; departureDate: string }>;
    passengers: { adults: number; children: number; infants: number };
    cabinClass: string;
    tripType: string;
}

export interface WebSearchResult {
    success: boolean;
    data: {
        offers: FlightOffer[];
        totalResults: number;
        allCount: number;
        searchTimestamp: string;
    };
}

export async function webSearchFlights(params: WebSearchParams): Promise<WebSearchResult> {
    return post('/api/flights/search', params);
}

// ─── Bags ─────────────────────────────────────────────────────────────────────

export interface NormalizedBagOption {
    serviceId: string;
    bagType: 'checked' | 'carry_on';
    price: number;
    currency: string;
    weightKg: number | null;
    maxQuantity: number;
    passengerIndex: number;
    appliesToAllSegments: boolean;
}

export async function webFetchBags(
    offerId: string,
    duffelPassengerIds: string[]
): Promise<{ success: boolean; bagOptions: NormalizedBagOption[] }> {
    return post('/api/flights/bags', { offerId, duffelPassengerIds });
}

// ─── Seat Map ─────────────────────────────────────────────────────────────────

export interface NormalizedSeat {
    designator: string;
    elementType: 'seat' | 'empty';
    type: 'window' | 'aisle' | 'middle' | 'unknown';
    status: 'available' | 'occupied' | 'restricted';
    price: number | null;
    currency: string;
    serviceId: string | null;
    extraLegroom: boolean;
    isExit: boolean;
}

export interface SeatRow {
    rowNumber: number;
    sections: NormalizedSeat[][];
}

export interface NormalizedSegmentSeatMap {
    segmentIndex: number;
    segmentId: string;
    origin: string;
    destination: string;
    cabinClass: string;
    rows: SeatRow[];
    columnHeaders: string[][];
}

export async function webFetchSeatMap(
    offerId: string,
    segments: Array<{ origin: string; destination: string }>
): Promise<{ success: boolean; seatMaps: NormalizedSegmentSeatMap[]; unavailable?: boolean }> {
    return post('/api/flights/seat-map', { offerId, segments });
}

// ─── Offer Refresh ────────────────────────────────────────────────────────────

export async function webRefreshOffer(
    rawOffer: unknown
): Promise<{ success: boolean; newOfferId: string; newOffer: FlightOffer }> {
    return post('/api/flights/offer-refresh', { rawOffer });
}

// ─── Airport Autocomplete ─────────────────────────────────────────────────────

export interface Airport {
    iata: string;
    name: string;
    city: string;
    country: string;
    countryCode: string;
}

export async function webSearchAirports(query: string): Promise<Airport[]> {
    const BASE = process.env.EXPO_PUBLIC_WEB_API_URL ?? 'https://cheapestgo.com';
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 5_000);
    try {
        const res = await fetch(
            `${BASE}/api/airports/search?q=${encodeURIComponent(query)}&limit=8`,
            { signal: controller.signal }
        );
        clearTimeout(timer);
        if (!res.ok) return [];
        const json = await res.json();
        return json.data ?? [];
    } catch {
        clearTimeout(timer);
        return [];
    }
}

// ─── Hotel Destination Autocomplete (Mapbox — same source as web) ─────────────
// Calls Mapbox geocoding directly using the same token and parameters as the
// web app's /api/autocomplete → fetchCitiesFromMapbox() in src/lib/server/search.ts.

export interface WebDestination {
    type: 'city' | 'country';
    title: string;
    subtitle: string;
    countryCode: string;
    id?: string;   // Mapbox feature ID — pass as placeId to hotel search
    code?: string; // TravelgateX destination code (not set from Mapbox results)
}

export async function webAutocompleteDestinations(query: string): Promise<WebDestination[]> {
    const token = process.env.EXPO_PUBLIC_MAPBOX_TOKEN;
    if (!token) return [];

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 5_000);

    try {
        const url = `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodeURIComponent(query)}.json?types=place,locality,region&limit=6&access_token=${token}`;
        const res = await fetch(url, { signal: controller.signal });
        clearTimeout(timer);
        if (!res.ok) return [];

        const data = await res.json();
        return (data.features ?? []).map((feature: any) => {
            const cityName: string = feature.text ?? '';
            const placeName: string = feature.place_name ?? '';
            const countryCtx = (feature.context ?? []).find((c: any) => c.id?.startsWith('country.'));
            const countryCode: string = (countryCtx?.short_code ?? '').toUpperCase().slice(0, 2);

            return {
                type: 'city' as const,
                title: cityName,
                subtitle: placeName,
                countryCode,
                id: feature.id ?? undefined,
            };
        });
    } catch {
        clearTimeout(timer);
        return [];
    }
}

// ─── Mobile Book ─────────────────────────────────────────────────────────────

export interface MobileBookParams {
    provider: string;
    flight: FlightOffer;
    passengers: Array<{
        type: string;
        firstName: string;
        lastName: string;
        gender: string;
        birthDate: string;
    }>;
    contact: { email: string; phone: string; countryCode: string; addressLine: string; city: string; postalCode: string; country: string };
    idempotencyKey: string;
    seatServiceIds?: string[];
    seatTotal?: number;
    bagServiceIds?: string[];
    bagTotal?: number;
    confirmedPrice?: number;
}

export interface MobileBookResult {
    success: boolean;
    clientSecret: string;
    sessionId: string;
}

export async function webMobileBook(params: MobileBookParams): Promise<MobileBookResult> {
    return post('/api/mobile/flights/book', params, { auth: true });
}

// ─── Mobile Confirm ───────────────────────────────────────────────────────────

export interface MobileConfirmResult {
    success: boolean;
    bookingId: string;
    pnr: string;
    status: string;
    ticketStatus?: string;
}

export async function webMobileConfirm(
    paymentIntentId: string,
    sessionId: string
): Promise<MobileConfirmResult> {
    return post('/api/mobile/flights/confirm', { paymentIntentId, sessionId }, { auth: true });
}

// ─── Hotel Payment ────────────────────────────────────────────────────────────

export interface CreateHotelPaymentParams {
    prebookId: string;
    amount: number;
    currency: string;
    holderEmail: string;
    propertyName?: string;
    roomName?: string;
    checkIn?: string;
    checkOut?: string;
}

export interface CreateHotelPaymentResult {
    success: boolean;
    data: { clientSecret: string; paymentIntentId: string };
}

/** Creates a Stripe PaymentIntent for a hotel booking. Returns the client secret. */
export async function createHotelPayment(
    params: CreateHotelPaymentParams
): Promise<CreateHotelPaymentResult> {
    return post('/api/booking/create-payment', params, { auth: true });
}

export interface ConfirmHotelBookingParams {
    prebookId: string;
    paymentIntentId: string;
    holder: { firstName: string; lastName: string; email: string };
    guests: Array<{ occupancyNumber: number; firstName: string; lastName: string; email: string; remarks?: string }>;
    payment: { method: string; transactionId?: string };
    propertyName?: string;
    propertyImage?: string;
    roomName?: string;
    checkIn?: string;
    checkOut?: string;
    adults?: number;
    children?: number;
    currency?: string;
    specialRequests?: string;
}

export interface ConfirmHotelBookingResult {
    success: boolean;
    data?: { bookingId: string; status: string; totalPrice?: number; currency?: string };
    error?: string;
}

/** Confirms a hotel booking after Stripe payment. Saves to DB and sends confirmation email. */
export async function confirmHotelBooking(
    params: ConfirmHotelBookingParams
): Promise<ConfirmHotelBookingResult> {
    return post('/api/booking/confirm', params, { auth: true });
}
