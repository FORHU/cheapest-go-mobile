import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:cheapest_go_mobile/features/map/components/airport_hub_sheet.dart';
import 'package:cheapest_go_mobile/features/map/components/flight_telemetry_hud.dart';
import 'package:cheapest_go_mobile/features/map/models/map_models.dart';
import 'package:cheapest_go_mobile/features/map/models/world_landmass_data.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/components/ui_kit.dart';
import 'package:cheapest_go_mobile/shared/flights/flight_status.dart';
import 'package:cheapest_go_mobile/shared/flights/offline_route_maps.dart';
import 'package:cheapest_go_mobile/shared/lib/demo.dart';
import 'package:cheapest_go_mobile/shared/stores/bookings_store.dart';
import 'package:cheapest_go_mobile/shared/stores/trip_search_store.dart';
import 'package:cheapest_go_mobile/shared/stores/ui_store.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_radius.dart';
import 'package:cheapest_go_mobile/shared/utils/format.dart';

/// Map tab: the catalogue's arrival airports on a native Mapbox map (2D, or
/// the 3D globe on capable phones), following the app's light or dark theme.
///
/// Selecting an airport zooms in on its stays and golf courses; the sheet
/// below lists them and opens a place, the airport hub, or a flight in.
/// "My flights" follows the traveler's booked flights: status before take-off,
/// the plane in the air (GPS when the phone has a fix, else the schedule), and
/// the arrival airport's stays and golf after landing.

class MapView extends StatefulWidget {
  const MapView({this.catalog = travelCatalog, super.key});

