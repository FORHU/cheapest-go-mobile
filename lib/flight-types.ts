/**
 * Flight types for the mobile app.
 * Mirrors the web app's src/types/flights.ts
 */

export type CabinClass = 'economy' | 'premium_economy' | 'business' | 'first';

export interface FlightPrice {
    total: number;
    base: number;
    taxes: number;
    currency: string;
    pricePerAdult: number;
}

export interface FlightSegmentDetail {
    segmentIndex: number;
    airline: {
        code: string;
        name: string;
    };
    origin: string;
    destination: string;
    flightNumber: string;
    departure: {
        airport: string;
        terminal?: string;
        time: string;
    };
    arrival: {
        airport: string;
        terminal?: string;
        time: string;
    };
    duration: number;
    stops: number;
    aircraft?: string;
    cabinClass: CabinClass;
    bookingClass?: string;
    fareBasis?: string;
}

export interface FarePolicy {
    isRefundable: boolean;
    isChangeable: boolean;
    refundPenaltyAmount?: number | null;
    refundPenaltyCurrency?: string | null;
    changePenaltyAmount?: number | null;
    changePenaltyCurrency?: string | null;
    policyVersion: 'search' | 'revalidated';
    policySource: 'duffel' | 'mystifly_v2';
}

export interface FlightOffer {
    offerId: string;
    provider: string;
    price: FlightPrice;
    segments: FlightSegmentDetail[];
    totalDuration: number;
    totalStops: number;
    refundable: boolean;
    farePolicy?: FarePolicy;
    baggage?: {
        checkedBags: number;
        weightPerBag?: number;
        cabinBag?: string;
    };
    seatsRemaining?: number;
    brandedFare?: {
        brandName?: string;
        brandId?: string;
        brandTier?: number;
        fareType?: string;
    };
    validatingAirline?: string;
    lastTicketDate?: string;
    tripType?: 'one-way' | 'round-trip' | 'multi-city';
    normalizedPriceUsd: number;
    bestScore: number;
    physicalFlightId: string;
    resultIndex?: string;
    traceId?: string;
    alternatives?: FlightOffer[];
    _rawOffer?: any;
}

export interface FilterState {
    sortBy: 'price' | 'duration' | 'departure';
    selectedAirlines: string[];
    maxStops: number | null;
    refundableOnly: boolean;
    selectedProviders: string[];
}

export const AIRLINES: Record<string, string> = {
    'KE': 'Korean Air', 'OZ': 'Asiana Airlines', '7C': 'Jeju Air', 'TW': 'T\'way Air',
    'LJ': 'Jin Air', 'ZE': 'Eastar Jet', 'BX': 'Air Busan', 'RS': 'Air Seoul',
    'PR': 'Philippine Airlines', '5J': 'Cebu Pacific', 'Z2': 'AirAsia Philippines',
    'JL': 'Japan Airlines', 'NH': 'ANA', 'MM': 'Peach Aviation', 'JW': 'Vanilla Air',
    'SQ': 'Singapore Airlines', 'TR': 'Scoot', 'MH': 'Malaysia Airlines', 'AK': 'AirAsia',
    'TG': 'Thai Airways', 'FD': 'Thai AirAsia', 'VN': 'Vietnam Airlines', 'VJ': 'VietJet',
    'GA': 'Garuda Indonesia', 'QZ': 'AirAsia Indonesia', 'QR': 'Qatar Airways',
    'CX': 'Cathay Pacific', 'HX': 'Hong Kong Airlines',
    'CA': 'Air China', 'MU': 'China Eastern', 'CZ': 'China Southern', 'HU': 'Hainan Airlines',
    'CI': 'China Airlines', 'BR': 'EVA Air',
    'EK': 'Emirates', 'EY': 'Etihad Airways', 'WY': 'Oman Air',
    'SV': 'Saudia', 'GF': 'Gulf Air', 'KU': 'Kuwait Airways',
    'AI': 'Air India', '6E': 'IndiGo', 'UL': 'SriLankan Airlines',
    'QF': 'Qantas', 'JQ': 'Jetstar', 'NZ': 'Air New Zealand', 'FJ': 'Fiji Airways',
    'AA': 'American Airlines', 'DL': 'Delta Air Lines', 'UA': 'United Airlines',
    'WN': 'Southwest Airlines', 'B6': 'JetBlue', 'AS': 'Alaska Airlines',
    'NK': 'Spirit Airlines', 'F9': 'Frontier Airlines', 'HA': 'Hawaiian Airlines',
    'AC': 'Air Canada', 'WS': 'WestJet',
    'LA': 'LATAM Airlines', 'AV': 'Avianca', 'CM': 'Copa Airlines', 'AM': 'Aeromexico',
    'BA': 'British Airways', 'LH': 'Lufthansa', 'AF': 'Air France', 'KL': 'KLM',
    'IB': 'Iberia', 'AZ': 'ITA Airways', 'LX': 'SWISS', 'OS': 'Austrian Airlines',
    'SK': 'SAS', 'AY': 'Finnair', 'TP': 'TAP Portugal', 'TK': 'Turkish Airlines',
    'LO': 'LOT Polish', 'SN': 'Brussels Airlines', 'EI': 'Aer Lingus',
    'FR': 'Ryanair', 'U2': 'easyJet', 'W6': 'Wizz Air', 'VY': 'Vueling',
    'ET': 'Ethiopian Airlines', 'SA': 'South African Airways', 'KQ': 'Kenya Airways',
    'AT': 'Royal Air Maroc', 'MS': 'EgyptAir',
};

