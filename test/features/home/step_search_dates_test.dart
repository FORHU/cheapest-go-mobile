import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/features/home/components/step_parts.dart';
import 'package:cheapest_go_mobile/features/home/components/step_search.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/search/destinations_api.dart';
import 'package:cheapest_go_mobile/app/theme/app_theme.dart';

class _AirportApi extends DestinationsApi {
  @override
  Future<List<DestinationSuggestion>> search(
    String query, {
    bool forFlights = false,
    int limit = 8,
  }) async => [
    DestinationSuggestion(
      id: query,
      kind: DestinationKind.airport,
      name: query,
      city: query,
      iata: query == 'Manila' ? 'MNL' : 'ICN',
    ),
  ];
}

void main() {
  late DestinationsApi original;

  setUp(() {
    original = destinationsApi;
    destinationsApi = _AirportApi();
  });

  tearDown(() => destinationsApi = original);

  Widget app(StepMode mode) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    theme: AppTheme.light,
    home: Scaffold(
      body: SingleChildScrollView(child: StepSearch(mode: mode)),
    ),
  );

  /// A place step's forward action lives at the end of the search field (#85), so it is
  /// reached by its arrow rather than by the label the pill below used to carry.
  Finder fieldAction() => find
      .ancestor(
        of: find.byIcon(Icons.arrow_forward_rounded),
        matching: find.byType(InkWell),
      )
      .first;

  bool actionIsLive(WidgetTester tester) =>
      tester.widget<InkWell>(fieldAction()).onTap != null;

  Future<void> tapAction(WidgetTester tester) async {
    await tester.tap(fieldAction());
    await tester.pumpAndSettle();
  }

  Future<void> pickPlace(WidgetTester tester, String name) async {
    await tester.enterText(find.byType(TextField), name);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(PlaceRow));
    await tester.pumpAndSettle();
  }

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  /// Next month, so every day of it is in the future and in one view whatever today is.
  DateTime nextMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1);
  }

  /// Scoped to the calendar: the step trail numbers its steps 1, 2, 3, and an unscoped
  /// `find.text('5')` would be ambiguous the moment a day collides with one.
  Finder day(int n) => find.descendant(
    of: find.byType(MonthCalendar),
    matching: find.text('$n'),
  );

  DateTimeRange? chosenRange(WidgetTester tester) =>
      tester.widget<MonthCalendar>(find.byType(MonthCalendar)).range;

  /// #85: an empty field is a question nobody has asked yet, so there is nothing to carry
  /// forward. Typing makes the action live even before anything has been chosen.
  testWidgets('the search field action is dead until something is typed', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(app(StepMode.stays));

    expect(actionIsLive(tester), isFalse, reason: 'nothing has been asked for');

    await tester.enterText(find.byType(TextField), 'Man');
    await tester.pump(const Duration(milliseconds: 300));
    expect(actionIsLive(tester), isTrue, reason: 'a question has been asked');

    await tester.enterText(find.byType(TextField), '');
    await tester.pump(const Duration(milliseconds: 300));
    expect(actionIsLive(tester), isFalse, reason: 'and withdrawn again');
  });

  /// #78: typed text with nothing chosen is not the same as an empty field. The action is
  /// live, and pressing it says what is still wanted instead of going quiet.
  testWidgets('pressing it with nothing chosen asks for the answer', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(app(StepMode.stays));

    await tester.enterText(find.byType(TextField), 'Manila');
    await tester.pump(const Duration(milliseconds: 300));
    await tapAction(tester);

    expect(find.text('Where do you want to stay?'), findsOneWidget);
    expect(find.byType(MonthCalendar), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).focusNode?.hasFocus,
      isTrue,
    );
  });

  /// #84: the destination used to outlive the text that chose it. Clearing the field left
  /// the choice holding Manila, so the next press searched a place no longer on screen.
  testWidgets('clearing the field forgets the place that was chosen', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(app(StepMode.stays));

    await pickPlace(tester, 'Manila');
    expect(find.textContaining('selected'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('selected'), findsNothing);
    expect(actionIsLive(tester), isFalse);

    // Re-typing the same letters does not bring the old answer back: it has to be chosen
    // again, which is the difference between the field and the answer.
    await tester.enterText(find.byType(TextField), 'Manila');
    await tester.pump(const Duration(milliseconds: 300));
    await tapAction(tester);

    expect(find.byType(MonthCalendar), findsNothing, reason: 'still unanswered');
  });

  /// #76, reported as "limited to 2 days": a third tap used to throw the range away, so
  /// anyone lengthening a stay they had already picked landed back on a single day.
  testWidgets('a stay can run longer than the two days first picked', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(app(StepMode.stays));

    await pickPlace(tester, 'Manila');
    await tapAction(tester);

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    final month = nextMonth();

    // Three days apart each, so the taps cannot be read as one range by accident.
    for (final n in [5, 8, 11]) {
      await tester.ensureVisible(day(n));
      await tester.tap(day(n));
      await tester.pumpAndSettle();
    }

    final range = chosenRange(tester)!;
    expect(range.start, DateTime(month.year, month.month, 5));
    expect(
      range.end,
      DateTime(month.year, month.month, 11),
      reason: 'the third tap extends the stay instead of starting over',
    );
    expect(range.duration.inDays, 6, reason: 'six nights, not two');

    // #83: tapping the day it starts on takes the stay back off.
    await tester.tap(day(5));
    await tester.pumpAndSettle();
    expect(chosenRange(tester), isNull);
  });

  /// #83 on its own: one day chosen, the same day tapped again, nothing chosen. Dates are
  /// optional on this step, so having picked one and changed your mind there has to be a
  /// way back to none.
  testWidgets('a single chosen day is cleared by tapping it again', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(app(StepMode.stays));

    await pickPlace(tester, 'Manila');
    await tapAction(tester);
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();

    await tester.tap(day(9));
    await tester.pumpAndSettle();
    expect(chosenRange(tester), isNotNull);

    await tester.tap(day(9));
    await tester.pumpAndSettle();
    expect(chosenRange(tester), isNull);
  });

  testWidgets('one-way flight search keeps only the last picked date', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(app(StepMode.flights));

    await tester.tap(find.text('One-way'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next: departure'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    await pickPlace(tester, 'Manila');
    expect(find.textContaining('selected'), findsOneWidget);
    await tapAction(tester);

    await pickPlace(tester, 'Seoul');
    await tapAction(tester);

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();

    await tester.tap(day(5));
    await tester.pumpAndSettle();
    await tester.tap(day(7));
    await tester.pumpAndSettle();

    final month = nextMonth();
    final range = chosenRange(tester)!;
    expect(range.start, DateTime(month.year, month.month, 7));
    expect(range.end, DateTime(month.year, month.month, 7));
  });
}
