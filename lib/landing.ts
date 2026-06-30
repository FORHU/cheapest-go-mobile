/**
 * Landing page data fetchers.
 *
 * Mobile has no direct Supabase access — like every other data path in the app
 * (see lib/travel-api.ts), landing data is proxied through the web backend.
 * The web exposes GET /api/mobile/landing, which returns the same payload its
 * own landing page renders (via the shared getLandingData() flow).
 *
 * We fetch that payload once, cache it briefly in-memory, and each exported
 * fetcher maps its slice into the mobile-facing type the section components use.
 */

import { WEB_API_URL } from './config';

export type FlightDeal = {
    id: string;
    origin: string;
    destination: string;
    price: number;
    originalPrice: number;
    currency: string;
    airline: string | null;
    imageUrl: string;
    discountTag: string;
    discountPct: number;
    endsIn: string;
    departureDate: string | null;
    returnDate: string | null;
};

export type WeekendDeal = {
    id: string;
    name: string;
    location: string;
    rating: number;
    reviews: number;
    originalPrice: number;
    salePrice: number;
    imageUrl: string;
    badge: string | null;
};

export type PopularDestination = {
    id: string;
    city: string;
    country: string;
    imageUrl: string;
    averagePrice: number;
};

export type UniqueStay = {
    id: string;
    name: string;
    location: string;
    rating: number;
    price: number;
    imageUrl: string;
    badge: string | null;
    category: string | null;
};

// ─── Shared fetch + cache ────────────────────────────────────────────────────

type LandingPayload = {
    flightDeals: any[];
    weekendDeals: any[];
    popularDestinations: any[];
    uniqueStays: any[];
    travelStyles: any[];
};

const EMPTY_PAYLOAD: LandingPayload = {
    flightDeals: [],
    weekendDeals: [],
    popularDestinations: [],
    uniqueStays: [],
    travelStyles: [],
};

const CACHE_TTL_MS = 5 * 60 * 1000; // landing data refreshes server-side every few hours
const FETCH_TIMEOUT_MS = 15_000;

let cache: { data: LandingPayload; expiry: number } | null = null;
let inFlight: Promise<LandingPayload> | null = null;

async function getLandingData(): Promise<LandingPayload> {
    if (cache && Date.now() < cache.expiry) return cache.data;
    if (inFlight) return inFlight;

    inFlight = (async () => {
        const controller = new AbortController();
        const timer = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);
        try {
            const res = await fetch(`${WEB_API_URL}/api/mobile/landing`, {
                headers: { 'Content-Type': 'application/json' },
                signal: controller.signal,
            });
            clearTimeout(timer);
            if (!res.ok) throw new Error(`landing failed (HTTP ${res.status})`);
            const json = (await res.json()) as Partial<LandingPayload>;
            const data: LandingPayload = {
                flightDeals: json.flightDeals ?? [],
                weekendDeals: json.weekendDeals ?? [],
                popularDestinations: json.popularDestinations ?? [],
                uniqueStays: json.uniqueStays ?? [],
                travelStyles: json.travelStyles ?? [],
            };
            cache = { data, expiry: Date.now() + CACHE_TTL_MS };
            return data;
        } catch (err) {
            clearTimeout(timer);
            if (__DEV__) console.warn('[landing] fetch failed:', (err as Error)?.message ?? err);
            // Serve stale cache when available; otherwise an empty payload so the
            // sections fall back to their loading/empty states instead of throwing.
            return cache?.data ?? EMPTY_PAYLOAD;
        } finally {
            inFlight = null;
        }
    })();

    return inFlight;
}

/** Force the next fetch to bypass the in-memory cache (e.g. pull-to-refresh). */
export function invalidateLandingCache() {
    cache = null;
}

// ─── Per-section mappers ─────────────────────────────────────────────────────

export async function fetchFlightDeals(): Promise<FlightDeal[]> {
    const { flightDeals } = await getLandingData();
    return flightDeals.map((d: any) => {
        const originalPrice = Number(d.originalPrice || 0);
        const salePrice = Number(d.salePrice || 0);
        return {
            id: String(d.id),
            origin: d.origin ?? '',
            destination: d.destination ?? '',
            price: salePrice,
            originalPrice,
            currency: d.currency || 'USD',
            airline: d.subtitle ?? null,
            imageUrl: d.image ?? '',
            discountTag: d.discount ?? '',
            discountPct: originalPrice > 0 ? Math.round((1 - salePrice / originalPrice) * 100) : 0,
            endsIn: d.endsIn ?? '',
            departureDate: d.departure_date ?? null,
            returnDate: d.return_date ?? null,
        };
    });
}

export async function fetchWeekendDeals(): Promise<WeekendDeal[]> {
    const { weekendDeals } = await getLandingData();
    return weekendDeals.map((d: any) => ({
        id: String(d.id),
        name: d.name ?? '',
        location: d.location ?? '',
        rating: Number(d.rating || 0),
        reviews: Number(d.reviews || 0),
        originalPrice: Number(d.originalPrice || 0),
        salePrice: Number(d.salePrice || 0),
        imageUrl: d.image ?? '',
        badge: d.badge ?? null,
    }));
}

export async function fetchPopularDestinations(): Promise<PopularDestination[]> {
    const { popularDestinations } = await getLandingData();
    return popularDestinations.map((d: any) => ({
        id: String(d.id),
        city: d.name ?? '',
        country: d.location ?? '',
        imageUrl: d.image ?? '',
        averagePrice: Number(d.salePrice || 0),
    }));
}

export async function fetchUniqueStays(): Promise<UniqueStay[]> {
    const { uniqueStays } = await getLandingData();
    return uniqueStays.map((d: any) => ({
        id: String(d.id),
        name: d.name ?? '',
        location: d.location ?? '',
        rating: Number(d.rating || 0),
        price: Number(d.price || 0),
        imageUrl: d.image ?? '',
        badge: d.badge ?? null,
        category: d.category ?? null,
    }));
}
