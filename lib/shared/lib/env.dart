// FAOS — Environment Configuration & Validation
//
// Mirrors `next-template-v1/src/shared/lib/env.ts` and `cheapest-go-mobile/lib/config.ts`.
// Uses compile-time `--dart-define` values with safe defaults for local/staging runs,
// and validates URL syntax on startup.

/// The storefront this build is. A build-time constant, as ADR-0005 requires: brand is chosen
/// when the APK is made, never at runtime, so there is no brand conditional to get wrong and no
/// way for one brand's failure to reach the other.
///
/// Most brand-bearing copy comes from the .arb files, which `tools/brand.dart` restates at sync
/// time. This covers what is NOT translated copy and so cannot be reached that way: the
/// task-switcher title, the name Stripe prints on its payment sheet, the AI chat's own name and
/// the settings footer.
///
/// The default is the brand this app ships as, matching `tools/brand.dart` and `android:label`.
/// It used to be `CheapestGo`, and because no env file sets `BRAND_NAME`, every one of those
/// surfaces said CheapestGo inside an app whose icon says AirangGo — the ARB rewrite could not
/// reach them. A CheapestGo build passes `--dart-define=BRAND_NAME=CheapestGo` and sets the
/// same name in `tools/brand.dart`.
const String brandName = String.fromEnvironment('BRAND_NAME', defaultValue: 'AirangGo');

/// The one currency this brand prices and charges in — its **Charge Currency** (ADR-0007).
/// KRW for AirangGo, USD for CheapestGo, mirroring the web's `NEXT_PUBLIC_DEFAULT_CURRENCY`
/// and api-v2, which already calls AirangGo Korea-locked.
///
/// Not a display preference: it is what the card is charged in, which is why the brand decides
/// it and a traveller is not asked. What a supplier quotes may be another currency entirely —
/// converting that for display is a separate thing and still happens.
const String brandCurrency = String.fromEnvironment('BRAND_CURRENCY', defaultValue: 'KRW');

/// The country this brand sells from — its **Market** (ADR-0007). Declared to hotel suppliers
/// as the guest's nationality, which they price against, so it is a commercial statement about
/// the storefront rather than a fact about whoever is holding the phone.
///
/// Not where the hotel is: that is the destination's country, and a search carries both.
const String brandMarket = String.fromEnvironment('BRAND_MARKET', defaultValue: 'KR');

/// Whether a traveller may change the language. A brand is locked to one (ADR-0007); this
/// opens the picker for builds made to be tested in.
///
/// Defaults to **locked**, so forgetting the flag ships correct behaviour rather than a control
/// that should not be there. It cannot be `kReleaseMode`: the APKs used for testing here are
/// release builds, so that would leave the picker in every one of them.
const bool kAllowLanguageSwitch = bool.fromEnvironment('ALLOW_LANGUAGE_SWITCH');

/// Whether auth is answered on the device instead of by the server: a demo user signs in and
/// nothing calls `/api/v2/auth`. Build with `--dart-define=MOCK_AUTH=false` for the real
/// endpoints.
///
/// Here rather than in the auth feature, where it used to live, because it is not only auth's
/// business: anything that asks the server about *the signed-in account* is asking about an
/// account the server has never heard of, and has to know that. Feature isolation means
/// `features/onboarding` cannot read a constant out of `features/auth`, so the one fact both
/// need lives in the one place both may import.
const bool kMockAuth = bool.fromEnvironment('MOCK_AUTH', defaultValue: true);

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
