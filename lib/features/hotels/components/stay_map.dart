import 'dart:async' show unawaited;
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb show Position;

import 'package:cheapest_go_mobile/features/hotels/components/stay_pin_painter.dart';
import 'package:cheapest_go_mobile/features/hotels/components/stay_pins.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/utils/currency.dart';
import 'package:cheapest_go_mobile/shared/utils/money.dart';

/// The search results as a map, as V2 draws them. See #39.
///
/// The markers are the map's own annotations, painted to images by [StayPinPainter] and handed
/// to Mapbox against a coordinate. The map then moves them: a pan carries the pins with the
/// streets, frame for frame, because nothing in Dart is deciding where they go.
///
/// What this replaced: the same pins as Flutter widgets positioned over the map from
/// `pixelsForCoordinates`. Every camera change had to ask the map where each coordinate had
/// landed and then lay the pins out again — two hops and a frame behind — so during a drag the
/// pins visibly slid across the map and settled afterwards.
///
/// Which stays are drawn as one is still decided here, and only when the camera stops: pins
/// that would overlap are collected into a cluster, so zooming parts them with no zoom-level
/// thresholds to keep in step.
class StayMap extends StatefulWidget {
    const StayMap({
        required this.hotels,
        required this.currency,
        required this.onSelect,
        this.selectedId,
        super.key,
    });

    final List<Hotel> hotels;
    final String currency;

    /// A pin was pressed: one stay, or the cheapest of a cluster.
    final ValueChanged<Hotel> onSelect;
    final String? selectedId;

    @override
    State<StayMap> createState() => _StayMapState();
}

/// How close two pins may come before they are drawn as one, in logical pixels. V2's
/// `CLUSTER_RADIUS`, which its own note calls a marker-count dial rather than a distance.
const double _clusterRadius = 80;

/// V2's `CLUSTER_MAX_ZOOM`: past this, every stay stands on its own however close they are.
const double _clusterMaxZoom = 16;

/// Mapbox's tiles are 512 wide, so this is the ground resolution at the equator for zoom 0.
const double _metresPerPixelAtZoom0 = 78271.516;

class _StayMapState extends State<StayMap> {
    MapboxMap? _map;
    PointAnnotationManager? _pins;

    /// Which group each annotation stands for, so a tap can name the stay.
    final _byAnnotation = <String, _Marker>{};

    /// Drawn for the headless case only; on a device the map holds the markers.
    List<_Marker> _flat = const [];
    Size _size = Size.zero;
    bool _drawing = false;

    /// Another draw was asked for while one was running, so run once more when it ends. The
    /// last word has to be the current state: a skipped draw used to leave the map holding
    /// the pins of the one before it, or none at all if it had already cleared them.
    bool _again = false;

    /// What the pins on the map stand for. A rebuild hands this widget a freshly built list
    /// every time, so identity says nothing; this says whether anything actually changed.
    String? _drawn;

    /// Painted pins, by what is drawn on them. However far a map of eight stays is zoomed it
    /// shows a dozen distinct pills at most, so this stays small and saves every repaint.
    final _pinCache = <String, Uint8List>{};

    /// Tests have no Mapbox: no token, no platform view, no camera to ask. The pins are still
    /// drawn, on a plain ground, from a straight projection of the bounds — so a test sees
    /// this screen's own layout rather than a stand-in for it.
    bool get _headless {
        try {
            return !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
        } catch (_) {
            return false;
        }
    }

    List<Hotel> get _placed =>
        widget.hotels.where((h) => h.latitude != null && h.longitude != null).toList();

    @override
    void initState() {
        super.initState();
        // The headless stand-in has no map to tell it when to draw, so it is told once here
        // and then only when the stays change. Scheduling it from build instead looped: the
        // draw set state, the state rebuilt, and the rebuild scheduled another draw.
        if (_headless) WidgetsBinding.instance.addPostFrameCallback((_) => _redraw());
    }

    @override
    void didUpdateWidget(StayMap old) {
        super.didUpdateWidget(old);
        _redraw();
    }

    @override
    void dispose() {
        _pins?.deleteAll();
        super.dispose();
    }

    Future<void> _onMapCreated(MapboxMap map) async {
        _map = map;
        await map.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
        await map.compass.updateSettings(CompassSettings(enabled: false));
        _pins = await map.annotations.createPointAnnotationManager();
        _pins!.tapEvents(onTap: (annotation) {
            final marker = _byAnnotation[annotation.id];
            if (marker != null) _onMarkerTap(marker);
        });
        await _frameHotels();
        await _redraw();
    }

    /// Metres to a logical pixel at a given zoom and latitude. Mapbox's tiles are 512 wide,
    /// which is where the constant comes from.
    static double _metresPerPixel(num zoom, double latitude) =>
        _metresPerPixelAtZoom0 * math.cos(latitude * math.pi / 180).abs() / math.pow(2, zoom);

