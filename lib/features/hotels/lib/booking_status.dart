/// A booking's status, kept fresh until it settles — V2's `useBookingStatus`.
///
/// The confirmation screen is where a traveller lands after paying, and the booking may still be
/// being made. This reads the status endpoint and keeps reading it while the answer is "not
/// yet", so the screen that says "we are confirming" turns into the one that says "you are
/// booked" without anyone pressing anything.
///
/// It stops, deliberately: a booking stuck with a supplier can stay that way for an hour, and a
/// phone polling every few seconds for an hour is not a service to anyone. After its budget it
/// says the answer is still not settled ([exhausted]) and offers [refresh].
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:cheapest_go_mobile/features/hotels/api/checkout_api.dart';
import 'package:cheapest_go_mobile/shared/errors/api_error.dart';

enum BookingLoad { loading, ready, notFound, error }

class BookingStatusPoller extends ChangeNotifier {
    BookingStatusPoller({
        required this.reference,
        required this.fetch,
        this.interval = const Duration(seconds: 3),
        this.maxPolls = 40,
    }) : load = reference.isEmpty ? BookingLoad.notFound : BookingLoad.loading;

    final String reference;
    final Future<ConfirmOutcome> Function(String reference) fetch;
    final Duration interval;
    final int maxPolls;

    BookingLoad load;
    ConfirmOutcome? outcome;

    /// The polling budget is spent and the booking has still not settled.
    bool exhausted = false;

    Timer? _timer;
    // Bumped by every (re)start, so an answer to a superseded round is dropped on arrival.
    int _round = 0;
    int _polls = 0;
    bool _disposed = false;

    /// Asks for the first time. Separate from the constructor so a screen can own the poller
    /// before anything is in flight.
    void start() {
        if (reference.isEmpty) return;
        _restart();
    }

    /// Asks again from the top, with a fresh budget. What is on screen stays while it does.
    Future<void> refresh() async {
        if (load != BookingLoad.ready) load = BookingLoad.loading;
        _notify();
        _restart();
    }

    void _restart() {
        _timer?.cancel();
        _polls = 0;
        exhausted = false;
        unawaited(_tick(++_round));
    }

    Future<void> _tick(int round) async {
        bool stale() => _disposed || round != _round;
        if (stale()) return;
        _polls += 1;

        try {
            final next = await fetch(reference);
            if (stale()) return;
            outcome = next;
            load = BookingLoad.ready;
            _notify();
            // Settled: a booking that is confirmed or failed will not change by being asked again.
            if (next.state == ConfirmState.confirmed || next.state == ConfirmState.failed) return;
        } catch (error) {
            if (stale()) return;
            if (error is ApiError && (error.status == 404 || error.code == 'BOOKING_NOT_FOUND')) {
                load = BookingLoad.notFound;
                _notify();
                return;
            }
            // Keep whatever was already shown; only a first load can be an outright error.
            if (load != BookingLoad.ready) load = BookingLoad.error;
            _notify();
            if (_polls == 1) return;
        }

        if (_polls >= maxPolls) {
            exhausted = true;
            _notify();
            return;
        }
        _timer = Timer(interval, () => _tick(round));
    }

    void _notify() {
        if (!_disposed) notifyListeners();
    }

    @override
    void dispose() {
        _disposed = true;
        _timer?.cancel();
        super.dispose();
    }
}
