// Builds the Google Play store-listing graphics from the brand files already in this
// repository, so the listing never drifts from the launcher icon. Run with:
//   dart run tool/make_play_assets.dart [output dir]
//
// Play's requirements, which are exact and not negotiable:
//   app icon        512 x 512   PNG, under 1 MB
//   feature graphic 1024 x 500  PNG or JPEG
// Screenshots are not made here: they have to come off a real device or emulator.
import 'dart:io';
import 'package:image/image.dart' as img;

const _iconSrc = 'assets/images/airanggo_icon_src.png'; // 1024x1024, mark on white
const _wordmark = 'assets/images/airanggo_wordmark.png'; // 534x173, transparent

// From lib/shared/theme/tokens/app_colors.dart — the same primary the app ships with.
final _blue = img.ColorRgb8(0x25, 0x63, 0xEB);
final _navy = img.ColorRgb8(0x1E, 0x3A, 0x8A);
final _slate50 = img.ColorRgb8(0xF8, 0xFA, 0xFC);

img.Image _read(String path) {
  final bytes = File(path).readAsBytesSync();
  final image = img.decodePng(bytes);
  if (image == null) throw StateError('could not decode $path');
  return image;
}

/// Reports what colours the wordmark actually uses, so a recolour is a decision and not a
/// guess. Opaque pixels only — the file is mostly transparent.
void _describe(img.Image mark) {
  final counts = <int, int>{};
  for (final p in mark) {
    if (p.a < 128) continue;
    final key = (p.r.toInt() ~/ 32) << 10 | (p.g.toInt() ~/ 32) << 5 | (p.b.toInt() ~/ 32);
    counts[key] = (counts[key] ?? 0) + 1;
  }
  final top = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final parts = top.take(4).map((e) {
    final r = (e.key >> 10) * 32, g = ((e.key >> 5) & 31) * 32, b = (e.key & 31) * 32;
    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')} x${e.value}';
  });
  stdout.writeln('wordmark opaque colours: ${parts.join(', ')}');
}

/// Keeps the shape, replaces the ink. Used to put the wordmark on a dark background without
/// needing a second artwork file.
img.Image _recolour(img.Image src, int r, int g, int b) {
  final out = img.Image.from(src);
  for (final p in out) {
    p.setRgb(r, g, b);
  }
  return out;
}

/// Centres [mark] on [canvas], fitted to [maxW] x [maxH] without distortion.
void _place(img.Image canvas, img.Image mark, int maxW, int maxH) {
  final scale = (maxW / mark.width) < (maxH / mark.height)
      ? maxW / mark.width
      : maxH / mark.height;
  final w = (mark.width * scale).round();
  final h = (mark.height * scale).round();
  final resized =
      img.copyResize(mark, width: w, height: h, interpolation: img.Interpolation.cubic);
  img.compositeImage(canvas, resized,
      dstX: ((canvas.width - w) / 2).round(), dstY: ((canvas.height - h) / 2).round());
}

img.Image _feature({required img.Image mark, required bool dark}) {
  final canvas = img.Image(width: 1024, height: 500, numChannels: 4);
  if (dark) {
    // Vertical navy -> blue. A flat fill reads as a placeholder at this size.
    for (var y = 0; y < canvas.height; y++) {
      final t = y / (canvas.height - 1);
      final c = img.ColorRgb8(
        (_navy.r + (_blue.r - _navy.r) * t).round(),
        (_navy.g + (_blue.g - _navy.g) * t).round(),
        (_navy.b + (_blue.b - _navy.b) * t).round(),
      );
      img.drawLine(canvas, x1: 0, y1: y, x2: canvas.width - 1, y2: y, color: c);
    }
  } else {
    img.fill(canvas, color: _slate50);
    // A brand bar along the bottom edge, so the light version is not a bare rectangle.
    img.fillRect(canvas, x1: 0, y1: canvas.height - 12, x2: canvas.width - 1,
        y2: canvas.height - 1, color: _blue);
  }
  _place(canvas, mark, 560, 190);
  return canvas;
}

void main(List<String> args) {
  final outDir = Directory(args.isEmpty ? 'build/play' : args.first)
    ..createSync(recursive: true);

  final icon = img.copyResize(_read(_iconSrc),
      width: 512, height: 512, interpolation: img.Interpolation.cubic);
  File('${outDir.path}/icon-512.png').writeAsBytesSync(img.encodePng(icon));

  final mark = _read(_wordmark);
  _describe(mark);

  File('${outDir.path}/feature-graphic-1024x500.png').writeAsBytesSync(
      img.encodePng(_feature(mark: _recolour(mark, 255, 255, 255), dark: true)));
  File('${outDir.path}/feature-graphic-light-1024x500.png')
      .writeAsBytesSync(img.encodePng(_feature(mark: mark, dark: false)));

  for (final f in outDir.listSync().whereType<File>()) {
    stdout.writeln('${f.path}  ${(f.lengthSync() / 1024).toStringAsFixed(0)} KB');
  }
}