    /// A pin was pressed.
    ///
    /// One stay selects it. A cluster opens: the camera eases to the zoom at which that group
    /// comes apart, and what was one pin becomes several — tap those and it happens again
    /// until single stays are left. V2 does this with supercluster's
    /// `getClusterExpansionZoom`; the arithmetic below is the same question asked directly,
    /// because the grouping here is distance in pixels rather than a tile index.
    ///
    /// Stays that share one coordinate are the exception, and V2 names it: zooming can never
    /// separate them, so the cheapest is selected instead of easing in forever.
    Future<void> _onMarkerTap(_Marker marker) async {
        final map = _map;
        if (marker.hotels.length == 1 || map == null) {
            widget.onSelect(marker.hotels.first);
            return;
        }

        final apart = _closestPairMetres(marker.hotels);
        if (apart <= 0) {
            // Every stay in this pin is at the same point. Already sorted cheapest first.
            widget.onSelect(marker.hotels.first);
            return;
        }

        // The zoom at which that closest pair is further apart than the clustering radius,
        // plus a step — the point where this pin is no longer one pin.
        final zoom = (math.log(_clusterRadius * _metresPerPixelAtZoom0 *
                    math.cos(marker.latitude * math.pi / 180).abs() /
                    apart) /
                math.ln2) +
            1;

        await map.flyTo(
            CameraOptions(
                center: Point(coordinates: mb.Position(marker.longitude, marker.latitude)),
                zoom: zoom.clamp(2, _clusterMaxZoom + 1),
            ),
            MapAnimationOptions(duration: 500),
        );

        // Redrawn here rather than left to the idle listener. Waiting for idle meant the
        // cluster sat whole for the length of the flight and a beat beyond it, so a tap felt
        // like it had not landed; this has the new pins ready as the camera settles.
        await _redraw();
    }

    /// How far apart the two closest stays in a group are, in metres. Zero when they coincide.
    static double _closestPairMetres(List<Hotel> hotels) {
        var closest = double.infinity;
        for (var i = 0; i < hotels.length; i++) {
            for (var j = i + 1; j < hotels.length; j++) {
                final apart = _metresBetween(hotels[i], hotels[j]);
                if (apart < closest) closest = apart;
            }
        }
        return closest.isFinite ? closest : 0;
    }

    /// Opens on the stays, not on wherever the camera happens to start.
    Future<void> _frameHotels() async {
        final placed = _placed;
        final map = _map;
        if (map == null || placed.isEmpty) return;

        final lats = placed.map((h) => h.latitude!).toList()..sort();
        final lngs = placed.map((h) => h.longitude!).toList()..sort();
        final span = math.max(lats.last - lats.first, lngs.last - lngs.first);

        await map.setCamera(CameraOptions(
            center: Point(coordinates: mb.Position(
                (lngs.first + lngs.last) / 2,
                (lats.first + lats.last) / 2,
            )),
            // One stay has no span to fit, so it gets a street-level zoom rather than infinity.
            zoom: span <= 0 ? 13 : (math.log(360 / span) / math.ln2).clamp(2, 15),
        ));
    }

