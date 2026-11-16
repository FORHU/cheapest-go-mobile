/// A flight offer as api-v2's `/flights/search` and `/flights/offers/:id` return it — Duffel's
/// fare, normalised by the server. See `FlightOffer` in `cheapestgo-api-v2/src/types/flights.ts`.
///
/// Named `FlightFare` rather than `FlightOffer` because `shared/catalog` already has a
/// `FlightOffer`: the catalogue's invented fares, which the map still draws. Nothing in this
/// feature reads that one — every fare here came from the airline, through the API.
///
/// [raw] is the offer exactly as it arrived, kept so it can be handed back: `/flights/revalidate`
/// takes the whole payload, as V2 sends it.
class FlightFare {
  const FlightFare({
    required this.offerId,
    required this.provider,
    required this.price,
    required this.segments,
    required this.totalDuration,
    required this.sliceDurations,
    required this.totalStops,
    required this.refundable,
    this.farePolicy,
    this.baggage,
    this.brandedFare,
    this.alternatives = const [],
    this.quote,
    this.displayPrice,
    this.raw = const {},
  });

  final String offerId;
  final String provider;

  /// In the airline's currency. Booking and revalidation compare against this figure.
  final FarePrice price;
  final List<FlightSegment> segments;
  final int totalDuration;

  /// Each direction's own elapsed minutes, by `segmentIndex`.
  final List<int> sliceDurations;
  final int totalStops;
  final bool refundable;
  final FarePolicy? farePolicy;
  final FareBaggage? baggage;
  final BrandedFare? brandedFare;
  final List<FlightFare> alternatives;

  /// What the card would be held for, on the single-offer read only.
  final FareQuote? quote;

  /// The fare in the currency the search asked for, when the server had a fresh rate.
  final DisplayPrice? displayPrice;
  final Map<String, dynamic> raw;

  FlightFare withTotal(num total) => FlightFare(
    offerId: offerId,
    provider: provider,
    price: FarePrice(total: total.toDouble(), currency: price.currency, pricePerAdult: price.pricePerAdult),
    segments: segments,
    totalDuration: totalDuration,
    sliceDurations: sliceDurations,
    totalStops: totalStops,
    refundable: refundable,
    farePolicy: farePolicy,
    baggage: baggage,
    brandedFare: brandedFare,
    alternatives: alternatives,
    quote: quote,
    displayPrice: displayPrice,
    raw: {
      ...raw,
      'price': {...?(raw['price'] as Map<String, dynamic>?), 'total': total},
    },
  );

  static FlightFare? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final id = json['offerId']?.toString();
    final price = FarePrice.tryParse(json['price']);
    final segs =
        (json['segments'] as List?)?.map(FlightSegment.tryParse).whereType<FlightSegment>().toList() ??
        const <FlightSegment>[];
    if (id == null || id.isEmpty || price == null || segs.isEmpty) return null;

    return FlightFare(
      offerId: id,
      provider: json['provider']?.toString() ?? '',
      price: price,
      segments: segs,
      totalDuration: _int(json['totalDuration']) ?? 0,
      sliceDurations: (json['sliceDurations'] as List?)?.map((e) => _int(e) ?? 0).toList() ?? const [],
      totalStops: _int(json['totalStops']) ?? 0,
      refundable: json['refundable'] == true,
      farePolicy: FarePolicy.tryParse(json['farePolicy']),
      baggage: FareBaggage.tryParse(json['baggage']),
      brandedFare: BrandedFare.tryParse(json['brandedFare']),
      alternatives:
          (json['alternatives'] as List?)?.map(FlightFare.tryParse).whereType<FlightFare>().toList() ?? const [],
      quote: FareQuote.tryParse(json['quote']),
      displayPrice: DisplayPrice.tryParse(json['displayPrice']),
      raw: json,
    );
  }
}

class FarePrice {
  const FarePrice({required this.total, required this.currency, required this.pricePerAdult});

  final double total;
  final String currency;
  final double pricePerAdult;

  static FarePrice? tryParse(Object? json) {
    if (json is! Map) return null;
    final total = _double(json['total']);
    if (total == null) return null;
    return FarePrice(
      total: total,
      currency: (json['currency']?.toString() ?? 'USD').toUpperCase(),
      pricePerAdult: _double(json['pricePerAdult']) ?? 0,
    );
  }
}

/// The card's hold, in the currency it is held in: `fare + serviceFee = total`.
class FareQuote {
  const FareQuote({required this.currency, required this.fare, required this.serviceFee, required this.total});

  final String currency;
  final double fare;
  final double serviceFee;
  final double total;

  static FareQuote? tryParse(Object? json) {
    if (json is! Map) return null;
    final total = _double(json['total']);
    final currency = json['currency']?.toString();
    if (total == null || currency == null) return null;
    return FareQuote(
      currency: currency.toUpperCase(),
      fare: _double(json['fare']) ?? total,
      serviceFee: _double(json['serviceFee']) ?? 0,
      total: total,
    );
  }
}

