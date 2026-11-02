import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cheapest_go_mobile/shared/utils/format.dart';

enum BookingKind { flight, stay, teeTime }

class Booking {
  const Booking({
    required this.reference,
    required this.kind,
    required this.airportCode,
    required this.title,
    required this.start,
    required this.when,
    required this.detail,
    required this.total,
  });

  final String reference;
  final BookingKind kind;
  final String airportCode;
  final String title;

  /// When the stay or round begins; decides upcoming vs past.
  final DateTime start;
  final String when;
  final String detail;

  /// Total charged, in whole pesos.
  final int total;
}

/// In-memory bookings for the mock build. Nothing is sent anywhere and the
/// list resets when the app restarts.
class BookingsStore extends ChangeNotifier {
  BookingsStore({Random? random, DateTime Function()? clock})
      : _random = random ?? Random(),
        _clock = clock ?? DateTime.now;

  final Random _random;
  final DateTime Function() _clock;
  final List<Booking> _bookings = [];

  List<Booking> get all => List.unmodifiable(_bookings);

  List<Booking> get upcoming {
    final today = dateOnly(_clock());
    return _bookings.where((b) => !b.start.isBefore(today)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  List<Booking> get past {
    final today = dateOnly(_clock());
    return _bookings.where((b) => b.start.isBefore(today)).toList()
      ..sort((a, b) => b.start.compareTo(a.start));
  }

  Booking addStay({
    required String airportCode,
    required String hotelName,
    required String roomName,
    required DateTime checkIn,
    required DateTime checkOut,
    required int adults,
    required int total,
  }) {
    final nights = checkOut.difference(checkIn).inDays;
    return _add(Booking(
      reference: _newReference('CG'),
      kind: BookingKind.stay,
      airportCode: airportCode,
      title: hotelName,
      start: checkIn,
      when: '${formatDayDate(checkIn)} → ${formatDayDate(checkOut)} · ${plural(nights, 'night')}',
      detail: '$roomName · ${plural(adults, 'adult')}',
      total: total,
    ));
  }

  Booking addFlight({
    required String origin,
    required String destination,
    required String airline,
    required String flightNo,
    required DateTime day,
    required String departs,
    required String arrives,
    required String stops,
    required int passengers,
    required int total,
  }) {
    return _add(Booking(
      reference: _newReference('CG-F'),
      kind: BookingKind.flight,
      airportCode: destination,
      title: '$airline $flightNo',
      start: day,
      when: '${formatDayDate(day)} · ${formatClock(departs)} → ${formatClock(arrives)}',
      detail: '$origin → $destination · $stops · ${plural(passengers, 'passenger')}',
      total: total,
    ));
  }

  Booking addTeeTime({
    required String airportCode,
    required String courseName,
    required String courseMeta,
    required DateTime day,
    required String teeTime,
    required int players,
    required int total,
  }) {
    return _add(Booking(
      reference: _newReference('CG-T'),
      kind: BookingKind.teeTime,
      airportCode: airportCode,
      title: courseName,
      start: day,
      when: '${formatDayDate(day)} · ${formatTeeTime(teeTime)}',
      detail: '$courseMeta · ${plural(players, 'player')}',
      total: total,
    ));
  }

  Booking _add(Booking booking) {
    _bookings.add(booking);
    notifyListeners();
    return booking;
  }

  String _newReference(String prefix) {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final code = List.generate(5, (_) => alphabet[_random.nextInt(alphabet.length)]).join();
    return prefix.endsWith('-') ? '$prefix$code' : '$prefix-$code';
  }
}

final BookingsStore bookingsStore = BookingsStore();
