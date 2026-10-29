// Flight Contracts & Helpers — mirrors `cheapest-go-mobile/lib/flight-types.ts`.

enum CabinClass {
  economy('economy'),
  premiumEconomy('premium_economy'),
  business('business'),
  first('first');

  const CabinClass(this.wireValue);
  final String wireValue;
}

class FlightPrice {
  const FlightPrice({
    required this.total,
    required this.base,
    required this.taxes,
    required this.currency,
    required this.pricePerAdult,
  });

  final double total;
  final double base;
  final double taxes;
  final String currency;
  final double pricePerAdult;

  factory FlightPrice.fromJson(Map<String, dynamic> json) {
    final total = (json['total'] ?? 0) as num;
    return FlightPrice(
      total: total.toDouble(),
      base: ((json['base'] ?? total) as num).toDouble(),
      taxes: ((json['taxes'] ?? 0) as num).toDouble(),
      currency: (json['currency'] ?? 'USD').toString(),
      pricePerAdult: ((json['pricePerAdult'] ?? total) as num).toDouble(),
    );
  }
}

class FlightSegmentDetail {
  const FlightSegmentDetail({
    required this.segmentIndex,
    required this.airlineCode,
    required this.airlineName,
    required this.origin,
    required this.destination,
    required this.flightNumber,
    required this.departureTime,
    required this.arrivalTime,
    required this.durationMinutes,
    required this.stops,
  });

  final int segmentIndex;
  final String airlineCode;
  final String airlineName;
  final String origin;
  final String destination;
  final String flightNumber;
  final String departureTime;
  final String arrivalTime;
  final int durationMinutes;
  final int stops;

  factory FlightSegmentDetail.fromJson(Map<String, dynamic> json) {
    final airline = json['airline'] as Map<String, dynamic>?;
    final dep = json['departure'] as Map<String, dynamic>?;
    final arr = json['arrival'] as Map<String, dynamic>?;
    final code = (airline?['code'] ?? json['airlineCode'] ?? 'XX').toString();

    return FlightSegmentDetail(
      segmentIndex: ((json['segmentIndex'] ?? 0) as num).toInt(),
      airlineCode: code,
      airlineName:
          (airline?['name'] ?? FlightFormatters.getAirlineName(code)).toString(),
      origin: (json['origin'] ?? dep?['airport'] ?? '').toString(),
      destination: (json['destination'] ?? arr?['airport'] ?? '').toString(),
      flightNumber: (json['flightNumber'] ?? '').toString(),
      departureTime: (dep?['time'] ?? json['departureTime'] ?? '').toString(),
      arrivalTime: (arr?['time'] ?? json['arrivalTime'] ?? '').toString(),
      durationMinutes: ((json['duration'] ?? 0) as num).toInt(),
      stops: ((json['stops'] ?? 0) as num).toInt(),
    );
  }
}

class FlightOffer {
  const FlightOffer({
    required this.offerId,
    required this.provider,
    required this.price,
    required this.segments,
    required this.totalDuration,
    required this.totalStops,
    required this.refundable,
  });

  final String offerId;
  final String provider;
  final FlightPrice price;
  final List<FlightSegmentDetail> segments;
  final int totalDuration;
  final int totalStops;
  final bool refundable;

  factory FlightOffer.fromJson(Map<String, dynamic> json) {
    final rawSegments = json['segments'] as List? ?? const [];
    final rawPrice = json['price'];
    return FlightOffer(
      offerId: (json['offerId'] ?? json['id'] ?? '').toString(),
      provider: (json['provider'] ?? 'duffel').toString(),
      price: rawPrice is Map<String, dynamic>
          ? FlightPrice.fromJson(rawPrice)
          : FlightPrice(
              total: ((rawPrice ?? 0) as num).toDouble(),
              base: ((rawPrice ?? 0) as num).toDouble(),
              taxes: 0,
              currency: (json['currency'] ?? 'USD').toString(),
              pricePerAdult: ((rawPrice ?? 0) as num).toDouble(),
            ),
      segments: rawSegments
          .whereType<Map<String, dynamic>>()
          .map(FlightSegmentDetail.fromJson)
          .toList(),
      totalDuration: ((json['totalDuration'] ?? 0) as num).toInt(),
      totalStops: ((json['totalStops'] ?? 0) as num).toInt(),
      refundable: json['refundable'] == true,
    );
  }
}

class FlightSearchParams {
  const FlightSearchParams({
    required this.origin,
    required this.destination,
    required this.departureDate,
    this.returnDate,
    this.adults = 1,
    this.children = 0,
    this.infants = 0,
    this.cabinClass = CabinClass.economy,
    this.tripType = 'one-way',
  });

  final String origin;
  final String destination;
  final String departureDate;
  final String? returnDate;
  final int adults;
  final int children;
  final int infants;
  final CabinClass cabinClass;
  final String tripType;
}

class FlightFormatters {
  static const Map<String, String> airlines = {
    'KE': 'Korean Air',
    'OZ': 'Asiana Airlines',
    '7C': 'Jeju Air',
    'PR': 'Philippine Airlines',
    '5J': 'Cebu Pacific',
    'JL': 'Japan Airlines',
    'NH': 'ANA',
    'SQ': 'Singapore Airlines',
    'CX': 'Cathay Pacific',
    'EK': 'Emirates',
    'QR': 'Qatar Airways',
    'AA': 'American Airlines',
    'DL': 'Delta Air Lines',
    'UA': 'United Airlines',
  };

  static String getAirlineName(String code) => airlines[code] ?? code;

  static String formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  static String stopsLabel(int stops) {
    if (stops == 0) return 'Nonstop';
    if (stops == 1) return '1 stop';
    return '$stops stops';
  }

  static String providerLabel(String provider) {
    if (provider == 'mystifly_v2' || provider == 'mystifly') return 'Mystifly';
    if (provider == 'duffel') return 'Duffel';
    return provider;
  }
}
