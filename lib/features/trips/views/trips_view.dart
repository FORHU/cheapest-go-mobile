import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/shared/components/glass_card.dart';
import 'package:cheapest_go_mobile/shared/components/skeleton.dart';
import 'package:cheapest_go_mobile/shared/errors/error_router.dart';
import 'package:cheapest_go_mobile/shared/lib/http.dart';
import 'package:cheapest_go_mobile/shared/stores/ui_store.dart';
import 'package:cheapest_go_mobile/shared/utils/currency.dart';

// --- Booked Trips Model & Store ---

class TripBookingRecord {
  const TripBookingRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.reference,
    required this.status,
    required this.totalPrice,
    required this.currency,
    required this.subtitle,
  });

  final String id;
  final String type; // 'hotel' | 'flight'
  final String title;
  final String reference;
  final String status;
  final double totalPrice;
  final String currency;
  final String subtitle;

  factory TripBookingRecord.fromHotelJson(Map<String, dynamic> json) {
    final checkIn = (json['check_in'] ?? '').toString().split('T').first;
    final checkOut = (json['check_out'] ?? '').toString().split('T').first;
    return TripBookingRecord(
      id: (json['id'] ?? json['booking_id'] ?? '').toString(),
      type: 'hotel',
      title: (json['property_name'] ?? 'Hotel Stay').toString(),
      reference: (json['booking_id'] ?? 'PENDING').toString(),
      status: (json['status'] ?? 'confirmed').toString(),
      totalPrice: ((json['total_price'] ?? 0) as num).toDouble(),
      currency: (json['currency'] ?? 'USD').toString(),
      subtitle: checkIn.isNotEmpty ? '$checkIn → $checkOut' : 'Hotel Booking',
    );
  }

  factory TripBookingRecord.fromFlightJson(Map<String, dynamic> json) {
    return TripBookingRecord(
      id: (json['id'] ?? '').toString(),
      type: 'flight',
      title: 'Flight (${(json['provider'] ?? 'duffel').toString().toUpperCase()})',
      reference: (json['pnr'] ?? 'PENDING').toString(),
      status: (json['status'] ?? 'booked').toString(),
      totalPrice:
          ((json['charged_price'] ?? json['total_price'] ?? 0) as num).toDouble(),
      currency: (json['currency'] ?? 'USD').toString(),
      subtitle: (json['created_at'] ?? '').toString().split('T').first,
    );
  }
}

class TripsStore extends ChangeNotifier {
  List<TripBookingRecord> _bookings = const [];
  bool _isLoading = false;
  String? _errorMessage;

