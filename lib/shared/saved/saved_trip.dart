/// A **Saved Trip** — a hotel or flight shortlisted against the account. See #43, ADR-0004.
///
/// What is saved is the thing, never an **Offer**: an Offer is a price for given dates and
/// lapses, while a shortlist is for coming back to weeks later. So a saved stay is named by
/// its `hotelId`, not by whatever rate was on screen when the heart was tapped.
library;

enum SavedKind { hotel, flight }

class SavedTrip {
    const SavedTrip({
        required this.id,
        required this.kind,
        required this.title,
        this.subtitle,
        this.price,
        this.currency = 'USD',
        this.imageUrl,
        this.deepLink = '',
        this.snapshot = const {},
    });

    /// The row's id, which is what un-saving deletes.
    final String id;
    final SavedKind kind;

    /// What the row carries about itself, so the list never has to look anything up. The
    /// catalogue cannot resolve an id it has not searched for, so a list built from lookups
    /// renders empty after a fresh launch.
    final String title;
    final String? subtitle;
    final num? price;
    final String currency;
    final String? imageUrl;

    /// V2's web path, written by whichever client saved it, so the account page on the web
    /// can link to it. Mobile ignores it and routes from the snapshot instead.
    final String deepLink;

    /// Where identity lives: `hotelId` for a stay, `provider` + `offerId` for a flight.
    final Map<String, dynamic> snapshot;

    String? get hotelId => snapshot['hotelId']?.toString();
    String? get offerId => snapshot['offerId']?.toString();

    /// Where this opens in *this* app, which is not where [deepLink] points.
    String? get route => switch (kind) {
        SavedKind.hotel => hotelId == null ? null : '/hotel/$hotelId',
        SavedKind.flight => '/flights',
    };

    factory SavedTrip.fromJson(Map<String, dynamic> json) {
        final snapshot = json['snapshot'] is Map
            ? (json['snapshot'] as Map).cast<String, dynamic>()
            : <String, dynamic>{};

        return SavedTrip(
            id: (json['id'] ?? '').toString(),
            kind: json['type']?.toString() == 'flight' ? SavedKind.flight : SavedKind.hotel,
            title: (json['title'] ?? '').toString(),
            subtitle: _textOrNull(json['subtitle']),
            // A Decimal column arrives as a string.
            price: json['price'] is num
                ? json['price'] as num
                : num.tryParse(json['price']?.toString() ?? ''),
            currency: (json['currency'] ?? 'USD').toString().toUpperCase(),
            imageUrl: _textOrNull(json['image_url'] ?? json['imageUrl']),
            deepLink: (json['deep_link'] ?? json['deepLink'] ?? '').toString(),
            snapshot: snapshot,
        );
    }

    static String? _textOrNull(Object? value) {
        final text = value?.toString() ?? '';
        return text.isEmpty ? null : text;
    }
}
