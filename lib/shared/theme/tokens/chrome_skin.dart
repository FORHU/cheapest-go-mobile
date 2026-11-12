import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// The bottom bar's own colours, as V2 states them in `MobileBottomNav.tsx`.
///
/// Hand-written rather than generated, and that is the exception worth explaining. Everything
/// else in `generated/` comes out of V2's `globals.css`; these live in the component itself and
/// `palette.ts` has never carried them, so the generator has nothing to read.
///
/// **They are not a defect to be overridden.** `CONTEXT.md`'s **Token Authority** says that
/// where a V2 screen contradicts V2's tokens, mobile implements the token — but the rule is
/// there to stop stray literals spreading, and these are not stray. The bronze comes in two
/// deliberate shades, and V2 explains why: *"The dark bar's bronze is 2.9:1 on white, under the
/// 3:1 an icon needs, so the light bar takes it a shade deeper."* Replacing that with the blue
/// from the token layer would throw away a contrast decision and make mobile wrong.
///
/// What is actually missing is the token: these belong in `palette.ts`, and that is the issue
/// to raise against V2. When they land there, delete this file and let the generator carry them.
///
/// ## Tone, not theme
///
/// V2 picks the skin by the screen's *chrome tone*, not the app theme. On most screens the two
/// agree. The exception is the search map, which inverts its floating chrome to contrast the
/// basemap; the bar overlaps that map, so it inverts with the toolbar rather than with the page.
/// Mobile keeps the distinction for the same reason, even though only one screen needs it today.
@immutable
class ChromeSkin {
    const ChromeSkin({
        required this.bar,
        required this.border,
        required this.dockShadow,
        required this.icon,
        required this.active,
        required this.divider,
    });

    /// The bar's own ground.
    final Color bar;

    /// A hairline on the top and shoulders. The light bar needs one the dark bar does not: a
    /// white bar on a light page has no contrast of its own to sit on.
    final Color border;

    /// Cast upward only — the bar is docked, not floating.
    final Color dockShadow;

    /// An inactive glyph, at full strength rather than dimmed.
    final Color icon;

    /// The slot you are on. Bronze, and a different bronze per tone; see above.
    final Color active;

    /// The hairline between slots.
    final Color divider;

    static const dark = ChromeSkin(
        bar:        Color(0xFF181C24),
        border:     Color(0x0FFFFFFF),
        dockShadow: Color(0x38000000),
        icon:       Color(0xFFFFFFFF),
        active:     Color(0xFFBB8E5E),
        divider:    Color(0x33FFFFFF),
    );

    static const light = ChromeSkin(
        bar:        Color(0xFFFFFFFF),
        border:     Color(0x14111111),
        dockShadow: Color(0x1A0F172A),
        icon:       Color(0xFF181C24),
        active:     Color(0xFF9A6E3F),
        divider:    Color(0x24181C24),
    );
}
