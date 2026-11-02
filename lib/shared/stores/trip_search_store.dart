import 'package:flutter/foundation.dart';
import 'package:cheapest_go_mobile/shared/utils/format.dart';

/// What the traveler is looking for on arrival.
enum SearchMode { stays, golf, both }

/// The current search: arrival airport, dates, and party size. Home edits it;
/// the airport hub, hotel, golf, and checkout screens read it.
class TripSearchStore extends ChangeNotifier {
  TripSearchStore({DateTime? today}) {
    final base = dateOnly(today ?? DateTime.now());
    _checkIn = base.add(const Duration(days: 14));
    _checkOut = _checkIn.add(const Duration(days: 3));
  }

  String _airportCode = 'MNL';
  late DateTime _checkIn;
  late DateTime _checkOut;
  int _adults = 2;
  SearchMode _mode = SearchMode.stays;
  final List<String> _recentAirports = [];

  String get airportCode => _airportCode;
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

  void setAirport(String code) {
    if (_airportCode == code) return;
    _airportCode = code;
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
