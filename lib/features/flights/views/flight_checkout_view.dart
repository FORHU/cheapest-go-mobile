import 'package:flutter/material.dart';
import 'package:cheapest_go_mobile/features/flights/api/flights_client.dart';
import 'package:cheapest_go_mobile/features/flights/contracts/flights_contract.dart';
import 'package:cheapest_go_mobile/features/flights/stores/flights_store.dart';
import 'package:cheapest_go_mobile/shared/utils/currency.dart';

class FlightCheckoutView extends StatefulWidget {
  const FlightCheckoutView({super.key});

  @override
  State<FlightCheckoutView> createState() => _FlightCheckoutViewState();
}

class _FlightCheckoutViewState extends State<FlightCheckoutView> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthDateController = TextEditingController(text: '1995-05-15');
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _submitting = false;
  String? _statusMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthDateController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitBooking(FlightOffer offer) async {
    setState(() {
      _submitting = true;
      _statusMessage = null;
    });
    try {
      final session = await flightsClient.bookFlight(
        offer: offer,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        gender: 'm',
        birthDate: _birthDateController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      final pnr = await flightsClient.confirmFlightBooking(
        paymentIntentId: session['clientSecret'] ?? '',
        sessionId: session['sessionId'] ?? '',
      );
      if (mounted) {
        setState(() {
          _statusMessage = 'Flight booked! PNR: $pnr';
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() => _statusMessage = err.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final offer = flightsStore.selectedOffer;
    return Scaffold(
      appBar: AppBar(title: const Text('Flight Checkout')),
      body: offer == null
          ? const Center(child: Text('No flight offer selected.'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: ListTile(
                    title: Text(
                      '${FlightFormatters.providerLabel(offer.provider)} Offer',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${FlightFormatters.formatDuration(offer.totalDuration)} • ${FlightFormatters.stopsLabel(offer.totalStops)}',
                    ),
                    trailing: Text(
                      CurrencyService.formatPrice(
                        offer.price.total,
                        offer.price.currency,
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Passenger Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name (as on passport)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name (as on passport)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _birthDateController,
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth (YYYY-MM-DD)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Contact Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact Phone',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_statusMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(_statusMessage!),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _submitting ? null : () => _submitBooking(offer),
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
                          'Confirm & Pay ${CurrencyService.formatPrice(offer.price.total, offer.price.currency)}',
                        ),
                ),
              ],
            ),
    );
  }
}
