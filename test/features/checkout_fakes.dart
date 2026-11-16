import 'package:cheapest_go_mobile/features/hotels/api/checkout_api.dart';
import 'package:cheapest_go_mobile/features/hotels/api/payment_gateway.dart';

/// api-v2 and Stripe, stood in for. See #41.
///
/// The two seams a widget test needs: HTTP, which `TestWidgetsFlutterBinding` answers 400 to,
/// and Stripe's sheet, which is a platform view behind a method channel that a test has
/// neither of. Everything between them — the price that is charged, the booking that is made,
/// the row Trips reads — is the real screen.
///
/// The bodies these answer with are api-v2's own shapes, parsed by the same `fromJson` the app
/// uses, so a test fails if the wire contract and this client drift apart.

/// A prebook body as `POST /api/v2/hotels/prebook` sends it.
Map<String, dynamic> prebookBody({
    String prebookId = 'pre_1',
    num total = 12000,
    num serviceFee = 1200,
    String currency = 'PHP',
    Map<String, dynamic>? priceChange,
    bool withDisplay = true,
    String? substitutedRoomName,
}) => {
        'success': true,
        'data': {
            'prebookId': prebookId,
            'provider': 'mock',
            'price': {'subtotal': total, 'taxes': 0, 'total': total},
            if (withDisplay)
                'display': {
                    'currency': currency,
                    'subtotal': total,
                    'taxes': 0,
                    'total': total,
                    'serviceFee': serviceFee,
                    'chargedTotal': total + serviceFee,
                    'converted': false,
                },
            'priceChange': ?priceChange,
            'currency': currency,
            'boardCode': 'RO',
            if (substitutedRoomName != null) ...{
                'roomSubstituted': true,
                'substitutedRoomName': substitutedRoomName,
            },
        },
    };

class FakeCheckoutApi extends CheckoutApi {
    FakeCheckoutApi({Map<String, dynamic>? prebook, Map<String, dynamic>? confirm})
        : _prebook = prebook ?? prebookBody(),
          _confirm = confirm ??
              {
                  'success': true,
                  'data': {'bookingId': 'CG-ABC12', 'status': 'confirmed'},
              };

    final Map<String, dynamic> _prebook;
    final Map<String, dynamic> _confirm;

    /// What the screen asked for, in order, so a test can hold it to the sequence.
    final calls = <String>[];

    /// The bodies the screen sent, for the figures and the guest it put in them.
    final sent = <String, Map<String, dynamic>>{};

    @override
    Future<PrebookQuote> prebook({
        required String offerId,
        required String currency,
        String? roomName,
        int? adults,
        int? children,
        num? expectedTotal,
    }) async {
        calls.add('prebook:$offerId');
        sent['prebook'] = {
            'currency': currency,
            'roomName': roomName,
            'adults': adults,
            'expectedTotal': expectedTotal,
        };
        return PrebookQuote.fromJson(_prebook);
    }

    @override
    Future<PaymentIntentHandle> createPayment({
        required PrebookQuote quote,
        required String firstName,
        required String lastName,
        required String email,
        required DateTime checkIn,
        required DateTime checkOut,
        String? holderPhone,
        String? propertyName,
        String? propertyImage,
        String? roomName,
        int? adults,
        int? children,
        String? specialRequests,
    }) async {
        final display = quote.display;
        if (display == null) {
            // The real client's rule, kept here so a test cannot sail past it.
            throw Exception('We could not confirm the price in your currency just now. '
                'Please try again in a moment.');
        }
        calls.add('createPayment:${quote.prebookId}');
        sent['createPayment'] = {
            'amount': display.total,
            'displayedTotal': display.chargedTotal,
            'currency': display.currency,
            'email': email,
            'name': '$firstName $lastName',
        };
        return PaymentIntentHandle.fromJson({
            'success': true,
            'data': {
                'clientSecret': 'pi_1_secret_x',
                'paymentIntentId': 'pi_1',
                'bookingReference': 'CG-ABC12',
                'chargedTotal': display.chargedTotal,
                'serviceFee': display.serviceFee,
                'currency': display.currency,
            },
        });
    }

    @override
    Future<ConfirmOutcome> confirm({
        required String paymentIntentId,
        required PrebookQuote quote,
        required String firstName,
        required String lastName,
        required String email,
        required DateTime checkIn,
        required DateTime checkOut,
        String? holderPhone,
        String? propertyName,
        String? propertyImage,
        String? roomName,
        int? adults,
        int? children,
        String? specialRequests,
    }) async {
        calls.add('confirm:$paymentIntentId');
        sent['confirm'] = {
            'prebookId': quote.prebookId,
            'email': email,
            'roomName': roomName,
            'specialRequests': specialRequests,
        };
        return ConfirmOutcome.fromJson(_confirm);
    }
}

/// The sheet, without the sheet. [cancel] is the traveller shutting it, which is not a failure.
class FakePaymentGateway implements PaymentGateway {
    FakePaymentGateway({this.cancel = false, this.declineWith});

    final bool cancel;
    final String? declineWith;
    bool presented = false;

    @override
    Future<void> payFor({
        required String clientSecret,
        required String email,
        required String name,
        String? phone,
    }) async {
        presented = true;
        if (cancel) throw const PaymentCancelled();
        if (declineWith != null) throw Exception(declineWith);
    }
}
