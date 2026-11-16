import 'package:flutter/foundation.dart';

import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/flights/offline_route_maps.dart';
import 'package:cheapest_go_mobile/shared/stores/bookings_store.dart';

/// Bumped every time app data was reloaded.
///
/// A screen that fetches for itself — My Bookings asks api-v2, not a store — watches this
/// and goes again. It is a counter rather than a callback because `shared/` may not reach
/// into a feature to tell it; the feature listens instead.
final appDataRevision = ValueNotifier<int>(0);

/// Reloads what the tabs show — the catalogue (prices, stays, courses, flights), bookings and
/// their flight status, and the offline maps for flights leaving soon.
Future<void> refreshAppData() async {
  await Future.wait([travelCatalog.refresh(), bookingsStore.init()]);
  // Offline maps download in the background; nothing waits on them.
  offlineRouteMaps.refresh(bookingsStore.flights);
  appDataRevision.value++;
}

/// How long data is treated as fresh. V2's query client sets `staleTime: 60 * 1000`, and this
/// is the same number for the same reason.
const refreshStaleAfter = Duration(seconds: 60);

DateTime? _lastRefresh;

/// The clock, so a test can age the data without waiting a minute.
DateTime Function() refreshClock = DateTime.now;

/// Reloads only if what we hold has gone stale.
///
/// This is what replaced pull to refresh in #36. V2 offers no pull gesture and sets
/// `refetchOnWindowFocus: false`, so on the web a screen refreshes when you navigate to it and
/// its data is older than a minute. Mobile now does the same, rather than carrying an
/// affordance the web does not have — see **Design Parity** in CONTEXT.md.
///
/// Without this the removal of pull to refresh would have left no way to pick up a booking
/// made in another session at all, which is a worse product than either option.
Future<void> refreshAppDataIfStale() async {
  final last = _lastRefresh;
  final now = refreshClock();
  if (last != null && now.difference(last) < refreshStaleAfter) return;
  _lastRefresh = now;
  await refreshAppData();
}

/// Forgets when we last refreshed. For tests, and for sign-in and sign-out, where the data
/// belongs to a different person and its age is beside the point.
void markAppDataStale() => _lastRefresh = null;
