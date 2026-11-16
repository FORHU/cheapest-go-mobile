import 'package:flutter/foundation.dart';

import 'package:cheapest_go_mobile/shared/lib/http.dart';
import 'package:cheapest_go_mobile/shared/saved/saved_trip.dart';

/// The traveller's shortlist, held against the account. See #43 and ADR-0004.
///
/// In `shared/` because two features need it: the heart lives on a hotel card and the list
/// lives in the account screen, and a feature may not reach into another.
///
/// What this replaced: a `Set<String>` of hotel ids in SharedPreferences. It went with the
/// app — invisible on the web, gone on reinstall — which is not what CONTEXT.md means by a
/// **Saved Trip**.
class SavedTripsStore extends ChangeNotifier {
    SavedTripsStore({HttpClientAdapter? client}) : _client = client ?? HttpClientAdapter();

    final HttpClientAdapter _client;

    static const _signedIn = HttpRequestOptions(useMobileApiKey: true, requiresAuth: true);

    List<SavedTrip> _trips = const [];
    bool _loaded = false;

    /// Hotel ids currently being saved or removed, so a heart can show the tap landed before
    /// the server answers.
    final _inFlight = <String>{};

    List<SavedTrip> get trips => List.unmodifiable(_trips);
    bool get loaded => _loaded;

    /// Whether this hotel is on the shortlist. Answered from the list already in hand, so a
    /// screen of fifty results costs one fetch rather than fifty.
    bool isSaved(String hotelId) =>
        _trips.any((t) => t.kind == SavedKind.hotel && t.hotelId == hotelId);

    bool isBusy(String hotelId) => _inFlight.contains(hotelId);

    /// Reads the shortlist. Signed out there is nothing to read, and that is not a failure.
    Future<void> refresh() async {
        try {
            final res = await _client.get('/api/v2/bookings/saved-trips', options: _signedIn);
            final rows = res is Map ? res['trips'] : null;
            _trips = [
                for (final row in (rows is List ? rows : const []))
                    if (row is Map) SavedTrip.fromJson(row.cast<String, dynamic>()),
            ];
        } catch (_) {
            // A shortlist that could not be read is empty rather than wrong: the hearts show
            // unfilled, and tapping one saves it again.
            _trips = const [];
        }
        _loaded = true;
        notifyListeners();
    }

    /// Saves a stay, or removes it if it is already there.
    ///
    /// Returns false when nothing happened because nobody is signed in — the caller decides
    /// what to say about that; this store does not navigate.
    Future<bool> toggleHotel({
        required String hotelId,
        required String title,
        String? subtitle,
        num? price,
        String? currency,
        String? imageUrl,
    }) async {
        if (_inFlight.contains(hotelId)) return true;

        final existing = _trips
            .where((t) => t.kind == SavedKind.hotel && t.hotelId == hotelId)
            .firstOrNull;

        _inFlight.add(hotelId);
        notifyListeners();

        try {
            if (existing != null) {
                await _client.delete('/api/v2/bookings/saved-trips/${existing.id}', options: _signedIn);
                _trips = [..._trips]..removeWhere((t) => t.id == existing.id);
            } else {
                final res = await _client.post(
                    '/api/v2/bookings/saved-trips',
                    body: {
                        'type': 'hotel',
                        'title': title,
                        'subtitle': ?subtitle,
                        'price': ?price,
                        'currency': ?currency,
                        'imageUrl': ?imageUrl,
                        // V2's own path, not this app's: the account page on the web links
                        // through this field. See ADR-0004.
                        'deepLink': '/property/$hotelId',
                        'snapshot': {'hotelId': hotelId},
                    },
                    options: _signedIn,
                );
                final row = res is Map ? (res['data'] ?? res['trip']) : null;
                if (row is Map) {
                    _trips = [SavedTrip.fromJson(row.cast<String, dynamic>()), ..._trips];
                }
            }
            return true;
        } catch (error) {
            // Signed out is the expected refusal, and the only one worth telling apart: it
            // asks something of the traveller, where a network failure asks nothing.
            return !_isUnauthorised(error);
        } finally {
            _inFlight.remove(hotelId);
            notifyListeners();
        }
    }

    /// Forgets everything held in memory. For sign-out: the next account's shortlist is not
    /// this one's.
    void forget() {
        _trips = const [];
        _loaded = false;
        notifyListeners();
    }

    static bool _isUnauthorised(Object error) {
        final text = error.toString();
        return text.contains('401') || text.toLowerCase().contains('unauthor');
    }
}

/// The app's shortlist. Replaced in tests.
SavedTripsStore savedTripsStore = SavedTripsStore();
