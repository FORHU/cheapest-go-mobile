import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:cheapest_go_mobile/shared/lib/env.dart';

/// Taking the card. See #41.
///
/// A seam, for one reason: Stripe's sheet is a platform view behind a method channel, and a
/// widget test has neither. Without this, the half of checkout that matters — paid, then
/// booked, then confirmed on screen — could only ever be tested by hand on a device.
///
/// The real implementation is four lines and holds no card data: the number is entered into
/// Stripe's own sheet, and this app never sees it.
abstract class PaymentGateway {
    /// Shows the sheet for an intent and returns when it has been paid.
    ///
    /// Throws [PaymentCancelled] when the traveller closed it, which is not a failure and must
    /// not be reported as one.
    Future<void> payFor({
        required String clientSecret,
        required String email,
        required String name,
        String? phone,
    });
}

/// The traveller shut the sheet. Their own decision, and the checkout stays where it was.
class PaymentCancelled implements Exception {
    const PaymentCancelled();
}

class StripePaymentGateway implements PaymentGateway {
    const StripePaymentGateway();

    @override
    Future<void> payFor({
        required String clientSecret,
        required String email,
        required String name,
        String? phone,
    }) async {
        // No key, no sheet. Said here rather than letting the SDK fail on a null key, and said
        // at the moment someone taps Pay, which is when it can be acted on.
        if (env.stripePublishableKey.isEmpty) {
            throw Exception('Payments are not configured in this build.');
        }
        try {
            await Stripe.instance.initPaymentSheet(
                paymentSheetParameters: SetupPaymentSheetParameters(
                    paymentIntentClientSecret: clientSecret,
                    merchantDisplayName: 'CheapestGo',
                    billingDetails: BillingDetails(email: email, name: name, phone: phone),
                ),
            );
            await Stripe.instance.presentPaymentSheet();
        } on StripeException catch (error) {
            if (error.error.code == FailureCode.Canceled) throw const PaymentCancelled();
            // The SDK's own wording: it knows why the bank refused and this app does not.
            throw Exception(error.error.localizedMessage ?? error.error.message);
        }
    }
}

/// The app's gateway. Replaced in tests.
PaymentGateway paymentGateway = const StripePaymentGateway();
