import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:cheapest_go_mobile/features/hotels/components/stay_map_card.dart';

/// Draws the **Stay Card** to a picture the map can carry, the way [StayPinPainter] draws a
/// **Stay Pin**. See ADR-0008.
///
/// Every mark here is V2's `HotelPreviewCard` — the 234 × 268 artboard, the photograph as the
/// card's whole ground, the four-stop scrim over its foot, the close disc, the gallery arrows
/// and the stretched dot. The difference is only that it is painted rather than laid out,
/// because a card laid out over the map trails the ground it stands on.
///
/// Nothing here is a button. [StayCardGeometry] says where each control was drawn so that a
/// tap can be answered, which is the price of being **Map-Locked**.
class StayCardPainter {
    const StayCardPainter({required this.ratio});

    /// The device's pixel ratio. The card is drawn at that scale and handed back with the size
    /// it should occupy in logical pixels, so it is sharp rather than resampled.
    final double ratio;

    /// `ON_PHOTO` and `ON_PHOTO_MUTED`: always white, because this ink sits on photography.
    static const _onPhoto = Color(0xFFFFFFFF);
    static const _onPhotoMuted = Color(0xB8FFFFFF);

    static const _radius = 16.0;
    static const _padX = 13.0;
    static const _padBottom = 11.0;

    /// Paints the card showing [photo], or the stand-in ground when there is none yet.
    Future<({Uint8List bytes, Size size})> paint({
        required String name,
        required String address,
        required String price,
        required String? rating,
        required ui.Image? photo,
        required int photos,
        required int shown,
    }) async {
        const width = stayMapCardWidth;
        const height = stayMapCardHeight;

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.scale(ratio);

        final card = RRect.fromRectAndRadius(
            const Rect.fromLTWH(0, 0, width, height),
            const Radius.circular(_radius),
        );

        // Under the card, as V2's `box-shadow` sits under it.
        canvas.drawRRect(
            card.shift(const Offset(0, 10)),
            Paint()
                ..color = const Color(0x61000000)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
        );

        canvas.save();
        canvas.clipRRect(card);
        // Stated rather than taken from the theme: every mark on this card is white over
        // photography, and a light ground would show through wherever a photo has not loaded.
        canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), Paint()..color = const Color(0xFF121212));

        if (photo != null) {
            _drawCover(canvas, photo, const Rect.fromLTWH(0, 0, width, height));
        } else {
            // The stand-in, while the photograph is still being fetched.
            _glyph(canvas, Icons.apartment_rounded, 24, const Color(0x4DFFFFFF),
                const Offset(width / 2, height / 2));
        }

        // Four stops rather than two: a straight fade leaves a visible band where it meets the
        // photo, and the eye catches that edge before it catches the stay's name.
        const scrim = Rect.fromLTWH(0, height * 0.32, width, height * 0.68);
        canvas.drawRect(
            scrim,
            Paint()
                ..shader = const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xF0000000), Color(0xDB000000), Color(0x7A000000), Color(0x00000000)],
                    stops: [0, 0.30, 0.64, 1],
                ).createShader(scrim),
        );

        final geometry = StayCardGeometry(photos: photos);

        _disc(canvas, geometry.close, const Color(0x8C000000));
        _glyph(canvas, Icons.close_rounded, 13, _onPhoto, geometry.close.center);

        if (photos > 1) {
            for (final (control, icon) in [
                (geometry.previous!, Icons.chevron_left_rounded),
                (geometry.next!, Icons.chevron_right_rounded),
            ]) {
                _disc(canvas, control, const Color(0x73000000));
                _glyph(canvas, icon, 17, _onPhoto, control.center);
            }
        }

        // The copy sits on the bottom edge, so a one-line address and a two-line one both
        // leave the price where the eye expects it. Laid out from the foot upwards.
        var y = height - _padBottom;

        if (photos > 1) {
            y -= 5;
            var x = (width - (photos.clamp(0, _maxDots) * 5 + (photos.clamp(0, _maxDots) - 1) * 5)) / 2;
            for (var i = 0; i < photos && i < _maxDots; i++) {
                final lit = i == shown;
                canvas.drawRRect(
                    RRect.fromRectAndRadius(
                        Rect.fromLTWH(x, y, lit ? 13 : 5, 5),
                        const Radius.circular(100),
                    ),
                    Paint()..color = lit ? _onPhoto : const Color(0x8CFFFFFF),
                );
                x += (lit ? 13 : 5) + 5;
            }
            y -= 10;
        }

        if (rating != null) {
            y -= _paintUp(canvas, y, rating, size: 10, weight: FontWeight.w400, color: _onPhotoMuted);
            y -= 2;
        }
        y -= _paintUp(canvas, y, price, size: 12, weight: FontWeight.w700, color: _onPhoto);
        y -= 6;
        if (address.isNotEmpty) {
            y -= _paintUp(canvas, y, address,
                size: 10, weight: FontWeight.w400, color: _onPhotoMuted, maxLines: 2);
            y -= 3;
        }
        _paintUp(canvas, y, name, size: 13.5, weight: FontWeight.w700, color: _onPhoto);

        canvas.restore();

        // Taller than the card by the pin's clearance, with nothing drawn in the gap.
        //
        // The annotation is anchored at its foot on the stay's coordinate, so that empty strip
        // is what holds the card above the pin. Mapbox's own `iconOffset` was the obvious way
        // to do this and did nothing measurable — the card sat with its feet on the
        // coordinate, over the pin, with its head behind the search bar. Space painted into
        // the picture cannot be ignored.
        final image = await recorder.endRecording().toImage(
            (width * ratio).ceil(),
            ((height + stayMapCardPinClearance) * ratio).ceil(),
        );
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();

        return (bytes: data!.buffer.asUint8List(), size: const Size(width, height));
    }

    /// `MAX_DOTS`: past this the strip is a gauge rather than one dot per photo.
    static const _maxDots = 8;

    /// Draws [text] with its *bottom* at [bottom], and answers how tall it was.
    double _paintUp(
        Canvas canvas,
        double bottom,
        String text, {
        required double size,
        required FontWeight weight,
        required Color color,
        int maxLines = 1,
    }) {
        final painter = TextPainter(
            text: TextSpan(
                text: text,
                style: TextStyle(
                    // The app's own face, so the card reads as part of the product.
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: size,
                    height: size == 13.5 ? 1.25 : 1.35,
                    fontWeight: weight,
                    color: color,
                ),
            ),
            textDirection: TextDirection.ltr,
            maxLines: maxLines,
            ellipsis: '…',
        )..layout(maxWidth: stayMapCardWidth - _padX * 2);
        painter.paint(canvas, Offset(_padX, bottom - painter.height));
        return painter.height;
    }

    /// The photograph, covering [into] and cropped to it rather than squashed.
    void _drawCover(Canvas canvas, ui.Image photo, Rect into) {
        final scale = (into.width / photo.width) > (into.height / photo.height)
            ? into.width / photo.width
            : into.height / photo.height;
        final w = photo.width * scale;
        final h = photo.height * scale;
        canvas.drawImageRect(
            photo,
            Rect.fromLTWH(0, 0, photo.width.toDouble(), photo.height.toDouble()),
            Rect.fromLTWH(into.center.dx - w / 2, into.center.dy - h / 2, w, h),
            Paint()..filterQuality = FilterQuality.medium,
        );
    }

    /// One of the controls floating on the photograph. Each carries its own scrim — the card
    /// has no surface faint enough to read against photography.
    void _disc(Canvas canvas, Rect at, Color background) =>
        canvas.drawOval(at, Paint()..color = background);

    void _glyph(Canvas canvas, IconData icon, double size, Color color, Offset centre) {
        final painter = TextPainter(
            text: TextSpan(
                text: String.fromCharCode(icon.codePoint),
                style: TextStyle(
                    fontFamily: icon.fontFamily,
                    package: icon.fontPackage,
                    fontSize: size,
                    color: color,
                ),
            ),
            textDirection: TextDirection.ltr,
        )..layout();
        painter.paint(canvas, centre - Offset(painter.width / 2, painter.height / 2));
    }
}

