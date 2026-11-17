import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/tips/tip_anchor.dart';
import 'package:cheapest_go_mobile/shared/tips/tip_overlay.dart';
import 'package:cheapest_go_mobile/shared/tips/tip_store.dart';

/// **Tips**: one per screen, non-blocking, after a pause. See #62 and ADR-0006.
///
/// #63 shipped the opposite — a dimmed screen with a cut-out, on app open, only on Home. These
/// are the cases that keep the new rules: the screen underneath stays usable, nothing appears
/// while a screen is still loading, and waving one away does not silence the rest.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TipAnchorRegistry.clear();
    tipStore.debugLoad();
  });

  Future<void> pumpTip(
    WidgetTester tester, {
    required String anchorId,
    bool ready = true,
    bool withAnchor = true,
    VoidCallback? onTapUnderneath,
  }) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(builder: (context) {
        final t = AppLocalizations.of(context)!;
        return TipScope(
          tip: tipFor(t, anchorId),
          ready: ready,
          child: Scaffold(
            body: Center(
              child: withAnchor
                  ? TipAnchor(
                      id: anchorId,
                      child: ElevatedButton(
                        onPressed: onTapUnderneath ?? () {},
                        child: const Text('the control'),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        );
      }),
    ));
    await tester.pump();
  }

  group('when a Tip appears', () {
    testWidgets('after a pause, not on arrival', (tester) async {
      // Material's guidance: a prompt that lands on somebody who opened the app to act is
      // unhelpful. #63 fired on app open; this waits.
      await pumpTip(tester, anchorId: TipAnchors.trips);
      expect(find.text('Everything you book lands here'), findsNothing);

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Everything you book lands here'), findsOneWidget);
    });

    testWidgets('never while the screen is still loading', (tester) async {
      // A Tip over a spinner, describing cards that have not arrived, teaches nothing.
      await pumpTip(tester, anchorId: TipAnchors.hotelResult, ready: false);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.text('Every price is the full price'), findsNothing);
    });

    testWidgets('never when there is nothing to point at', (tester) async {
      await pumpTip(tester, anchorId: TipAnchors.hotelResult, withAnchor: false);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.text('Every price is the full price'), findsNothing);
      // Its turn is kept, not spent: nothing was shown, so nothing was seen.
      expect(tipStore.shouldShow(TipAnchors.hotelResult), isTrue);
    });
  });

  testWidgets('waits for an anchor that arrives late', (tester) async {
    // Home's TipScope sits above the router and mounts while the traveller is still at the
    // sign-in wall, where there is no bottom bar to point at. Looking once found nothing and
    // gave up, so Home showed no Tip at all — on a real handset, after a real sign-up.
    var arrived = false;

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: StatefulBuilder(builder: (context, setState) {
        if (!arrived) {
          Future<void>.delayed(const Duration(minutes: 2), () {
            if (!arrived) setState(() => arrived = true);
          });
        }
        return TipScope(
          tip: tipFor(AppLocalizations.of(context)!, TipAnchors.bottomBar),
          child: Scaffold(
            body: arrived
                ? TipAnchor(
                    id: TipAnchors.bottomBar,
                    child: const SizedBox(height: 60, width: 200),
                  )
                : const SizedBox.shrink(),
          ),
        );
      }),
    ));

    // The pause passes with nothing on screen to point at.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Your trips live here'), findsNothing);

    // Minutes later — a sign-up, a currency, a birth date — the bar turns up, and the Tip
    // is still waiting. An earlier version polled for twenty seconds and had long given up.
    await tester.pump(const Duration(minutes: 3));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Your trips live here'), findsOneWidget);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
  });

  group('it does not get in the way', () {
    testWidgets('the control underneath still takes the tap', (tester) async {
      // The whole difference from #63: no scrim, and the screen keeps working. A tap goes to
      // the button, not to the tip.
      var tapped = false;
      await pumpTip(
        tester,
        anchorId: TipAnchors.trips,
        onTapUnderneath: () => tapped = true,
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Everything you book lands here'), findsOneWidget);

      await tester.tap(find.text('the control'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue, reason: 'the tap must reach the screen underneath');
      // ...and the Tip is still there to be read. Dismissing on any touch is what this did
      // first, and it meant the card vanished on the traveller's next tap before they had
      // read a word of it.
      expect(find.text('Everything you book lands here'), findsOneWidget);
      expect(tipStore.shouldShow(TipAnchors.trips), isTrue);
    });
  });

  group('being waved away', () {
    testWidgets('one Skip ends the whole walkthrough', (tester) async {
      // Skip means the walkthrough, not the card in front of you. It was the other way round
      // until somebody watching it mid-booking asked for a way out that stayed put.
      await pumpTip(tester, anchorId: TipAnchors.hotelResult);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(tipStore.ended, isTrue);
      expect(tipStore.isSilenced, isTrue);
      // Nothing more, on any screen — including the ones never reached.
      expect(tipStore.shouldShow(TipAnchors.hotelCheckout), isFalse);
      expect(tipStore.shouldShow(TipAnchors.flightCheckout), isFalse);
      expect(tipStore.shouldShow(TipAnchors.trips), isFalse);
    });

    testWidgets('Skip is on every Tip, not just the first', (tester) async {
      // Asked for explicitly: a way out has to be there throughout, not only at the start.
      for (final id in [TipAnchors.hotelRooms, TipAnchors.flightCheckout, TipAnchors.trips]) {
        tipStore.debugLoad();
        await pumpTip(tester, anchorId: id);
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        expect(find.text('Skip'), findsOneWidget, reason: '$id offered no way out');
      }
    });

    testWidgets('"Got it" takes the help rather than refusing it', (tester) async {
      await pumpTip(tester, anchorId: TipAnchors.trips);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      expect(tipStore.ended, isFalse, reason: 'reading one is not ending them');
      expect(tipStore.shouldShow(TipAnchors.trips), isFalse);
      // The rest of the walkthrough is still coming.
      expect(tipStore.shouldShow(TipAnchors.hotelResult), isTrue);
    });

    testWidgets('says one thing, with no step counter', (tester) async {
      await pumpTip(tester, anchorId: TipAnchors.hotelRooms);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Numbering made the help read as a flow somebody was inside, so Skip looked like it
      // should let them out of it. No OTA found does this; each Tip is its own hint.
      expect(find.textContaining('Tip 3 of'), findsNothing);
      expect(find.textContaining(' of 7'), findsNothing);
      expect(find.text('Pick a room to continue'), findsOneWidget);
    });
  });

  testWidgets('waits for the account answer, then shows', (tester) async {
    // The anchor is on screen long before the server replies: the Tip is silent until then,
    // and the only thing that could wake it was the anchor appearing — which had already
    // happened. On a handset that meant Home showed nothing at all, with every Tip eligible.
    tipStore.reset(); // signed in, answer not back yet

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(builder: (context) {
        return TipScope(
          tip: tipFor(AppLocalizations.of(context)!, TipAnchors.trips),
          child: Scaffold(
            body: Center(
              child: TipAnchor(
                id: TipAnchors.trips,
                child: const SizedBox(height: 60, width: 200),
              ),
            ),
          ),
        );
      }),
    ));

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Everything you book lands here'), findsNothing);

    // The account's answer arrives: nothing seen, nothing stopped.
    tipStore.debugLoad();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Everything you book lands here'), findsOneWidget);
  });

  group('they belong to the account, not the phone', () {
    test('a different account signing in gets its own', () async {
      // The case that found this: account after account on one handset, and nothing shown.
      // They were stored on the device, so a new sign-in inherited whatever the last person
      // had seen — and whatever they had skipped.
      tipStore.debugLoad(shown: {TipAnchors.hotelResult}, ended: true);
      expect(tipStore.shouldShow(TipAnchors.hotelRooms), isFalse);

      tipStore.reset(); // signed out
      tipStore.debugLoad(); // ...and somebody else signed in
      expect(tipStore.shouldShow(TipAnchors.hotelRooms), isTrue);
      expect(tipStore.ended, isFalse, reason: "one person's Skip is not everybody's");
    });

    test('nothing is offered until the account has answered', () async {
      // Between sign-in and the server replying, showing a Tip would risk repeating help this
      // traveller already dismissed. Silence is the safe side of that.
      tipStore.reset();
      expect(tipStore.isSilenced, isTrue);
      expect(tipStore.shouldShow(TipAnchors.trips), isFalse);
    });
  });

  group('shown once', () {
    testWidgets('a Tip already seen does not come back', (tester) async {
      await tipStore.markShown(TipAnchors.trips);

      await pumpTip(tester, anchorId: TipAnchors.trips);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.text('Everything you book lands here'), findsNothing);
    });
  });

  group('every screen on the way to a booking has one', () {
    test('and golf does not, because golf cannot be booked', () {
      // ADR-0003: a tee time is written to the on-device store and never reaches Trips.
      // Teaching somebody to complete that booking would be teaching a fiction.
      const onTheWay = [
        TipAnchors.hotelResult,
        TipAnchors.hotelRooms,
        TipAnchors.hotelCheckout,
        TipAnchors.flightSearch,
        TipAnchors.flightCheckout,
        TipAnchors.trips,
      ];
      expect(onTheWay.toSet(), hasLength(onTheWay.length), reason: 'ids must be distinct');
    });
  });

  placementTests();
}

