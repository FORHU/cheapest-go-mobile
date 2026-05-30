/**
 * Fetches the signed-in user's flight bookings from Supabase,
 * including segments and passengers (with seat_number if assigned).
 */

import { supabase } from '../utils/supabase/client';

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
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return [];

    const { data, error } = await supabase
        .from('flight_bookings')
        .select(`
            id, pnr, provider, status, trip_type,
            total_price, charged_price, currency, created_at,
            flight_segments (
                id, airline, flight_number,
                origin, destination, departure, arrival, itinerary_index
            ),
            passengers (
                id, first_name, last_name, type, ticket_number, seat_number
            )
        `)
        .eq('user_id', user.id)
        .order('created_at', { ascending: false });

    if (error) {
        console.error('[trips] fetchMyFlightBookings error:', error.message);
        return [];
    }

    return (data ?? []) as FlightBooking[];
}
