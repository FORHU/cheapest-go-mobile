/// Converting CSS colours to the 32-bit ARGB Flutter wants.
///
/// V2 writes most of its palette in `oklch`, which Flutter has no notion of, so something has
/// to do the conversion. Doing it here rather than by hand is the whole point of ADR-0002: 77
/// role colours and 244 ramp stops converted by eye would produce errors that look like design
/// decisions, and nobody would ever find them.
library;

import 'dart:math' as math;

/// A colour as Flutter writes it: 0xAARRGGBB.
typedef Argb = int;

/// `oklch(70.4% 0.04 256.788)`, `oklch(1 0 0)`, `oklch(0.63 0.2 29 / 50%)`.
final _oklch = RegExp(
    r'oklch\(\s*([\d.]+%?)\s+([\d.]+)\s+([\d.]+)(?:\s*/\s*([\d.]+%?))?\s*\)',
    caseSensitive: false);

/// `rgba(255, 255, 255, 0.05)` and `rgb(0 0 0)`.
final _rgb = RegExp(
    r'rgba?\(\s*([\d.]+)[\s,]+([\d.]+)[\s,]+([\d.]+)(?:[\s,/]+([\d.]+%?))?\s*\)',
    caseSensitive: false);

final _hex = RegExp(r'^#([0-9a-fA-F]{3,8})$');

/// The colour a CSS value names, or null when the value is not a colour at all —
/// a length, a font stack, a transition. Callers use the null to sort one from the other.
Argb? parseCssColor(String raw) {
  final value = raw.trim();

  final ok = _oklch.firstMatch(value);
  if (ok != null) {
    return _oklchToArgb(
      _number(ok.group(1)!),
      double.parse(ok.group(2)!),
      double.parse(ok.group(3)!),
      ok.group(4) == null ? 1.0 : _number(ok.group(4)!),
    );
  }

  final rgb = _rgb.firstMatch(value);
  if (rgb != null) {
    final a = rgb.group(4) == null ? 1.0 : _number(rgb.group(4)!);
    return _argb(a, double.parse(rgb.group(1)!) / 255, double.parse(rgb.group(2)!) / 255,
        double.parse(rgb.group(3)!) / 255);
  }

  final hex = _hex.firstMatch(value);
  if (hex != null) return _hexToArgb(hex.group(1)!);

  return null;
}

/// `70.4%` and `0.704` mean the same thing in these files; both appear.
double _number(String token) =>
    token.endsWith('%') ? double.parse(token.substring(0, token.length - 1)) / 100 : double.parse(token);

Argb _hexToArgb(String digits) {
  var h = digits;
  if (h.length == 3 || h.length == 4) {
    h = h.split('').map((c) => '$c$c').join();
  }
  if (h.length == 6) return int.parse('ff$h', radix: 16);
  if (h.length == 8) {
    // CSS puts alpha last, Flutter puts it first.
    final rgb = h.substring(0, 6);
    final alpha = h.substring(6, 8);
    return int.parse('$alpha$rgb', radix: 16);
  }
  throw FormatException('Not a hex colour: #$digits');
}

/// oklch -> OKLab -> linear sRGB -> sRGB, per the CSS Color 4 definition.
Argb _oklchToArgb(double l, double c, double hDegrees, double alpha) {
  final h = hDegrees * math.pi / 180;
  final a = c * math.cos(h);
  final b = c * math.sin(h);

  final lp = l + 0.3963377774 * a + 0.2158037573 * b;
  final mp = l - 0.1055613458 * a - 0.0638541728 * b;
  final sp = l - 0.0894841775 * a - 1.2914855480 * b;

  final lc = lp * lp * lp;
  final mc = mp * mp * mp;
  final sc = sp * sp * sp;

  final rLin = 4.0767416621 * lc - 3.3077115913 * mc + 0.2309699292 * sc;
  final gLin = -1.2684380046 * lc + 2.6097574011 * mc - 0.3413193965 * sc;
  final bLin = -0.0041960863 * lc - 0.7034186147 * mc + 1.7076147010 * sc;

  return _argb(alpha, _gamma(rLin), _gamma(gLin), _gamma(bLin));
}

/// Linear light to sRGB. Out-of-gamut channels are clamped, which is what a browser does too.
double _gamma(double v) {
  final c = v <= 0.0031308 ? 12.92 * v : 1.055 * math.pow(v, 1 / 2.4) - 0.055;
  return c.clamp(0.0, 1.0).toDouble();
}

Argb _argb(double a, double r, double g, double b) =>
    (_byte(a) << 24) | (_byte(r) << 16) | (_byte(g) << 8) | _byte(b);

int _byte(double v) => (v.clamp(0.0, 1.0) * 255).round();

/// `0xFF94A3B8`, as it will appear in the generated Dart.
String argbLiteral(Argb value) =>
    '0x${value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
