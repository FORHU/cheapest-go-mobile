/**
 * Helpers for hotel display names.
 *
 * Hotel records can end up with a raw supplier `hotelCode` (e.g. "1405692") stored
 * where a human name belongs — see the `property_name` note on the booking payload.
 * These helpers keep a code from ever being shown as if it were the hotel's name.
 */

/**
 * True when a value is missing or looks like a supplier hotel code rather than a name.
 * Conservative on purpose: only flags empty values, pure-digit strings, and spaceless
 * code-shaped tokens (uppercase/alphanumeric containing a digit), so real names like
 * "Hotel 7" or "B&B Roma" are never mistaken for codes.
 */
export function looksLikeHotelCode(name?: string | null): boolean {
    if (!name) return true;
    const v = name.trim();
    if (!v) return true;
    if (/^\d+$/.test(v)) return true;                       // pure digits
    if (!/\s/.test(v) && /\d/.test(v) && /^[A-Z0-9._-]+$/.test(v)) return true; // CODE123
    return false;
}

/**
 * Returns a safe display name: the property name if it reads like a real name,
 * otherwise the given fallback (never the raw code).
 */
export function displayHotelName(propertyName?: string | null, fallback = 'Hotel'): string {
    return looksLikeHotelCode(propertyName) ? fallback : (propertyName as string).trim();
}
