/// Offline maps for booked flights, so the tracker still draws the route with
/// no internet on board.
///
/// For each flight it downloads the map styles and a low-detail tile region
/// covering the route (zoom 0–5, a few MB) into Mapbox's tile store. Downloads
/// start when a flight is booked and again on app start for flights leaving
/// within [refreshWindow]; regions are removed once the trip is over.
library;

import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/flights/flight_status.dart';
import 'package:cheapest_go_mobile/shared/lib/map_tier.dart';
import 'package:cheapest_go_mobile/shared/stores/bookings_store.dart';
import 'package:cheapest_go_mobile/shared/stores/ui_store.dart';

enum OfflineMapState { none, downloading, ready, failed }

class OfflineMapStatus {
  const OfflineMapStatus(this.state, {this.progress = 0, this.bytes = 0});

  final OfflineMapState state;

  /// 0–1 while downloading.
  final double progress;

  /// Size on the device once ready.
  final int bytes;

  String get sizeLabel => '${math.max(1, (bytes / (1024 * 1024)).round())} MB';
}

class OfflineRouteMaps extends ChangeNotifier {
  OfflineRouteMaps({bool? enabled, this.catalog = travelCatalog}) : _enabled = enabled ?? !_isTest;

  final bool _enabled;
  final TravelCatalog catalog;

  /// Flights leaving within this window get their map (re)downloaded on start.
  static const refreshWindow = Duration(hours: 36);
  static const _maxZoom = 5;

  /// Degrees of margin around the route.
  static const _margin = 3.0;

  final Map<String, OfflineMapStatus> _status = {};
  TileStore? _tileStore;
  OfflineManager? _offlineManager;

  static bool get _isTest {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  OfflineMapStatus statusOf(String reference) => _status[reference] ?? const OfflineMapStatus(OfflineMapState.none);

  static String _regionId(String reference) => 'route-$reference';

  Future<(TileStore, OfflineManager)> _stores() async {
    final tileStore = _tileStore ??= await TileStore.createDefault();
    final offlineManager = _offlineManager ??= await OfflineManager.create();
    return (tileStore, offlineManager);
  }

  List<String> get _styles => [
        MapboxStyles.LIGHT,
        MapboxStyles.DARK,
        if (uiSettingsStore.mapTier == MapTier.standard) MapboxStyles.STANDARD,
      ];

  /// Downloads (or tops up) the offline map for [booking]'s flight.
  Future<void> download(Booking booking) async {
    final flight = booking.flight;
    if (!_enabled || flight == null || statusOf(booking.reference).state == OfflineMapState.downloading) return;
    final from = catalog.origin(flight.origin);
    final to = catalog.origin(flight.destination);
    if (from == null || to == null) return;

    _set(booking.reference, const OfflineMapStatus(OfflineMapState.downloading));
    try {
      final (tileStore, offlineManager) = await _stores();
      for (final style in _styles) {
        await offlineManager.loadStylePack(style, StylePackLoadOptions(acceptExpired: true), null);
      }
      final west = math.min(from.longitude, to.longitude) - _margin;
      final east = math.max(from.longitude, to.longitude) + _margin;
      final south = math.max(math.min(from.latitude, to.latitude) - _margin, -85.0);
      final north = math.min(math.max(from.latitude, to.latitude) + _margin, 85.0);
      final area = Polygon(coordinates: [
        [Position(west, south), Position(east, south), Position(east, north), Position(west, north), Position(west, south)],
      ]);
      final region = await tileStore.loadTileRegion(
        _regionId(booking.reference),
        TileRegionLoadOptions(
          geometry: area.toJson().cast<String?, Object?>(),
          descriptorsOptions: [
            for (final style in _styles) TilesetDescriptorOptions(styleURI: style, minZoom: 0, maxZoom: _maxZoom),
          ],
          acceptExpired: true,
          networkRestriction: NetworkRestriction.NONE,
        ),
        (p) {
          if (p.requiredResourceCount > 0) {
            _set(booking.reference, OfflineMapStatus(OfflineMapState.downloading, progress: p.completedResourceCount / p.requiredResourceCount));
          }
        },
      );
      _set(booking.reference, OfflineMapStatus(OfflineMapState.ready, bytes: region.completedResourceSize));
    } catch (e) {
      debugPrint('Offline map for ${booking.reference}: $e');
      _set(booking.reference, const OfflineMapStatus(OfflineMapState.failed));
    }
  }

  /// On app start: reads what's already on the device, downloads maps for
  /// flights leaving soon (or in the air), and removes maps of finished trips.
  Future<void> refresh(List<Booking> flights, {DateTime? nowUtc}) async {
    if (!_enabled) return;
    final now = nowUtc ?? DateTime.now().toUtc();
    try {
      final (tileStore, _) = await _stores();
      final existing = {for (final r in await tileStore.allTileRegions()) r.id: r};
      for (final b in flights) {
        final f = b.flight!;
        final id = _regionId(b.reference);
        final region = existing[id];
        if (now.isAfter(f.arrivalUtc.add(kTrackAfterLanding))) {
          if (region != null) await tileStore.removeRegion(id);
          _status.remove(b.reference);
          continue;
        }
        if (region != null && region.requiredResourceCount > 0 && region.completedResourceCount == region.requiredResourceCount) {
          _set(b.reference, OfflineMapStatus(OfflineMapState.ready, bytes: region.completedResourceSize));
        } else if (f.departureUtc.difference(now) < refreshWindow) {
          await download(b);
        }
      }
    } catch (e) {
      debugPrint('Offline maps refresh: $e');
    }
  }

  void _set(String reference, OfflineMapStatus status) {
    _status[reference] = status;
    notifyListeners();
  }
}

final OfflineRouteMaps offlineRouteMaps = OfflineRouteMaps();
