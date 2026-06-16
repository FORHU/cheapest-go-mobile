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

// Landing page fetchers are temporarily stubbed — data will be served from
// the web API once those endpoints are ready.
export async function fetchFlightDeals(): Promise<FlightDeal[]> { return []; }
export async function fetchWeekendDeals(): Promise<WeekendDeal[]> { return []; }
export async function fetchPopularDestinations(): Promise<PopularDestination[]> { return []; }
export async function fetchUniqueStays(): Promise<UniqueStay[]> { return []; }
