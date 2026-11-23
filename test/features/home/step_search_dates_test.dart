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
