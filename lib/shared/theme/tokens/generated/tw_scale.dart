// GENERATED — do not edit by hand.
//
// Tailwind's type, radius and spacing scales.
// Mirrored from FORHU/cheapestgo-app-v2 at 78c0c1026710e11a419b2df69c71219c7bdb0a9e
// Regenerate with: dart run tools/sync_design.dart
// See docs/adr/0002-tokens-and-copy-are-generated-from-a-pinned-v2-commit.md

import 'package:flutter/foundation.dart';

/// A size and the line height that goes with it, as Tailwind pairs them.
@immutable
class TwFont {
    const TwFont(this.size, this.height);

    /// Logical pixels. A CSS rem and a Flutter logical pixel are the same size at 1x.
    final double size;

    /// A multiplier, which is what `TextStyle.height` wants. Null where Tailwind states none.
    final double? height;
}

/// `text-sm` and the rest, as sizes rather than class names.
abstract final class TwText {
    /// --text-2xl
    static const n2xl = TwFont(24.0, 1.3333333333333333);
    /// --text-3xl
    static const n3xl = TwFont(30.0, 1.2);
    /// --text-4xl
    static const n4xl = TwFont(36.0, 1.1111111111111112);
    /// --text-5xl
    static const n5xl = TwFont(48.0, 1.0);
    /// --text-6xl
    static const n6xl = TwFont(60.0, 1.0);
    /// --text-7xl
    static const n7xl = TwFont(72.0, 1.0);
    /// --text-8xl
    static const n8xl = TwFont(96.0, 1.0);
    /// --text-9xl
    static const n9xl = TwFont(128.0, 1.0);
    /// --text-base
    static const base = TwFont(16.0, 1.5);
    /// --text-lg
    static const lg = TwFont(18.0, 1.5555555555555556);
    /// --text-sm
    static const sm = TwFont(14.0, 1.4285714285714286);
    /// --text-xl
    static const xl = TwFont(20.0, 1.4);
    /// --text-xs
    static const xs = TwFont(12.0, 1.3333333333333333);
}

/// `rounded-2xl` and the rest, in logical pixels.
abstract final class TwRadius {
    /// --radius-2xl
    static const n2xl = 16.0;
    /// --radius-3xl
    static const n3xl = 24.0;
    /// --radius-4xl
    static const n4xl = 32.0;
    /// --radius-dashboard
    static const dashboard = 32.0;
    /// --radius-lg
    static const lg = 8.0;
    /// --radius-md
    static const md = 6.0;
    /// --radius-sm
    static const sm = 4.0;
    /// --radius-xl
    static const xl = 12.0;
    /// --radius-xs
    static const xs = 2.0;
}

/// The families V2 asks for, first in each stack. Bundled as assets under the same names,
/// so a fallback never silently stands in for one.
abstract final class TwFonts {
    /// --font-sans
    static const sans = 'Plus Jakarta Sans';
    /// --font-serif
    static const serif = 'ui-serif';
    /// --font-mono
    static const mono = 'JetBrains Mono';
    /// --font-weight-thin
    static const weightThin = '100';
    /// --font-weight-extralight
    static const weightExtralight = '200';
    /// --font-weight-light
    static const weightLight = '300';
    /// --font-weight-normal
    static const weightNormal = '400';
    /// --font-weight-medium
    static const weightMedium = '500';
    /// --font-weight-semibold
    static const weightSemibold = '600';
    /// --font-weight-bold
    static const weightBold = '700';
    /// --font-weight-extrabold
    static const weightExtrabold = '800';
    /// --font-weight-black
    static const weightBlack = '900';
    /// --font-display
    static const display = 'Plus Jakarta Sans';
}

/// Tailwind counts spacing in units of `--spacing`, so `p-6` is six of them.
abstract final class TwSpace {
    static const unit = 4.0;

    /// `TwSpace.of(6)` is `p-6`.
    static double of(num steps) => steps * unit;
}
