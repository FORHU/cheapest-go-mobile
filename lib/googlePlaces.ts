/**
 * Google Places photo lookup for destination images.
 * Uses the legacy Places API (Text Search → photo_reference → photo URL).
 * Results are cached in memory for the lifetime of the app session.
 */

const API_KEY = process.env.EXPO_PUBLIC_GOOGLE_PLACES_API_KEY ?? '';

// Curated search queries per IATA code for high-quality landmark photos
const PLACE_QUERIES: Record<string, string> = {
    MNL: 'Manila Philippines skyline',
    CEB: 'Cebu City Philippines',
    CRK: 'Clark Pampanga Philippines',
    DVO: 'Davao City Philippines',
    ILO: 'Iloilo City Philippines',
    KLO: 'Boracay Philippines beach',
    PPS: 'Puerto Princesa Palawan Philippines',
    NRT: 'Tokyo Japan landmark',
    HND: 'Tokyo Japan cityscape',
    KIX: 'Osaka Japan castle',
    FUK: 'Fukuoka Japan',
    OKA: 'Okinawa Japan beach',
    CTS: 'Sapporo Japan',
    ICN: 'Seoul South Korea Gyeongbokgung',
    GMP: 'Seoul South Korea skyline',
    SIN: 'Singapore Marina Bay Sands',
    BKK: 'Bangkok Thailand temple',
    KUL: 'Kuala Lumpur Malaysia skyline',
    HKG: 'Hong Kong Victoria Harbour skyline',
    TPE: 'Taipei 101 Taiwan',
    DXB: 'Dubai Burj Khalifa skyline',
    AUH: 'Abu Dhabi UAE',
    DOH: 'Doha Qatar skyline',
    SYD: 'Sydney Opera House Australia',
    MEL: 'Melbourne Australia',
    LHR: 'London Big Ben UK',
    CDG: 'Paris Eiffel Tower France',
    FRA: 'Frankfurt Germany skyline',
    AMS: 'Amsterdam Netherlands canal',
    JFK: 'New York City Times Square',
    LAX: 'Los Angeles California',
    SFO: 'San Francisco Golden Gate Bridge',
    YYZ: 'Toronto Canada skyline',
    PEK: 'Beijing Forbidden City China',
    PVG: 'Shanghai China skyline',
    CGK: 'Jakarta Indonesia',
    SGN: 'Ho Chi Minh City Vietnam',
    HAN: 'Hanoi Vietnam',
    DEL: 'New Delhi India',
    BOM: 'Mumbai India',
    NAN: 'Fiji island beach',
    GUM: 'Guam beach',
    FCO: 'Rome Colosseum Italy',
    BCN: 'Barcelona Sagrada Familia Spain',
    IST: 'Istanbul Hagia Sophia Turkey',
};

const cache = new Map<string, string>();

function buildQuery(iata: string, city?: string, country?: string): string {
    return PLACE_QUERIES[iata.toUpperCase()]
        ?? `${city ?? iata} ${country ?? ''} landmark tourism`.trim();
}

/**
 * Returns a Google Places photo URL for the given destination.
 * The URL redirects to the actual photo on Google's CDN — expo-image follows it automatically.
 * Falls back to null if the API call fails or returns no photos.
 */
export async function getDestinationPhoto(
    iata: string,
    city?: string,
    country?: string,
): Promise<string | null> {
    if (!API_KEY) return null;

    const key = iata.toUpperCase();
    const cached = cache.get(key);
    if (cached !== undefined) return cached || null;

    const query = buildQuery(key, city, country);

    try {
        const searchUrl =
            `https://maps.googleapis.com/maps/api/place/textsearch/json` +
            `?query=${encodeURIComponent(query)}&key=${API_KEY}`;

        const res = await fetch(searchUrl);
        if (!res.ok) {
            cache.set(key, '');
            return null;
        }

        const data: any = await res.json();
        const photoRef: string | undefined =
            data.results?.[0]?.photos?.[0]?.photo_reference;

        if (!photoRef) {
            cache.set(key, '');
            return null;
        }

        const photoUrl =
            `https://maps.googleapis.com/maps/api/place/photo` +
            `?maxwidth=800&photoreference=${encodeURIComponent(photoRef)}&key=${API_KEY}`;

        cache.set(key, photoUrl);
        return photoUrl;
    } catch {
        cache.set(key, '');
        return null;
    }
}

/** True when a URL is missing, a placeholder, a flag, or any SVG symbol. */
export function isPlaceholderUrl(url: string | null | undefined): boolean {
    if (!url || url.trim() === '') return true;
    const u = url.toLowerCase();
    return (
        u.includes('picsum.photos') ||
        u.includes('placeholder') ||
        u.includes('via.placeholder') ||
        u.includes('lorempixel') ||
        u.includes('flag') ||
        u.includes('coat_of_arms') ||
        u.includes('emblem') ||
        u.includes('seal_of') ||
        u.includes('national_symbol') ||
        u.endsWith('.svg') ||
        u.includes('.svg?') ||
        u.includes('.svg/')
    );
}
