# The Map tab is unreachable but kept

**Status:** accepted · 2026-11-10

Mobile's bottom bar now matches V2's exactly — Home, Trips, Settings — and V2 has no map. The
globe button that reached `lib/features/map` is gone. The feature stays: the 3D globe, the
airport hub and the in-air telemetry HUD all work, and hiding them is a consistency choice we
may want back.

**Corrected on implementation (#36).** This ADR first said nothing links to the map any more.
That was wrong, and the code proved it: `features/trips` offers *Track* on a flight and
`features/airports` opens the hub's map, and both still go to `/map`. What went is the globe —
the one entry point that existed purely to be a tab. The map is harder to reach, not
unreachable, and `/map` still routes.

The airport hub never lost its entry point at all: Home links to it directly.

## Considered Options

Keeping the globe as a fourth icon was rejected because it breaks the parity the bar exists to
demonstrate. Deleting the feature was rejected because it buys nothing: `shared/flights/offline_route_maps.dart`
imports `mapbox_maps_flutter` for flight route maps, so the SDK, the `sk.` download token, the
NDK requirement and the build weight all stay whether or not the Map tab does. Dropping it
would have cost the globe and the HUD and saved no dependency.

## Consequences

Dormant code rots, so the dormancy is managed rather than silent: `test/features/map/map_feature_test.dart`
and `test/shared/map_tier_test.dart` stay in CI. If a change elsewhere breaks the map, the build
says so — which is the only thing that keeps this reversible rather than merely undeleted.

A reader who finds a feature with no tab should not delete it on the assumption it is dead.
That assumption is exactly what this ADR exists to prevent.

One thing this did strand, which the map did not: **flight search**. Its only remaining link is
the "no flights" card inside the map. V2 reaches flight search from its landing page, and
mobile's landing gains that in #38 — until then `/flights` is effectively off the map in both
senses. Do not ship #36 to anyone without #38 or a temporary entry point on Home.
