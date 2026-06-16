# CheapestGo Mobile App

React Native mobile app for CheapestGo — a travel deals platform for finding cheap flights and hotels. Built with Expo SDK 56, Expo Router, and NativeWind.

## Tech Stack

- **Framework:** Expo SDK 56 (New Architecture enabled)
- **Navigation:** Expo Router v4 (file-based)
- **Styling:** NativeWind v4 (Tailwind CSS for React Native)
- **Auth:** Supabase Auth
- **Payments:** Stripe React Native
- **Maps:** Mapbox
- **Notifications:** Expo Notifications

## Prerequisites

- Node.js 18+
- npm
- [Expo CLI](https://docs.expo.dev/get-started/installation/) (`npm install -g expo-cli`)
- [Expo Go](https://expo.dev/go) app on your device, **or** Android Studio / Xcode for native builds
- Access to the team's environment variables (`.env` file)

## Setup

### 1. Clone and install

```bash
git clone https://github.com/FORHU/cheapest-go-mobile
cd cheapest-go-mobile
npm install
```

### 2. Environment variables

Create a `.env` file in the project root with the following keys:

```env
# Supabase (auth only — data is served from the web API)
EXPO_PUBLIC_SUPABASE_URL=
EXPO_PUBLIC_SUPABASE_ANON_KEY=

# Mapbox
EXPO_PUBLIC_MAPBOX_TOKEN=

# Google Places
EXPO_PUBLIC_GOOGLE_PLACES_API_KEY=

# Foursquare
EXPO_PUBLIC_FOURSQUARE_SERVICE_API_KEY=

# Duffel (flights)
EXPO_PUBLIC_DUFFEL_API_KEY=

# Web backend
EXPO_PUBLIC_WEB_API_URL=https://cheapestgo.com
EXPO_PUBLIC_MOBILE_API_KEY=

# Stripe
EXPO_PUBLIC_STRIPE_PUBLISHABLE_KEY=

# ETG / RateHawk (hotels)
ETG_KEY_ID=
ETG_API_KEY=

# TravelgateX
TRAVELGATEX_API_KEY=
TRAVELGATEX_CODE=
TRAVELGATEX_SUPPLIER=
TRAVELGATEX_CONTEXT=
TRAVELGATEX_CLIENT=
TRAVELGATEX_ENDPOINT_URL=

# Local Postgres (server-side only, not used directly in mobile)
DATABASE_URL=
```

Get the values from a team member or the shared secrets store.

### 3. Start the dev server

```bash
npx expo start --clear
```

The `--clear` flag resets the Metro cache. Use it whenever you change `metro.config.js` or add polyfills.

Scan the QR code with Expo Go, or press `a` for Android emulator / `i` for iOS simulator.

## App Structure

```
app/
  _layout.tsx           # Root layout (auth gate, theme)
  (auth)/               # Login, register, forgot/reset password
  (tabs)/               # Main tab navigator
    index.tsx           # Home / landing
    search.tsx          # Flight & hotel search
    trips.tsx           # Booked trips
    saved.tsx           # Saved deals
    explore.tsx         # Explore destinations
    profile.tsx         # User profile
  flights.tsx           # Flight results
  flight-checkout.tsx   # Flight booking flow
  hotel/[id].tsx        # Hotel detail
  checkout.tsx          # Hotel checkout

components/             # Reusable UI components
lib/                    # Data fetchers and utilities
utils/supabase/         # Supabase auth client
polyfills/              # React Native compatibility patches
```

## Known Issues & Patches

### Event phase constants (RN 0.76+)

React Native 0.76+ defines `Event.prototype.NONE` and related phase constants as non-writable via `Object.defineProperty`. Hermes compiles class field declarations to simple assignments (`this.NONE = undefined`) which throw in strict mode when hitting a non-writable prototype property.

**Fix:** `polyfills/EventPatch.js` intercepts `Object.defineProperty` before the base polyfills run and replaces non-writable data descriptors for these constants with getter/setter pairs (no-op setter). This is loaded first in `metro.config.js` via `getPolyfills`.

### Supabase DB quota

Landing page data (`flight_deals`, `unique_stays`, etc.) was previously fetched directly from Supabase. It has been stubbed out in `lib/landing.ts` pending migration to the web API. Supabase is still used for **authentication only**.

## Building for Production

```bash
# Android
npx expo run:android --variant release

# iOS
npx expo run:ios --configuration Release

# EAS Build (recommended)
eas build --platform android
eas build --platform ios
```

## Environment Notes

- `EXPO_PUBLIC_*` variables are bundled into the client — do not put secrets there.
- Server-side keys (`ETG_API_KEY`, `TRAVELGATEX_API_KEY`, `DATABASE_URL`, etc.) are used by the web backend, not the mobile app directly.
- The mobile app talks to `EXPO_PUBLIC_WEB_API_URL` using `EXPO_PUBLIC_MOBILE_API_KEY` for authenticated backend calls.