  final TravelCatalog catalog;

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with WidgetsBindingObserver {
  /// How often the tracker panel and the plane update.
  static const _tickEvery = Duration(seconds: 1);

  /// A GPS fix older than this, or vaguer than [_gpsMaxAccuracyM], falls back to the schedule.
  static const _gpsMaxAge = Duration(minutes: 1);
  static const _gpsMaxAccuracyM = 5000.0;

  static const _airportZoom = 9.0;

  // One colour per kind of pin, explained by the legend over the map.
  static const _selectedColor = Color(0xFF06B6D4);
  static const _hotelColor = Color(0xFF2563EB);
  static const _golfColor = Color(0xFF16A34A);
  static const _flightColor = Color(0xFFEA580C);

  late final List<Airport> _airports = widget.catalog.airports();

  late MapTier _tier = uiSettingsStore.mapTier;
  Airport? _selected;
  MapFilter _filter = MapFilter.overview;
  MapPlace? _place;
  bool _tracking = false;

  /// The booking the tracker shows; the first trackable flight when unset.
  String? _trackedRef;
  bool _dark = false;
  double _sheetHeight = 0;
  Size _mapSize = const Size(360, 640);

  Timer? _ticker;
  StreamSubscription<geo.Position>? _gps;
  geo.Position? _fix;
  bool _askingLocation = false;
  bool _locationDenied = false;

  /// False while another tab is showing (the tab shell turns tickers off).
  bool _tabVisible = true;

  /// False while the app is in the background.
  bool _foreground = true;

  /// The tracker only ticks, and GPS only runs, while it's on screen.
  bool get _trackerOnScreen => _tracking && _tabVisible && _foreground;

  MapboxMap? _map;
  PolylineAnnotationManager? _routes;
  CircleAnnotationManager? _dots;
  PointAnnotationManager? _labels;
  CircleAnnotationManager? _planeLayer;
  CircleAnnotation? _plane;

  /// What each annotation on the map stands for: an [Airport] or a [MapPlace].
  final Map<String, Object> _targets = {};

  /// Annotation updates run one after another so a quick second tap can't
  /// interleave with the first and leave duplicate pins.
  Future<void> _syncQueue = Future.value();

  bool get _isTestEnvironment {
    try {
      return !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  List<TrackedFlight> get _flights => trackableFlights(widget.catalog, bookingsStore.flights, flightSimulator.nowFor);

  TrackedFlight? get _flight {
    final flights = _flights;
    if (flights.isEmpty) return null;
    for (final f in flights) {
      if (f.reference == _trackedRef) return f;
    }
    return flights.first;
  }

  FlightStatus _statusOf(TrackedFlight f) => flightStatusService.statusOf(f.flight, flightSimulator.nowFor(f.reference));

  /// Where to draw the plane, and where that position comes from.
  (LatLng, PositionSource) _planeAt(TrackedFlight f, FlightStatus status) {
    final estimated = _locationDenied ? PositionSource.scheduleNoPermission : PositionSource.schedule;
    switch (status.phase) {
      case FlightPhase.scheduled:
      case FlightPhase.boarding:
        return (f.from, estimated);
      case FlightPhase.landed:
        return (f.to, estimated);
      case FlightPhase.inAir:
        final fix = _fix;
        final fresh = fix != null &&
            !flightSimulator.isRunning(f.reference) &&
            DateTime.now().difference(fix.timestamp) < _gpsMaxAge &&
            fix.accuracy < _gpsMaxAccuracyM;
        return fresh ? ((fix.latitude, fix.longitude), PositionSource.gps) : (f.positionAt(status.progress), estimated);
    }
  }

  List<MapPlace> get _places {
    final airport = _selected;
    return airport == null ? const [] : placesNear(widget.catalog, airport, MapFilter.overview);
  }

  @override
  void initState() {
    super.initState();
    _selected = widget.catalog.airport(tripSearchStore.airportCode);
    uiSettingsStore.addListener(_onSettingsChanged);
    tripSearchStore.addListener(_onSearchChanged);
    bookingsStore.addListener(_onFlightsChanged);
    flightSimulator.addListener(_onFlightsChanged);
    offlineRouteMaps.addListener(_onFlightsChanged);
    flightToTrack.addListener(_onTrackRequest);
    WidgetsBinding.instance.addObserver(this);
    // Trips may have asked for a flight before this tab was first built.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onTrackRequest());
  }

  @override
  void dispose() {
    uiSettingsStore.removeListener(_onSettingsChanged);
    tripSearchStore.removeListener(_onSearchChanged);
    bookingsStore.removeListener(_onFlightsChanged);
    flightSimulator.removeListener(_onFlightsChanged);
    offlineRouteMaps.removeListener(_onFlightsChanged);
    flightToTrack.removeListener(_onTrackRequest);
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _gps?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible != _tabVisible) {
      _tabVisible = visible;
      _syncTracker();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (foreground != _foreground) {
      _foreground = foreground;
      _syncTracker();
    }
  }

  void _onFlightsChanged() {
    if (!mounted) return;
    setState(() {});
    if (_tracking) _refresh();
  }

  /// Opens the tracker on the booking Trips asked for.
  void _onTrackRequest() {
    final reference = flightToTrack.value;
    if (!mounted || reference == null) return;
    flightToTrack.value = null;
    _trackedRef = reference;
    _setTracking(true);
  }

  void _onSettingsChanged() {
    if (mounted && _tier != uiSettingsStore.mapTier) setState(() => _tier = uiSettingsStore.mapTier);
  }

  /// Follows the arrival airport picked elsewhere (Home, the airport hub).
  void _onSearchChanged() {
    final airport = widget.catalog.airport(tripSearchStore.airportCode);
    if (mounted && airport != null && airport.code != _selected?.code && !_tracking) _selectAirport(airport);
  }

  // --- Selection -----------------------------------------------------------

  void _selectAirport(Airport airport) {
    setState(() {
      _selected = airport;
      _place = null;
    });
    tripSearchStore.setAirport(airport.code);
    _refresh();
  }

  void _stepAirport(int step) {
    final i = _airports.indexWhere((a) => a.code == _selected?.code);
    _selectAirport(_airports[(i + step) % _airports.length]);
  }

  void _selectPlace(MapPlace place) {
    setState(() {
      _place = place;
      _filter = place.isGolf ? MapFilter.golf : MapFilter.stays;
    });
    _refresh();
  }

  void _setFilter(MapFilter filter) {
    setState(() {
      _filter = filter;
      _place = null;
    });
    _refresh();
  }

  void _closeSheet() {
    setState(() {
      _selected = null;
      _place = null;
    });
    _refresh();
  }

  void _setTracking(bool on) {
    setState(() => _tracking = on);
    _syncTracker();
    _refresh();
  }

  /// Starts the tracker's clock and GPS while it's on screen; stops both when
  /// the tracker closes, another tab shows, or the app goes to the background.
  void _syncTracker() {
    if (_trackerOnScreen) {
      _ticker ??= Timer.periodic(_tickEvery, (_) => _tick());
      _maybeStartGps();
      if (mounted) setState(() {});
      _updatePlane();
    } else {
      _ticker?.cancel();
      _ticker = null;
      _gps?.cancel();
      _gps = null;
    }
  }

  void _tick() {
    if (!mounted) return;
    setState(() {});
    _maybeStartGps();
    _updatePlane();
  }

  /// Asks for location once the tracked flight is boarding or in the air.
  Future<void> _maybeStartGps() async {
    final flight = _flight;
    if (_gps != null || _askingLocation || _locationDenied || _isTestEnvironment || flight == null) return;
    final phase = _statusOf(flight).phase;
    if (phase != FlightPhase.boarding && phase != FlightPhase.inAir) return;
    _askingLocation = true;
    try {
      var permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied || permission == geo.LocationPermission.deniedForever) {
        if (mounted) setState(() => _locationDenied = true);
        return;
      }
      if (!mounted || !_trackerOnScreen) return;
      _gps = geo.Geolocator.getPositionStream(
        locationSettings: const geo.LocationSettings(accuracy: geo.LocationAccuracy.high, distanceFilter: 200),
      ).listen((p) => _fix = p, onError: (Object e) => debugPrint('GPS: $e'));
    } catch (e) {
      debugPrint('Location: $e');
    } finally {
      _askingLocation = false;
    }
  }

  void _nextFlight() {
    final flights = _flights;
    if (flights.length < 2) return;
    final i = flights.indexWhere((f) => f.reference == _flight?.reference);
    setState(() => _trackedRef = flights[(i + 1) % flights.length].reference);
    _refresh();
  }

  void _toggleSimulation(TrackedFlight flight) {
    if (flightSimulator.isRunning(flight.reference)) {
      flightSimulator.stop(flight.reference);
    } else {
      flightSimulator.start(flight.reference, flight.flight);
    }
  }

  /// Leaves the tracker for the flight's arrival airport.
  void _exploreDestination(TrackedFlight flight) {
    _setTracking(false);
    setState(() => _filter = MapFilter.overview);
    _selectAirport(flight.destination);
  }

  // --- Navigation ----------------------------------------------------------

  void _openPlace(MapPlace place) {
    final hotel = place.hotel;
    if (hotel != null) {
      context.push('/hotel/${hotel.id}');
    } else {
      tripSearchStore
        ..setAirport(place.airportCode)
        ..setMode(SearchMode.golf);
      context.push('/golf');
    }
  }

  void _bookFlight(FlightOffer offer) {
    tripSearchStore
      ..setOrigin(offer.origin)
      ..setAirport(offer.destination);
    context.push('/flight-checkout?offer=${offer.id}');
  }

  // --- Mapbox --------------------------------------------------------------

  Future<void> _onMapCreated(MapboxMap map) async {
    _map = map;
    _routes = _dots = _labels = _planeLayer = null;
    _plane = null;
    try {
      await map.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
      await map.compass.updateSettings(CompassSettings(enabled: false));
      await map.gestures.updateSettings(GesturesSettings(pitchEnabled: _tier == MapTier.standard));
      // Top left, so the sheet never covers the Mapbox logo and attribution.
      await map.logo.updateSettings(LogoSettings(position: OrnamentPosition.TOP_LEFT, marginLeft: 12, marginTop: 14));
      await map.attribution.updateSettings(
        AttributionSettings(position: OrnamentPosition.TOP_LEFT, marginLeft: 100, marginTop: 14),
      );
    } catch (e) {
      debugPrint('Mapbox setup: $e');
    }
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData _) async {
    final map = _map;
    if (map == null) return;
    try {
      if (_tier == MapTier.standard) {
        await map.style.setProjection(StyleProjection(name: StyleProjectionName.globe));
        await map.style.setStyleImportConfigProperty('basemap', 'lightPreset', _dark ? 'night' : 'day');
      } else {
        await map.style.setProjection(StyleProjection(name: StyleProjectionName.mercator));
      }
    } catch (e) {
      debugPrint('Mapbox style: $e');
    }
    try {
      _routes = await map.annotations.createPolylineAnnotationManager();
      _dots = await map.annotations.createCircleAnnotationManager();
      _labels = await map.annotations.createPointAnnotationManager();
      _planeLayer = await map.annotations.createCircleAnnotationManager();
      _dots!.tapEvents(onTap: (a) => _onTargetTap(a.id));
      _labels!.tapEvents(onTap: (a) => _onTargetTap(a.id));
    } catch (e) {
      debugPrint('Mapbox annotations: $e');
    }
    _refresh(animate: false);
  }

  void _onTargetTap(String annotationId) {
    switch (_targets[annotationId]) {
      case final Airport airport:
        if (!_tracking) _selectAirport(airport);
      case final MapPlace place:
        _selectPlace(place);
      case final FlightOffer offer:
        _bookFlight(offer);
    }
  }

  /// Redraws the pins and moves the camera to match the current selection.
  void _refresh({bool animate = true}) {
    _syncQueue = _syncQueue.then((_) => _syncAnnotations()).then((_) => _moveCamera(animate: animate)).catchError((Object e) {
      debugPrint('Map refresh: $e');
    });
  }

  Future<void> _syncAnnotations() async {
    final routes = _routes, dots = _dots, labels = _labels, planeLayer = _planeLayer;
    if (routes == null || dots == null || labels == null || planeLayer == null) return;
    final c = _dark ? AppColors.dark : AppColors.light;
    final text = c.textPrimary.toARGB32();
    final halo = c.background.toARGB32();

    await routes.deleteAll();
    await dots.deleteAll();
    await labels.deleteAll();
    await planeLayer.deleteAll();
    _plane = null;
    _targets.clear();

    // The only line on the map is the tracked flight's route.
    final selectedAirport = _selected;
    final flight = _tracking ? _flight : null;
    if (flight != null) {
      await routes.create(PolylineAnnotationOptions(
        geometry: LineString(coordinates: [for (var i = 0; i <= 24; i++) _position(interpolate(flight.from, flight.to, i / 24))]),
        lineColor: _flightColor.toARGB32(),
        lineWidth: 3,
        lineOpacity: 0.9,
      ));
    }

    // Airports, plus the tracked flight's origin when it isn't one of them.
    // Plain loops and locals here: a closure over the nullable `flight` in this
    // async method crashed the 32-bit ARM release build (SIGSEGV on the Realme C21Y).
    final originCode = flight?.origin.code;
    final destinationCode = flight?.destination.code;
    final selectedCode = _selected?.code;
    final airports = <Airport>[..._airports];
    if (flight != null) {
      var known = false;
      for (final a in _airports) {
        if (a.code == originCode) known = true;
      }
      if (!known) airports.add(flight.origin);
    }
    final labelsAbove = _labelsAbove(airports);
    final dotTargets = <Object>[];
    final dotOptions = <CircleAnnotationOptions>[];
    final labelTargets = <Object>[];
    final labelOptions = <PointAnnotationOptions>[];
    // On the Flights tab the departure cities get their own flight pin below;
    // skip the airport pin under it so pins and labels don't double up.
    final flightOrigins = <String>{};
    if (!_tracking && _selected != null && _filter == MapFilter.flights) {
      for (final offer in flightsInto(widget.catalog, _selected!)) {
        flightOrigins.add(offer.origin);
      }
    }
    for (final a in airports) {
      if (flightOrigins.contains(a.code)) continue;
      final selected = a.code == selectedCode || a.code == originCode || a.code == destinationCode;
      final at = Point(coordinates: Position(a.longitude, a.latitude));
      dotTargets.add(a);
      dotOptions.add(CircleAnnotationOptions(
        geometry: at,
        // The open airport shrinks a little so the stays and courses right at
        // the terminal (drawn above it) stay tappable.
        circleRadius: a.code == selectedCode ? 7 : (selected ? 9 : 6.5),
        circleColor: (selected ? _selectedColor : _flightColor).toARGB32(),
        circleStrokeColor: 0xFFFFFFFF,
        circleStrokeWidth: 2,
        circleSortKey: a.code == selectedCode ? 1 : 10,
      ));
      labelTargets.add(a);
      labelOptions.add(PointAnnotationOptions(
        geometry: at,
        textField: a.code,
        textSize: selected ? 13 : 11.5,
        textColor: text,
        textHaloColor: halo,
        textHaloWidth: 1.5,
        textOffset: [0, labelsAbove.contains(a.code) ? -1.5 : 1.5],
      ));
    }

    // Stays and courses: around the selected airport (narrowed by the Stays or
    // Golf tab), or around every airport when none is selected.
    final placeAirports = _tracking ? const <Airport>[] : (selectedAirport == null ? _airports : [selectedAirport]);
    final placeFilter = selectedAirport != null && (_filter == MapFilter.stays || _filter == MapFilter.golf) ? _filter : MapFilter.overview;
    for (final airport in placeAirports) {
      for (final p in placesNear(widget.catalog, airport, placeFilter)) {
        final selected = p.id == _place?.id;
        final at = Point(coordinates: _position(p.position));
        dotTargets.add(p);
        dotOptions.add(CircleAnnotationOptions(
          geometry: at,
          circleRadius: selected ? 10 : (selectedAirport == null ? 3.5 : 7.5),
          circleColor: (selected ? _selectedColor : (p.isGolf ? _golfColor : _hotelColor)).toARGB32(),
          circleStrokeColor: 0xFFFFFFFF,
          circleStrokeWidth: selectedAirport == null ? 0.8 : 1.5,
          circleSortKey: selected ? 30 : 20,
        ));
        // Only the selected place gets a price label: stays sit close together
        // and their labels would overlap. The sheet lists every price.
        if (!selected) continue;
        labelTargets.add(p);
        labelOptions.add(PointAnnotationOptions(
          geometry: at,
          // Map fonts have no ₱ glyph; every price in the app is in pesos.
          textField: formatPeso(p.price).replaceFirst('₱', ''),
          textSize: 12.5,
          textColor: text,
          textHaloColor: halo,
          textHaloWidth: 1.5,
          textOffset: const [0, -1.5],
        ));
      }
    }

    // Flights tab: a pin at each city a flight comes from; tapping it books that flight.
    if (!_tracking && selectedAirport != null && _filter == MapFilter.flights) {
      for (final offer in flightsInto(widget.catalog, selectedAirport)) {
        final origin = widget.catalog.origin(offer.origin);
        if (origin == null) continue;
        final at = Point(coordinates: Position(origin.longitude, origin.latitude));
        dotTargets.add(offer);
        dotOptions.add(CircleAnnotationOptions(
          geometry: at,
          circleRadius: 8,
          circleColor: _flightColor.toARGB32(),
          circleStrokeColor: 0xFFFFFFFF,
          circleStrokeWidth: 2,
          circleSortKey: 25,
        ));
        labelTargets.add(offer);
        labelOptions.add(PointAnnotationOptions(
          geometry: at,
          textField: '${offer.origin} ${formatPeso(offer.price).replaceFirst('₱', '')}',
          textSize: 11.5,
          textColor: text,
          textHaloColor: halo,
          textHaloWidth: 1.5,
          textOffset: const [0, -1.5],
        ));
      }
    }

    final created = await dots.createMulti(dotOptions);
    for (var i = 0; i < created.length; i++) {
      if (created[i] case final a?) _targets[a.id] = dotTargets[i];
    }
    final createdLabels = await labels.createMulti(labelOptions);
    for (var i = 0; i < createdLabels.length; i++) {
      if (createdLabels[i] case final a?) _targets[a.id] = labelTargets[i];
    }

    if (flight != null) {
      _plane = await planeLayer.create(CircleAnnotationOptions(
        geometry: Point(coordinates: _position(_planeAt(flight, _statusOf(flight)).$1)),
        circleRadius: 7,
        circleColor: 0xFFFFFFFF,
        circleStrokeColor: _selectedColor.toARGB32(),
        circleStrokeWidth: 4,
      ));
    }
  }

  void _updatePlane() {
    final plane = _plane, layer = _planeLayer, flight = _flight;
    if (plane == null || layer == null || flight == null) return;
    plane.geometry = Point(coordinates: _position(_planeAt(flight, _statusOf(flight)).$1));
    layer.update(plane).catchError((Object e) => debugPrint('Plane update: $e'));
  }

  Future<void> _moveCamera({bool animate = true}) async {
    final map = _map;
    if (map == null || !mounted) return;
    final top = MediaQuery.paddingOf(context).top + 56;
    // Room for the sheet or tracker panel, or for the airport cards when zoomed out.
    final bottom = (_tracking || _selected != null) ? _sheetHeight + 24 : 136.0;

    LatLng center;
    double zoom;
    final flight = _tracking ? _flight : null;
    if (flight != null) {
      center = flight.positionAt(0.5);
      zoom = _zoomToFitBox(flight.from, flight.to, _mapSize.width, _mapSize.height - top - bottom);
    } else if (_tracking) {
      (center, zoom) = _overview(top, bottom);
    } else if (_selected case final airport?) {
      // Selecting a place keeps the same framing (all its neighbours stay in
      // view) and only recentres on it; zooming in to street level hid them.
      final airportAt = (airport.latitude, airport.longitude);
      if (_filter == MapFilter.flights) {
        var south = airport.latitude, north = airport.latitude, west = airport.longitude, east = airport.longitude;
        for (final offer in flightsInto(widget.catalog, airport)) {
          final o = widget.catalog.origin(offer.origin);
          if (o == null) continue;
          south = math.min(south, o.latitude);
          north = math.max(north, o.latitude);
          west = math.min(west, o.longitude);
          east = math.max(east, o.longitude);
        }
        center = ((south + north) / 2, (west + east) / 2);
        zoom = _zoomToFitBox((south, west), (north, east), _mapSize.width, _mapSize.height - top - bottom);
      } else {
        final spread = placesNear(widget.catalog, airport, _filter).map((p) => distanceKm(airportAt, p.position));
        zoom = spread.isEmpty ? _airportZoom : math.min(_zoomToFit(2 * spread.reduce(math.max)), 13.0);
        center = _place?.position ?? airportAt;
      }
    } else {
      (center, zoom) = _overview(top, bottom);
    }

    final camera = CameraOptions(
      center: Point(coordinates: _position(center)),
      zoom: _tier == MapTier.standard ? zoom - 0.3 : zoom,
      pitch: 0,
      padding: MbxEdgeInsets(top: top, left: 0, bottom: bottom, right: 0),
    );
    try {
      if (animate) {
        await map.flyTo(camera, MapAnimationOptions(duration: 1000));
      } else {
        await map.setCamera(camera);
      }
    } catch (e) {
      debugPrint('Map camera: $e');
    }
  }

  /// Center and zoom that frame every arrival airport above the bottom cards.
  (LatLng, double) _overview(double top, double bottom) {
    final lats = _airports.map((a) => a.latitude);
    final lngs = _airports.map((a) => a.longitude);
    final sw = (lats.reduce(math.min), lngs.reduce(math.min));
    final ne = (lats.reduce(math.max), lngs.reduce(math.max));
    return (((sw.$1 + ne.$1) / 2, (sw.$2 + ne.$2) / 2), _zoomToFitBox(sw, ne, _mapSize.width, _mapSize.height - top - bottom));
  }

  /// A zoom that fits the box spanning [a] and [b] into [width] × [height]
  /// logical pixels, with some margin (Web Mercator, so latitude stretches;
  /// Mapbox draws the world 512 px wide at zoom 0).
  static double _zoomToFitBox(LatLng a, LatLng b, double width, double height) {
    double y(double lat) => math.log(math.tan(math.pi / 4 + lat * math.pi / 360));
    final dLng = math.max((a.$2 - b.$2).abs(), 0.5) / 360;
    final dLat = math.max((y(a.$1) - y(b.$1)).abs(), 0.01) / (2 * math.pi);
    const margin = 0.75;
    final zx = math.log(width * margin / (512 * dLng)) / math.ln2;
    final zy = math.log(math.max(height, 120) * margin / (512 * dLat)) / math.ln2;
    return math.min(zx, zy).clamp(1.0, 8.0);
  }

  /// A zoom that fits a route of [km] across most of a phone's width.
  double _zoomToFit(double km) => (math.log(40075 * 0.35 * 360 / (256 * math.max(km, 50))) / math.ln2).clamp(1.5, 8.0);

  /// Airports whose label goes above the pin: those whose nearest neighbour lies
  /// to the south, so close pairs like Clark and Manila don't cover each other.
  static Set<String> _labelsAbove(List<Airport> all) {
    final above = <String>{};
    for (final a in all) {
      Airport? nearest;
      var best = double.infinity;
      for (final o in all) {
        if (o.code == a.code) continue;
        final d = distanceKm((a.latitude, a.longitude), (o.latitude, o.longitude));
        if (d < best) {
          best = d;
          nearest = o;
        }
      }
      if (nearest != null && best < 250 && nearest.latitude < a.latitude) above.add(a.code);
    }
    return above;
  }

  static Position _position(LatLng p) => Position(p.$2, p.$1);

  // --- UI ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (dark != _dark) _dark = dark;

    return LayoutBuilder(
      builder: (context, box) {
        // Room for the place preview and its book button, now that the header sits above the map.
        _sheetHeight = _tracking ? 360 : math.min(410, box.maxHeight * 0.58);
        _mapSize = box.biggest;
        final airport = _selected;
        return ColoredBox(
          color: c.background,
          child: Stack(
            children: [
              if (!_isTestEnvironment)
                Positioned.fill(
                  child: MapWidget(
                    key: ValueKey('cheapest-go-map-${_tier.name}-${dark ? 'dark' : 'light'}'),
                    styleUri: _tier == MapTier.standard ? MapboxStyles.STANDARD : (dark ? MapboxStyles.DARK : MapboxStyles.LIGHT),
                    onMapCreated: _onMapCreated,
                    onStyleLoadedListener: _onStyleLoaded,
                  ),
                )
              else
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MapCanvasPainter(airports: _airports, selected: airport, colors: c),
                  ),
                ),
              Positioned(
                top: 8,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _ModeSwitch(tracking: _tracking, onChanged: _setTracking),
                    if (!_tracking) ...[
                      const SizedBox(height: 8),
                      const _PinLegend(),
                    ],
                  ],
                ),
              ),
              if (_tracking)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: _buildTracker(context),
                )
              else if (airport != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: _sheetHeight),
                    child: AirportHubSheet(
                      airport: airport,
                      places: _places,
                      filter: _filter,
                      selectedPlace: _place,
                      catalog: widget.catalog,
                      onFilterChanged: _setFilter,
                      onPlaceSelected: _selectPlace,
                      onClearPlace: () => _setFilter(_place!.isGolf ? MapFilter.golf : MapFilter.stays),
                      onOpenPlace: _openPlace,
                      onOpenHub: () => context.push('/airport/${airport.code}'),
                      onBookFlight: _bookFlight,
                      onNextAirport: () => _stepAirport(1),
                      onPreviousAirport: () => _stepAirport(-1),
                      onClose: _closeSheet,
                    ),
                  ),
                )
              else
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: _AirportStrip(airports: _airports, catalog: widget.catalog, onTap: _selectAirport),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTracker(BuildContext context) {
    final flights = _flights;
    final flight = _flight;
    if (flight == null) return NoFlightsCard(onFindFlights: () => context.go('/flights'));
    final status = _statusOf(flight);
    final i = flights.indexWhere((f) => f.reference == flight.reference);
    return FlightTelemetryHud(
      flight: flight,
      status: status,
      positionSource: _planeAt(flight, status).$2,
      offlineMap: offlineRouteMaps.statusOf(flight.reference),
      onDownloadMap: () => offlineRouteMaps.download(flight.booking),
      onExitTracking: () => _setTracking(false),
      onNextFlight: flights.length > 1 ? _nextFlight : null,
      flightLabel: flights.length > 1 ? '${i + 1} of ${flights.length}' : null,
      onViewDestinationHub: flight.hasHub(widget.catalog) ? () => _exploreDestination(flight) : null,
      onSimulate: kDemoTools ? () => _toggleSimulation(flight) : null,
      simulating: flightSimulator.isRunning(flight.reference),
    );
  }
}