  List<TripBookingRecord> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Calls `GET /api/v2/mobile/trips`
  Future<void> fetchMyTrips() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await http.get('/api/v2/mobile/trips');
      if (res is Map<String, dynamic>) {
        final hotels = (res['hotels'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(TripBookingRecord.fromHotelJson);
        final flights = (res['flights'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(TripBookingRecord.fromFlightJson);
        final legacyList = (res['data'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(TripBookingRecord.fromFlightJson);
        _bookings = [...hotels, ...flights, ...legacyList];
      }
    } catch (err) {
      final routed = routeError(err);
      _errorMessage = routed.toast ?? err.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

final TripsStore tripsStore = TripsStore();

// --- Saved / Favorite Stays Model & Store ---

class SavedHotelItem {
  const SavedHotelItem({
    required this.hotelId,
    required this.name,
    required this.city,
    required this.nightlyRate,
    required this.currency,
  });

  final String hotelId;
  final String name;
  final String city;
  final double nightlyRate;
  final String currency;

  factory SavedHotelItem.fromJson(Map<String, dynamic> json) {
    return SavedHotelItem(
      hotelId: (json['hotelId'] ?? '').toString(),
      name: (json['name'] ?? 'Saved Property').toString(),
      city: (json['city'] ?? '').toString(),
      nightlyRate: ((json['nightlyRate'] ?? 0) as num).toDouble(),
      currency: (json['currency'] ?? 'USD').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'hotelId': hotelId,
        'name': name,
        'city': city,
        'nightlyRate': nightlyRate,
        'currency': currency,
      };
}

class SavedHotelsStore extends ChangeNotifier {
  static const String _savedKey = 'saved_hotels_data';

  final Map<String, SavedHotelItem> _saved = {};

  List<SavedHotelItem> get items => _saved.values.toList(growable: false);

  bool isFavorite(String hotelId) => _saved.containsKey(hotelId);

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_savedKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _saved.clear();
        for (final entry in decoded.entries) {
          if (entry.value is Map<String, dynamic>) {
            _saved[entry.key] = SavedHotelItem.fromJson(
              entry.value as Map<String, dynamic>,
            );
          }
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> toggleFavorite(SavedHotelItem item) async {
    final bool added;
    if (_saved.containsKey(item.hotelId)) {
      _saved.remove(item.hotelId);
      added = false;
    } else {
      _saved[item.hotelId] = item;
      added = true;
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final serialized = _saved.map((k, v) => MapEntry(k, v.toJson()));
      await prefs.setString(_savedKey, jsonEncode(serialized));
    } catch (_) {}
    return added;
  }
}

final SavedHotelsStore savedHotelsStore = SavedHotelsStore();

// --- Consolidated Trips & Saved View ---

class TripsView extends StatefulWidget {
  const TripsView({super.key});

  @override
  State<TripsView> createState() => _TripsViewState();
}

class _TripsViewState extends State<TripsView> {
  int _selectedTab = 0; // 0: Booked Trips, 1: Saved Stays

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      tripsStore.fetchMyTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([tripsStore, savedHotelsStore, uiSettingsStore]),
      builder: (context, _) {
        final bookedCount = tripsStore.bookings.length;
        final savedCount = savedHotelsStore.items.length;

        return Column(
          children: [
            // Segmented Switcher Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: context.colors.background,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: context.colors.backgroundCanvas,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0
                                ? context.colors.surface
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: _selectedTab == 0
                                ? const [
                                    BoxShadow(
                                      color: Color(0x0F0F172A),
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.luggage_outlined,
                                size: 16,
                                color: _selectedTab == 0
                                    ? context.colors.accent
                                    : context.colors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Bookings ($bookedCount)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _selectedTab == 0
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: _selectedTab == 0
                                      ? context.colors.textPrimary
                                      : context.colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1
                                ? context.colors.surface
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: _selectedTab == 1
                                ? const [
                                    BoxShadow(
                                      color: Color(0x140F172A),
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.favorite_rounded,
                                size: 16,
                                color: _selectedTab == 1
                                    ? const Color(0xFFF43F5E)
                                    : context.colors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Saved Stays ($savedCount)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _selectedTab == 1
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: _selectedTab == 1
                                      ? context.colors.textPrimary
                                      : context.colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tab Content
            Expanded(
              child: _selectedTab == 0
                  ? _buildBookingsTab(context)
                  : _buildSavedTab(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBookingsTab(BuildContext context) {
    if (tripsStore.isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => const Skeleton(height: 96),
      );
    }
    if (tripsStore.bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: KineticHorizonColors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.luggage_outlined,
                  size: 32,
                  color: KineticHorizonColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Booked Trips Yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: KineticHorizonColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Once you confirm a hotel or flight booking, your live itinerary will appear here.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              if (tripsStore.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  tripsStore.errorMessage!,
                  style: const TextStyle(fontSize: 11, color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KineticHorizonColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: tripsStore.fetchMyTrips,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh Bookings'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tripsStore.bookings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final b = tripsStore.bookings[index];
        final isHotel = b.type == 'hotel';
        final colors = context.colors;
        return GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.backgroundCanvas,
                  borderRadius: AppRadius.brMd,
                ),
                child: Icon(
                  isHotel ? Icons.hotel_rounded : Icons.flight_takeoff_rounded,
                  color: isHotel ? const Color(0xFF0D9488) : colors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ref: ${b.reference}',
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                    Text(
                      b.subtitle,
                      style: TextStyle(fontSize: 11, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyService.formatPrice(b.totalPrice, b.currency),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.accent,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: b.status == 'confirmed' || b.status == 'booked'
                          ? const Color(0xFFCCFBF1)
                          : colors.backgroundCanvas,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      b.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: b.status == 'confirmed' || b.status == 'booked'
                            ? const Color(0xFF0F766E)
                            : colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSavedTab(BuildContext context) {
    final items = savedHotelsStore.items;
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_outline_rounded,
                  size: 32,
                  color: KineticHorizonColors.dealCoral,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Saved Stays',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: KineticHorizonColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Explore hotels and resorts, then tap the heart icon on any card to save your favorites here.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KineticHorizonColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => context.go('/hotels'),
                child: const Text('Explore Hotels'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        final converted = CurrencyService.convertCurrency(
          item.nightlyRate,
          item.currency,
          uiSettingsStore.displayCurrency,
        );
        final colors = context.colors;

        return GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          onTap: () => context.go('/hotels'),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.backgroundCanvas,
                  borderRadius: AppRadius.brMd,
                ),
                child: Icon(
                  Icons.hotel_outlined,
                  color: colors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.city,
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyService.formatPrice(
                      converted,
                      uiSettingsStore.displayCurrency,
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.accent,
                    ),
                  ),
                  Text(
                    '/night',
                    style: TextStyle(fontSize: 10, color: colors.textMuted),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFF43F5E),
                  size: 20,
                ),
                onPressed: () => savedHotelsStore.toggleFavorite(item),
              ),
            ],
          ),
        );
      },
    );
  }
}
