/// The flight search as V2's `/flights/search` URL carries it, and the two checkout hops built
/// from it. The query names are V2's own — `origin`, `destination`, `depart`, `return`,
/// `adults`, `children`, `infants`, `cabin`, `tripType` — so a link from one product opens the
/// same search in the other.
library;

/// `YYYY-MM-DD` in the handset's calendar.
String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime? parseIsoDate(String? s) {
  if (s == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) return null;
  final p = s.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

/// V2's `resolveDepartureDate`: a date the traveller asked for, if it is still ahead, else a
/// month out — and whether it was theirs, so the page can say it picked one.
({String departure, bool chosen}) resolveDepartureDate(String? asked, {DateTime? now}) {
  final at = now ?? DateTime.now();
  final today = DateTime(at.year, at.month, at.day);
  final valid = asked != null && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(asked) ? asked : null;
  if (valid != null && valid.compareTo(isoDate(today)) > 0) return (departure: valid, chosen: true);
  return (departure: isoDate(today.add(const Duration(days: 30))), chosen: false);
}

const _cityToIata = <String, String>{
  'manila': 'MNL',
  'tokyo': 'NRT',
  'osaka': 'KIX',
  'seoul': 'ICN',
  'busan': 'PUS',
  'beijing': 'PEK',
  'shanghai': 'PVG',
  'hong kong': 'HKG',
  'hongkong': 'HKG',
  'taipei': 'TPE',
  'singapore': 'SIN',
  'bangkok': 'BKK',
  'kuala lumpur': 'KUL',
  'kl': 'KUL',
  'bali': 'DPS',
  'denpasar': 'DPS',
  'jakarta': 'CGK',
  'hanoi': 'HAN',
  'ho chi minh': 'SGN',
  'saigon': 'SGN',
  'dubai': 'DXB',
  'abu dhabi': 'AUH',
  'doha': 'DOH',
  'istanbul': 'IST',
  'delhi': 'DEL',
  'new delhi': 'DEL',
  'mumbai': 'BOM',
  'colombo': 'CMB',
  'kathmandu': 'KTM',
  'london': 'LHR',
  'paris': 'CDG',
  'amsterdam': 'AMS',
  'frankfurt': 'FRA',
  'munich': 'MUC',
  'berlin': 'BER',
  'rome': 'FCO',
  'milan': 'MXP',
  'madrid': 'MAD',
  'barcelona': 'BCN',
  'zurich': 'ZRH',
  'vienna': 'VIE',
  'athens': 'ATH',
  'lisbon': 'LIS',
  'brussels': 'BRU',
  'copenhagen': 'CPH',
  'stockholm': 'ARN',
  'oslo': 'OSL',
  'helsinki': 'HEL',
  'prague': 'PRG',
  'warsaw': 'WAW',
  'budapest': 'BUD',
  'new york': 'JFK',
  'nyc': 'JFK',
  'los angeles': 'LAX',
  'la': 'LAX',
  'san francisco': 'SFO',
  'sf': 'SFO',
  'chicago': 'ORD',
  'miami': 'MIA',
  'toronto': 'YYZ',
  'vancouver': 'YVR',
  'cancun': 'CUN',
  'mexico city': 'MEX',
  'sydney': 'SYD',
  'melbourne': 'MEL',
  'auckland': 'AKL',
  'da nang': 'DAD',
  'danang': 'DAD',
  'phu quoc': 'PQC',
};

/// An airport code from whatever the link carries: "MNL", "Clark (CRK)", or "Seoul".
/// The parenthesised code wins when there is one.
String? resolveIata(String input) {
  final trimmed = input.trim();
  final upper = trimmed.toUpperCase();
  if (RegExp(r'^[A-Z]{3}$').hasMatch(upper)) return upper;
  final tagged = RegExp(r'\(([A-Z]{3})\)').firstMatch(upper);
  if (tagged != null) return tagged.group(1);
  return _cityToIata[trimmed.toLowerCase()];
}

/// "CRK" out of "Clark (CRK)" — what the phone bar has room for.
String shortPlaceLabel(String place) => RegExp(r'\(([A-Z]{3})\)').firstMatch(place)?.group(1) ?? place;

/// "Seoul" out of "Seoul (ICN)", for "Flights to …".
String placeCity(String place) {
  final city = place.replaceAll(RegExp(r'\s*\([A-Z]{3}\)\s*$'), '');
  return city.isEmpty ? place : city;
}

const fareGoneParam = 'fareGone';

class FlightSearchQuery {
  const FlightSearchQuery({
    required this.origin,
    required this.destination,
    required this.departure,
    this.returnDate,
    this.adults = 1,
    this.children = 0,
    this.infants = 0,
    this.cabin = 'economy',
    this.departureChosen = true,
  });

  /// As the link carries them — "Clark (CRK)", or a bare code.
  final String origin;
  final String destination;
  final String departure;
  final String? returnDate;
  final int adults;
  final int children;
  final int infants;
  final String cabin;

  /// False when the departure is one this screen picked rather than one the traveller asked for.
  final bool departureChosen;

  String get tripType => returnDate != null && returnDate!.isNotEmpty ? 'round-trip' : 'one-way';

  factory FlightSearchQuery.fromParams(Map<String, String> p, {DateTime? now}) {
    final resolved = resolveDepartureDate(p['depart'] ?? p['departure'], now: now);
    int count(String key, int fallback, int min) {
      final n = int.tryParse(p[key] ?? '') ?? fallback;
      return n < min ? min : n;
    }

    final ret = p['return'];
    return FlightSearchQuery(
      origin: p['origin'] ?? '',
      destination: p['destination'] ?? '',
      departure: resolved.departure,
      departureChosen: resolved.chosen,
      returnDate: ret == null || ret.isEmpty ? null : ret,
      adults: count('adults', 1, 1),
      children: count('children', 0, 0),
      infants: count('infants', 0, 0),
      cabin: p['cabin'] ?? 'economy',
    );
  }

  FlightSearchQuery copyWith({
    String? origin,
    String? destination,
    String? departure,
    String? Function()? returnDate,
    int? adults,
    int? children,
    int? infants,
    String? cabin,
  }) => FlightSearchQuery(
    origin: origin ?? this.origin,
    destination: destination ?? this.destination,
    departure: departure ?? this.departure,
    returnDate: returnDate != null ? returnDate() : this.returnDate,
    adults: adults ?? this.adults,
    children: children ?? this.children,
    infants: infants ?? this.infants,
    cabin: cabin ?? this.cabin,
  );

  /// The search as a link, in the shape V2's landing search writes it.
  Map<String, String> toParams() => {
    'origin': origin,
    'destination': destination,
    'depart': departure,
    'tripType': tripType,
    'cabin': cabin,
    'adults': '$adults',
    'children': '$children',
    'infants': '$infants',
    if (returnDate != null && returnDate!.isNotEmpty) 'return': returnDate!,
  };

  String toLocation({bool fareGone = false}) =>
      Uri(path: '/flights/search', queryParameters: {...toParams(), if (fareGone) fareGoneParam: '1'}).toString();
}