/// Airports ↔ my flights switch, top right over the map.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.tracking, required this.onChanged});

  final bool tracking;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.glassStrong,
      shape: StadiumBorder(side: BorderSide(color: c.border)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (on, label, icon) in [(false, 'Airports', Icons.place_rounded), (true, 'My flights', Icons.flight_rounded)])
              Semantics(
                selected: tracking == on,
                button: true,
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () {
                    if (tracking != on) onChanged(on);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: tracking == on ? kBrandGradient : null,
                      borderRadius: AppRadius.brPill,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 15, color: tracking == on ? Colors.white : c.textSecondary),
                        const SizedBox(width: 5),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: tracking == on ? Colors.white : c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// What each pin colour means.
class _PinLegend extends StatelessWidget {
  const _PinLegend();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget item(Color color, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
            ),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: c.textSecondary)),
          ],
        );
    return Material(
      color: c.glassStrong,
      shape: StadiumBorder(side: BorderSide(color: c.border)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            item(_MapViewState._hotelColor, 'Hotels'),
            const SizedBox(width: 10),
            item(_MapViewState._golfColor, 'Golf'),
            const SizedBox(width: 10),
            item(_MapViewState._flightColor, 'Flights'),
          ],
        ),
      ),
    );
  }
}

/// Zoomed out: one card per arrival airport with its stays, golf and lowest
/// rate, since at this zoom their pins sit too close to tell apart.
class _AirportStrip extends StatelessWidget {
  const _AirportStrip({required this.airports, required this.catalog, required this.onTap});

