import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cheapest_go_mobile/shared/utils/format.dart';

enum BookingKind { flight, stay, teeTime }

/// The flight inside a flight booking, kept so the trip can be tracked.
class BookedFlight {
  const BookedFlight({
    required this.offerId,
    required this.airline,
    required this.flightNo,
    required this.origin,
    required this.destination,
    required this.departureUtc,
    required this.durationMinutes,
  });

  final String offerId;
  final String airline;
  final String flightNo;
  final String origin;
  final String destination;
  final DateTime departureUtc;
  final int durationMinutes;

  DateTime get arrivalUtc => departureUtc.add(Duration(minutes: durationMinutes));

  Map<String, Object?> toJson() => {
        'offerId': offerId,
        'airline': airline,
        'flightNo': flightNo,
        'origin': origin,
        'destination': destination,
        'departureUtc': departureUtc.toIso8601String(),
        'durationMinutes': durationMinutes,
      };

  factory BookedFlight.fromJson(Map<String, Object?> j) => BookedFlight(
        offerId: j['offerId']! as String,
        airline: j['airline']! as String,
        flightNo: j['flightNo']! as String,
        origin: j['origin']! as String,
        destination: j['destination']! as String,
        departureUtc: DateTime.parse(j['departureUtc']! as String).toUtc(),
        durationMinutes: j['durationMinutes']! as int,
      );
}

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
    this.flight,
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

  /// The booked flight, for flight bookings made with one.
  final BookedFlight? flight;

  Map<String, Object?> toJson() => {
        'reference': reference,
        'kind': kind.name,
        'airportCode': airportCode,
        'title': title,
        'start': start.toIso8601String(),
        'when': when,
        'detail': detail,
        'total': total,
        if (flight != null) 'flight': flight!.toJson(),
      };

  factory Booking.fromJson(Map<String, Object?> j) => Booking(
        reference: j['reference']! as String,
        kind: BookingKind.values.byName(j['kind']! as String),
        airportCode: j['airportCode']! as String,
        title: j['title']! as String,
        start: DateTime.parse(j['start']! as String),
        when: j['when']! as String,
        detail: j['detail']! as String,
        total: j['total']! as int,
        flight: j['flight'] == null ? null : BookedFlight.fromJson((j['flight']! as Map).cast<String, Object?>()),
      );
}

/// Bookings for the mock build, kept on the device so they survive a restart
/// (a traveler opens the app mid-flight). Nothing is sent anywhere.
class BookingsStore extends ChangeNotifier {
  static const _key = 'cheapestgo_bookings_v1';

  BookingsStore({Random? random, DateTime Function()? clock})
      : _random = random ?? Random(),
        _clock = clock ?? DateTime.now;

  final Random _random;
  final DateTime Function() _clock;
  final List<Booking> _bookings = [];

  List<Booking> get all => List.unmodifiable(_bookings);

  /// Flight bookings that carry their flight, earliest departure first.
  List<Booking> get flights => _bookings.where((b) => b.flight != null).toList()
    ..sort((a, b) => a.flight!.departureUtc.compareTo(b.flight!.departureUtc));

  Booking? byReference(String reference) {
    for (final b in _bookings) {
      if (b.reference == reference) return b;
    }
    return null;
  }

  /// Loads the bookings saved on this device.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved == null) return;
      _bookings
        ..clear()
        ..addAll([
          for (final item in jsonDecode(saved) as List) Booking.fromJson((item as Map).cast<String, Object?>()),
        ]);
      notifyListeners();
    } catch (e) {
      debugPrint('Bookings not loaded: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode([for (final b in _bookings) b.toJson()]));
    } catch (_) {}
  }

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
    BookedFlight? flight,
  }) {
    return _add(Booking(
      reference: _newReference('CG-F'),
      flight: flight,
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

  /// Fills an empty store with a few earlier trips so Trips › Past has
  /// something to show in the mock build. Dates are relative to today.
  void seedDemoHistory() {
    if (_bookings.isNotEmpty) return;
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

  /// Back to the sample trips only, dropping every booking made since.
  Future<void> resetToDemo() async {
    _bookings.clear();
    seedDemoHistory();
    await _save();
  }

  Booking _add(Booking booking) {
    _bookings.add(booking);
    notifyListeners();
    _save();
    return booking;
  }

  String _newReference(String prefix) {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final code = List.generate(5, (_) => alphabet[_random.nextInt(alphabet.length)]).join();
    return prefix.endsWith('-') ? '$prefix$code' : '$prefix-$code';
  }
}

final BookingsStore bookingsStore = BookingsStore();
