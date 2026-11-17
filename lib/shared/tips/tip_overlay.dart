import 'dart:async';

import 'package:flutter/material.dart';

import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/tips/tip_anchor.dart';
import 'package:cheapest_go_mobile/shared/tips/tip_store.dart';

/// One thing a screen is willing to explain.
class Tip {
  const Tip({required this.anchorId, required this.title, required this.body});

  final String anchorId;
  final String title;
  final String body;
}

/// A **Tip**: a card beside one control, the first time somebody reaches the screen that
/// carries it. See #62 and ADR-0006.
///
/// It does not dim, does not cover the control it names, and does not take taps — the screen
/// underneath keeps working, and using it dismisses the Tip. That is the whole difference from
/// what #63 shipped, and it is deliberate: a tutorial that blocks the screen you are trying to
/// use is the one people resent, and on a checkout it would cover the price while asking
/// somebody to read about paying.
///
/// Wrap a screen in one of these. Each screen carries its own; they are not steps of a tour,
/// so no screen has to know where a traveller goes next.
class TipScope extends StatefulWidget {
  const TipScope({required this.tip, required this.child, this.ready = true, super.key});

  /// What to say. Null shows nothing, for a screen whose Tip depends on state.
  final Tip? tip;

  /// Whether the screen has something to point at yet.
  ///
  /// A results screen passes false while it is loading: a Tip over a spinner, describing cards
  /// that have not arrived, teaches nothing.
  final bool ready;

  final Widget child;

  @override
  State<TipScope> createState() => _TipScopeState();
}

class _TipScopeState extends State<TipScope> {
  /// How long somebody has to do nothing before the Tip offers itself.
  ///
  /// Material's guidance is that prompts should follow what somebody is doing rather than a
  /// page load, and that a prompt landing on someone who opened the app to act is unhelpful.
  /// Two seconds is the line: act within it and the Tip never appears at all.
  static const Duration _pause = Duration(seconds: 2);