/// Where the card's controls were drawn, in the card's own coordinates.
///
/// A painted card has no buttons, so this is what answers a tap: the card's rect is projected
/// from the camera, the tap is put into the card's own frame, and these say what it landed on.
/// Shared by the painter and the hit test so the two cannot drift apart.
class StayCardGeometry {
    const StayCardGeometry({required this.photos});

    /// How many pictures the gallery holds. With one there is nothing to page, and V2 draws no
    /// arrows at all rather than two controls that do nothing.
    final int photos;

    static const _discClose = 24.0;
    static const _discArrow = 30.0;

    Rect get close => const Rect.fromLTWH(
        stayMapCardWidth - 8 - _discClose, 8, _discClose, _discClose);

    /// Centred on the clear part of the photograph rather than on the card: halfway down would
    /// put them on the stay's name.
    Rect? get previous => photos > 1
        ? const Rect.fromLTWH(8, stayMapCardHeight * 0.32 - _discArrow / 2, _discArrow, _discArrow)
        : null;

    Rect? get next => photos > 1
        ? const Rect.fromLTWH(stayMapCardWidth - 8 - _discArrow,
            stayMapCardHeight * 0.32 - _discArrow / 2, _discArrow, _discArrow)
        : null;

    /// What a press at [at] — in the card's own coordinates — asks for.
    StayCardPress hitTest(Offset at) {
        // A finger is wider than a 24px disc, so each control answers for a little more than it
        // draws. The body is the rest of the card, which is the way through to the stay.
        if (_near(close, at)) return StayCardPress.close;
        if (previous != null && _near(previous!, at)) return StayCardPress.previous;
        if (next != null && _near(next!, at)) return StayCardPress.next;
        return StayCardPress.open;
    }

    static bool _near(Rect control, Offset at) => control.inflate(6).contains(at);
}

/// What a press on the card asked for.
enum StayCardPress { open, close, previous, next }
