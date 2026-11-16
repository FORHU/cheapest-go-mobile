import 'package:flutter/material.dart';

import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_palette.dart';

/// The flight pages' own materials, as V2 states them. See `flight-card.tsx` (the card's
/// SURFACE / TITLE / TEXT / MUTED / HAIRLINE), `search-chrome.ts` (`sortPalette`, the bar's
/// controls) and the results page's `GROUND`.
///
/// Like the hotel search, these screens do not take the app theme wholesale: V2 paints them in
/// two tones of its own, chosen by brightness. Hotels hold the same values in `StaySkin`; the
/// features may not import one another, so flights state their own.
class FlightSkin {
  const FlightSkin._({
    required this.ground,
    required this.surface,
    required this.title,
    required this.text,
    required this.muted,
    required this.hairline,
    required this.control,
    required this.field,
    required this.menu,
    required this.hover,
    required this.chip,
  });

  /// The page behind the cards: slate-100, or V2's obsidian.
  final Color ground;

  /// A card, and the toolbar's plate.
  final Color surface;
  final Color title;
  final Color text;
  final Color muted;
  final Color hairline;

  /// A round control on the bar (`sortPalette.surface`).
  final Color control;

  /// The route field (`sortPalette.field`).
  final Color field;
  final Color menu;
  final Color hover;

  /// A fact on a card on a phone: slate-100, or white at 8%.
  final Color chip;

  static const light = FlightSkin._(
    ground: TwPalette.slate100,
    surface: TwPalette.white,
    title: TwPalette.slate900,
    text: TwPalette.slate700,
    muted: TwPalette.slate500,
    hairline: TwPalette.slate200,
    control: TwPalette.white,
    field: TwPalette.white,
    menu: TwPalette.white,
    hover: TwPalette.slate100,
    chip: TwPalette.slate100,
  );

  static const dark = FlightSkin._(
    ground: TwPalette.obsidian,
    surface: TwPalette.slate900,
    title: TwPalette.slate50,
    text: TwPalette.slate100,
    muted: TwPalette.slate400,
    hairline: Color(0x1AFFFFFF),
    control: TwPalette.slate800,
    field: TwPalette.obsidian,
    menu: TwPalette.slate900,
    hover: Color(0x12FFFFFF),
    chip: Color(0x14FFFFFF),
  );

  static FlightSkin of(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? dark : light;

  /// Select, a picked chip, the stop marker: V2's brand gradient, blue-600 → cyan-500.
  static const gradient = LinearGradient(colors: [TwPalette.blue600, TwPalette.cyan500]);
}

/// A pill filled with the brand gradient — the card's Select, the sheet's Done.
class GradientPill extends StatelessWidget {
  const GradientPill({
    required this.label,
    required this.onTap,
    this.height = 44,
    this.radius = 12,
    this.busy = false,
    this.expand = false,
    this.fontSize = 14,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;
  final double height;
  final double radius;
  final bool busy;
  final bool expand;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !busy;
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: height,
          width: expand ? double.infinity : null,
          decoration: BoxDecoration(gradient: FlightSkin.gradient, borderRadius: BorderRadius.circular(radius)),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(radius),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Center(
                widthFactor: 1,
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        label,
                        style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
