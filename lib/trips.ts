// Session is cookie-based — the native HTTP client sends the session cookie automatically.

const BASE = process.env.EXPO_PUBLIC_WEB_API_URL ?? 'https://cheapestgo.com';

export interface FlightSegment {
    id: string;
    airline: string;
    flight_number: string;
    origin: string;
    destination: string;
    departure: string;
    arrival: string;
    itinerary_index: number;
}

export interface FlightPassenger {
    id: string;
    first_name: string;
    last_name: string;
    type: string;
    ticket_number: string | null;
    seat_number: string | null;
}

export interface FlightBooking {
    id: string;
    pnr: string;
    provider: string;
    status: string;
    trip_type: string | null;
    total_price: number;
    charged_price: number | null;
    currency: string | null;
    created_at: string;
    flight_segments: FlightSegment[];
    passengers: FlightPassenger[];
}

export type BookingStatus =
    | 'booked' | 'pnr_created' | 'awaiting_ticket' | 'ticketed'
    | 'failed' | 'cancel_requested' | 'cancelled' | 'cancel_failed'
    | 'refund_pending' | 'refund_failed' | 'refunded' | 'cancelled_provider_missing';

export async function fetchMyFlightBookings(): Promise<FlightBooking[]> {
    try {
        const res = await fetch(`${BASE}/api/mobile/trips`, {
            credentials: 'include',
        });
        if (!res.ok) return [];
        const json = await res.json();
        return json.data ?? [];
    } catch (e: any) {
        console.error('[trips] fetchMyFlightBookings error:', e.message);
        return [];
    }
}
