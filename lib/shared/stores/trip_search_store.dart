import 'package:flutter/foundation.dart';
import 'package:cheapest_go_mobile/shared/search/destinations_api.dart';
import 'package:cheapest_go_mobile/shared/utils/format.dart';

/// What the traveler is looking for on arrival.
enum SearchMode { flights, stays, golf, both }

/// The current search: arrival airport, dates, and party size. Home edits it;
/// the airport hub, hotel, golf, and checkout screens read it.
class TripSearchStore extends ChangeNotifier {
  TripSearchStore({DateTime? today}) {
    final base = dateOnly(today ?? DateTime.now());
    _checkIn = base.add(const Duration(days: 14));
    _checkOut = _checkIn.add(const Duration(days: 3));
  }

  String _airportCode = 'MNL';
  String _originCode = 'SIN';

  /// Where a stay is being looked for, as a place rather than an airport.
  ///
  /// V2 asks "where are you going?" and answers it from the destination autocomplete, so a
  /// stay search is scoped to a city or a country (#38). Mobile asked for an arrival airport,
  /// which is a different question: it is where you land, not where you are going.
  ///
  /// [airportCode] stays beside it rather than being replaced. Flights genuinely need an
  /// airport, and the surfaces built on arrival airports — the hub and the map — still read it
  /// while they remain in the tree (ADR-0001). Null until someone has chosen.
  DestinationSuggestion? _destination;
  late DateTime _checkIn;
  late DateTime _checkOut;
  int _adults = 2;
  SearchMode _mode = SearchMode.stays;
  final List<String> _recentAirports = [];

  String get airportCode => _airportCode;

  /// Where the traveler flies from; [airportCode] is where they land.
  String get originCode => _originCode;
  DateTime get checkIn => _checkIn;
  DateTime get checkOut => _checkOut;
  int get adults => _adults;
  SearchMode get mode => _mode;
  int get nights => _checkOut.difference(_checkIn).inDays;
  List<String> get recentAirports => List.unmodifiable(_recentAirports);

  /// Golf players default to the party size, capped at a four-ball.
  int get players => _adults.clamp(1, 4);

  /// The days of the stay a round can be played on.
  List<DateTime> get playDays =>
      List.generate(nights + 1, (i) => _checkIn.add(Duration(days: i)));

  /// Where the stay search is pointed, once someone has said.
  DestinationSuggestion? get destination => _destination;

  /// What to call the place in a heading or a button — the chosen destination if there is
  /// one, and the arrival airport's code until then.
  String get destinationLabel => _destination?.name ?? _airportCode;

  void setDestination(DestinationSuggestion place) {
    if (_destination?.id == place.id) return;
    _destination = place;
    // An airport chosen as a destination is still an airport, and the screens that read one
    // should follow rather than stay pointed somewhere the traveller has moved on from.
    if (place.iata != null) _airportCode = place.iata!;
    notifyListeners();
  }

  void setAirport(String code) {
    if (_airportCode == code) return;
    _airportCode = code;
    notifyListeners();
  }

  void setOrigin(String code) {
    if (_originCode == code) return;
    _originCode = code;
    notifyListeners();
  }

  void setDates(DateTime checkIn, DateTime checkOut) {
    final start = dateOnly(checkIn);
    var end = dateOnly(checkOut);
    if (!end.isAfter(start)) end = start.add(const Duration(days: 1));
    _checkIn = start;
    _checkOut = end;
    notifyListeners();
  }

  void setAdults(int adults) {
    final next = adults.clamp(1, 8);
    if (_adults == next) return;
    _adults = next;
    notifyListeners();
  }

  void setMode(SearchMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }

  /// Records a submitted search so Home can offer it again.
  void remember() {
    _recentAirports
      ..remove(_airportCode)
      ..insert(0, _airportCode);
    if (_recentAirports.length > 3) _recentAirports.removeLast();
    notifyListeners();
  }
}

final TripSearchStore tripSearchStore = TripSearchStore();
