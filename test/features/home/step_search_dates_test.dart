import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/features/home/components/stage_chrome.dart';
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

  /// #76, reported as "limited to 2 days": a third tap used to throw the range away, so
  /// anyone lengthening a stay they had already picked landed back on a single day.
  testWidgets('a stay can run longer than the two days first picked', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(StepMode.stays));

    await tester.enterText(find.byType(TextField), 'Manila');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(PlaceRow));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next: dates'));
    await tester.pumpAndSettle();

    // Next month, so every day of it is in the future and in one view whatever today is.
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    final month = DateTime(now.year, now.month + 1);

    // Scoped to the calendar: the step trail numbers its steps 1, 2, 3, and an unscoped
    // `find.text('5')` would be ambiguous the moment a month's day collides with one.
    Finder day(int n) => find.descendant(
      of: find.byType(MonthCalendar),
      matching: find.text('$n'),
    );

    // Three days apart each, so the taps cannot be read as one range by accident.
    for (final n in [5, 8, 11]) {
      await tester.ensureVisible(day(n));
      await tester.tap(day(n));
      await tester.pumpAndSettle();
    }

    final range = tester
        .widget<MonthCalendar>(find.byType(MonthCalendar))
        .range!;
    expect(range.start, DateTime(month.year, month.month, 5));
    expect(
      range.end,
      DateTime(month.year, month.month, 11),
      reason: 'the third tap extends the stay instead of starting over',
    );
    expect(range.duration.inDays, 6, reason: 'six nights, not two');
  });

  /// #78: the primary action used to be greyed out until the step was answered, which reads
  /// as a broken button. It stays live and says what it wants instead.
  testWidgets('Next on an unanswered step asks for the answer, not nothing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(StepMode.stays));

    expect(
      tester.widget<GradientPill>(find.byType(GradientPill)).onPressed,
      isNotNull,
      reason: 'a disabled primary action cannot say why it is disabled',
    );

    await tester.tap(find.text('Next: dates'));
    await tester.pumpAndSettle();

    // Still being asked where, and the cursor is in the field that answers it.
    expect(find.text('Where do you want to stay?'), findsOneWidget);
    expect(find.byType(MonthCalendar), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).focusNode?.hasFocus,
      isTrue,
    );
  });

  testWidgets('one-way flight search keeps only the last picked date', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: StepSearch(mode: StepMode.flights),
          ),
        ),
      ),
    );

    await tester.tap(find.text('One-way'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next: departure'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Manila');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(PlaceRow));
    await tester.pumpAndSettle();
    expect(find.textContaining('selected'), findsOneWidget);
    await tester.tap(find.text('Next: destination'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Seoul');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(PlaceRow));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next: dates'));
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final first = DateTime(now.year, now.month, now.day + 3);
    final second = first.add(const Duration(days: 2));
    if (second.month != now.month) {
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
    }

    await tester.ensureVisible(find.text('${first.day}'));
    await tester.tap(find.text('${first.day}'));
    await tester.ensureVisible(find.text('${second.day}'));
    await tester.tap(find.text('${second.day}'));
    await tester.pumpAndSettle();

    final range = tester
        .widget<MonthCalendar>(find.byType(MonthCalendar))
        .range!;
    expect(range.start, DateUtils.dateOnly(second));
    expect(range.end, DateUtils.dateOnly(second));
  });
}
