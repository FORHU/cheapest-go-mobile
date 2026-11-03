import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/flights/offline_route_maps.dart';
import 'package:cheapest_go_mobile/shared/stores/bookings_store.dart';

/// Pull to refresh: reloads what the tabs show — the catalogue (prices,
/// stays, courses, flights), bookings and their flight status, and the
/// offline maps for flights leaving soon.
Future<void> refreshAppData() async {
  await Future.wait([travelCatalog.refresh(), bookingsStore.init()]);
  // Offline maps download in the background; the spinner needn't wait.
  offlineRouteMaps.refresh(bookingsStore.flights);
}