    /// Regroups and repaints the markers. Called when the camera settles, not while it moves:
    /// the annotations already track the map, so the only thing a camera change alters is
    /// which stays are close enough to be drawn as one.
    Future<void> _redraw() async {
        final map = _map;
        final pins = _pins;
        final placed = _placed;

        if (_headless || map == null || pins == null) {
            final next = _clusterFlat(placed);
            if (mounted && next.length != _flat.length) setState(() => _flat = next);
            return;
        }
        // One pass at a time: the camera can settle again while the images are still being
        // painted, and two passes would both delete and both create. The second is
        // remembered rather than dropped.
        if (_drawing) {
            _again = true;
            return;
        }
        _drawing = true;

        // Everything this needs from the element tree, taken before the first await: the
        // camera, the images and the annotations are all asynchronous, and a BuildContext is
        // not something to hold across them.
        final t = AppLocalizations.of(context)!;
        final painter = StayPinPainter(
            background: _pinBackground(context),
            foreground: _pinForeground(context),
            ratio: MediaQuery.devicePixelRatioOf(context),
        );
        final brightness = Theme.of(context).brightness.name;

        // The pin is painted at the device's pixel scale and Mapbox draws an annotation's
        // bitmap one image pixel to one device pixel, so it is already the right size on
        // screen. Dividing by the ratio again drew them at half.
        const iconSize = 1.0;

        try {
            final camera = await map.getCameraState();
            final markers = _cluster(
                placed,
                // Past the max zoom nothing is clustered, as V2 has it: at that scale two
                // pins a few metres apart are two buildings, and drawing them as one hides
                // the choice between them.
                radiusMetres: camera.zoom >= _clusterMaxZoom
                    ? 0
                    : _metresPerPixel(camera.zoom, camera.center.coordinates.lat.toDouble()) *
                        _clusterRadius,
            );

            // Nothing to do if the map is already showing exactly this. Without the check, a
            // rebuild — the rail scrolling a card into view sends a stream of them — cleared
            // the pins and painted them again for no reason, which shows as a flicker and, if
            // another draw lands in the gap, as a map with no pins at all.
            final signature = [
                widget.currency,
                widget.selectedId ?? '',
                brightness,
                for (final marker in markers) marker.hotels.map((h) => h.id).join('+'),
            ].join('|');
            if (signature == _drawn) return;

            final options = <PointAnnotationOptions>[];
            for (final marker in markers) {
                final badge = marker.hotels.length > 1 ? '${marker.hotels.length}' : '';
                final lines = _linesFor(marker, t);
                final chosen = marker.hotels.any((h) => h.id == widget.selectedId);

                // Painted once per distinct pin. Expanding a cluster redraws the same pills at
                // every step — a price does not change because the camera moved — and encoding
                // each one again is what made a tap take a visible moment to answer.
                final key = '$badge|${lines.join('~')}|$chosen|$brightness';
                final drawn = _pinCache[key] ??= (await painter.paint(
                    badge: badge,
                    lines: lines,
                    selected: chosen,
                )).bytes;
                options.add(PointAnnotationOptions(
                    geometry: Point(coordinates: mb.Position(marker.longitude, marker.latitude)),
                    image: drawn,
                    // The pin stands on its coordinate rather than over it.
                    iconAnchor: IconAnchor.BOTTOM,
                    iconSize: iconSize,
                    // The chosen pin draws over its neighbours.
                    symbolSortKey: marker.hotels.any((h) => h.id == widget.selectedId) ? 2 : 1,
                ));
            }

            if (!mounted) return;
            await pins.deleteAll();
            _byAnnotation.clear();
            final created = await pins.createMulti(options);
            for (var i = 0; i < created.length && i < markers.length; i++) {
                final annotation = created[i];
                if (annotation != null) _byAnnotation[annotation.id] = markers[i];
            }
            _drawn = signature;
        } finally {
            _drawing = false;
            if (_again) {
                _again = false;
                unawaited(_redraw());
            }
        }
    }

    /// What a pin says: a cluster names how many and the cheapest of them, a single stay just
    /// its price. A cluster with no price yet says it is still checking, rather than naming a
    /// count that cannot be booked.
    List<String> _linesFor(_Marker marker, AppLocalizations t) {
        final cheapest = marker.hotels.first;
        final shown = exchangeRates.convertForDisplay(
            cheapest.fromRate,
            cheapest.currency,
            widget.currency,
        );
        final price = formatMoney(shown.amount, shown.currency);

        if (marker.hotels.length == 1) return [price];
        return [t.search_v2_clusterHotels(marker.hotels.length), t.search_v2_clusterFrom(price)];
    }

    /// Stays within [radiusMetres] of one another become one marker, cheapest first.
    List<_Marker> _cluster(List<Hotel> placed, {required double radiusMetres}) => [
        for (final group in groupNearbyStays(placed, radiusMetres: radiusMetres))
            _Marker(
                // The cluster sits on the stays it stands for, not on whichever came first.
                latitude: group.map((h) => h.latitude!).reduce((a, b) => a + b) / group.length,
                longitude: group.map((h) => h.longitude!).reduce((a, b) => a + b) / group.length,
                hotels: group,
            ),
    ];

    /// Flat-earth enough at the distances a cluster cares about, and far cheaper than a
    /// great-circle for a list this size.
    static double _metresBetween(Hotel a, Hotel b) => metresBetweenStays(a, b);

    /// The headless grouping: no camera, so the stays are spread over the box as they lie and
    /// grouped at a fixed distance.
    List<_Marker> _clusterFlat(List<Hotel> placed) =>
        placed.isEmpty ? const [] : _cluster(placed, radiusMetres: 400);

    Color _pinBackground(BuildContext context) =>
        Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : const Color(0xFFFFFFFF);

    Color _pinForeground(BuildContext context) =>
        Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFF8FAFC)
            : const Color(0xFF0F172A);

    @override
    Widget build(BuildContext context) {
        final dark = Theme.of(context).brightness == Brightness.dark;

        return LayoutBuilder(
            builder: (context, box) {
                _size = box.biggest;

                if (_headless) return _HeadlessMap(markers: _flat, size: _size, dark: dark, map: this);

                return MapWidget(
                    key: ValueKey('stay-map-${dark ? 'dark' : 'light'}'),
                    styleUri: dark ? MapboxStyles.DARK : MapboxStyles.LIGHT,
                    onMapCreated: _onMapCreated,
                    // Only when it stops. The pins hold their place on the map while it moves,
                    // so there is nothing to recompute until the grouping could have changed.
                    onMapIdleListener: (_) => _redraw(),
                );
            },
        );
    }
}

