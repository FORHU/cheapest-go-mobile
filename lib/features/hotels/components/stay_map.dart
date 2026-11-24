import 'dart:async' show unawaited;
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb show Position;

import 'package:cheapest_go_mobile/features/hotels/components/stay_card_painter.dart';
import 'package:cheapest_go_mobile/features/hotels/components/stay_map_card.dart';
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
        required this.onOpen,
        this.selectedId,
        this.card,
        this.onMapTap,
        this.topInset = 0,
        super.key,
    });

    final List<Hotel> hotels;
    final String currency;

    /// A pin was pressed: one stay, or the cheapest of a cluster.
    final ValueChanged<Hotel> onSelect;

    /// The **Stay Card** was pressed, or the pin of the stay already showing. Open the stay.
    final ValueChanged<Hotel> onOpen;

    final String? selectedId;

    /// The card's own state — its gallery, and the photograph ready to be painted. The map
    /// draws the card itself (ADR-0008), so it needs the thing to draw, not a widget.
    final StayCardModel? card;

    /// The map was pressed, away from any pin and away from the card. The selected stay is
    /// dismissed on this, as is the card's own close control; a second press on the stay's own
    /// pin opens the property instead of closing the card (client decision, 2026-11-23).
    final VoidCallback? onMapTap;

    /// How much of the map's top edge is covered by the screen's search bar. The camera eases
    /// a newly selected card clear of it, since a **Map-Locked** card cannot be nudged out of
    /// the way afterwards without the drift that being map-locked exists to remove.
    final double topInset;

    @override
    State<StayMap> createState() => _StayMapState();
}

/// How close two pins may come before they are drawn as one, in logical pixels. V2's
/// `CLUSTER_RADIUS`, which its own note calls a marker-count dial rather than a distance.
const double _clusterRadius = 80;

/// V2's `CLUSTER_MAX_ZOOM`: past this, every stay stands on its own however close they are.
const double _clusterMaxZoom = 16;

/// Where the stand-in map puts one coordinate along one axis.
///
/// A plain linear fit of the bounds into the box with a 60px inset, which is enough for a
/// test to tell one pin from another and to find the card over the right one. Top level so
/// the stand-in map and the anchor it reports are provably the same projection.
double _headlessPlace(double v, double min, double max, double extent) =>
    max == min ? extent / 2 : 60 + (v - min) / (max - min) * (extent - 160);

/// Mapbox's tiles are 512 wide, so this is the ground resolution at the equator for zoom 0.
const double _metresPerPixelAtZoom0 = 78271.516;

class _StayMapState extends State<StayMap> {
    MapboxMap? _map;
    PointAnnotationManager? _pins;

    /// The **Stay Card**, as the map's own annotation. Its own manager so that replacing the
    /// card as the gallery advances never disturbs the pins.
    PointAnnotationManager? _cards;
    PointAnnotation? _card;

    /// Which group each annotation stands for, so a tap can name the stay.
    final _byAnnotation = <String, _Marker>{};

    /// The markers as last drawn, with where each one was painted, so a press can be answered
    /// without asking the map anything.
    List<({_Marker marker, Size size})> _hit = const [];

