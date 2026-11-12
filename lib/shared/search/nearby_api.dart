import 'package:cheapest_go_mobile/shared/lib/http.dart';

/// What is around a property. See #40 and V2's nearby explorer.
///
/// api-v2 asks Google Places and hands back GeoJSON features, so the categories and the
/// radius are its decisions, not this app's: `all`, `restaurant`, `cafe`, `attraction`,
/// `grocery` and the rest map to lists of Google types on that side of the wire.

/// One place near the hotel.
class NearbyPlace {
    const NearbyPlace({
        required this.id,
        required this.name,
        required this.category,
        required this.latitude,
        required this.longitude,
        this.vicinity,
        this.rating,
        this.ratingCount,
        this.photoReference,
    });

    /// Google's `place_id`, which the details endpoint is keyed by.
    final String id;
    final String name;

    /// The first of Google's types — "restaurant", "museum" — as api-v2 passes it through.
    final String category;
    final double latitude;
    final double longitude;

    /// The street or district Google names, not a full address.
    final String? vicinity;
    final double? rating;
    final int? ratingCount;

    /// Fetched through api-v2's own proxy rather than Google directly: the key stays server
    /// side, which is the reason the proxy exists.
    final String? photoReference;

    static NearbyPlace? fromFeature(Map<String, dynamic> feature) {
        final props = feature['properties'];
        final geometry = feature['geometry'];
        if (props is! Map<String, dynamic> || geometry is! Map<String, dynamic>) return null;

        final coordinates = geometry['coordinates'];
        if (coordinates is! List || coordinates.length < 2) return null;

        final id = props['place_id']?.toString();
        final name = props['name']?.toString();
        if (id == null || id.isEmpty || name == null || name.isEmpty) return null;

        return NearbyPlace(
            id: id,
            name: name,
            category: props['category']?.toString() ?? 'all',
            // GeoJSON is longitude first, which is the opposite of every other coordinate in
            // this app and the reason this parsing is in one place.
            longitude: (coordinates[0] as num).toDouble(),
            latitude: (coordinates[1] as num).toDouble(),
            vicinity: props['vicinity']?.toString(),
            rating: (props['rating'] as num?)?.toDouble(),
            ratingCount: (props['userRatingsTotal'] as num?)?.toInt(),
            photoReference: props['photoReference']?.toString(),
        );
    }
}

/// The categories V2 offers, in V2's order. `all` is what the explorer opens on.
/// V2's `POI_FILTERS`, in V2's order and with its ids — api-v2 maps each to a list of Google
/// types, so the id is a contract rather than a label.
enum NearbyCategory {
    all('all', 'All'),
    restaurant('restaurant', 'Food'),
    cafe('cafe', 'Cafés'),
    attraction('attraction', 'Attractions'),
    grocery('grocery', 'Groceries'),
    medical('medical', 'Pharmacy'),
    transit('transit', 'Transit');

    const NearbyCategory(this.query, this.label);

    /// What api-v2 expects; it maps each to a list of Google types.
    final String query;

    /// What a person reads. Literals because V2's own filter labels are literals.
    final String label;
}

class NearbyApi {
    NearbyApi({HttpClientAdapter? client}) : _client = client ?? HttpClientAdapter();

    final HttpClientAdapter _client;

    static const _options = HttpRequestOptions(useMobileApiKey: true, requiresAuth: false);

    /// Places within [radius] metres of a point.
    ///
    /// Empty on failure rather than throwing: the explorer is one section of a page that is
    /// perfectly readable without it, and api-v2 answers 503 when it has no Places key —
    /// which is a configuration fact, not something to put in front of a traveller.
    Future<List<NearbyPlace>> around(
        double latitude,
        double longitude, {
        NearbyCategory category = NearbyCategory.all,
        int radius = 3000,
    }) async {
        try {
            final res = await _client.get(
                '/api/v2/hotels/nearby?lat=$latitude&lng=$longitude'
                '&category=${category.query}&radius=$radius',
                options: _options,
            );
            final features = res is Map<String, dynamic> ? res['features'] : null;
            if (features is! List) return const [];

            return features
                .whereType<Map<String, dynamic>>()
                .map(NearbyPlace.fromFeature)
                .whereType<NearbyPlace>()
                .toList();
        } catch (_) {
            return const [];
        }
    }
}

/// The app's instance. Replaced in tests.
NearbyApi nearbyApi = NearbyApi();
