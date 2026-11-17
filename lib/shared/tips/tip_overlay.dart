import 'dart:async';

import 'package:flutter/material.dart';

import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/coachmarks/coach_mark_store.dart';
import 'package:cheapest_go_mobile/shared/coachmarks/coach_mark_target.dart';

/// One thing the tour points at.
class CoachMark {
  const CoachMark({required this.anchorId, required this.title, required this.body});

  final String anchorId;
  final String title;
  final String body;
}

/// The first-run tour: a dimmed screen with one thing left lit, and a line about it. See #63.
///
/// Coach marks rather than a carousel of slides, because the gate (#62) means somebody now
/// reaches Home having never browsed: they arrive cold where a web visitor would have found
/// their way in by searching. A carousel teaches in the abstract and gets tapped through; this
/// points at the actual control, on the actual screen, while they are looking at it.
///
/// Shown once per device and skippable on every step. It is a help, and a help somebody cannot
/// dismiss is an obstacle.
class CoachMarkOverlay extends StatefulWidget {
  const CoachMarkOverlay({required this.marks, required this.child, super.key});

  final List<CoachMark> marks;
  final Widget child;

  @override
  State<CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<CoachMarkOverlay> {
  /// How long to keep looking for something to point at before giving up.
  ///
  /// The tour is mounted above the router, so it exists before any route does. On the launch
  /// it matters for, the screen it describes is still being built — and worse, the gate (#62)
  /// may put a spinner and a sign-in screen in front of Home first. One look after the first
  /// frame finds nothing and, since nothing notifies this widget when a route lays out, it
  /// would never look again. That is exactly what it did on a handset.
  static const Duration _lookInterval = Duration(milliseconds: 400);
  static const int _maxLooks = 30; // 12 seconds, then stop burning frames.

  int _step = 0;
  bool _ready = false;
  int _looks = 0;
  Timer? _look;

  @override
  void initState() {
    super.initState();
    // After the first frame: anchors have no position until their widgets are laid out, and
    // asking before that gives an empty tour on the very launch it exists for.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      _startLooking();
    });
  }

  void _startLooking() {
    _look?.cancel();
    if (coachMarkStore.seen) return;

    _look = Timer.periodic(_lookInterval, (timer) {
      if (!mounted || coachMarkStore.seen || ++_looks >= _maxLooks) {
        timer.cancel();
        return;
      }
      // Rebuild first, stop second. Stopping on the tick that finds the anchor without
      // rebuilding leaves the tour invisible forever: the thing it was waiting for has
      // arrived and nothing redraws to say so.
      setState(() {});
      if (_anchorIsShowing) timer.cancel();
    });
  }

  bool get _anchorIsShowing =>
      widget.marks.skip(_step).any((m) => CoachMarkRegistry.rectOf(m.anchorId) != null);

  @override
  void dispose() {
    _look?.cancel();
    super.dispose();
  }

  void _next() {
    if (_step + 1 >= widget.marks.length) {
      coachMarkStore.markSeen();
      return;
    }
    setState(() => _step += 1);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: coachMarkStore,
      builder: (context, child) {
        if (coachMarkStore.seen || !_ready) return widget.child;

        // A step whose anchor is not on screen is skipped rather than drawn over nothing.
        // That happens legitimately: the tour starts on Home, and Home does not hold every
        // control it mentions.
        final visible = widget.marks
            .skip(_step)
            .where((m) => CoachMarkRegistry.rectOf(m.anchorId) != null)
            .toList();

        if (visible.isEmpty) return widget.child;

        final mark = visible.first;
        final rect = CoachMarkRegistry.rectOf(mark.anchorId)!;

        return Stack(
          children: [
            widget.child,
            Positioned.fill(
              child: _Scrim(
                rect: rect,
                mark: mark,
                step: widget.marks.indexOf(mark) + 1,
                total: widget.marks.length,
                onNext: _next,
                onSkip: coachMarkStore.markSeen,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Scrim extends StatelessWidget {
  const _Scrim({
    required this.rect,
    required this.mark,
    required this.step,
    required this.total,
    required this.onNext,
    required this.onSkip,
  });

  final Rect rect;
  final CoachMark mark;
  final int step;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;

    // Below the highlight when there is room beneath it, above it otherwise. The card must
    // never cover the thing it is describing, which is the one way a coach mark can be worse
    // than no coach mark at all.
    final below = rect.bottom + 180 < size.height;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Tapping the dimmed area advances, which is what people try first.
          Positioned.fill(
            child: GestureDetector(
              onTap: onNext,
              child: CustomPaint(painter: _CutOutPainter(rect)),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: below ? rect.bottom + 16 : null,
            bottom: below ? null : size.height - rect.top + 16,
            child: _Caption(
              mark: mark,
              step: step,
              total: total,
              isLast: step == total,
              onNext: onNext,
              onSkip: onSkip,
              nextLabel: step == total ? t.coach_done : t.coach_next,
              skipLabel: t.coach_skip,
              stepLabel: t.coach_step(step, total),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dims everything, then clears a rounded window over the thing being pointed at.
class _CutOutPainter extends CustomPainter {
  const _CutOutPainter(this.rect);

  final Rect rect;

  @override
  void paint(Canvas canvas, Size size) {
    final hole = RRect.fromRectAndRadius(rect.inflate(8), const Radius.circular(16));

    // Even-odd so the hole is genuinely transparent rather than painted lighter: the control
    // underneath should look exactly as it does normally, because that is what somebody has
    // to recognise again a moment later.
    final scrim = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(hole),
    );

    canvas.drawPath(scrim, Paint()..color = const Color(0xCC0B1220));
    canvas.drawRRect(
      hole,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF2563EB),
    );
  }

  @override
  bool shouldRepaint(_CutOutPainter old) => old.rect != rect;
}

class _Caption extends StatelessWidget {
  const _Caption({
    required this.mark,
    required this.step,
    required this.total,
    required this.isLast,
    required this.onNext,
    required this.onSkip,
    required this.nextLabel,
    required this.skipLabel,
    required this.stepLabel,
  });

  final CoachMark mark;
  final int step;
  final int total;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final String nextLabel;
  final String skipLabel;
  final String stepLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(stepLabel, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Text(
              mark.title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(mark.body, style: TextStyle(fontSize: 13.5, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Always there, on every step. A tour you cannot leave is not a help.
                TextButton(onPressed: onSkip, child: Text(skipLabel)),
                FilledButton(onPressed: onNext, child: Text(nextLabel)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// What the first-run tour says, in order. See #63.
///
/// Three, and no more: each one points at something on screen and says what it is for. The
/// order follows what somebody does — choose what they are looking for, search for it, then
/// find it again afterwards.
List<CoachMark> coachMarksFor(AppLocalizations t) => [
      CoachMark(
        anchorId: CoachMarkIds.searchFaces,
        title: t.coach_faces_title,
        body: t.coach_faces_body,
      ),
      CoachMark(
        anchorId: CoachMarkIds.searchStart,
        title: t.coach_search_title,
        body: t.coach_search_body,
      ),
      CoachMark(
        anchorId: CoachMarkIds.bottomBar,
        title: t.coach_bar_title,
        body: t.coach_bar_body,
      ),
    ];