  final List<Airport> airports;
  final TravelCatalog catalog;
  final ValueChanged<Airport> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: airports.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final a = airports[i];
          final hotels = catalog.hotelsNear(a.code);
          final golf = catalog.coursesNear(a.code).length;
          final from = hotels.isEmpty ? null : hotels.map((h) => h.fromRate).reduce(math.min);
          return SizedBox(
            width: 200,
            child: AppCard(
              color: c.glassStrong,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              onTap: () => onTap(a),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${a.code} · ${a.city}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('${plural(hotels.length, 'stay')} · $golf golf', style: TextStyle(fontSize: 12, color: c.textSecondary)),
                  if (from != null) ...[
                    const SizedBox(height: 4),
                    PriceText(from, suffix: '/night', size: 13),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Static stand-in for the native map in widget tests, which can't host Mapbox.
class _MapCanvasPainter extends CustomPainter {
  _MapCanvasPainter({required this.airports, required this.selected, required this.colors});

  final List<Airport> airports;
  final Airport? selected;
  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final land = Paint()..color = colors.surfaceMuted;
    for (final polygon in kWorldLandmasses) {
      final path = Path();
      for (final (i, pt) in polygon.points.indexed) {
        final o = _project(pt.$1, pt.$2, size);
        i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(path..close(), land);
    }
    for (final a in airports) {
      final o = _project(a.latitude, a.longitude, size);
      canvas.drawCircle(o, a.code == selected?.code ? 6 : 4, Paint()..color = colors.accent);
    }
  }

  Offset _project(double lat, double lng, Size size) => Offset((lng + 180) / 360 * size.width, (90 - lat) / 180 * size.height);

  @override
  bool shouldRepaint(covariant _MapCanvasPainter old) => old.selected != selected || old.colors != colors;
}
