enum ErrorCategory {
  auth,
  forbidden,
  validation,
  notFound,
  network,
  server,
  unknown,
}

class ApiError implements Exception {
  ApiError(
    this.message, {
    this.category = ErrorCategory.unknown,
    this.status,
    this.code,
    this.details,
    this.priceChanged,
    this.newPrice,
    this.body,
  });

  /// The error's whole JSON body, for the refusals that carry more than a sentence — the
  /// duplicate-departure warning names the route, the date and the booking it clashes with.
  final Map<String, dynamic>? body;

  final String message;
  final ErrorCategory category;
  final int? status;
  final String? code;
  final Map<String, List<String>>? details;
  final bool? priceChanged;
  final double? newPrice;

  @override
  String toString() => 'ApiError($category, status: $status): $message';
}
