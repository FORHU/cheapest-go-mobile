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
      // Two very different 401s. api-v2 answers a wrong password or an unknown account with
      // `INVALID_CREDENTIALS`, and a session that has run out with `AUTH_INVALID`. Reporting
      // both as "Session expired" told someone who had simply mistyped their password that
      // something had expired, and signed them out of an account they were never in.
      if (error.code == 'INVALID_CREDENTIALS') {
        return const RoutedError(
          toast: 'Those details did not match an account',
          action: ErrorRouteAction.form,
        );
      }
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
