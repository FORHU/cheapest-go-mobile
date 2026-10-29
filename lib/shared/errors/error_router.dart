import 'package:cheapest_go_mobile/shared/errors/api_error.dart';

enum ErrorRouteAction {
  log,
  logout,
  none,
  form,
  retryable,
}

class RoutedError {
  const RoutedError({
    required this.toast,
    required this.action,
  });

  final String? toast;
  final ErrorRouteAction action;
}

RoutedError routeError(Object? error) {
  if (error is! ApiError) {
    return const RoutedError(
      toast: 'Unexpected error occurred',
      action: ErrorRouteAction.log,
    );
  }

  switch (error.category) {
    case ErrorCategory.auth:
      return const RoutedError(
        toast: 'Session expired',
        action: ErrorRouteAction.logout,
      );
    case ErrorCategory.forbidden:
      return const RoutedError(
        toast: 'Access denied',
        action: ErrorRouteAction.none,
      );
    case ErrorCategory.validation:
      return const RoutedError(
        toast: null,
        action: ErrorRouteAction.form,
      );
    case ErrorCategory.network:
      return const RoutedError(
        toast: 'Network connection issue',
        action: ErrorRouteAction.retryable,
      );
    case ErrorCategory.notFound:
    case ErrorCategory.server:
    case ErrorCategory.unknown:
      return RoutedError(
        toast: error.message,
        action: ErrorRouteAction.log,
      );
  }
}
