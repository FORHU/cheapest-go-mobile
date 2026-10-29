import 'package:flutter/foundation.dart';
import 'package:cheapest_go_mobile/features/flights/api/flights_client.dart';
import 'package:cheapest_go_mobile/features/flights/contracts/flights_contract.dart';
import 'package:cheapest_go_mobile/shared/errors/error_router.dart';

class FlightsStore extends ChangeNotifier {
  List<FlightOffer> _offers = const [];
  FlightOffer? _selectedOffer;
  bool _isLoading = false;
  String? _errorMessage;

  List<FlightOffer> get offers => _offers;
  FlightOffer? get selectedOffer => _selectedOffer;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void selectOffer(FlightOffer offer) {
    _selectedOffer = offer;
    notifyListeners();
  }

  Future<void> search(FlightSearchParams params) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _offers = await flightsClient.searchFlights(params);
    } catch (err) {
      final routed = routeError(err);
      _errorMessage = routed.toast ?? err.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

final FlightsStore flightsStore = FlightsStore();