/// Where the card lands. See #62 and ADR-0006.
///
/// On a handset these appeared "in random areas", with the words off-screen and only "Got it"
/// and "Skip" visible. The placement assumed the card was 170 logical pixels tall; a longer
/// line, a translation or a larger text scale made it taller, and the rest ran off the bottom.
void placementTests() {
  group('the card stays on screen', () {
    Future<void> pumpAnchoredAt(WidgetTester tester, Alignment where, {double height = 56}) async {
      // A handset, not the 800x600 the test binding defaults to. On that larger surface the
      // old arithmetic happened to fit, which is why nothing caught this before a phone did.
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      tipStore.debugLoad();
      TipAnchorRegistry.clear();

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(builder: (context) {
          return TipScope(
            tip: tipFor(AppLocalizations.of(context)!, TipAnchors.hotelCheckout),
            child: Scaffold(
              body: Align(
                alignment: where,
                child: TipAnchor(
                  id: TipAnchors.hotelCheckout,
                  child: SizedBox(height: height, width: 320),
                ),
              ),
            ),
          );
        }),
      ));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    }

    void expectFullyVisible(WidgetTester tester) {
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;

      // The words, not just the buttons at the card's bottom edge. That was the whole
      // complaint: "some points that i cant see text, only buttons like got it and skip".
      final title = tester.getRect(find.text('Check the total before you pay'));
      expect(title.top, greaterThanOrEqualTo(0.0), reason: 'the title ran off the top');
      expect(title.bottom, lessThanOrEqualTo(screen.height), reason: 'the title ran off the bottom');

      final body = tester.getRect(find.textContaining('This is what will be charged'));
      expect(body.top, greaterThanOrEqualTo(0.0));
      expect(body.bottom, lessThanOrEqualTo(screen.height), reason: 'the body ran off the bottom');

      final skip = tester.getRect(find.text('Skip'));
      expect(skip.bottom, lessThanOrEqualTo(screen.height), reason: 'the buttons ran off');
    }

    testWidgets('anchored at the very bottom', (tester) async {
      // The case from the handset: a checkout button sits at the bottom, so there is no room
      // beneath it and the card has to go above.
      await pumpAnchoredAt(tester, Alignment.bottomCenter);
      expectFullyVisible(tester);
    });

    testWidgets('anchored at the very top', (tester) async {
      await pumpAnchoredAt(tester, Alignment.topCenter);
      expectFullyVisible(tester);
    });

    testWidgets('anchored in the middle', (tester) async {
      await pumpAnchoredAt(tester, Alignment.center);
      expectFullyVisible(tester);
    });

    testWidgets('anchored to something tall that starts at the top', (tester) async {
      // The case from the handset. Trips wraps its whole list, flight search its whole top
      // bar: anchors that are tall and start high. The old formula put the card "above" such
      // an anchor by measuring from its top, which is off the top of the screen — leaving the
      // buttons showing and the words gone.
      await pumpAnchoredAt(tester, Alignment.topCenter, height: 780);
      expectFullyVisible(tester);
    });

    testWidgets('and at a large text scale, where the card grows', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      tipStore.debugLoad();
      TipAnchorRegistry.clear();

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: Builder(builder: (context) {
            return TipScope(
              tip: tipFor(AppLocalizations.of(context)!, TipAnchors.hotelCheckout),
              child: Scaffold(
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: TipAnchor(
                    id: TipAnchors.hotelCheckout,
                    child: const SizedBox(height: 56, width: 320),
                  ),
                ),
              ),
            );
          }),
        ),
      ));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expectFullyVisible(tester);
    });
  });
}