    /// The camera as the map last reported it. Every press is answered against this: the card
    /// and the pins are projected from it, which is the same arithmetic that put them there.
    CameraState? _camera;

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
    final _pinCache = <String, ({Uint8List bytes, Size size})>{};

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
        widget.card?.addListener(_repaintCard);
    }

    @override
    void didUpdateWidget(StayMap old) {
        super.didUpdateWidget(old);
        _redraw();

        // Frame again when the stays themselves change.
        //
        // `_onMapCreated` frames once, and the map is routinely created before the search has
        // answered — so it framed an empty list, returned, and left the camera wherever Mapbox
        // opened. A Manila search was shown over New York: the markers were in the right place,
        // the camera was not. Against a fast local API the stays usually arrived first and the
        // race was invisible, which is why this only showed against dev.
        //
        // Keyed on which stays are placed, not on every rebuild: selecting a pin or redrawing
        // must not yank the camera back from wherever the traveller has panned to.
        if (_mapKeyOf(old.hotels) != _mapKeyOf(widget.hotels) && _placed.isNotEmpty) {
            _frameHotels();
        }

        if (old.card != widget.card) {
            old.card?.removeListener(_repaintCard);
            widget.card?.addListener(_repaintCard);
        }

        // A newly chosen stay gets its card eased into view; the same stay staying chosen does
        // not, or every repaint of the gallery would nudge the camera.
        if (old.selectedId != widget.selectedId) _revealCard();
    }

    /// The placed stays, as one comparable value. Two lists with the same stays in the same
    /// order are the same view, however many times the widget rebuilds around them.
    static String _mapKeyOf(List<Hotel> hotels) => hotels
        .where((h) => h.latitude != null && h.longitude != null)
        .map((h) => h.id)
        .join(',');

    @override
    void dispose() {
        widget.card?.removeListener(_repaintCard);
        _pins?.deleteAll();
        _cards?.deleteAll();
        super.dispose();
    }

    Future<void> _onMapCreated(MapboxMap map) async {
        _map = map;
        await map.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
        await map.compass.updateSettings(CompassSettings(enabled: false));
        // Flat and north-up, always. The card over the selected pin is placed by projecting
        // the stay's coordinate here (see `_projectWith`), and that projection is only exact
        // on a map with no bearing and no pitch. Neither gesture does anything for a search
        // map — the pins are flat pills, and a tilted city hides the ones behind it — so they
        // are turned off rather than carried through the arithmetic.
        await map.gestures.updateSettings(
            GesturesSettings(rotateEnabled: false, pitchEnabled: false),
        );
        // The pins' manager is created first so the card's sits above it. The card is one
        // stay's answer and it covers whatever it covers, as V2's popup does over its markers
        // — a neighbour's pin punching through the middle of a photograph reads as a fault.
        // The press order below matches: the card is tested before the pins, so what looks
        // topmost is what answers.
        _pins = await map.annotations.createPointAnnotationManager();
        _cards = await map.annotations.createPointAnnotationManager();

        // One handler answers every press on this map.
        //
        // Neither manager is given a tap listener of its own. An annotation that has one
        // swallows the press and reports only *which* annotation it was, and the card needs to
        // know *where* on itself it was pressed — the close disc and the gallery arrows are
        // regions of a picture now, not buttons (ADR-0008). With no listener to swallow it,
        // every press arrives here carrying its position, and the hit test below answers it
        // against the same projection that drew the things being pressed.
        map.addInteraction(
            TapInteraction.onMap((context) => _onPress(
                Offset(
                    context.touchPosition.x.toDouble(),
                    context.touchPosition.y.toDouble(),
                ),
            )),
        );

        await _frameHotels();
        await _redraw();
        await _repaintCard();
    }

    /// Answers a press at [at], in the map's own logical pixels.
    ///
    /// In front-to-back order, which is the order they are drawn in: the card first, because it
    /// stands over the pins; then the pins; then the ground, which dismisses.
    void _onPress(Offset at) {
        final card = widget.card?.hotel;
        if (card != null) {
            final rect = _cardRect(card);
            if (rect != null && rect.contains(at)) {
                switch (StayCardGeometry(photos: widget.card!.photos.length)
                    .hitTest(at - rect.topLeft)) {
                    case StayCardPress.open:
                        widget.onOpen(card);
                    case StayCardPress.close:
                        widget.onMapTap?.call();
                    case StayCardPress.previous:
                        widget.card!.page(-1);
                    case StayCardPress.next:
                        widget.card!.page(1);
                }
                return;
            }
        }

        // The nearest pin whose painted pill holds the press. Nearest rather than first,
        // because pins overlap and the one a traveller means is the one they pressed closest
        // to the middle of.
        _Marker? pressed;
        var closest = double.infinity;
        for (final drawn in _hit) {
            final rect = _pinRect(drawn.marker, drawn.size);
            if (rect == null || !rect.contains(at)) continue;
            final away = (rect.center - at).distanceSquared;
            if (away < closest) {
                closest = away;
                pressed = drawn.marker;
            }
        }

        if (pressed != null) {
            _onMarkerTap(pressed);
            return;
        }
        widget.onMapTap?.call();
    }

    /// Where the card is drawn, in the map's own logical pixels, or null when there is none or
    /// the camera has not been reported yet.
    Rect? _cardRect(Hotel hotel) {
        final camera = _camera;
        if (camera == null || hotel.latitude == null) return null;

        final at = _projectWith(camera, hotel);
        if (at == null) return null;
        return Rect.fromLTWH(
            at.dx - stayMapCardWidth / 2,
            at.dy - stayMapCardPinClearance - stayMapCardHeight,
            stayMapCardWidth,
            stayMapCardHeight,
        );
    }

    /// Where a pin's pill is drawn. Mapbox anchors these at the bottom, so the coordinate is
    /// the middle of the pill's foot.
    Rect? _pinRect(_Marker marker, Size size) {
        final camera = _camera;
        if (camera == null) return null;

        final at = offsetOnMap(
            longitude: marker.longitude,
            latitude: marker.latitude,
            centreLongitude: camera.center.coordinates.lng.toDouble(),
            centreLatitude: camera.center.coordinates.lat.toDouble(),
            zoom: camera.zoom,
            view: _size,
        );
        return Rect.fromLTWH(at.dx - size.width / 2, at.dy - size.height, size.width, size.height);
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
            // Kept for the hit test, which has nothing else to go on until the camera first
            // moves — and a press that lands before any pan still has to find its pin.
            _camera = camera;
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
            // What was painted where, so that a press can be answered without asking the map
            // which annotation it landed on. The sizes are the painter's own, in logical
            // pixels, and they are what the press is tested against.
            final hit = <({_Marker marker, Size size})>[];
            for (final marker in markers) {
                final badge = marker.hotels.length > 1 ? '${marker.hotels.length}' : '';
                final lines = _linesFor(marker, t);
                final chosen = marker.hotels.any((h) => h.id == widget.selectedId);

                // Painted once per distinct pin. Expanding a cluster redraws the same pills at
                // every step — a price does not change because the camera moved — and encoding
                // each one again is what made a tap take a visible moment to answer.
                final key = '$badge|${lines.join('~')}|$chosen|$brightness';
                final painted = _pinCache[key] ??= await painter.paint(
                    badge: badge,
                    lines: lines,
                    selected: chosen,
                );
                final drawn = painted.bytes;
                hit.add((marker: marker, size: painted.size));
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
            _hit = hit;
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

    /// Paints the **Stay Card** and hands it to the map, or clears it.
    ///
    /// Called whenever the card's state says something has changed: a stay selected, its
    /// photograph decoded, the gallery advanced. The card is one annotation standing on the
    /// stay's own coordinate with the picture lifted clear of the pin, so from here on the map
    /// moves it and nothing in Dart has an opinion about where it is.
    Future<void> _repaintCard() async {
        final cards = _cards;
        if (cards == null || _headless) return;

        final model = widget.card;
        final hotel = model?.hotel;
        if (model == null || hotel == null || hotel.latitude == null) {
            if (_card != null) {
                await cards.deleteAll();
                _card = null;
            }
            return;
        }

        // One paint at a time. A photograph decoding while the gallery advances would
        // otherwise create two cards and delete neither.
        if (_painting) {
            _paintAgain = true;
            return;
        }
        _painting = true;

        try {
            final t = AppLocalizations.of(context)!;
            final ratio = MediaQuery.devicePixelRatioOf(context);
            final shown = exchangeRates.convertForDisplay(
                hotel.fromRate,
                hotel.currency,
                widget.currency,
            );

            final painted = await StayCardPainter(ratio: ratio).paint(
                name: hotel.name,
                address: (hotel.address?.isNotEmpty ?? false) ? hotel.address! : hotel.area,
                price: '${formatMoney(shown.amount, shown.currency)}${t.hotels_perNight}',
                rating: hotel.score > 0
                    ? '${hotel.score.toStringAsFixed(1)} ${t.hotels_description_rating}'
                    : null,
                photo: model.photo,
                photos: model.photos.length,
                shown: model.shown,
            );
            if (!mounted) return;

            await cards.deleteAll();
            _card = await cards.create(PointAnnotationOptions(
                geometry: Point(coordinates: mb.Position(hotel.longitude!, hotel.latitude!)),
                image: painted.bytes,
                // Anchored at its foot on the stay's coordinate. The picture carries the pin's
                // clearance as empty space below the card, so the card itself stands above the
                // pin — see the painter, and why `iconOffset` is not used for this.
                iconAnchor: IconAnchor.BOTTOM,
                iconSize: 1.0,
            ));
        } finally {
            _painting = false;
            if (_paintAgain) {
                _paintAgain = false;
                unawaited(_repaintCard());
            }
        }
    }

    bool _painting = false;
    bool _paintAgain = false;

    /// Eases the camera until the whole card is in view.
    ///
    /// A **Map-Locked** card cannot be nudged out from under the search bar after the fact —
    /// nudging it is the drift that locking it to the map removes. So the map moves instead,
    /// once, by exactly as much as it takes, and then holds still. Nothing happens when the
    /// card already fits, which is most presses.
    Future<void> _revealCard() async {
        await _repaintCard();

        final map = _map;
        final camera = _camera;
        final hotel = widget.card?.hotel;
        if (map == null || camera == null || hotel == null || _headless) return;

        final rect = _cardRect(hotel);
        if (rect == null) return;

        // What the card needs clearing on each side, in logical pixels: the search bar at the
        // top, the gutter everywhere else.
        var dx = 0.0;
        var dy = 0.0;
        if (rect.top < widget.topInset + mapGutter) dy = rect.top - widget.topInset - mapGutter;
        if (rect.left < mapGutter) dx = rect.left - mapGutter;
        if (rect.right > _size.width - mapGutter) dx = rect.right - _size.width + mapGutter;
        if (dx == 0 && dy == 0) return;

        // Moving the camera by a screen offset: the centre takes the place of the point that
        // many pixels away from it, which is the same projection read backwards.
        final world = 512 * math.pow(2, camera.zoom).toDouble();
        final centre = camera.center.coordinates;
        final lng = centre.lng.toDouble() + dx / world * 360;

        final y = (0.5 -
                math.log((1 + math.sin(centre.lat.toDouble() * math.pi / 180)) /
                        (1 - math.sin(centre.lat.toDouble() * math.pi / 180))) /
                    (4 * math.pi)) *
            world;
        final lat = math.atan(_sinh(math.pi * (1 - 2 * (y + dy) / world))) * 180 / math.pi;

        await map.flyTo(
            CameraOptions(center: Point(coordinates: mb.Position(lng, lat))),
            MapAnimationOptions(duration: 220),
        );
    }

    static double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;

    /// Where a coordinate sits on screen, worked out from a camera already in hand.
    ///
    /// Web Mercator, which is what the map itself draws with. Exact while bearing and pitch
    /// are zero, which `_onMapCreated` makes certain of.
    Offset? _projectWith(CameraState camera, Hotel hotel) {
        if (_size == Size.zero) return null;
        final centre = camera.center.coordinates;
        return offsetOnMap(
            longitude: hotel.longitude!,
            latitude: hotel.latitude!,
            centreLongitude: centre.lng.toDouble(),
            centreLatitude: centre.lat.toDouble(),
            zoom: camera.zoom,
            view: _size,
        );
    }

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
                    // Regrouping only when it stops. The pins and the card hold their place on
                    // the map while it moves — they are all the map's own annotations now — so
                    // the only thing a camera change alters is which stays are close enough to
                    // be drawn as one.
                    onMapIdleListener: (_) => _redraw(),
                    // Nothing is drawn from this: it is kept only so that a press can be
                    // answered. The card and the pins are already where they belong, and the
                    // hit test needs the camera they were last drawn against.
                    onCameraChangeListener: (event) => _camera = event.cameraState,
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

        const place = _headlessPlace;

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

        // Tappable, because the card over a pin is now what this screen is for and a stand-in
        // map that cannot be tapped leaves that whole interaction — open, swap, route — with
        // no automated cover. On a device the annotation carries the tap; here the widget
        // does, and both end at `onSelect`.
        //
        // A cluster selects its cheapest rather than zooming: there is no camera here to fly,
        // and `_onMarkerTap` already falls back to exactly that when stays share a point.
        return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => map.widget.onSelect(marker.hotels.first),
            child: marker.hotels.length > 1
                ? ClusterPin(count: marker.hotels.length, priceLabel: lines.last, active: active)
                : HotelPin(name: marker.hotels.first.name, priceLabel: lines.first, active: active),
        );
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

/// Where a coordinate falls on a map of [view] pointed at a centre, in logical pixels from
/// the view's top left.
///
/// Web Mercator, which is what the map itself draws with: the world is 512 logical pixels
/// square at zoom 0 and doubles with every zoom level, so a coordinate's distance from the
/// camera's centre in that square is its distance from the middle of the view. Exact for a
/// north-up map with no pitch, which is the only kind this screen allows.
///
/// Public because it is the whole of the card's placement during a pan, and a projection that
/// is a pixel out is a card that does not sit on its pin.
Offset offsetOnMap({
    required double longitude,
    required double latitude,
    required double centreLongitude,
    required double centreLatitude,
    required double zoom,
    required Size view,
}) {
    final world = 512 * math.pow(2, zoom).toDouble();

    double atLng(double lng) => (lng + 180) / 360 * world;
    double atLat(double lat) {
        // Mercator runs to infinity at the poles; the map stops where the square does.
        final sin = math.sin(lat.clamp(-85.05112878, 85.05112878) * math.pi / 180);
        return (0.5 - math.log((1 + sin) / (1 - sin)) / (4 * math.pi)) * world;
    }

    var dx = atLng(longitude) - atLng(centreLongitude);
    // The short way round. Without this a stay on the far side of the antimeridian from the
    // camera is a world away instead of a few pixels.
    if (dx > world / 2) dx -= world;
    if (dx < -world / 2) dx += world;

    return Offset(
        view.width / 2 + dx,
        view.height / 2 + (atLat(latitude) - atLat(centreLatitude)),
    );
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
