// Builds the two launcher sources from the brand mark. Run with:
//   dart run tool/make_icon.dart && dart run flutter_launcher_icons
//
// The mark (assets/images/airanggo_mark.png) is 229x203 and transparent. Two problems for a
// launcher icon, both fixed here rather than by hand:
//
//   * Not square. flutter_launcher_icons scales its source to a square canvas, so a 229x203
//     source reaches the home screen stretched 13% wide.
//   * Transparent, with a black "A". On a dark launcher background the A disappears and the
//     icon reads as "Go".
//
// So: pad to square, and lay the legacy icon on white. The adaptive foreground keeps its
// transparency — its background comes from adaptive_icon_background — but is inset so the
// mark survives the circular mask Android applies (the safe zone is the middle ~66%).
import 'dart:io';
import 'package:image/image.dart' as img;

const _src = 'assets/images/airanggo_mark.png';
const _legacyOut = 'assets/images/airanggo_icon_src.png';
const _foregroundOut = 'assets/images/airanggo_icon_fg.png';
const _canvas = 1024;

/// How much of the canvas the mark occupies. 0.62 for the adaptive foreground because Android
/// masks it to a circle and crops roughly a third away; 0.80 for the legacy icon, which is not
/// masked and only needs a little breathing room.
const _adaptiveScale = 0.62;
const _legacyScale = 0.80;

img.Image _centre(img.Image mark, double scale, {required bool onWhite}) {
    final canvas = img.Image(width: _canvas, height: _canvas, numChannels: 4);
    img.fill(canvas, color: onWhite
        ? img.ColorRgba8(255, 255, 255, 255)
        : img.ColorRgba8(0, 0, 0, 0));

    // Fit inside the box without distorting: the longer side decides.
    final box = (_canvas * scale).round();
    final ratio = mark.width / mark.height;
    final w = ratio >= 1 ? box : (box * ratio).round();
    final h = ratio >= 1 ? (box / ratio).round() : box;

    final resized = img.copyResize(mark, width: w, height: h,
        interpolation: img.Interpolation.cubic);
    img.compositeImage(canvas, resized,
        dstX: ((_canvas - w) / 2).round(), dstY: ((_canvas - h) / 2).round());
    return canvas;
}

void main() {
    final mark = img.decodePng(File(_src).readAsBytesSync());
    if (mark == null) {
        stderr.writeln('could not read $_src');
        exit(1);
    }
    stdout.writeln('source: ${mark.width}x${mark.height}');

    File(_legacyOut).writeAsBytesSync(
        img.encodePng(_centre(mark, _legacyScale, onWhite: true)));
    File(_foregroundOut).writeAsBytesSync(
        img.encodePng(_centre(mark, _adaptiveScale, onWhite: false)));

    stdout.writeln('wrote $_legacyOut and $_foregroundOut at ${_canvas}x$_canvas');
}