class DisplayPrice {
  const DisplayPrice({required this.currency, required this.total, required this.pricePerAdult});

  final String currency;
  final double total;
  final double pricePerAdult;

  static DisplayPrice? tryParse(Object? json) {
    if (json is! Map) return null;
    final total = _double(json['total']);
    final currency = json['currency']?.toString();
    if (total == null || currency == null) return null;
    return DisplayPrice(
      currency: currency.toUpperCase(),
      total: total,
      pricePerAdult: _double(json['pricePerAdult']) ?? total,
    );
  }
}

class FarePolicy {
  const FarePolicy({required this.isRefundable, this.refundPenaltyAmount, this.refundPenaltyCurrency});

  final bool isRefundable;
  final double? refundPenaltyAmount;
  final String? refundPenaltyCurrency;

  static FarePolicy? tryParse(Object? json) {
    if (json is! Map) return null;
    return FarePolicy(
      isRefundable: json['isRefundable'] == true,
      refundPenaltyAmount: _double(json['refundPenaltyAmount']),
      refundPenaltyCurrency: json['refundPenaltyCurrency']?.toString(),
    );
  }
}

class FareBaggage {
  const FareBaggage({required this.checkedBags, this.cabinBag});

  final int checkedBags;

  /// null when the fare says nothing about a carry-on — which is not the same as none.
  final bool? cabinBag;

  static FareBaggage? tryParse(Object? json) {
    if (json is! Map) return null;
    final cabin = json['cabinBag'];
    return FareBaggage(
      checkedBags: _int(json['checkedBags']) ?? 0,
      // The type says string, the wire says boolean; either way, present and truthy is a bag.
      cabinBag: cabin == null ? null : (cabin == true || (cabin is String && cabin.isNotEmpty && cabin != 'false')),
    );
  }
}

class BrandedFare {
  const BrandedFare({this.brandName, this.fareType});

  final String? brandName;
  final String? fareType;

  String? get label => (brandName?.isNotEmpty ?? false) ? brandName : fareType;

  static BrandedFare? tryParse(Object? json) {
    if (json is! Map) return null;
    return BrandedFare(brandName: json['brandName']?.toString(), fareType: json['fareType']?.toString());
  }
}

/// One end of a flight. Its `time` is Local Airport Time with no UTC offset — see `formatTime`.
class SegmentEnd {
  const SegmentEnd({required this.airport, this.airportName, this.city, this.terminal, this.time});

  final String airport;
  final String? airportName;
  final String? city;
  final String? terminal;
  final String? time;

  static SegmentEnd? tryParse(Object? json, String fallbackAirport) {
    if (json is! Map) return null;
    return SegmentEnd(
      airport: json['airport']?.toString() ?? fallbackAirport,
      airportName: json['airportName']?.toString(),
      city: json['city']?.toString(),
      terminal: json['terminal']?.toString(),
      time: json['time']?.toString(),
    );
  }
}

class FlightSegment {
  const FlightSegment({
    required this.segmentIndex,
    required this.airline,
    required this.airlineName,
    required this.origin,
    required this.destination,
    required this.flightNumber,
    required this.departure,
    required this.arrival,
    required this.duration,
    required this.cabinClass,
    this.aircraft,
  });

  final int segmentIndex;

  /// The IATA code, "PR".
  final String airline;
  final String airlineName;
  final String origin;
  final String destination;
  final String flightNumber;
  final SegmentEnd? departure;
  final SegmentEnd? arrival;
  final int duration;
  final String cabinClass;
  final String? aircraft;

  static FlightSegment? tryParse(Object? json) {
    if (json is! Map) return null;
    // api-v2 sends the airline as its code with the name beside it; an older shape sent
    // `{ code, name }`. Both are read.
    final rawAirline = json['airline'];
    final code = rawAirline is Map ? rawAirline['code']?.toString() : rawAirline?.toString();
    final name = json['airlineName']?.toString() ?? (rawAirline is Map ? rawAirline['name']?.toString() : null);
    final origin = json['origin']?.toString() ?? '';
    final destination = json['destination']?.toString() ?? '';
    return FlightSegment(
      segmentIndex: _int(json['segmentIndex']) ?? 0,
      airline: code ?? '',
      airlineName: (name == null || name.isEmpty) ? (code ?? '') : name,
      origin: origin,
      destination: destination,
      flightNumber: json['flightNumber']?.toString() ?? '',
      departure: SegmentEnd.tryParse(json['departure'], origin),
      arrival: SegmentEnd.tryParse(json['arrival'], destination),
      duration: _int(json['duration']) ?? 0,
      cabinClass: json['cabinClass']?.toString() ?? 'economy',
      aircraft: json['aircraft']?.toString(),
    );
  }
}

int? _int(Object? v) => v is num ? v.round() : int.tryParse(v?.toString() ?? '');
double? _double(Object? v) => v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '');
