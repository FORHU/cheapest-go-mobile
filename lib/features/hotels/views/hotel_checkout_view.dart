import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cheapest_go_mobile/features/hotels/api/hotels_client.dart';
import 'package:cheapest_go_mobile/features/hotels/stores/hotels_store.dart';
import 'package:cheapest_go_mobile/shared/utils/currency.dart';

class HotelCheckoutView extends StatefulWidget {
  const HotelCheckoutView({super.key});

  @override
  State<HotelCheckoutView> createState() => _HotelCheckoutViewState();
}

class _HotelCheckoutViewState extends State<HotelCheckoutView> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _submitting = false;
  String? _statusMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _completeBooking() async {
    final quote = hotelsStore.activePrebook;
    final hotel = hotelsStore.selectedHotel;
    if (quote == null) return;

    setState(() {
      _submitting = true;
      _statusMessage = null;
    });

    try {
      final payment = await hotelsClient.createHotelPayment(
        prebookId: quote.prebookId,
        amount: quote.authoritativePrice,
        currency: quote.chargeCurrency,
        holderEmail: _emailController.text.trim(),
        propertyName: hotel?.name,
        checkIn: hotelsStore.lastCheckIn,
        checkOut: hotelsStore.lastCheckOut,
      );

      final bookingId = await hotelsClient.confirmHotelBooking(
        prebookId: quote.prebookId,
        paymentIntentId: payment['paymentIntentId'] ?? '',
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        propertyName: hotel?.name,
        checkIn: hotelsStore.lastCheckIn,
        checkOut: hotelsStore.lastCheckOut,
        currency: quote.chargeCurrency,
      );

      if (mounted) {
        setState(() {
          _statusMessage = 'Booking confirmed! Reference: $bookingId';
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _statusMessage = err.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quote = hotelsStore.activePrebook;
    final hotel = hotelsStore.selectedHotel;

    return Scaffold(
      appBar: AppBar(title: const Text('Hotel Checkout')),
      body: quote == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No active Prebook quote locked.'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Back to Hotel'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hotel?.name ?? 'Selected Property',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Check-in: ${hotelsStore.lastCheckIn} → Check-out: ${hotelsStore.lastCheckOut}',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Authoritative Prebook Total (${quote.chargeCurrency}): '
                          '${CurrencyService.formatPrice(quote.authoritativePrice, quote.chargeCurrency)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (quote.refundableTag != null)
                          Text('Policy: ${quote.refundableTag}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Lead Guest Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Lead Guest First Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Lead Guest Last Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Confirmation Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_statusMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage!,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submitting ? null : _completeBooking,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Pay ${CurrencyService.formatPrice(quote.authoritativePrice, quote.chargeCurrency)}',
                        ),
                ),
              ],
            ),
    );
  }
}
