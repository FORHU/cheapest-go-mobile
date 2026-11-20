import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/shared/lib/receipt_url.dart';

void main() {
  test('builds the same combined receipt endpoint for flights and hotels', () {
    expect(
      bookingReceiptUri(
        apiUrl: 'https://cheapestgo.com',
        bookingId: '11111111-2222-3333-4444-555555555555',
        type: ReceiptType.flight,
      ).toString(),
      'https://cheapestgo.com/api/v2/invoices/11111111-2222-3333-4444-555555555555/pdf?type=flight',
    );
    expect(
      bookingReceiptUri(
        apiUrl: 'https://cheapestgo.com',
        bookingId: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        type: ReceiptType.hotel,
      ).queryParameters['type'],
      'hotel',
    );
  });
}
