import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/errors/api_error.dart';

enum ErrorRouteAction { log, logout, none, form, retryable }

class RoutedError {
  const RoutedError({required this.toast, required this.action});

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
String errorMessage(Object? error, {AppLocalizations? t}) {
  // Anything that is not an ApiError already carries words worth showing — a declined card
  // arrives as Stripe's own sentence, and routeError would replace it with "Unexpected error
  // occurred". Only an ApiError gets routed.
  if (error is! ApiError) return error.toString().replaceFirst('Exception: ', '');
  return routeError(error, t: t).toast ?? error.message;
}

/// [t] is optional because the one caller that needs this most — `AuthStore` — is a
/// `ChangeNotifier` with no `BuildContext`, so the screen hands its localisations down. Without
/// it the English literals stand, which is what the tests read and what a failure outside a
/// widget tree would otherwise have no words for at all.
///
/// It replaced a single `invalidCredentialsMessage` parameter (#75). That localised the one
/// branch somebody happened to hit, and left "Session expired", "Access denied" and the
/// network line in English on a Korean screen — a tester with no signal sees English at the
/// exact moment the app is least able to explain itself.
RoutedError routeError(Object? error, {AppLocalizations? t}) {
  if (error is! ApiError) {
    return RoutedError(
      toast: t?.errors_generic ?? 'Unexpected error occurred',
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
        return RoutedError(
          toast: t?.auth_signIn_invalidCredentials ?? 'Those details did not match an account',
          action: ErrorRouteAction.form,
        );
      }
      return RoutedError(
        toast: t?.mobile_errors_sessionExpired ?? 'Session expired',
        action: ErrorRouteAction.logout,
      );
    case ErrorCategory.forbidden:
      return RoutedError(
        toast: t?.mobile_errors_accessDenied ?? 'Access denied',
        action: ErrorRouteAction.none,
      );
    case ErrorCategory.validation:
      return const RoutedError(toast: null, action: ErrorRouteAction.form);
    case ErrorCategory.network:
      return RoutedError(
        toast: t?.mobile_errors_network ?? 'Network connection issue',
        action: ErrorRouteAction.retryable,
      );
    case ErrorCategory.notFound:
    case ErrorCategory.server:
    case ErrorCategory.unknown:
      // api-v2's own sentence, which it writes in English — except when the server is
      // reporting its own fault.
      //
      // A refusal the server worded for a person is the better message and is kept: "Hotel
      // booking is switched off in this environment" tells a traveller why their booking did
      // not go through, and this app cannot compose that for itself.
      //
      // A 5xx is different. It means the deployment is wrong, not that the traveller asked
      // for something unavailable, and what the server writes for those is addressed to
      // whoever runs it: a Korean sign-in form carried "Native Google sign-in is not
      // configured" in English, naming an environment variable to somebody who only wanted to
      // log in. There is nothing there to act on, so they get this app's general sentence in
      // their own language and the server's words go to the log — which `log` already does.
      if ((error.status ?? 0) >= 500) {
        return RoutedError(
          toast: t?.errors_generic ?? 'Something went wrong. Please try again.',
          action: ErrorRouteAction.log,
        );
      }
      return RoutedError(toast: error.message, action: ErrorRouteAction.log);
  }
}
