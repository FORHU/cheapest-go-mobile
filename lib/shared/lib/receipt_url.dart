enum ReceiptType { hotel, flight }

Uri bookingReceiptUri({
  required String apiUrl,
  required String bookingId,
  required ReceiptType type,
}) {
  final base = Uri.parse(apiUrl);
  return base.replace(
    path: '/api/v2/invoices/${Uri.encodeComponent(bookingId)}/pdf',
    queryParameters: {'type': type.name},
  );
}
