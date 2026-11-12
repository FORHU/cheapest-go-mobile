import 'dart:async' show unawaited;
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb show Position;

import 'package:cheapest_go_mobile/features/hotels/components/nearby_icons.dart';
import 'package:cheapest_go_mobile/shared/search/nearby_api.dart';

/// The places around a property, on the map. See #40 and V2's `NearbyMap`.
///
/// The property is one marker and every place is another, each wearing its category's glyph —
/// a fork for food, a cup for a café — so the map says what is around without the strip
/// underneath having to be read first.
///
/// Markers are the map's own annotations for the reason the search map's are: a pin laid out
/// in Flutter has to be repositioned from the camera on every change, and lags the map it is
/// supposed to be stuck to.
class NearbyMap extends StatefulWidget {
    const NearbyMap({
        required this.latitude,
        required this.longitude,
        required this.places,
        required this.onSelect,
        this.selectedId,
        super.key,
    });

    /// The property, which the map opens on.
    final double latitude;
    final double longitude;
    final List<NearbyPlace> places;
    final ValueChanged<NearbyPlace> onSelect;
    final String? selectedId;

    static const height = 220.0;

    @override
    State<NearbyMap> createState() => _NearbyMapState();
}

class _NearbyMapState extends State<NearbyMap> {
    MapboxMap? _map;
    PointAnnotationManager? _pins;
    final _byAnnotation = <String, NearbyPlace>{};
    bool _drawing = false;
    bool _again = false;
    String? _drawn;

    /// Tests have no Mapbox — no token, no platform view — so the map is a plain ground there
    /// and the places are read from the strip beneath it.
    bool get _headless {
        try {
            return !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
        } catch (_) {
            return false;
        }
    }

    @override
    void didUpdateWidget(NearbyMap old) {
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
        await map.gestures.updateSettings(GesturesSettings(
            // One finger drags the page, not the map: this map sits inside a scrolling
            // property page, and a map that swallows vertical drags traps the reader in it.
            scrollEnabled: false,
            pitchEnabled: false,
            rotateEnabled: false,
        ));
        _pins = await map.annotations.createPointAnnotationManager();
        _pins!.tapEvents(onTap: (annotation) {
            final place = _byAnnotation[annotation.id];
            if (place != null) widget.onSelect(place);
        });
        await _frame();
        await _redraw();
    }

    /// Opens on the property with its places around it.
    Future<void> _frame() async {
        final map = _map;
        if (map == null) return;

        await map.setCamera(CameraOptions(
            center: Point(coordinates: mb.Position(widget.longitude, widget.latitude)),
            // Close enough that a walk reads as a walk. V2 opens its nearby map at the same
            // sort of scale rather than fitting every result, which pulls a lone outlier's
            // distance into the whole frame.
            zoom: 14.5,
        ));
    }

    Future<void> _redraw() async {
        final map = _map;
        final pins = _pins;
        if (_headless || map == null || pins == null) return;

        if (_drawing) {
            _again = true;
            return;
        }
        _drawing = true;

        final ratio = MediaQuery.devicePixelRatioOf(context);
        final dark = Theme.of(context).brightness == Brightness.dark;
        final signature = [
            widget.selectedId ?? '',
            dark,
            for (final place in widget.places) place.id,
        ].join('|');

        try {
            if (signature == _drawn) return;

            final options = <PointAnnotationOptions>[
                PointAnnotationOptions(
                    geometry: Point(coordinates: mb.Position(widget.longitude, widget.latitude)),
                    image: await glyphPin(
                        icon: Icons.hotel_rounded,
                        ratio: ratio,
                        // The property is the thing everything else is "near", so it wears the
                        // brand colours and the places take the page's.
                        background: const Color(0xFF2563EB),
                        foreground: Colors.white,
                    ),
                    iconAnchor: IconAnchor.CENTER,
                    symbolSortKey: 3,
                ),
                for (final place in widget.places)
                    PointAnnotationOptions(
                        geometry: Point(coordinates: mb.Position(place.longitude, place.latitude)),
                        image: await glyphPin(
                            icon: iconForPoi(place.category),
                            ratio: ratio,
                            background: place.id == widget.selectedId
                                ? const Color(0xFF06B6D4)
                                : dark ? const Color(0xFF1A1A1A) : Colors.white,
                            foreground: place.id == widget.selectedId
                                ? Colors.white
                                : dark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        iconAnchor: IconAnchor.CENTER,
                        symbolSortKey: place.id == widget.selectedId ? 2 : 1,
                    ),
            ];

            if (!mounted) return;
            await pins.deleteAll();
            _byAnnotation.clear();
            final created = await pins.createMulti(options);
            // The first annotation is the property; the rest line up with the places.
            for (var i = 1; i < created.length && i - 1 < widget.places.length; i++) {
                final annotation = created[i];
                if (annotation != null) _byAnnotation[annotation.id] = widget.places[i - 1];
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

    @override
    Widget build(BuildContext context) {
        final dark = Theme.of(context).brightness == Brightness.dark;

        return SizedBox(
            height: NearbyMap.height,
            child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _headless
                    ? ColoredBox(color: dark ? const Color(0xFF0B1222) : const Color(0xFFE8EDF2))
                    : MapWidget(
                        key: ValueKey('nearby-map-${dark ? 'dark' : 'light'}'),
                        styleUri: dark ? MapboxStyles.DARK : MapboxStyles.LIGHT,
                        onMapCreated: _onMapCreated,
                    ),
            ),
        );
    }
}

/// A round marker carrying one glyph, painted at the device's scale.
///
/// Icons are font glyphs, so this is a text run in a circle — which is why it can carry
/// Material's icons and the app's own without an asset per category.
Future<Uint8List> glyphPin({
    required IconData icon,
    required double ratio,
    required Color background,
    required Color foreground,
}) async {
    const size = 32.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(ratio);

    final centre = const Offset(size / 2, size / 2);
    canvas.drawCircle(
        centre.translate(0, 1),
        size / 2,
        Paint()
            ..color = const Color(0x38000000)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(centre, size / 2, Paint()..color = background);

    final glyph = TextPainter(
        text: TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
                fontSize: 17,
                fontFamily: icon.fontFamily,
                package: icon.fontPackage,
                color: foreground,
            ),
        ),
        textDirection: TextDirection.ltr,
    )..layout();
    glyph.paint(canvas, centre - Offset(glyph.width / 2, glyph.height / 2));

    final image = await recorder.endRecording().toImage(
        (size * ratio).ceil(),
        (size * ratio).ceil(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
}