/// The map's stand-in under `flutter test`: the same pins, laid out over a plain ground.
class _HeadlessMap extends StatelessWidget {
    const _HeadlessMap({required this.markers, required this.size, required this.dark, required this.map});

    final List<_Marker> markers;
    final Size size;
    final bool dark;
    final _StayMapState map;

    @override
    Widget build(BuildContext context) {
        final lats = markers.map((m) => m.latitude);
        final lngs = markers.map((m) => m.longitude);
        final minLat = lats.isEmpty ? 0.0 : lats.reduce(math.min);
        final maxLat = lats.isEmpty ? 0.0 : lats.reduce(math.max);
        final minLng = lngs.isEmpty ? 0.0 : lngs.reduce(math.min);
        final maxLng = lngs.isEmpty ? 0.0 : lngs.reduce(math.max);

        double place(double v, double min, double max, double extent) =>
            max == min ? extent / 2 : 60 + (v - min) / (max - min) * (extent - 160);

        return Stack(
            children: [
                Positioned.fill(
                    child: ColoredBox(color: dark ? const Color(0xFF0B1222) : const Color(0xFFE8EDF2)),
                ),
                for (final marker in markers)
                    Positioned(
                        left: place(marker.longitude, minLng, maxLng, size.width),
                        top: size.height - place(marker.latitude, minLat, maxLat, size.height),
                        child: FractionalTranslation(
                            translation: const Offset(-0.5, -1),
                            child: GestureDetector(
                                onTap: () => map.widget.onSelect(marker.hotels.first),
                                child: _HeadlessPin(marker: marker, map: map),
                            ),
                        ),
                    ),
            ],
        );
    }
}

class _HeadlessPin extends StatelessWidget {
    const _HeadlessPin({required this.marker, required this.map});

    final _Marker marker;
    final _StayMapState map;

    @override
    Widget build(BuildContext context) {
        final lines = map._linesFor(marker, AppLocalizations.of(context)!);
        final active = marker.hotels.any((h) => h.id == map.widget.selectedId);

        return marker.hotels.length > 1
            ? ClusterPin(count: marker.hotels.length, priceLabel: lines.last, active: active)
            : HotelPin(name: marker.hotels.first.name, priceLabel: lines.first, active: active);
    }
}

class _Marker {
    const _Marker({required this.latitude, required this.longitude, required this.hotels});

    final double latitude;
    final double longitude;

    /// One stay, or several drawn as one. Cheapest first.
    final List<Hotel> hotels;
}

/// Stays grouped so that none is drawn on top of another, and every stay is in exactly one
/// group. Public because the counts it produces are what a traveller reads off the map.
///
/// Greedy and seeded in list order, which is enough for a few hundred stays and keeps the
/// grouping stable between redraws at one zoom. Zooming changes [radiusMetres], so a group
/// that held two stays at one zoom holds one at the next — and its neighbours part at the same
/// time, which is why expanding a pin marked "2" can leave four pins in view. They are not
/// that pin's four; they are its two and its neighbour's two, no longer overlapping.
List<List<Hotel>> groupNearbyStays(List<Hotel> stays, {required double radiusMetres}) {
    final taken = List.filled(stays.length, false);
    final groups = <List<Hotel>>[];

    for (var i = 0; i < stays.length; i++) {
        if (taken[i]) continue;
        taken[i] = true;
        final group = <Hotel>[stays[i]];

        for (var j = i + 1; j < stays.length; j++) {
            if (taken[j]) continue;
            if (metresBetweenStays(stays[i], stays[j]) > radiusMetres) continue;
            taken[j] = true;
            group.add(stays[j]);
        }

        group.sort((a, b) => a.fromRate.compareTo(b.fromRate));
        groups.add(group);
    }

    return groups;
}

/// Metres between two stays, flat-earth — accurate enough at the distances a cluster cares
/// about and far cheaper than a great-circle for a list this size.
double metresBetweenStays(Hotel a, Hotel b) {
    const metresPerDegree = 111320.0;
    final dLat = (a.latitude! - b.latitude!) * metresPerDegree;
    final dLng = (a.longitude! - b.longitude!) *
        metresPerDegree *
        math.cos((a.latitude! + b.latitude!) / 2 * math.pi / 180);
    return math.sqrt(dLat * dLat + dLng * dLng);
}