export function getAirlineName(code: string): string {
    return AIRLINES[code] || code;
}

// ─── Formatting helpers ──────────────────────────────────────────────

export function formatTime(iso: string | undefined): string {
    if (!iso) return '--:--';
    const d = new Date(iso);
    if (isNaN(d.getTime())) return '--:--';
    return d.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false });
}

export function formatDuration(minutes: number): string {
    const h = Math.floor(minutes / 60);
    const m = minutes % 60;
    return h > 0 ? `${h}h ${m}m` : `${m}m`;
}

export function stopsLabel(stops: number): string {
    if (stops === 0) return 'Nonstop';
    if (stops === 1) return '1 stop';
    return `${stops} stops`;
}

export function providerLabel(provider: string): string {
    if (provider === 'mystifly_v2' || provider === 'mystifly') return 'Mystifly';
    if (provider === 'duffel') return 'Duffel';
    return provider;
}

/**
 * Normalizes a raw flight result from the edge function into a proper FlightOffer.
 * Mirrors the web app's normalizedToFlightOffer from flight-utils.ts
 */
export function normalizeFlightOffer(nf: any, tripType?: FlightOffer['tripType']): FlightOffer {
    let rawSegments = nf.segments;

    // Resilience: If segments are missing but we have basic flight info, create a synthetic segment
    if ((!rawSegments || rawSegments.length === 0) && nf.departure_time && nf.arrival_time) {
        rawSegments = [{
            airline: nf.airline,
            origin: nf.origin || '',
            destination: nf.destination || '',
            flightNumber: nf.flightNumber || '',
            departureTime: nf.departure_time,
            arrivalTime: nf.arrival_time,
            duration: nf.duration || 0,
            cabinClass: nf.cabinClass || 'economy'
        }];
    }

    const segments: FlightSegmentDetail[] = (rawSegments ?? []).map((seg: any, idx: number) => ({
        segmentIndex: seg.segmentIndex ?? idx,
        airline: {
            code: (() => {
                const raw = typeof seg.airline === 'object' ? seg.airline?.code : seg.airline;
                const fallback = /^[A-Z0-9]{2,3}$/.test(nf.airline ?? '') ? nf.airline : '';
                return (raw && raw.length <= 3 ? raw : null) ?? fallback ?? '';
            })(),
            name: (typeof seg.airline === 'object' ? seg.airline.name : (seg.airlineName || getAirlineName(seg.airline ?? '') || nf.airline || '')),
        },
        origin: seg.origin ?? nf.origin ?? '',
        destination: seg.destination ?? nf.destination ?? '',
        flightNumber: seg.flightNumber ?? nf.flightNumber ?? '',
        departure: {
            airport: seg.departure?.airport ?? seg.origin ?? nf.origin ?? '',
            terminal: seg.departure?.terminal ?? seg.terminal,
            time: seg.departure?.time ?? seg.departureTime ?? nf.departure_time ?? '',
        },
        arrival: {
            airport: seg.arrival?.airport ?? seg.destination ?? nf.destination ?? '',
            terminal: seg.arrival?.terminal ?? seg.arrivalTerminal,
            time: seg.arrival?.time ?? seg.arrivalTime ?? nf.arrival_time ?? '',
        },
        duration: seg.duration ?? nf.duration ?? 0,
        stops: seg.stops ?? 0,
        aircraft: seg.aircraft,
        cabinClass: (seg.cabinClass ?? nf.cabinClass ?? 'economy') as CabinClass,
    }));

    return {
        offerId: nf.offerId ?? nf.id ?? nf.offer_id ?? '',
        provider: nf.provider ?? '',
        price: nf.price && typeof nf.price === 'object' ? {
            total: nf.price.total ?? 0,
            base: nf.price.base ?? 0,
            taxes: nf.price.taxes ?? 0,
            currency: nf.price.currency ?? 'USD',
            pricePerAdult: nf.price.pricePerAdult ?? nf.price.total ?? 0,
        } : {
            total: nf.price ?? 0,
            base: nf.baseFare ?? nf.base ?? 0,
            taxes: nf.taxes ?? 0,
            currency: nf.currency ?? 'USD',
            pricePerAdult: nf.pricePerAdult ?? nf.price ?? 0,
        },
        segments,
        totalDuration: nf.totalDuration ?? nf.durationMinutes ?? nf.duration ?? 0,
        totalStops: nf.totalStops ?? nf.stops ?? 0,
        refundable: nf.refundable ?? false,
        farePolicy: nf.farePolicy,
        baggage: nf.baggage ?? (nf.checkedBags != null ? {
            checkedBags: nf.checkedBags,
            weightPerBag: nf.weightPerBag,
            cabinBag: nf.cabinBag,
        } : undefined),
        seatsRemaining: nf.seatsRemaining ?? nf.remaining_seats,
        brandedFare: nf.brandedFare,
        validatingAirline: nf.validatingAirline,
        lastTicketDate: nf.lastTicketDate,
        tripType: nf.tripType ?? tripType ?? 'one-way',
        normalizedPriceUsd: nf.normalizedPriceUsd ?? 0,
        bestScore: nf.bestScore ?? 0,
        physicalFlightId: nf.physicalFlightId ?? nf.offerId ?? nf.id ?? '',
        resultIndex: nf.resultIndex,
        traceId: nf.traceId,
        alternatives: nf.alternatives,
        ...(nf.provider === 'duffel' ? {
            _rawOffer: nf._rawOffer || nf.raw || nf.rawOffer,
        } : {}),
    };
}
