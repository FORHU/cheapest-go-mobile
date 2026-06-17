export const SITE_URL = process.env.EXPO_PUBLIC_SITE_URL ?? 'https://cheapestgo.com';
export const MAPBOX_TOKEN = process.env.EXPO_PUBLIC_MAPBOX_TOKEN!;
export const GOOGLE_PLACES_API_KEY = process.env.EXPO_PUBLIC_GOOGLE_PLACES_API_KEY!;
export const FOURSQUARE_SERVICE_API_KEY = process.env.EXPO_PUBLIC_FOURSQUARE_SERVICE_API_KEY!;

/** Base URL for the CheapestGo web backend (booking, push, version-check). */
export const WEB_API_URL = (process.env.EXPO_PUBLIC_WEB_API_URL ?? 'https://cheapestgo.com').replace(/\/$/, '');

/** Shared secret for /api/mobile/* endpoints. Rotated via admin panel. */
export const MOBILE_API_KEY = process.env.EXPO_PUBLIC_MOBILE_API_KEY ?? '';

/** Semver of this build — bump on every release. */
export const APP_VERSION = '1.0.0';

