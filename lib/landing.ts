/**
 * Landing page data fetchers — read from Supabase tables populated by CRON jobs.
 *
 * flight_deals      → refreshed every 6 hours via refresh-deal-prices edge function
 * weekend_flight_deals → hotel deals with ratings and sale prices
 * unique_stays      → curated unique accommodations
 * popular_destinations → destination cards with average prices
 *
 * All tables have public RLS SELECT policies — the anon key is sufficient.
 */

import { supabase } from '../utils/supabase/client';

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

/** Parse "35% OFF" → 35, returns 0 if unparseable. */
function parseDiscountPct(tag: string | null): number {
    if (!tag) return 0;
    const match = tag.match(/(\d+)/);
    return match ? parseInt(match[1], 10) : 0;
}

export async function fetchFlightDeals(): Promise<FlightDeal[]> {
    const { data, error } = await supabase
        .from('flight_deals')
        .select('*')
        .order('updated_at', { ascending: false })
        .limit(6);

    if (error) {
        console.error('[Landing] flight_deals error:', error.message);
        return [];
    }

    return (data ?? []).map((d: any) => ({
        id: String(d.id),
        origin: d.origin ?? '',
        destination: d.destination ?? '',
        price: Number(d.price ?? 0),
        originalPrice: Number(d.baseline_price ?? d.original_price ?? 0),
        currency: d.currency ?? 'USD',
        airline: d.airline ?? null,
        imageUrl: d.image_url ?? '',
        discountTag: d.discount_tag ?? '',
        discountPct: parseDiscountPct(d.discount_tag),
        endsIn: d.ends_in ?? 'Limited Time',
        departureDate: d.departure_date ?? null,
        returnDate: d.return_date ?? null,
    }));
}

export async function fetchWeekendDeals(): Promise<WeekendDeal[]> {
    const { data, error } = await supabase
        .from('weekend_flight_deals')
        .select('*')
        .limit(8);

    if (error) {
        console.error('[Landing] weekend_flight_deals error:', error.message);
        return [];
    }

    return (data ?? []).map((d: any) => ({
        id: String(d.id),
        name: d.name ?? '',
        location: d.location ?? '',
        rating: Number(d.rating ?? 0),
        reviews: Number(d.reviews ?? 0),
        originalPrice: Number(d.original_price ?? 0),
        salePrice: Number(d.sale_price ?? 0),
        imageUrl: d.image_url ?? '',
        badge: d.badge ?? null,
    }));
}

export async function fetchPopularDestinations(): Promise<PopularDestination[]> {
    const { data, error } = await supabase
        .from('popular_destinations')
        .select('*')
        .limit(8);

    if (error) {
        console.error('[Landing] popular_destinations error:', error.message);
        return [];
    }

    return (data ?? []).map((d: any) => ({
        id: String(d.id),
        city: d.city ?? '',
        country: d.country ?? '',
        imageUrl: d.image_url ?? '',
        averagePrice: Number(d.average_price ?? 0),
    }));
}

export async function fetchUniqueStays(): Promise<UniqueStay[]> {
    const { data, error } = await supabase
        .from('unique_stays')
        .select('*')
        .limit(6);

    if (error) {
        console.error('[Landing] unique_stays error:', error.message);
        return [];
    }

    return (data ?? []).map((d: any) => ({
        id: String(d.id),
        name: d.name ?? '',
        location: d.location ?? '',
        rating: Number(d.rating ?? 0),
        price: Number(d.price ?? 0),
        imageUrl: d.image_url ?? '',
        badge: d.badge ?? null,
        category: d.category ?? null,
    }));
}
