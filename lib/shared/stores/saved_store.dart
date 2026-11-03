import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hotels the traveler has saved, kept on the device.
class SavedStaysStore extends ChangeNotifier {
  static const _key = 'cheapestgo_saved_hotel_ids';

  final Set<String> _ids = {};

  Set<String> get ids => Set.unmodifiable(_ids);

  bool isSaved(String hotelId) => _ids.contains(hotelId);

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _ids
        ..clear()
        ..addAll(prefs.getStringList(_key) ?? const []);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> clear() async {
    _ids.clear();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }

  Future<void> toggle(String hotelId) async {
    if (!_ids.remove(hotelId)) _ids.add(hotelId);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, _ids.toList());
    } catch (_) {}
  }
}

final SavedStaysStore savedStaysStore = SavedStaysStore();