  Timer? _wait;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    TipAnchorRegistry.revision.addListener(_onAnchorsChanged);
    // ...and to the store, because a Tip is silent until the account's answer arrives. The
    // anchor is usually on screen long before that reply, so without this the only thing
    // that could wake it up had already happened.
    tipStore.addListener(_onAnchorsChanged);
    _considerShowing();
  }

  @override
  void didUpdateWidget(TipScope old) {
    super.didUpdateWidget(old);
    // The screen just became ready, or is now about something else.
    if (old.ready != widget.ready || old.tip?.anchorId != widget.tip?.anchorId) {
      _visible = false;
      _considerShowing();
    }
  }

  /// Waits for the pause, then shows the Tip if its anchor is there.
  ///
  /// The anchor arriving later is not a failure and has no deadline. Home's TipScope sits
  /// above the router and mounts while the traveller is still at the sign-in wall; the bottom
  /// bar it points at does not exist until they are through the gate and past onboarding,
  /// which can be minutes. An earlier version polled for twenty seconds and gave up, so Home
  /// showed nothing at all. [TipAnchorRegistry.revision] says when to look again.
  void _considerShowing() {
    _wait?.cancel();
    final tip = widget.tip;
    if (!widget.ready || tip == null || !tipStore.shouldShow(tip.anchorId)) return;
    if (!TipAnchorRegistry.has(tip.anchorId)) return; // nothing yet; wait to be told.

    _wait = Timer(_pause, () {
      if (!mounted || !tipStore.shouldShow(tip.anchorId)) return;
      // Gone again during the pause — the traveller moved on. Its turn is kept.
      if (TipAnchorRegistry.rectOf(tip.anchorId) == null) return;
      setState(() => _visible = true);
    });
  }

  /// An anchor appeared or went. If this Tip is still waiting for its own, try again.
  void _onAnchorsChanged() {
    if (_visible || !mounted) return;
    _considerShowing();
  }

  /// Seen, and finished with. Not a refusal: they read it or they acted.
  void _dismiss() {
    final tip = widget.tip;
    if (tip == null) return;
    setState(() => _visible = false);
    tipStore.markShown(tip.anchorId);
  }

  /// Ends the walkthrough. Not this card — all of it.
  void _refuse() {
    setState(() => _visible = false);
    tipStore.endTutorial();
  }

  @override
  void dispose() {
    TipAnchorRegistry.revision.removeListener(_onAnchorsChanged);
    tipStore.removeListener(_onAnchorsChanged);
    _wait?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tip = widget.tip;
    if (!_visible || tip == null) return widget.child;

    final rect = TipAnchorRegistry.rectOf(tip.anchorId);
    if (rect == null) return widget.child;

    return Stack(
      children: [
        // The screen underneath keeps working — nothing is dimmed and nothing is intercepted.
        //
        // It does **not** dismiss on touch. That is what this did first, and on a handset it
        // meant the Tip appeared and was gone on the traveller's very next tap, before it had
        // been read: three were marked seen on a test device by somebody who never saw one.
        // A card that vanishes when you touch anything cannot be read on a screen you are
        // using. It stays until "Got it" or "Skip".
        widget.child,
        // Positioned by a delegate rather than by arithmetic, because only the delegate is
        // told how tall the card turned out to be. Guessing it — this guessed 170 — put the
        // card half off the bottom of handsets, where a traveller saw "Got it" and "Skip"
        // floating with no words above them.
        Positioned.fill(
          child: CustomSingleChildLayout(
            delegate: _TipPlacement(anchor: rect, safe: MediaQuery.paddingOf(context)),
            child: _TipCard(tip: tip, onGotIt: _dismiss, onSkip: _refuse),
          ),
        ),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip, required this.onGotIt, required this.onSkip});

  final Tip tip;
  final VoidCallback onGotIt;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip.title,
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(tip.body, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Waving this one away is not "never help me again" — but three of them is.
                TextButton(onPressed: onSkip, child: Text(t.tip_skip)),
                TextButton(onPressed: onGotIt, child: Text(t.tip_done)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The Tip for a screen, by anchor. See #62 and ADR-0006.
///
/// One function rather than a list, because these are not a sequence: each screen asks for its
/// own and no screen needs to know the others exist.
Tip? tipFor(AppLocalizations t, String anchorId) => switch (anchorId) {
      TipAnchors.bottomBar => Tip(
          anchorId: TipAnchors.bottomBar,
          title: t.tip_bar_title,
          body: t.tip_bar_body,
        ),
      TipAnchors.hotelResult => Tip(
          anchorId: TipAnchors.hotelResult,
          title: t.tip_hotelResult_title,
          body: t.tip_hotelResult_body,
        ),
      TipAnchors.hotelRooms => Tip(
          anchorId: TipAnchors.hotelRooms,
          title: t.tip_hotelRooms_title,
          body: t.tip_hotelRooms_body,
        ),
      TipAnchors.hotelCheckout => Tip(
          anchorId: TipAnchors.hotelCheckout,
          title: t.tip_hotelCheckout_title,
          body: t.tip_hotelCheckout_body,
        ),
      TipAnchors.flightSearch => Tip(
          anchorId: TipAnchors.flightSearch,
          title: t.tip_flightSearch_title,
          body: t.tip_flightSearch_body,
        ),
      TipAnchors.flightCheckout => Tip(
          anchorId: TipAnchors.flightCheckout,
          title: t.tip_flightCheckout_title,
          body: t.tip_flightCheckout_body,
        ),
      TipAnchors.trips => Tip(
          anchorId: TipAnchors.trips,
          title: t.tip_trips_title,
          body: t.tip_trips_body,
        ),
      _ => null,
    };

/// What Home explains: where the bar takes you. The faces and the search box are the screen's
/// own subject and explain themselves; the bar is the thing a newcomer has no reason to read.
Tip? homeTip(AppLocalizations t) => tipFor(t, TipAnchors.bottomBar);

/// Every Tip, for anything that needs the whole set — a test, or a debug screen.
///
/// A set, not a sequence: there is no order to a Tip, which is the point. Each waits on its
/// own screen and says one thing about what is in front of somebody. An earlier version
/// numbered them "Tip 2 of 7", and that made the help read as a flow the traveller was inside
/// — so Skip looked like it should let them out of it, and leaving them where they stood felt
/// broken. Nothing numbers them now.
const List<String> allTips = [
  TipAnchors.bottomBar,
  TipAnchors.hotelResult,
  TipAnchors.hotelRooms,
  TipAnchors.hotelCheckout,
  TipAnchors.flightSearch,
  TipAnchors.flightCheckout,
  TipAnchors.trips,
];

/// Puts the card beside the thing it describes, and never off the screen.
///
/// A `SingleChildLayoutDelegate` rather than a `Positioned`, for one reason: this is told the
/// card's real height before it has to place it. The arithmetic version assumed 170 logical
/// pixels, and a card with a longer line — or a larger text scale, or a translation — ran past
/// the bottom of the screen. What was left on screen was its last row: "Got it" and "Skip",
/// with nothing above them. That is the bug this exists to make impossible.
class _TipPlacement extends SingleChildLayoutDelegate {
  const _TipPlacement({required this.anchor, required this.safe});

  /// Where the thing being described is, in global coordinates.
  final Rect anchor;

  /// The system insets — status bar, gesture bar — which are not ours to draw in.
  final EdgeInsets safe;

  static const double _margin = 16;
  static const double _gap = 12;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // Width is the screen less a margin either side. Height is loose: the card is as tall as
    // its words, and the placement below copes with whatever that turns out to be.
    final width = constraints.maxWidth - _margin * 2;
    return BoxConstraints(
      minWidth: width,
      maxWidth: width,
      maxHeight: (constraints.maxHeight - safe.vertical - _margin * 2).clamp(0.0, double.infinity),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final top = safe.top + _margin;
    final bottom = size.height - safe.bottom - _margin;

    // Below the anchor if it fits there, above it if it fits there instead. Never over it: a
    // card covering the control it is describing is worse than no card.
    final roomBelow = bottom - (anchor.bottom + _gap);
    final roomAbove = (anchor.top - _gap) - top;

    double y;
    if (childSize.height <= roomBelow) {
      y = anchor.bottom + _gap;
    } else if (childSize.height <= roomAbove) {
      y = anchor.top - _gap - childSize.height;
    } else {
      // Neither side has room — a tall anchor, a small screen, a large text scale. Being
      // readable beats being beside the right thing, so it goes wherever it fits.
      y = roomBelow >= roomAbove ? bottom - childSize.height : top;
    }

    return Offset(_margin, y.clamp(top, (bottom - childSize.height).clamp(top, bottom)));
  }

  @override
  bool shouldRelayout(_TipPlacement old) => old.anchor != anchor || old.safe != safe;
}
