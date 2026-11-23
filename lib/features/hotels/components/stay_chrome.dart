import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';

/// The search screen's own chrome, as V2 draws it. See #39 and `rail-card.tsx`.
///
/// Like the landing's Stage, this screen does not take the app theme wholesale: the cards and
/// the toolbar sit over a map, so their surfaces are stated here in the two tones V2 uses and
/// chosen by brightness rather than by the theme's roles.

/// V2's `railCardPalette`, which the cards, the toolbar and the status screens all read.
class StaySkin {
    const StaySkin({
        required this.surface,
        required this.title,
        required this.muted,
        required this.hairline,
        required this.imageBg,
        required this.chipBg,
        required this.chipText,
        required this.chipTrack,
    });

    /// The card's own ground.
    final Color surface;
    final Color title;
    final Color muted;
    final Color hairline;
    final Color imageBg;

    /// A chip on a card — the View button, and the ring on the status screens. V2's note:
    /// "the price circle and the View Stay button wear the brand gradient", so this is a
    /// gradient rather than a colour, in both themes.
    final Color chipBg;
    final Color chipText;
    final Color chipTrack;

    /// What a chip is actually filled with. [chipBg] is its flat stand-in, for the places a
    /// gradient cannot go.
    static const chipGradient = kBrandGradient;

    /// `brandTheme('light')`: white surface, slate-900 titles, slate-500 muted, slate-200
    /// hairlines, slate-100 for a control on a surface.
    static const light = StaySkin(
        surface: Color(0xFFFFFFFF),
        title: Color(0xFF0F172A),
        muted: Color(0xFF64748B),
        hairline: Color(0xFFE2E8F0),
        imageBg: Color(0xFFF1F5F9),
        chipBg: Color(0xFF2563EB),
        chipText: Color(0xFFFFFFFF),
        chipTrack: Color(0x40FFFFFF),
    );

    /// `brandTheme('dark')`: slate-900 surface on the obsidian ground.
    static const dark = StaySkin(
        surface: Color(0xFF0F172A),
        title: Color(0xFFF8FAFC),
        muted: Color(0xFF94A3B8),
        hairline: Color(0x1AFFFFFF),
        imageBg: Color(0x0DFFFFFF),
        chipBg: Color(0xFF2563EB),
        chipText: Color(0xFFFFFFFF),
        chipTrack: Color(0x40FFFFFF),
    );

    static StaySkin of(BuildContext context) =>
        Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// How the results are ordered.
///
/// V2's `SORT_OPTIONS`, in its order and with its labels. The labels are English literals
/// there — `search-chrome.ts` holds them as a constant rather than in the locale files — so
/// they are literals here too. Translating them on mobile only would put the two products out
/// of step, which is the thing this port exists to prevent; they move when V2's move.
enum StaySort {
    recommended,
    priceLow,
    rating,
    mostReviewed,
    priceHigh;

    /// The words, in the language the app renders in.
    ///
    /// They were const English literals mirroring V2's `search-chrome.ts`, on the reasoning
    /// that translating only here would put the two products out of step. A brand locked to
    /// one language (ADR-0007) settles it the other way: five English chips inside an
    /// otherwise Korean sheet is V2's screen contradicting the product, which is what
    /// **Token Authority** covers.
    String labelIn(AppLocalizations t) => switch (this) {
        StaySort.recommended => t.mobile_hotels_sortRecommended,
        StaySort.priceLow => t.mobile_hotels_sortCheapest,
        StaySort.rating => t.mobile_hotels_sortTopRated,
        StaySort.mostReviewed => t.mobile_hotels_sortMostReviewed,
        StaySort.priceHigh => t.mobile_hotels_sortPriceHighLow,
    };
}

/// The words V2 puts to an **aggregate score** or a review's own, so one number is not called
/// "excellent" in the summary and "very good" in the list under it.
String scoreBand(double score, AppLocalizations t) {
    if (score >= 9) return t.hotels_ratings_exceptional;
    if (score >= 8) return t.hotels_ratings_excellent;
    if (score >= 7) return t.hotels_ratings_veryGood;
    if (score >= 6) return t.hotels_ratings_good;
    return t.hotels_ratings_average;
}
