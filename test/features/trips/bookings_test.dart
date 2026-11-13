import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/features/trips/api/api_bookings_source.dart';
import 'package:cheapest_go_mobile/features/trips/api/bookings_source.dart';
import 'package:cheapest_go_mobile/features/trips/api/mock_bookings_source.dart';
import 'package:cheapest_go_mobile/features/trips/lib/booking_search.dart';
import 'package:cheapest_go_mobile/features/trips/lib/travel_documents.dart';
import 'package:cheapest_go_mobile/features/trips/models/trip_booking.dart';
import 'package:cheapest_go_mobile/shared/lib/http.dart';

/// The rules behind My Bookings. See #42 and ADR-0003.
void main() {
  group('search', () {
    test('every word has to appear, so a second word narrows', () {
      const text = 'bayside grand manila standard double room cg-y7yy3k';
      expect(matchesTerms(text, queryTerms('manila')), isTrue);
      expect(matchesTerms(text, queryTerms('manila double')), isTrue);
      expect(matchesTerms(text, queryTerms('manila cebu')), isFalse);
    });

    test('accents are ignored, so cebu finds Cebú', () {
      expect(fold('Cebú Harbour'), 'cebu harbour');
      expect(matchesTerms(fold('Cebú Harbour Suites'), queryTerms('cebu')), isTrue);
    });

    test('a reference or a route typed whole still finds itself', () {
      // Dashes and arrows separate words, so both halves have to be present.
      expect(queryTerms('CG-AB12CD'), ['cg', 'ab12cd']);
      expect(queryTerms('MNL → ICN'), ['mnl', 'icn']);
      expect(matchesTerms(fold('MNL ICN ZZ 2036'), queryTerms('MNL-ICN')), isTrue);
    });

    test('an empty query narrows nothing', () {
      expect(queryTerms('   '), isEmpty);
      expect(matchesTerms('anything', queryTerms('')), isTrue);
    });
  });

  group('travel documents', () {
    final ticketed = MockBookingsSource.flights.first;
    final unticketed = MockBookingsSource.flights.last;
    final confirmedStay = MockBookingsSource.hotels.first;
    final cancelledStay = MockBookingsSource.hotels.last;

    test('a PNR is not a ticket: no e-ticket until the airline issues one', () {
      expect(isTicketed(unticketed), isFalse,
          reason: 'it has a PNR and nothing else');
      expect(availableDocuments(unticketed), [TravelDocument.receipt]);
      expect(pendingReason(unticketed), DocumentPending.awaitingTicket);

      expect(isTicketed(ticketed), isTrue);
      expect(availableDocuments(ticketed), contains(TravelDocument.eticket));
      expect(pendingReason(ticketed), isNull);
    });

    test('a confirmed stay earns a voucher; an unconfirmed one says why not', () {
      expect(availableDocuments(confirmedStay), contains(TravelDocument.voucher));

      final pending = HotelStayBooking(
        id: 'x', reference: 'CG-X', status: 'pending',
        propertyName: 'P', roomName: 'R',
        checkIn: DateTime(2026), checkOut: DateTime(2026, 1, 2),
        totalPaid: 1, currency: 'USD', searchText: '',
      );
      expect(availableDocuments(pending), isNot(contains(TravelDocument.voucher)));
      expect(pendingReason(pending), DocumentPending.awaitingConfirmation);
    });

    test('a cancelled booking keeps its receipt and loses the rest', () {
      // Paid is paid: a refund is a second entry on the record, not a reason to withdraw
      // the evidence of the first.
      expect(availableDocuments(cancelledStay), [TravelDocument.receipt]);
      expect(pendingReason(cancelledStay), isNull);
    });
  });

  group('the mock source', () {
    test('covers each kind, and golf is reported separately', () async {
      final page = await const MockBookingsSource().myBookings();
      expect(page.bookings.whereType<HotelStayBooking>(), isNotEmpty);
      expect(page.bookings.whereType<FlightTripBooking>(), isNotEmpty);
      expect(page.golf, isNotEmpty);
      expect(page.golfFailed, isFalse);
    });

    test('the list is newest first, whichever kind', () async {
      final page = await const MockBookingsSource().myBookings();
      final dates = page.all.map((b) => b.bookedAt!).toList();
      expect(dates, [...dates]..sort((a, b) => b.compareTo(a)));
    });

    test('a lapsed hold is never described as paid', () {
      final held = GolfTeeTimeBooking(
        reference: 'CG-H', status: 'held', players: 1, leadName: 'A',
        contactEmail: 'a@b.c', totalPaid: 10, currency: 'USD', searchText: '',
        startsAt: DateTime(2026), courseName: 'C',
      );
      expect(held.wasCharged, isFalse);
      expect(MockBookingsSource.golf.first.wasCharged, isTrue,
          reason: 'cancelled after payment, so money did move');
    });
  });

  group('the api source', () {
    test('reads api-v2 rows, including a Decimal that arrives as a string', () async {
      final source = ApiBookingsSource(client: _FakeHttp({
        '/api/v2/bookings': {
          'success': true,
          'data': [
            {
              'type': 'hotel',
              'id': 'row-1',
              'booking_id': 'CG-ABC12',
              'property_name': 'Bayside Grand Manila',
              'room_name': 'Standard Double Room',
              'check_in': '2026-11-27',
              'check_out': '2026-11-28',
              'guests_adults': 2,
              // Prisma sends a Decimal column as a string.
              'total_price': '138.00',
              'currency': 'usd',
              'holder_first_name': 'Billy',
              'holder_last_name': 'Busilan',
              'holder_email': 'a@b.c',
              'status': 'confirmed',
              'policy_type': 'free_cancellation',
              'provider_metadata': {'supplierRef': 'OTV-9'},
              'created_at': '2026-11-13T01:30:00.000Z',
            },
          ],
        },
        '/api/v2/golf/bookings': {'success': true, 'data': []},
      }));

      final page = await source.myBookings();
      final stay = page.bookings.single as HotelStayBooking;
      expect(stay.id, 'row-1');
      expect(stay.reference, 'CG-ABC12');
      expect(stay.totalPaid, 138);
      expect(stay.currency, 'USD');
      expect(stay.nights, 1);
      expect(stay.refundable, isTrue);
      // The supplier's reference, not ours: it is the one a front desk can look up.
      expect(stay.supplierReference, 'OTV-9');
      expect(matchesTerms(stay.searchText, queryTerms('bayside')), isTrue);
      expect(matchesTerms(stay.searchText, queryTerms('OTV-9')), isTrue);
    });

    test('a golf outage costs the golf rows and nothing else', () async {
      final source = ApiBookingsSource(client: _FakeHttp({
        '/api/v2/bookings': {
          'success': true,
          'data': [
            {
              'type': 'flight',
              'id': 'row-2',
              'pnr': '4SDPCA',
              'total_price': 224,
              'currency': 'USD',
              'status': 'ticketed',
              'flight_segments': [
                {
                  'airline': 'ZZ', 'flight_number': '2036',
                  'origin': 'MNL', 'destination': 'ICN',
                  'departure': '2026-11-26T11:21:00.000Z',
                  'arrival': '2026-11-26T16:24:00.000Z',
                },
              ],
            },
          ],
        },
        // Golf throws.
        '/api/v2/golf/bookings': null,
      }));

      final page = await source.myBookings();
      expect(page.bookings, hasLength(1), reason: 'the flight still arrived');
      expect(page.golf, isEmpty);
      expect(page.golfFailed, isTrue, reason: 'missing is not the same as none');
    });

    test('a 401 asks the traveller to sign in rather than reporting a fault', () async {
      final source = ApiBookingsSource(client: _FakeHttp(const {}, status: 401));
      expect(source.myBookings(), throwsA(isA<NotSignedIn>()));
    });

    test('an unreadable body is an error, but an empty list is an answer', () async {
      final empty = ApiBookingsSource(client: _FakeHttp({
        '/api/v2/bookings': {'success': true, 'data': []},
        '/api/v2/golf/bookings': {'success': true, 'data': []},
      }));
      expect((await empty.myBookings()).all, isEmpty);

      final nonsense = ApiBookingsSource(client: _FakeHttp({
        '/api/v2/bookings': {'unexpected': true},
        '/api/v2/golf/bookings': {'success': true, 'data': []},
      }));
      expect(nonsense.myBookings(), throwsA(isA<Exception>()));
    });
  });
}

/// api-v2, answering from a map. A null answer throws, which is how the golf outage is driven.
class _FakeHttp implements HttpClientAdapter {
  _FakeHttp(this.answers, {this.status = 200});

  final Map<String, Object?> answers;
  final int status;

  @override
  Future<dynamic> get(String url, {HttpRequestOptions? options}) async {
    if (status == 401) throw Exception('HTTP 401 Unauthorized');
    final answer = answers[url];
    if (answer == null) throw Exception('no answer for $url');
    return answer;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
