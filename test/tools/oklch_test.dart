import 'package:flutter_test/flutter_test.dart';

import '../../tools/oklch.dart';

/// The conversion the whole token mirror rests on.
///
/// Tailwind 4 states its ramp in oklch; Flutter needs ARGB. If this is wrong, every colour in
/// the app is slightly wrong in a way no reviewer would catch.
///
/// Ground truth is the three sRGB primaries, whose oklch coordinates are exact and published,
/// so they check the maths rather than the expectation.
void main() {
    group('oklch', () {
        test('white and black are exact', () {
            expect(parseCssColor('oklch(1 0 0)'), 0xFFFFFFFF);
            expect(parseCssColor('oklch(0 0 0)'), 0xFF000000);
        });

        /// Exact, not approximate: if the matrices or the gamma curve are wrong, these move.
        test('round-trips the sRGB primaries exactly', () {
            expect(parseCssColor('oklch(62.796% 0.25768 29.234)'),  0xFFFF0000);
            expect(parseCssColor('oklch(86.644% 0.29483 142.495)'), 0xFF00FF00);
            expect(parseCssColor('oklch(45.201% 0.31321 264.052)'), 0xFF0000FF);
        });

        /// Tailwind 4 re-derived its palette in oklch, so its stops are **not** the hexes
        /// Tailwind 3 published and that everyone has memorised. slate-400 — 536 uses in V2,
        /// the single most common colour in the product — is #90A1B9 here and #94A3B8 there.
        /// Anyone mirroring the palette from memory would put the whole app four points off on
        /// its most-used colour, so this guards the difference rather than papering over it.
        test('gives Tailwind 4 values, which differ from the Tailwind 3 hexes', () {
            expect(parseCssColor('oklch(70.4% 0.04 256.788)'), 0xFF90A1B9);
            expect(parseCssColor('oklch(70.4% 0.04 256.788)'), isNot(0xFF94A3B8));
        });

        test('reads a percentage lightness and a unit lightness alike', () {
            expect(parseCssColor('oklch(50% 0 0)'), parseCssColor('oklch(0.5 0 0)'));
        });

        test('carries alpha through', () {
            expect(parseCssColor('oklch(1 0 0 / 50%)')! >> 24 & 0xFF, 128);
        });
    });

    group('the other notations V2 writes colours in', () {
        test('hex, long and short', () {
            expect(parseCssColor('#2563eb'), 0xFF2563EB);
            expect(parseCssColor('#fff'), 0xFFFFFFFF);
        });

        test('hex with alpha moves the alpha to the front, as Flutter wants', () {
            expect(parseCssColor('#2563eb80'), 0x802563EB);
        });

        test('rgba', () {
            expect(parseCssColor('rgba(255, 255, 255, 0.05)'), 0x0DFFFFFF);
            expect(parseCssColor('rgb(0 0 0)'), 0xFF000000);
        });
    });

    group('values that are not colours', () {
        test('return null so the caller can tell a length from a colour', () {
            expect(parseCssColor('0.625rem'), isNull);
            expect(parseCssColor("'Plus Jakarta Sans', sans-serif"), isNull);
            expect(parseCssColor('backdrop-filter 800ms ease'), isNull);
            expect(parseCssColor('clamp(0.75rem, 0.7061rem + 0.1878vw, 0.875rem)'), isNull);
        });
    });
}
