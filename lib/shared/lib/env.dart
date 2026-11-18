// FAOS — Environment Configuration & Validation
//
// Mirrors `next-template-v1/src/shared/lib/env.ts` and `cheapest-go-mobile/lib/config.ts`.
// Uses compile-time `--dart-define` values with safe defaults for local/staging runs,
// and validates URL syntax on startup.

/// The storefront this build is. A build-time constant, as ADR-0005 requires: brand is chosen
/// when the APK is made, never at runtime, so there is no brand conditional to get wrong and no
/// way for one brand's failure to reach the other.
///
/// Most brand-bearing copy comes from the .arb files, which tool/brand_l10n.dart rewrites before
/// the build. This covers what is NOT translated copy and so cannot be reached that way: the
/// task-switcher title, the name Stripe prints on its payment sheet, and a handful of labels.
const String brandName = String.fromEnvironment('BRAND_NAME', defaultValue: 'CheapestGo');

enum AppEnvironment {
  development,
  staging,
  production,
}

class EnvConfig {
  const EnvConfig({
    required this.webApiUrl,
    required this.siteUrl,
    required this.mobileApiKey,
    required this.mapboxToken,
    required this.stripePublishableKey,
    required this.googleServerClientId,
    required this.appEnv,
    required this.appVersion,
  });

  final String webApiUrl;
  final String siteUrl;
  final String mobileApiKey;
  final String mapboxToken;
  final String stripePublishableKey;

  /// The **web** OAuth client id, which is what a native Google sign-in audiences its ID
  /// token to. Not the Android client: that one is matched by package name and signature.
  final String googleServerClientId;
  final AppEnvironment appEnv;
  final String appVersion;

  static EnvConfig fromEnvironment() {
    const rawApiUrl = String.fromEnvironment(
      'API_URL',
      defaultValue: String.fromEnvironment(
        'EXPO_PUBLIC_WEB_API_URL',
        defaultValue: 'https://cheapestgo.com',
      ),
    );
    const rawSiteUrl = String.fromEnvironment(
      'SITE_URL',
      defaultValue: String.fromEnvironment(
        'EXPO_PUBLIC_SITE_URL',
        defaultValue: 'https://cheapestgo.com',
      ),
    );
    const mobileApiKey = String.fromEnvironment(
      'MOBILE_API_KEY',
      defaultValue: String.fromEnvironment('EXPO_PUBLIC_MOBILE_API_KEY'),
    );
    const mapboxToken = String.fromEnvironment(
      'MAPBOX_TOKEN',
      defaultValue: String.fromEnvironment('EXPO_PUBLIC_MAPBOX_TOKEN'),
    );
    const stripePublishableKey = String.fromEnvironment(
      'STRIPE_PUBLISHABLE_KEY',
      defaultValue: String.fromEnvironment(
        'EXPO_PUBLIC_STRIPE_PUBLISHABLE_KEY',
      ),
    );
    // The web OAuth client id. Native Google sign-in is off without it, rather than failing
    // at the moment somebody taps the button.
    const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
    const rawAppEnv = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    );

    final parsedApiUri = Uri.tryParse(rawApiUrl);
    if (parsedApiUri == null || !parsedApiUri.hasScheme) {
      throw StateError(
        'Invalid EXPO_PUBLIC_WEB_API_URL "$rawApiUrl". Must be a valid URL.',
      );
    }

    final cleanApiUrl = rawApiUrl.endsWith('/')
        ? rawApiUrl.substring(0, rawApiUrl.length - 1)
        : rawApiUrl;

    final appEnv = switch (rawAppEnv) {
      'production' => AppEnvironment.production,
      'staging' => AppEnvironment.staging,
      _ => AppEnvironment.development,
    };

    return EnvConfig(
      webApiUrl: cleanApiUrl,
      siteUrl: rawSiteUrl,
      mobileApiKey: mobileApiKey,
      mapboxToken: mapboxToken,
      stripePublishableKey: stripePublishableKey,
      googleServerClientId: googleServerClientId,
      appEnv: appEnv,
      appVersion: '1.0.0',
    );
  }
}

final EnvConfig env = EnvConfig.fromEnvironment();
