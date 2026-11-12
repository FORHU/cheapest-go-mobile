import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Draws V2's map pin to a picture the map can carry. See #39.
///
/// Mapbox anchors an annotation to a coordinate and moves it with the camera itself, which is
/// the whole reason these are painted rather than laid out: pins drawn as Flutter widgets over
/// the map had to be repositioned from the camera every frame, and each reposition is a round
/// trip — so during a pan they lagged the map and slid about over the streets.
///
/// The shape is `ClusterPin`/`HotelPin`: a pill holding a gradient disc and one or two lines.
class StayPinPainter {
    const StayPinPainter({
        required this.background,
        required this.foreground,
        required this.ratio,
    });

    /// `--pin-bg` and `--pin-fg` for the theme in force.
    final Color background;
    final Color foreground;

    /// The device's pixel ratio: the pin is drawn at that scale and handed back with the size
    /// it should occupy in logical pixels, so it is sharp rather than resampled.
    final double ratio;

    static const _gradient = [Color(0xFF2563EB), Color(0xFF06B6D4)];
    static const _disc = 34.0;
    static const _padLeft = 4.0;
    static const _padRight = 14.0;
    static const _gap = 8.0;

    /// [badge] goes in the disc — a count, or nothing for a single stay. [lines] are drawn
    /// beside it: the muted line first, then the price.
    Future<({Uint8List bytes, Size size})> paint({
        required String badge,
        required List<String> lines,
        required bool selected,
    }) async {
        final scale = ratio * (selected ? 1.15 : 1.0);
        final texts = [
            for (final (i, line) in lines.indexed)
                _layout(
                    line,
                    size: i == 0 && lines.length > 1 ? 10 : 12,
                    weight: FontWeight.w600,
                    color: i == 0 && lines.length > 1 ? foreground.withValues(alpha: 0.62) : foreground,
                ),
        ];
        final textW = texts.fold<double>(0, (w, t) => math.max(w, t.width));
        final textH = texts.fold<double>(0, (h, t) => h + t.height);

        final width = _padLeft + _disc + _gap + textW + _padRight;
        final height = math.max(_disc + _padLeft * 2, textH + 12);

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.scale(scale);

        final pill = RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, width, height),
            const Radius.circular(100),
        );
        // The shadow first, under the pill, as the web's `box-shadow` sits under the marker.
        canvas.drawRRect(
            pill.shift(const Offset(0, 2)),
            Paint()
                ..color = const Color(0x38000000)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
        canvas.drawRRect(pill, Paint()..color = background);

        final discRect = Rect.fromLTWH(_padLeft, (height - _disc) / 2, _disc, _disc);
        canvas.drawOval(
            discRect,
            Paint()..shader = const LinearGradient(colors: _gradient).createShader(discRect),
        );

        if (badge.isNotEmpty) {
            // Three digits fit by shrinking the type rather than by growing the pin, which
            // would shift every marker beside it.
            final painted = _layout(
                badge,
                size: badge.length > 3 ? 11 : badge.length > 2 ? 13 : 15,
                weight: FontWeight.w700,
                color: Colors.white,
            );
            painted.paint(
                canvas,
                Offset(
                    discRect.center.dx - painted.width / 2,
                    discRect.center.dy - painted.height / 2,
                ),
            );
        }

        var y = (height - textH) / 2;
        for (final text in texts) {
            text.paint(canvas, Offset(_padLeft + _disc + _gap, y));
            y += text.height;
        }

        final image = await recorder.endRecording().toImage(
            (width * scale).ceil(),
            (height * scale).ceil(),
        );
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();

        return (bytes: data!.buffer.asUint8List(), size: Size(width, height));
    }

    TextPainter _layout(String text, {required double size, required FontWeight weight, required Color color}) {
        final painter = TextPainter(
            text: TextSpan(
                text: text,
                style: TextStyle(
                    // The app's own face, so a pin reads as part of the product rather than as
                    // the platform's default.
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: size,
                    height: 1.15,
                    fontWeight: weight,
                    color: color,
                ),
            ),
            textDirection: TextDirection.ltr,
            maxLines: 1,
        )..layout();
        return painter;
    }
}
