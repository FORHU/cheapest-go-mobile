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

  /// Fills the store with a few earlier trips so Trips › Past has something
  /// to show in the mock build. Dates are relative to today.
  void seedDemoHistory() {
    final today = dateOnly(_clock());
    DateTime ago(int days) => today.subtract(Duration(days: days));
    addFlight(
      origin: 'MNL', destination: 'TAG', airline: 'Islas Express', flightNo: 'IX 412',
      day: ago(58), departs: '07:40', arrives: '09:05', stops: 'Non-stop', passengers: 2, total: 9480,
    );
    addStay(
      airportCode: 'TAG', hotelName: 'Alona Beach Resort', roomName: _demoRoom,
      checkIn: ago(58), checkOut: ago(54), adults: 2, total: 30910,
    );
    addTeeTime(
      airportCode: 'TAG', courseName: 'Panglao Ridge Golf', courseMeta: '18 holes · Par 72 · buggy included',
      day: ago(56), teeTime: '07:45', players: 2, total: 10400,
    );
    addStay(
      airportCode: 'CRK', hotelName: 'Freeport Runway Hotel', roomName: _demoRoom,
      checkIn: ago(121), checkOut: ago(119), adults: 1, total: 9180,
    );
    addTeeTime(
      airportCode: 'CRK', courseName: 'Mimosa Greens', courseMeta: '36 holes · Par 72 · buggy included',
      day: ago(120), teeTime: '06:45', players: 1, total: 6500,
    );
  }

  static const _demoRoom = 'Deluxe King';

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
