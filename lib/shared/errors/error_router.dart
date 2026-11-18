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

/// The one sentence to show a traveller for [error].
///
/// `ApiError.toString()` is a diagnostic — it renders as
/// "ApiError(ErrorCategory.unknown, status: 200): Hotel booking is switched off in this
/// environment." — and three screens were putting that on the page verbatim. [routeError]
/// already decides what each category should say; this is that decision as a single line.
///
/// Validation is the one category routeError deliberately gives no toast, because its place is
/// against the field. A screen with nowhere to put it still has to say something, so the error's
/// own message is used rather than nothing at all.
String errorMessage(Object? error) {
  // Anything that is not an ApiError already carries words worth showing — a declined card
  // arrives as Stripe's own sentence, and routeError would replace it with "Unexpected error
  // occurred". Only an ApiError gets routed.
  if (error is! ApiError) return error.toString().replaceFirst('Exception: ', '');
  return routeError(error).toast ?? error.message;
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
