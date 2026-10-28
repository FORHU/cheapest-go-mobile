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

export type HotelBookingStatus =
    | 'pending' | 'confirmed' | 'completed'
    | 'cancelled' | 'cancelled_refunded' | 'cancelled_refund_failed';

export interface HotelBooking {
    id: string;
    booking_id: string;
    user_id: string;
    property_name: string;      // may be a raw hotelCode — use displayHotelName() to render
    property_image?: string;
    room_name: string;
    check_in: string;           // ISO date
    check_out: string;
    guests_adults: number;
    guests_children: number;
    total_price: number;
    currency: string;
    holder_first_name: string;
    holder_last_name: string;
    holder_email: string;
    status: HotelBookingStatus;
    special_requests?: string;
    created_at: string;
    updated_at: string;
    hotel_code?: string;
    cancellation_policy?: any;
}

function isHotelRecord(x: any): boolean {
    return !!x && (x.type === 'hotel' || x.property_name !== undefined || x.room_name !== undefined || x.check_in !== undefined);
}
function isFlightRecord(x: any): boolean {
    return !!x && (x.type === 'flight' || x.flight_segments !== undefined || x.pnr !== undefined);
}

/**
 * Loads the signed-in user's trips. `/api/mobile/trips` returns flights and hotels
 * together; the envelope may be a discriminated array or a `{ flights, hotels }` split,
 * so we handle both. Always resolves (never throws) so the Trips screen can render.
 */
export async function fetchMyTrips(): Promise<{ flights: FlightBooking[]; hotels: HotelBooking[] }> {
    try {
        const res = await fetch(`${BASE}/api/mobile/trips`, {
            credentials: 'include',
        });
        if (!res.ok) return { flights: [], hotels: [] };
        const json = await res.json();
        const data = json.data ?? json ?? {};
        if (Array.isArray(data)) {
            return {
                flights: data.filter(isFlightRecord),
                hotels: data.filter(isHotelRecord),
            };
        }
        return {
            flights: data.flights ?? [],
            hotels: data.hotels ?? [],
        };
    } catch (e: any) {
        console.error('[trips] fetchMyTrips error:', e.message);
        return { flights: [], hotels: [] };
    }
}

export async function fetchMyFlightBookings(): Promise<FlightBooking[]> {
    return (await fetchMyTrips()).flights;
}
