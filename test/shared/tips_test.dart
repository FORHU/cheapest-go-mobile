import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cheapest_go_mobile/shared/coachmarks/coach_mark_overlay.dart';
import 'package:cheapest_go_mobile/shared/coachmarks/coach_mark_store.dart';
import 'package:cheapest_go_mobile/shared/coachmarks/coach_mark_target.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';

/// The first-run tour. See #63.
///
/// It exists because the gate (#62) means somebody reaches Home without having browsed first,
/// so they arrive where a web visitor would already have found their way around. These cases
/// are the ones that keep it a help rather than an obstacle: it shows once, it can always be
/// left, and it never points at something that is not on screen.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CoachMarkRegistry.clear();
  });

  Future<void> pumpTour(
    WidgetTester tester, {
    required List<String> anchors,
    List<CoachMark>? marks,
  }) async {
    await coachMarkStore.reset();

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(builder: (context) {
        final t = AppLocalizations.of(context)!;
        return CoachMarkOverlay(
          marks: marks ?? coachMarksFor(t),
          child: Scaffold(
            body: Column(
              children: [
                for (final id in anchors)
                  CoachMarkTarget(id: id, child: SizedBox(height: 60, child: Text(id))),
              ],
            ),
          ),
        );
      }),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('walks the three tips in order and then stops for good', (tester) async {
    await pumpTour(tester, anchors: [
      CoachMarkIds.searchFaces,
      CoachMarkIds.searchStart,
      CoachMarkIds.bottomBar,
    ]);

    expect(find.text('Three ways to travel'), findsOneWidget);
    expect(find.text('Tip 1 of 3'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Search in three steps'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Your trips live here'), findsOneWidget);
    // The last step says "Got it", not "Next": there is nothing after it.
    expect(find.text('Got it'), findsOneWidget);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Your trips live here'), findsNothing);
    expect(coachMarkStore.seen, isTrue);
  });

  testWidgets('can be left on the first step', (tester) async {
    // A tour nobody can dismiss is an obstacle, so Skip is on every step and not only the last.
    await pumpTour(tester, anchors: [CoachMarkIds.searchFaces, CoachMarkIds.bottomBar]);

    expect(find.text('Skip'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Three ways to travel'), findsNothing);
    expect(coachMarkStore.seen, isTrue);
  });

  testWidgets('does not run again once it has been seen', (tester) async {
    SharedPreferences.setMockInitialValues({'flutter.cheapestgo_coach_marks_seen': true});
    await coachMarkStore.init();

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(builder: (context) {
        return CoachMarkOverlay(
          marks: coachMarksFor(AppLocalizations.of(context)!),
          child: Scaffold(
            body: CoachMarkTarget(
              id: CoachMarkIds.searchFaces,
              child: const SizedBox(height: 60),
            ),
          ),
        );
      }),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Three ways to travel'), findsNothing);
  });

  testWidgets('skips a tip whose anchor is not on screen', (tester) async {
    // Legitimate: the tour starts on Home, and Home does not hold every control it mentions.
    // Drawing a highlight over nothing is the failure this prevents.
    await pumpTour(tester, anchors: [CoachMarkIds.bottomBar]);

    expect(find.text('Three ways to travel'), findsNothing, reason: 'its anchor is absent');
    expect(find.text('Your trips live here'), findsOneWidget);
    expect(find.text('Tip 3 of 3'), findsOneWidget, reason: 'the number is the real position');
  });

  testWidgets('shows nothing at all when no anchor is on screen', (tester) async {
    await pumpTour(tester, anchors: []);

    expect(find.text('Skip'), findsNothing);
    expect(coachMarkStore.seen, isFalse, reason: 'not seen — it never ran');
  });

  testWidgets('tapping the dimmed area advances, which is what people try first', (tester) async {
    await pumpTour(tester, anchors: [CoachMarkIds.searchFaces, CoachMarkIds.bottomBar]);

    expect(find.text('Three ways to travel'), findsOneWidget);
    // The top-left corner is scrim, never the highlight or the card.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.text('Your trips live here'), findsOneWidget);
  });

  testWidgets('waits for a screen that arrives late', (tester) async {
    // The tour is mounted above the router, so it exists before any route does. On the launch
    // it matters for, the gate (#62) shows a spinner and a sign-in screen before Home ever
    // lays out. Looking once and giving up is what it did on a handset: no tour at all.
    await coachMarkStore.reset();
    var arrived = false;

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: StatefulBuilder(builder: (context, setState) {
        if (!arrived) {
          Future<void>.delayed(const Duration(milliseconds: 600), () {
            if (!arrived) setState(() => arrived = true);
          });
        }
        return CoachMarkOverlay(
          marks: coachMarksFor(AppLocalizations.of(context)!),
          child: Scaffold(
            body: arrived
                ? CoachMarkTarget(
                    id: CoachMarkIds.searchFaces,
                    child: const SizedBox(height: 60),
                  )
                : const SizedBox.shrink(),
          ),
        );
      }),
    ));

    await tester.pump();
    expect(find.text('Three ways to travel'), findsNothing, reason: 'nothing to point at yet');

    // The screen turns up a moment later, and the tour notices rather than having given up.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Three ways to travel'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
  });

  group('the registry', () {
    testWidgets('forgets an anchor whose widget has gone', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: CoachMarkTarget(id: 'x', child: const SizedBox(height: 10)),
      ));
      expect(CoachMarkRegistry.rectOf('x'), isNotNull);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      expect(CoachMarkRegistry.rectOf('x'), isNull);
    });

    testWidgets('an unknown id has no position rather than a wrong one', (tester) async {
      expect(CoachMarkRegistry.rectOf('nobody.registered.this'), isNull);
    });
  });
}
