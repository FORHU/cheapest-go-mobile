/**
 * HTTP client for cheapestgo.com web API routes.
 *
 * Replaces direct Supabase edge function calls for the flight booking flow.
 * Non-booking routes (bags, seat-map, offer-refresh) need no auth.
 * Booking routes (book, confirm) use X-Mobile-Api-Key.
 */

import { FlightOffer } from './flight-types';

import { supabase } from '../utils/supabase/client';

const BASE = process.env.EXPO_PUBLIC_WEB_API_URL ?? 'https://cheapestgo.com';
const MOBILE_KEY = process.env.EXPO_PUBLIC_MOBILE_API_KEY ?? '';
const TIMEOUT_MS = 30_000;

// ─── Core fetch helper ────────────────────────────────────────────────────────

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
            // Include the user's Supabase session token so the web endpoint
            // can identify the real user instead of using a guest UUID.
            const { data } = await supabase.auth.getSession();
            if (data.session?.access_token) {
                headers['X-Supabase-Token'] = data.session.access_token;
            }
        }

        const res = await fetch(`${BASE}${path}`, {
            method: 'POST',
            headers,
            body: JSON.stringify(body),
            signal: opts?.signal ?? controller.signal,
        });

        clearTimeout(timer);
        const data = await res.json();

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
    contact: { email: string; phone: string; countryCode: string };
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
