import 'package:cheapest_go_mobile/shared/lib/http.dart';

/// Where a search can be pointed: a city, a country, or an airport.
///
/// V2's landing search asks "where" and resolves it against api-v2, and mobile now asks the
/// same question of the same endpoints (#38). Two of them, not one, because the two answers
/// come from different places and carry different things — hotels from the destination
/// autocomplete, which knows a city's granularity and bounding box, and flights from the
/// airport index. See `destinations.api.ts` in the web repo, and ADR-0017 there.
enum DestinationKind { city, country, airport }

class DestinationSuggestion {
    const DestinationSuggestion({
        required this.id,
        required this.kind,
        required this.name,
        this.city,
        this.countryCode = '',
        this.iata,
    });

    /// What the search is pointed at afterwards. For an airport this is its IATA code.
    final String id;
    final DestinationKind kind;

    /// What a person reads in the list.
    final String name;
    final String? city;
    final String countryCode;

    /// Present on airports only.
    final String? iata;

    /// A city has no IATA code and an airport always does, which is how a caller tells a
    /// stays destination from a flight endpoint without inspecting [kind].
    bool get isAirport => kind == DestinationKind.airport;

    @override
    String toString() => 'DestinationSuggestion($kind, $id, $name)';
}

DestinationKind _kindOf(String? raw) => switch (raw) {
        'airport' => DestinationKind.airport,
        'country' => DestinationKind.country,
        _ => DestinationKind.city,
    };

/// Suggestions for the "where" step.
///
/// [forFlights] picks the airport index instead of the destination autocomplete, matching
/// V2's branch: a flight leaves from and arrives at an airport, a stay is in a place.
class DestinationsApi {
    DestinationsApi({HttpClientAdapter? client}) : _client = client ?? HttpClientAdapter();

    final HttpClientAdapter _client;

    static const _options = HttpRequestOptions(useMobileApiKey: true, requiresAuth: false);

    Future<List<DestinationSuggestion>> search(
        String query, {
        bool forFlights = false,
        int limit = 8,
    }) async {
        final q = query.trim();
        // The endpoints answer nothing useful for a single letter, and asking costs a
        // supplier lookup on the hotels side.
        if (q.length < 2) return const [];

        final path = forFlights
            ? '/api/v2/airports/search?q=${Uri.encodeQueryComponent(q)}&limit=$limit'
            : '/api/v2/hotels/destinations?q=${Uri.encodeQueryComponent(q)}&limit=$limit';

        try {
            final res = await _client.get(path, options: _options);
            final rows = _rowsOf(res);
            return rows
                .map((r) => forFlights ? _airport(r) : _destination(r))
                .whereType<DestinationSuggestion>()
                .toList();
        } catch (_) {
            // A failed lookup leaves the field as the person typed it rather than clearing
            // what they were doing. The caller decides whether to say anything.
            return const [];
        }
    }

    /// Both endpoints answer `{ success, data: [...] }`, and one of them has been seen to
    /// answer a bare list; accepting either costs two lines.
    List<Map<String, dynamic>> _rowsOf(dynamic res) {
        final data = res is Map<String, dynamic> ? res['data'] : res;
        if (data is! List) return const [];
        return data.whereType<Map<String, dynamic>>().toList();
    }

    DestinationSuggestion? _airport(Map<String, dynamic> r) {
        final iata = (r['iata'] ?? r['code'])?.toString();
        if (iata == null || iata.isEmpty) return null;
        return DestinationSuggestion(
            id: iata,
            kind: DestinationKind.airport,
            name: (r['name'] ?? iata).toString(),
            city: r['city']?.toString(),
            countryCode: (r['countryCode'] ?? r['country'] ?? '').toString(),
            iata: iata,
        );
    }

    DestinationSuggestion? _destination(Map<String, dynamic> r) {
        final id = (r['id'] ?? r['code'] ?? r['name'])?.toString();
        if (id == null || id.isEmpty) return null;
        return DestinationSuggestion(
            id: id,
            kind: _kindOf(r['type']?.toString()),
            name: (r['name'] ?? id).toString(),
            city: r['city']?.toString(),
            countryCode: (r['countryCode'] ?? '').toString(),
        );
    }
}

/// The app's instance. Replaced in tests.
DestinationsApi destinationsApi = DestinationsApi();
