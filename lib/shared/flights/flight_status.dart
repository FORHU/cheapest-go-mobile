/// Where a booked flight is now: scheduled, boarding, in the air or landed,
/// and how far along its route.
///
/// Screens read status through [FlightStatusService]. Today the only
/// implementation is [ScheduleFlightStatusService], which works it out from
/// the booked departure time and duration; a provider-backed one (through
/// `cheapestgo-api-v2`) can replace it without touching the screens.
library;

import 'package:flutter/foundation.dart';
import 'package:cheapest_go_mobile/shared/stores/bookings_store.dart';

enum FlightPhase { scheduled, boarding, inAir, landed }

class FlightStatus {
  const FlightStatus({required this.phase, required this.progress, required this.now, required this.flight});

  final FlightPhase phase;

  /// 0 at take-off to 1 at landing; 0 before take-off, 1 after landing.
  final double progress;

  /// The moment this status describes (UTC); simulated in a debug replay.
  final DateTime now;
  final BookedFlight flight;

  Duration get untilDeparture => flight.departureUtc.difference(now);
  Duration get untilArrival => flight.arrivalUtc.difference(now);
  Duration get sinceArrival => now.difference(flight.arrivalUtc);
}

abstract class FlightStatusService {
  FlightStatus statusOf(BookedFlight flight, DateTime nowUtc);
}

/// Status from the schedule alone: boarding opens [boardingWindow] before
/// departure and the flight lands exactly on time.
class ScheduleFlightStatusService implements FlightStatusService {
  const ScheduleFlightStatusService();

  static const boardingWindow = Duration(minutes: 45);

  @override
  FlightStatus statusOf(BookedFlight flight, DateTime nowUtc) {
    final dep = flight.departureUtc;
    final arr = flight.arrivalUtc;
    final FlightPhase phase;
    final double progress;
    if (nowUtc.isBefore(dep.subtract(boardingWindow))) {
      (phase, progress) = (FlightPhase.scheduled, 0);
    } else if (nowUtc.isBefore(dep)) {
      (phase, progress) = (FlightPhase.boarding, 0);
    } else if (nowUtc.isBefore(arr)) {
      (phase, progress) = (FlightPhase.inAir, nowUtc.difference(dep).inSeconds / arr.difference(dep).inSeconds);
    } else {
      (phase, progress) = (FlightPhase.landed, 1);
    }
    return FlightStatus(phase: phase, progress: progress, now: nowUtc, flight: flight);
  }
}

/// The status service the app reads from.
const FlightStatusService flightStatusService = ScheduleFlightStatusService();

/// A flight is worth tracking until this long after it lands.
const Duration kTrackAfterLanding = Duration(hours: 6);

/// Debug builds only: replays a booked flight fast, from just before
/// take-off, so the tracker can be tried without waiting for a real departure.
class FlightSimulator extends ChangeNotifier {
  FlightSimulator({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  /// Simulated minutes per real second.
  static const speed = 60;
  static const _lead = Duration(minutes: 2);

  final Map<String, (DateTime startedAt, DateTime from)> _runs = {};

  bool isRunning(String reference) => _runs.containsKey(reference);

  void start(String reference, BookedFlight flight) {
    assert(!kReleaseMode, 'The flight simulator is for debug builds only');
    _runs[reference] = (_clock().toUtc(), flight.departureUtc.subtract(_lead));
    notifyListeners();
  }

  void stop(String reference) {
    if (_runs.remove(reference) != null) notifyListeners();
  }

  /// Simulated now for [reference], or real now when it isn't being replayed.
  DateTime nowFor(String reference) {
    final now = _clock().toUtc();
    final run = _runs[reference];
    if (run == null) return now;
    final (startedAt, from) = run;
    return from.add(now.difference(startedAt) * speed);
  }
}

final FlightSimulator flightSimulator = FlightSimulator();

/// The booking the Map tab should open in the tracker, set by Trips.
final ValueNotifier<String?> flightToTrack = ValueNotifier<String?>(null);
