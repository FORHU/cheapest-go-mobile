import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cheapest_go_mobile/app/router/v2_bottom_nav.dart';
import 'package:cheapest_go_mobile/features/home/components/stage_chrome.dart';
import 'package:cheapest_go_mobile/features/home/components/step_search.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_palette.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_scale.dart';

/// Home: V2's landing, as the **Plain Journey**. See #38 and `CONTEXT.md`.
///
/// V2's landing is a scroll-driven descent through Stages. Only one Stage is visible — the AI
/// planner sits in `HIDDEN_STAGES` — and it wears three faces, switched by tabs rather than by
/// scrolling: Stays, Flights, Golf. Mobile shows that one Stage without the choreography:
/// every heading stated outright, the tabs switching in place. That is the **Plain Journey**,
/// and on mobile it is the default rendering rather than a reduced-motion fallback.
///
/// What this replaced: an airport-first search — "Where are you flying into?" with tabs for
/// Stays, Golf and Stay + Golf. V2 asks where you are *going*, which is a different question,
/// and answering it is what gave Flights an entry point again after #36 took its tab away.
class HomeView extends StatefulWidget {
    const HomeView({super.key});

    @override
    State<HomeView> createState() => _HomeViewState();
}

/// The faces of the one visible Stage, in V2's order.
enum _Face { stays, flights, golf }

class _HomeViewState extends State<HomeView> {
    _Face _face = _Face.stays;

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;

        // The showcase runs the whole screen, not a band at the top: V2 pins it behind
        // everything and docks the search on top of it, which is why the panel's own chrome is
        // dark glass rather than taking the page's colours. The photograph does not scroll —
        // the content moves over it, as a fixed backdrop does on the web.
        // One render object, not a Stack of two layers. Behind the list, the backdrop left
        // the previous tab's step trail and question on screen when the content above them
        // changed height — the list painted over a layer nothing was repainting, so stale
        // pixels stayed put. Painting the backdrop as this box's own decoration repaints it
        // with the content every frame.
        return _Showcase(
            child: SafeArea(
                    bottom: false,
                    child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        children: [
                            _Hero(t: t),
                            Padding(
                                padding: EdgeInsets.fromLTRB(
                                    TwSpace.of(4),
                                    TwSpace.of(2),
                                    TwSpace.of(4),
                                    // Clear of the bar, which the body now runs under.
                                    TwSpace.of(8) + V2BottomNav.barHeight +
                                        MediaQuery.viewPaddingOf(context).bottom,
                                ),
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                        _Tabs(face: _face, onChanged: (f) => setState(() => _face = f)),
                                        SizedBox(height: TwSpace.of(5)),
                                        _StageHeading(face: _face, t: t),
                                        SizedBox(height: TwSpace.of(5)),
                                        // Keyed by face: a tab switched in place starts its own
                                        // search afresh, as V2 does by keying on mode.
                                        switch (_face) {
                                            _Face.stays => const StepSearch(
                                                key: ValueKey('stays'), mode: StepMode.stays),
                                            _Face.flights => const StepSearch(
                                                key: ValueKey('flights'), mode: StepMode.flights),
                                            _Face.golf => _GolfPanel(t: t),
                                        },
                                    ],
                                ),
                            ),
                        ],
                    ),
                ),
        );
    }
}

/// The Stage's backdrop: its ground, the photograph over it, and a wash so the copy stays
/// readable wherever the frame happens to be bright.
///
/// V2's Stays stage opens on dusk over a city. The ground beneath is what shows if the
/// photograph will not load, and it is warm at the horizon so the frame reads as late
/// afternoon rather than as a photo behind smoked glass.
class _Showcase extends StatelessWidget {
    const _Showcase({required this.child});

    /// Painted over the backdrop, in the same render object, so the two repaint together.
    final Widget child;

