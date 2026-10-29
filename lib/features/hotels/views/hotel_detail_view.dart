import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cheapest_go_mobile/features/hotels/stores/hotels_store.dart';
import 'package:cheapest_go_mobile/shared/stores/ui_store.dart';
import 'package:cheapest_go_mobile/shared/utils/currency.dart';

class HotelDetailView extends StatefulWidget {
  const HotelDetailView({
    super.key,
    required this.hotelId,
  });

  final String hotelId;

  @override
  State<HotelDetailView> createState() => _HotelDetailViewState();
}

class _HotelDetailViewState extends State<HotelDetailView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      hotelsStore.loadHotelDetails(
        widget.hotelId,
        currency: uiSettingsStore.displayCurrency,
      );
    });
  }

  Future<void> _selectAndPrebook(String offerId, String roomName) async {
    final quote = await hotelsStore.lockRatePrebook(
      offerId: offerId,
      currency: uiSettingsStore.displayCurrency,
      roomName: roomName,
    );
    if (quote != null && mounted) {
      context.push('/checkout');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hotel Details')),
      body: ListenableBuilder(
        listenable: Listenable.merge([hotelsStore, uiSettingsStore]),
        builder: (context, _) {
          if (hotelsStore.isLoading && hotelsStore.selectedHotel == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final hotel = hotelsStore.selectedHotel;
          if (hotel == null) {
            return Center(
              child: Text(
                hotelsStore.errorMessage ?? 'Hotel details unavailable.',
              ),
            );
          }
          final displayCcy = uiSettingsStore.displayCurrency;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                hotel.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${hotel.city}, ${hotel.countryCode} • ${'★' * hotel.starRating}',
                style: const TextStyle(color: Colors.grey),
              ),
              if (hotel.reviewRating != null) ...[
                const SizedBox(height: 8),
                Chip(
                  avatar: const Icon(Icons.verified, size: 18),
                  label: Text(
                    'Aggregate Score: ${hotel.reviewRating!.toStringAsFixed(1)} (${hotel.reviewsCount} reviews)',
                  ),
                ),
              ],
              const Divider(height: 32),
              const Text(
                'Available Offers & Rates',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (hotel.offers.isEmpty)
                Card(
                  child: ListTile(
                    title: const Text('Standard Room (First Available Rate)'),
                    subtitle: Text(
                      'Stay Total: ${CurrencyService.formatPrice(hotel.stayTotal, displayCcy)}',
                    ),
                    trailing: FilledButton(
                      onPressed: hotelsStore.isLoading
                          ? null
                          : () => _selectAndPrebook(
                                hotel.hotelId,
                                'Standard Room',
                              ),
                      child: const Text('Prebook'),
                    ),
                  ),
                )
              else
                ...hotel.offers.map(
                  (offer) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(offer.roomName),
                      subtitle: Text(
                        '${offer.refundable ? 'Refundable' : 'Non-refundable'}'
                        '${offer.boardName != null ? ' • ${offer.boardName}' : ''}\n'
                        'Stay Total: ${CurrencyService.formatPrice(offer.stayTotal, offer.currency)}',
                      ),
                      isThreeLine: true,
                      trailing: FilledButton(
                        onPressed: hotelsStore.isLoading
                            ? null
                            : () => _selectAndPrebook(
                                  offer.offerId,
                                  offer.roomName,
                                ),
                        child: Text(
                          '${CurrencyService.formatPrice(offer.nightlyRate, offer.currency)} / night',
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
