import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/features/hotels/components/room_selection.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';

/// A Room is a card and its Offers are the rows in it. See #40, and ADR-0007 in the web repo.
///
/// The failure this guards against is quiet: showing one price per room looks tidy and
/// withdraws the refundable rate from sale, so a traveller who would have paid more for the
/// right to cancel never learns it was for sale.
void main() {
    Offer offer({
        required String id,
        required int price,
        String board = 'Room only',
        bool refundable = false,
        String? bed,
        List<String> terms = const [],
        DateTime? deadline,
    }) =>
        Offer(
            offerId: id,
            nightlyRate: price,
            stayTotal: price,
            currency: 'PHP',
            boardName: board,
            refundable: refundable,
            bed: bed,
            terms: terms,
            cancellationDeadline: deadline,
        );

    Room room(List<Offer> offers) => Room(
        id: 'r1',
        name: 'Deluxe Twin room',
        meta: offers.first.boardName,
        nightlyRate: offers.first.nightlyRate,
        offers: offers,
    );

    Future<void> pump(WidgetTester tester, List<Room> rooms, {String? selected, void Function(Offer)? onSelect}) async {
        tester.view.physicalSize = const Size(390 * 3, 844 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: AppTheme.light,
            home: Scaffold(
                body: SingleChildScrollView(
                    child: RoomSelection(
                        rooms: rooms,
                        currency: 'PHP',
                        selectedOfferId: selected,
                        onSelect: onSelect ?? (_) {},
                    ),
                ),
            ),
        ));
        await tester.pump();
    }

    testWidgets('one card for the room, one row for each way to buy it', (tester) async {
        await pump(tester, [
            room([
                offer(id: 'nrfn', price: 2425),
                offer(id: 'rfn', price: 3173, refundable: true),
            ]),
        ]);

        expect(find.text('Deluxe Twin room'), findsOneWidget, reason: 'one card, not two');
        expect(find.text('Free cancellation'), findsOneWidget);
        expect(find.text('Non-refundable'), findsOneWidget);
        expect(find.textContaining('2,425'), findsOneWidget);
        expect(find.textContaining('3,173'), findsOneWidget, reason: 'the refundable rate is on sale');
    });

    testWidgets('says what differs between two offers that share a board', (tester) async {
        // Two rows reading "Room only" at different prices tell a reader there is a
        // difference and refuse to say what it is. Whichever attribute varies is printed.
        await pump(tester, [
            room([
                offer(id: 'twin', price: 2000, bed: 'twin beds'),
                offer(id: 'double', price: 2200, bed: 'full double bed'),
            ]),
        ]);

        expect(find.text('twin beds'), findsOneWidget);
        expect(find.text('full double bed'), findsOneWidget);
    });

    testWidgets('carries the qualifier chip the supplier hid in the room name', (tester) async {
        await pump(tester, [
            room([offer(id: 'unsure', price: 2000, terms: ['bed not guaranteed'])]),
        ]);

        expect(find.text('bed not guaranteed'), findsOneWidget);
    });

    testWidgets('names the day free cancellation ends', (tester) async {
        await pump(tester, [
            room([
                offer(
                    id: 'rfn',
                    price: 3173,
                    refundable: true,
                    deadline: DateTime.utc(2026, 11, 18, 10),
                ),
            ]),
        ]);

        expect(find.textContaining('Free until Nov 18'), findsOneWidget);
    });

    testWidgets('picking an offer reports that offer, not the room', (tester) async {
        Offer? picked;
        await pump(
            tester,
            [
                room([
                    offer(id: 'nrfn', price: 2425),
                    offer(id: 'rfn', price: 3173, refundable: true),
                ]),
            ],
            onSelect: (o) => picked = o,
        );

        await tester.tap(find.text('Free cancellation'));
        await tester.pump();

        expect(picked?.offerId, 'rfn');
    });

    testWidgets('a room with no offers of its own is still bookable', (tester) async {
        // The bundled fixtures and any disk cache written before #40 carry no Offers; the
        // room's own nightly rate stands as one rather than leaving the card unbuyable.
        await pump(tester, [
            const Room(id: 'fixture', name: 'Standard Room', meta: 'Room only', nightlyRate: 4400),
        ]);

        expect(find.text('Standard Room'), findsOneWidget);
        expect(find.textContaining('4,400'), findsOneWidget);
    });
}