    static const _ground = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0B1222), Color(0xFF132A46), Color(0xFF2B3F52)],
        stops: [0.0, 0.45, 1.0],
    );

    @override
    Widget build(BuildContext context) {
        return DecoratedBox(
            decoration: const BoxDecoration(
                gradient: _ground,
                image: DecorationImage(
                    image: AssetImage('assets/images/destinations/downtown-dusk.webp'),
                    fit: BoxFit.cover,
                    opacity: 0.55,
                ),
            ),
            child: DecoratedBox(
                // Darker at the foot, where the search sits, than at the head.
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x40000000), Color(0xB3050A14)],
                        stops: [0.0, 0.55],
                    ),
                ),
                child: child,
            ),
        );
    }
}

/// The opening: kicker, a two-line title, and the line under it. All of it V2's own copy.
class _Hero extends StatelessWidget {
    const _Hero({required this.t});

    final AppLocalizations t;

    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: EdgeInsets.fromLTRB(
                TwSpace.of(4), TwSpace.of(16), TwSpace.of(4), TwSpace.of(8),
            ),
            child: Column(
                // Centred: the hero is the one block on the page with nothing beside it, and
                // left-aligned over a full-bleed photograph it read as a caption stuck to
                // the edge rather than the page's opening line.
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                    Text(
                        t.landing_journey_hero_kicker,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: TwText.xs.size,
                            height: TwText.xs.height,
                            fontWeight: FontWeight.w600,
                            letterSpacing: TwText.xs.size * 0.1,
                            color: TwPalette.obsidianAccent,
                        ),
                    ),
                    SizedBox(height: TwSpace.of(4)),
                    // Two lines because V2 writes them as two: the second is the turn.
                    Text(
                        t.landing_journey_hero_titleLine1,
                        textAlign: TextAlign.center,
                        style: _title,
                    ),
                    Text(
                        t.landing_journey_hero_titleLine2,
                        textAlign: TextAlign.center,
                        style: _title,
                    ),
                    SizedBox(height: TwSpace.of(4)),
                    Text(
                        t.landing_journey_hero_subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: TwText.base.size,
                            height: 1.625,
                            color: TwPalette.slate400,
                        ),
                    ),
                ],
            ),
        );
    }

    TextStyle get _title => TextStyle(
        fontSize: TwText.n3xl.size,
        height: 1.1,
        fontWeight: FontWeight.w800,
        letterSpacing: TwText.n3xl.size * -0.025,
        color: Colors.white,
    );
}

/// Stays · Flights · Golf. Three, so each has a place of its own and moving between any two
/// of them is a single tap.
/// Stays · Flights · Golf, as one glass group with the chosen segment filled.
///
/// V2 draws these as a single dark pill holding three segments, not three separate buttons —
/// the group is the control and the gradient marks which part of it you are in.
class _Tabs extends StatelessWidget {
    const _Tabs({required this.face, required this.onChanged});

    final _Face face;
    final ValueChanged<_Face> onChanged;

    @override
    Widget build(BuildContext context) {
        return Align(
            // Centred with the hero above it: the three faces are the page's main choice,
            // and a choice reads as one when it sits under the line that offered it.
            alignment: Alignment.center,
            child: GlassPanel(
                radius: 999,
                padding: EdgeInsets.all(TwSpace.of(1)),
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        for (final f in _Face.values)
                            _Tab(
                                label: switch (f) {
                                    _Face.stays => 'Stays',
                                    _Face.flights => 'Flights',
                                    _Face.golf => 'Golf',
                                },
                                selected: f == face,
                                onTap: () => onChanged(f),
                            ),
                    ],
                ),
            ),
        );
    }
}

class _Tab extends StatelessWidget {
    const _Tab({required this.label, required this.selected, required this.onTap});

    final String label;
    final bool selected;
    final VoidCallback onTap;

