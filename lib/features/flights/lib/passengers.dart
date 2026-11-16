import 'package:cheapest_go_mobile/features/flights/lib/flight_search_query.dart';

/// One traveller on the booking form — V2's `PassengerInfo`.
class PassengerInfo {
  PassengerInfo(this.type);

  /// `ADT`, `CHD` or `INF`, in the order the offer lists its passengers.
  final String type;
  String firstName = '';
  String lastName = '';

  /// The lead traveller's only: they are the booking's contact.
  String email = '';
  String phone = '';

  /// `YYYY-MM-DD`.
  String dateOfBirth = '';

  /// `M` or `F`, as the API takes it; empty until chosen.
  String gender = '';
  String passportNumber = '';
  String passportExpiry = '';

  /// The passport's issuing country, ISO 3166 alpha-2.
  String country = '';

  /// The body `/flights/book` takes for this traveller. Duffel puts the booking's contact on
  /// every passenger, so each carries the lead's email and phone.
  Map<String, Object?> toBooking(PassengerInfo lead) => {
    'firstName': firstName.trim(),
    'lastName': lastName.trim(),
    'email': lead.email.trim(),
    'phone': lead.phone.trim(),
    'dateOfBirth': dateOfBirth,
    'gender': gender,
    'passportNumber': passportNumber.trim(),
    'passportExpiry': passportExpiry,
    'nationality': country.trim().toUpperCase(),
    'type': type,
  };
}

/// One form per traveller the fare was priced for: adults, then children, then infants.
List<PassengerInfo> passengersFor({required int adults, required int children, required int infants}) => [
  for (var i = 0; i < (adults < 1 ? 1 : adults); i++) PassengerInfo('ADT'),
  for (var i = 0; i < children; i++) PassengerInfo('CHD'),
  for (var i = 0; i < infants; i++) PassengerInfo('INF'),
];

bool validEmail(String email) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);

/// V2's `validatePassengers`, message for message, keyed `"<index>.<field>"`.
Map<String, String> validatePassengers(List<PassengerInfo> passengers) {
  final errors = <String, String>{};
  for (var i = 0; i < passengers.length; i++) {
    final p = passengers[i];
    if (p.firstName.trim().isEmpty) errors['$i.firstName'] = 'Required';
    if (p.lastName.trim().isEmpty) errors['$i.lastName'] = 'Required';
    if (i == 0) {
      if (p.email.trim().isEmpty) {
        errors['$i.email'] = 'Required';
      } else if (!validEmail(p.email)) {
        errors['$i.email'] = 'Invalid email';
      }
      if (p.phone.trim().isEmpty) errors['$i.phone'] = 'Required';
    }
    if (p.dateOfBirth.isEmpty) errors['$i.dateOfBirth'] = 'Required';
    // Gender, because the order builder defaults a missing one to female and a ticket whose
    // gender disagrees with the passport is refused at the gate.
    if (p.gender.isEmpty) errors['$i.gender'] = 'Required';
    if (p.passportNumber.trim().isEmpty) errors['$i.passportNumber'] = 'Required';
    // Expiry and issuing country travel with the number or the airline gets none of it.
    if (p.passportExpiry.isEmpty) errors['$i.passportExpiry'] = 'Required';
    if (p.country.trim().length != 2) errors['$i.country'] = '2-letter country code';
  }
  return errors;
}

/// The dates a date field may take, and where it opens — V2's `DateBounds`.
class DateBounds {
  const DateBounds({required this.min, required this.max, required this.anchor});

  final String min;
  final String max;
  final String anchor;
}

String _addYears(String iso, int years) {
  final d = parseIsoDate(iso)!;
  final year = d.year + years;
  final lastDay = DateTime(year, d.month + 1, 0).day;
  return isoDate(DateTime(year, d.month, d.day > lastDay ? lastDay : d.day));
}

String _addDays(String iso, int days) => isoDate(parseIsoDate(iso)!.add(Duration(days: days)));

String _clamp(String iso, String min, String max) =>
    iso.compareTo(min) < 0 ? min : (iso.compareTo(max) > 0 ? max : iso);

/// An airline judges age on the day of travel: an adult is 12 or over, a child 2 to 11, an infant
/// under 2. A birthday outside the band is refused when the order is placed — after the card.
DateBounds birthDateBounds(String type, String departure, String today) {
  final on = departure.isNotEmpty ? departure : today;
  final (min, max, likely) = switch (type) {
    'CHD' => (_addDays(_addYears(on, -12), 1), _addYears(on, -2), _addYears(on, -7)),
    'INF' => (_addDays(_addYears(on, -2), 1), on, _addYears(on, -1)),
    _ => (_addYears(on, -120), _addYears(on, -12), _addYears(on, -30)),
  };
  // Nobody is booked before they are born.
  final capped = max.compareTo(today) < 0 ? max : today;
  return DateBounds(min: min, max: capped, anchor: _clamp(likely, min, capped));
}

/// Valid on the day of departure; passports run ten years, so twenty is a generous ceiling.
DateBounds passportExpiryBounds(String departure, String today) {
  final min = departure.isNotEmpty ? departure : today;
  return DateBounds(min: min, max: _addYears(today, 20), anchor: min);
}
