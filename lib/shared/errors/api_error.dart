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
  });

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