    @override
    Widget build(BuildContext context) {
        return Material(
            color: Colors.transparent,
            child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(999),
                child: Ink(
                    decoration: BoxDecoration(
                        gradient: selected ? brandGradient : null,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: selected
                            ? const [
                                BoxShadow(
                                    color: Color(0xA62563EB),
                                    blurRadius: 18,
                                    spreadRadius: -6,
                                    offset: Offset(0, 6),
                                ),
                            ]
                            : null,
                    ),
                    child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: TwSpace.of(5),
                            vertical: TwSpace.of(2.5),
                        ),
                        child: Text(
                            label,
                            style: TextStyle(
                                fontSize: TwText.sm.size,
                                fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : Colors.white70,
                            ),
                        ),
                    ),
                ),
            ),
        );
    }
}

class _StageHeading extends StatelessWidget {
    const _StageHeading({required this.face, required this.t});

    final _Face face;
    final AppLocalizations t;

    @override
    Widget build(BuildContext context) {
        final (lead, rest, caption) = switch (face) {
            _Face.stays => (
                t.landing_journey_stages_stays_titleLead,
                t.landing_journey_stages_stays_titleRest,
                t.landing_journey_stages_stays_caption,
            ),
            _Face.flights => (
                t.landing_journey_stages_flights_titleLead,
                t.landing_journey_stages_flights_titleRest,
                t.landing_journey_stages_flights_caption,
            ),
            _Face.golf => (
                t.landing_journey_stages_golf_titleLead,
                t.landing_journey_stages_golf_titleRest,
                t.landing_journey_stages_golf_caption,
            ),
        };

        return Column(
            // Centred with the hero and the faces above it, so the stage's own heading
            // continues the same column rather than stepping back to the left margin.
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
                // Text.rich, not RichText: RichText takes no style from its surroundings, so
                // the heading silently fell back to the platform font — Roboto on a device,
                // and tofu in a test render, which is how this was caught.
                Text.rich(
                    TextSpan(
                        style: TextStyle(
                            fontFamily: TwFonts.display,
                            fontSize: TwText.n2xl.size,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: TwText.n2xl.size * -0.025,
                            color: Colors.white,
                        ),
                        // Uppercase, as V2 sets it — the copy itself is sentence case in the
                        // message files and the stage shouts it.
                        children: [
                            TextSpan(
                                text: '${lead.toUpperCase()} ',
                                style: const TextStyle(color: TwPalette.blue600),
                            ),
                            TextSpan(text: rest.toUpperCase()),
                        ],
                    ),
                ),
                SizedBox(height: TwSpace.of(2)),
                Text(
                    caption,
                    style: TextStyle(
                        fontSize: TwText.sm.size,
                        height: 1.625,
                        color: Colors.white70,
                    ),
                ),
            ],
        );
    }
}

/// Golf does not use the step search: V2 asks it as a sentence about a course, because a tee
/// time is requested rather than searched. Mobile hands off to the golf screen, which already
/// lists the courses we work with.
class _GolfPanel extends StatelessWidget {
    const _GolfPanel({required this.t});

    final AppLocalizations t;

    @override
    Widget build(BuildContext context) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                Text(
                    t.golf_subtitle,
                    // White, like every other line on the Stage: slate-500 is the page's
                    // muted grey and all but disappeared against the photograph.
                    style: TextStyle(fontSize: TwText.sm.size, color: Colors.white70),
                ),
                SizedBox(height: TwSpace.of(4)),
                // The Stage's own button, not the theme's: a FilledButton here took the page's
                // flat blue and was the one control on the photograph that did not match the
                // rest. Aligned left and hugging its label, as the step buttons do.
                Align(
                    alignment: Alignment.centerLeft,
                    child: GradientPill(
                        // No trailing icon: V2's own copy for this one ends in an arrow, so
                        // adding the usual one drew it twice.
                        label: t.search_golf_allCourses,
                        onPressed: () => context.go('/golf'),
                    ),
                ),
            ],
        );
    }
}
