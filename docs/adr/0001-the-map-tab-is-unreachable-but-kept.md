# The Map tab is unreachable but kept

**Status:** accepted · 2026-11-10

Mobile's bottom bar now matches V2's exactly — Home, Trips, Settings — and V2 has no map.
The globe button that reached `lib/features/map` is gone, so roughly 2,732 lines across
`features/map` and `features/airports` are in the tree with nothing linking to them. They stay
anyway: the 3D globe, the airport hub and the in-air telemetry HUD all work, and the decision
to hide them is a consistency choice we may want back.

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

A reader who finds an unreachable feature should not delete it on the assumption it is dead.
That assumption is exactly what this ADR exists to prevent.
