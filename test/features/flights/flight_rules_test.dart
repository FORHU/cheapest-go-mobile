import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http_pkg;
import 'package:http/testing.dart';

import 'package:cheapest_go_mobile/features/flights/lib/filter_offers.dart';
import 'package:cheapest_go_mobile/features/flights/lib/flight_search_query.dart';
import 'package:cheapest_go_mobile/features/flights/lib/flight_utils.dart';
import 'package:cheapest_go_mobile/features/flights/lib/passengers.dart';
import 'package:cheapest_go_mobile/features/flights/models/flight_fare.dart';
import 'package:cheapest_go_mobile/shared/errors/api_error.dart';
import 'package:cheapest_go_mobile/shared/lib/http.dart';

import 'fixtures.dart';

void main() {
  group('FlightFare reads api-v2\'s Duffel offer', () {
    test('as the live search returns it', () {
      final o = FlightFare.tryParse(offerJson())!;
      expect(o.offerId, 'off_034wAvwB5YwUzZRDSUHUOW');
      expect(o.provider, 'duffel');
      expect(o.price.total, 116.17);
      expect(o.price.currency, 'USD');
      expect(o.segments.single.airline, 'ZZ');
      expect(o.segments.single.airlineName, 'Duffel Airways');
      expect(o.segments.single.departure?.terminal, '2');
      expect(o.baggage?.cabinBag, isTrue);
      expect(o.baggage?.checkedBags, 1);
      expect(o.farePolicy, isNull);
      expect(o.refundable, isTrue);
      // Kept whole: `/flights/revalidate` takes the offer back as it came.
      expect(o.raw['_rawOffer'], {'id': 'off_034wAvwB5YwUzZRDSUHUOW'});
    });

    test('refuses an offer with no price or no flights rather than inventing one', () {
      expect(FlightFare.tryParse({...offerJson(), 'price': null}), isNull);
      expect(FlightFare.tryParse({...offerJson(), 'segments': <Object>[]}), isNull);
    });

    test('a re-quoted fare keeps everything but the total', () {
      final o = FlightFare.tryParse(offerJson())!.withTotal(120);
      expect(o.price.total, 120);
      expect(o.raw['price']['total'], 120);
      expect(o.offerId, 'off_034wAvwB5YwUzZRDSUHUOW');
    });
  });

  group('Local Airport Time is read from the digits, never converted', () {
    test('formatTime', () {
      expect(formatTime('2026-12-03T01:32:00'), '01:32');
      expect(formatTime('2026-12-03T23:05'), '23:05');
      expect(formatTime(null), '--:--');
      expect(formatTime('garbage'), '--:--');
    });

    test('dayOffset is whole calendar days', () {
      expect(dayOffset('2026-12-03T23:30:00', '2026-12-04T05:00:00'), 1);
      expect(dayOffset('2026-12-03T01:00:00', '2026-12-03T05:00:00'), 0);
    });

    test('layoverMinutes', () {
      expect(layoverMinutes('2026-12-03T03:00:00', '2026-12-03T04:10:00'), 70);
      expect(layoverMinutes('2026-12-03T04:10:00', '2026-12-03T03:00:00'), isNull);
    });

    test('durations, cabins and airports as V2 prints them', () async {
      // , not the deleted : one way to name a cabin, in the app's
      // own language rather than title-cased English.
      final t = await AppLocalizations.delegate.load(const Locale('en'));
      expect(formatDuration(225), '3h 45m');
      expect(formatDuration(45), '45m');
      expect(cabinName(t, 'premium_economy'), 'Premium economy');
      expect(
        airportLabel(const SegmentEnd(airport: 'SIN', airportName: 'Singapore Changi Airport'), 'SIN'),
        'Singapore Changi Airport (SIN)',
      );
      expect(airportLabel(null, 'SIN'), 'SIN');
      expect(checkoutMoney(8108.79, 'PHP'), 'PHP 8,108.79');
      expect(checkoutMoney(287730, 'KRW'), 'KRW 287,730');
    });
  });

  group('filter-offers', () {
    final offers = sampleOffers();

    test('the cheapest and the fastest are marked, one mark each', () {
      final marks = offerHighlights(offers);
      expect(marks[offers[1]], OfferHighlight.cheapest); // Duffel Airways, $116.17, 3h 45m
      expect(marks[offers[0]], OfferHighlight.fastest); // PAL, 3h 35m
      expect(marks[offers[2]], isNull);
    });

    test('a list of one has nothing to be compared with', () {
      expect(offerHighlights([offers.first]), isEmpty);
    });

    test('stops count plane changes per direction; 2 means two or more', () {
      expect(applyFlightFilters(offers, const FlightFilterState(stops: 0)).map((o) => o.offerId), [
        'off_duffel',
        'off_pal',
      ]);
      expect(applyFlightFilters(offers, const FlightFilterState(stops: 1)).map((o) => o.offerId), ['off_sq']);
      expect(applyFlightFilters(offers, const FlightFilterState(stops: 2)), isEmpty);
    });

    test('sorts cheapest first by default and keeps ties in the API\'s order', () {
      expect(applyFlightFilters(offers, defaultFlightFilters).map((o) => o.offerId), [
        'off_duffel',
        'off_sq',
        'off_pal',
      ]);
      final tied = [
        FlightFare.tryParse(offerJson(id: 'a', total: 100))!,
        FlightFare.tryParse(offerJson(id: 'b', total: 100))!,
        FlightFare.tryParse(offerJson(id: 'c', total: 100))!,
      ];
      expect(applyFlightFilters(tied, defaultFlightFilters).map((o) => o.offerId), ['a', 'b', 'c']);
    });

    test('refundable only, airlines, price range and departure window narrow the list', () {
      expect(applyFlightFilters(offers, const FlightFilterState(refundableOnly: true)).length, 2);
      expect(
        applyFlightFilters(offers, const FlightFilterState(selectedAirlines: ['Singapore Airlines'])).single.offerId,
        'off_sq',
      );
      expect(applyFlightFilters(offers, const FlightFilterState(priceRange: (150, 200))).single.offerId, 'off_sq');
      expect(
        applyFlightFilters(offers, const FlightFilterState(departureWindow: (6 * 60, 12 * 60))).single.offerId,
        'off_pal',
      );
    });

    test('the panel\'s bounds come from every offer, in the currency the cards print', () {
      final b = filterBounds(offers, (amount, _) => amount * 58);
      expect(b.price, ((116.17 * 58).floorToDouble(), (210.40 * 58).ceilToDouble()));
      expect(b.airlines, ['Duffel Airways', 'Philippine Airlines', 'Singapore Airlines']);
      expect(b.duration, (215, 330));
    });

    test('sort is not a filter', () {
      expect(activeFilterCount(const FlightFilterState(sortBy: FlightSortBy.duration)), 0);
      expect(activeFilterCount(const FlightFilterState(stops: 0, refundableOnly: true)), 2);
    });
  });

  group('the search link', () {
    test('reads an airport from any of the three shapes a link carries', () {
      expect(resolveIata('MNL'), 'MNL');
      expect(resolveIata('Clark (CRK)'), 'CRK');
      expect(resolveIata('Seoul'), 'ICN');
      expect(resolveIata('London (LHR)'), 'LHR');
      expect(resolveIata('Nowhere'), isNull);
    });

    test('a departure that has gone is replaced a month out, and said to be picked', () {
      final now = DateTime(2026, 11, 12);
      expect(resolveDepartureDate('2026-12-03', now: now), (departure: '2026-12-03', chosen: true));
      expect(resolveDepartureDate('2026-01-01', now: now), (departure: '2026-12-12', chosen: false));
      expect(resolveDepartureDate(null, now: now).chosen, isFalse);
    });

    test('round-trips through V2\'s query names', () {
      final q = FlightSearchQuery.fromParams({
        'origin': 'Manila (MNL)',
        'destination': 'SIN',
        'depart': '2026-12-03',
        'return': '2026-12-10',
        'adults': '2',
        'cabin': 'business',
      }, now: DateTime(2026, 11, 12));
      expect(q.tripType, 'round-trip');
      expect(q.toParams(), {
        'origin': 'Manila (MNL)',
        'destination': 'SIN',
        'depart': '2026-12-03',
        'tripType': 'round-trip',
        'cabin': 'business',
        'adults': '2',
        'children': '0',
        'infants': '0',
        'return': '2026-12-10',
      });
      expect(placeCity('Seoul (ICN)'), 'Seoul');
      expect(shortPlaceLabel('Clark (CRK)'), 'CRK');
    });
  });

  group('passengers, as V2 checks them', () {
    test('every field V2 requires, with V2\'s messages', () {
      final ps = passengersFor(adults: 1, children: 1, infants: 0);
      final errors = validatePassengers(ps);
      expect(errors['0.firstName'], 'Required');
      expect(errors['0.email'], 'Required');
      expect(errors['0.phone'], 'Required');
      expect(errors['0.gender'], 'Required');
      expect(errors['0.passportExpiry'], 'Required');
      expect(errors['0.country'], '2-letter country code');
      // Contact details are the lead traveller's alone.
      expect(errors.containsKey('1.email'), isFalse);
      expect(errors.containsKey('1.phone'), isFalse);

      ps.first.email = 'not-an-email';
      expect(validatePassengers(ps)['0.email'], 'Invalid email');
    });

    test('adults, then children, then infants — the order the airline matches them by', () {
      expect(passengersFor(adults: 2, children: 1, infants: 1).map((p) => p.type), ['ADT', 'ADT', 'CHD', 'INF']);
      expect(passengersFor(adults: 0, children: 0, infants: 0).map((p) => p.type), ['ADT']);
    });

    test('a birthday inside the passenger\'s age band on the day they fly', () {
      final adult = birthDateBounds('ADT', '2026-12-03', '2026-11-12');
      expect(adult.max, '2014-12-03');
      expect(adult.min, '1906-12-03');
      final child = birthDateBounds('CHD', '2026-12-03', '2026-11-12');
      expect(child.min, '2014-12-04');
      expect(child.max, '2024-12-03');
      // Nobody is booked before they are born.
      expect(birthDateBounds('INF', '2026-12-03', '2026-11-12').max, '2026-11-12');
      expect(passportExpiryBounds('2026-12-03', '2026-11-12').min, '2026-12-03');
    });

    test('the booking body puts the lead\'s contact on everyone', () {
      final ps = passengersFor(adults: 2, children: 0, infants: 0);
      ps[0]
        ..email = 'lead@example.com'
        ..phone = '9123456789'
        ..country = 'ph';
      final body = ps[1].toBooking(ps[0]);
      expect(body['email'], 'lead@example.com');
      expect(body['phone'], '9123456789');
      expect(ps[0].toBooking(ps[0])['nationality'], 'PH');
    });
  });

  group('api-v2 errors', () {
    Future<ApiError> errorFor(int status, String body) async {
      final client = HttpClientAdapter(
        client: MockClient(
          (_) async => http_pkg.Response.bytes(
            utf8.encode(body),
            status,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      try {
        await client.get('/anything', options: const HttpRequestOptions(requiresAuth: false));
      } on ApiError catch (e) {
        return e;
      }
      fail('expected an ApiError');
    }

    test('an AppError\'s code is a code and its message is the message', () async {
      final e = await errorFor(410, '{"error":"OFFER_EXPIRED","message":"This fare is no longer available."}');
      expect(e.code, 'OFFER_EXPIRED');
      expect(e.message, 'This fare is no longer available.');
    });

    test('an older route\'s sentence in `error` still reads as the message', () async {
      final e = await errorFor(401, '{"success":false,"error":"Unauthorized"}');
      expect(e.code, isNull);
      expect(e.message, 'Unauthorized');
    });

    test('the whole body travels with it — the duplicate warning names the clash', () async {
      final e = await errorFor(
        409,
        '{"error":"DUPLICATE_BOOKING","message":"x","route":"MNL → SIN","departureDate":"2026-12-03"}',
      );
      expect(e.code, 'DUPLICATE_BOOKING');
      expect(e.body?['route'], 'MNL → SIN');
    });
  });
}
