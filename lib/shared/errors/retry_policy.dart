import 'package:cheapest_go_mobile/shared/errors/api_error.dart';

int getRetryCount(Object? error) {
  if (error is! ApiError) return 0;

  if (error.category == ErrorCategory.network) return 3;
  final status = error.status;
  if (status != null && status >= 500) return 2;
  if (status == 429) return 1;

  return 0;
}
