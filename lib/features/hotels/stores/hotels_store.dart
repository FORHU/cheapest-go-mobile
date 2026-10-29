import 'package:flutter/foundation.dart';
import 'package:cheapest_go_mobile/features/hotels/api/hotels_client.dart';
import 'package:cheapest_go_mobile/features/hotels/contracts/hotels_contract.dart';
import 'package:cheapest_go_mobile/shared/errors/error_router.dart';

class HotelsStore extends ChangeNotifier {
  List<HotelSummary> _results = const [];
  HotelSummary? _selectedHotel;
  PrebookQuote? _activePrebook;
  bool _isLoading = false;
  String? _errorMessage;

  String _lastCheckIn = '2026-11-10';
  String _lastCheckOut = '2026-11-13';
  int _lastAdults = 2;
  int _lastRooms = 1;

  List<HotelSummary> get results => _results;
  HotelSummary? get selectedHotel => _selectedHotel;
  PrebookQuote? get activePrebook => _activePrebook;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get lastCheckIn => _lastCheckIn;
  String get lastCheckOut => _lastCheckOut;
  int get lastAdults => _lastAdults;
  int get lastRooms => _lastRooms;

  Future<void> search(HotelSearchParams params) async {
    _isLoading = true;
    _errorMessage = null;
    _lastCheckIn = params.checkIn;
    _lastCheckOut = params.checkOut;
    _lastAdults = params.adults;
    _lastRooms = params.rooms;
    notifyListeners();

    try {
      _results = await hotelsClient.searchHotels(params);
    } catch (err) {
      final routed = routeError(err);
      _errorMessage = routed.toast ?? err.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadHotelDetails(String hotelId, {String currency = 'USD'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final existing = _results.where((h) => h.hotelId == hotelId).firstOrNull;
      if (existing != null) {
        _selectedHotel = existing;
      }
      final detail = await hotelsClient.getHotelDetails(
        hotelId,
        checkIn: _lastCheckIn,
        checkOut: _lastCheckOut,
        adults: _lastAdults,
        rooms: _lastRooms,
        currency: currency,
        fallback: existing,
      );
      if (detail != null) {
        _selectedHotel = detail;
      }
    } catch (err) {
      final routed = routeError(err);
      _errorMessage = routed.toast ?? err.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PrebookQuote?> lockRatePrebook({
    required String offerId,
    required String currency,
    String? roomName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final quote = await hotelsClient.prebookRoom(
        offerId: offerId,
        currency: currency,
        adults: _lastAdults,
        roomName: roomName,
      );
      _activePrebook = quote;
      return quote;
    } catch (err) {
      final routed = routeError(err);
      _errorMessage = routed.toast ?? err.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

final HotelsStore hotelsStore = HotelsStore();
