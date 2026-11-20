/// Which brand this app's copy names.
///
/// V2's locale files are written for CheapestGo and name it outright — the sign-in prompt,
/// the footer, the FAQ, and the privacy and cookie documents that state which company is
/// collecting the reader's data. V2 does not serve those sentences unchanged either: it
/// restates them per brand in `src/i18n/applyBrand.ts`, because the two storefronts are one
/// product under two names (its ADR-0005), not two products.
///
/// Mirrored here because this sync is where mobile's copy comes from. Without it the app
/// says CheapestGo on every screen that names a brand while its own launcher icon says
/// AirangGo — which is what it did on a handset until this existed.
///
/// Lives beside `oklch.dart` rather than inside `sync_design.dart` so the parity tests can
/// hold the generator to the same rule instead of restating it.
library;

/// The brand this app ships as, as `android:label` has said all along, and the reason
/// `UiSettingsStore` opens in Korean rather than following the handset.
///
/// A CheapestGo-branded build would set this to `CheapestGo` and regenerate; [inBrand] is
/// then a no-op and the ARB is V2's copy verbatim.
const String brand = 'AirangGo';

/// V2's substitution, kept to V2's rule.
///
/// Case-sensitive on purpose, and this is the part worth not "improving": the brand appears
/// lowercase only inside `support@cheapestgo.com` and `crm@cheapestgo.com`. Those are real
/// mailboxes, shared across both brands, and rewriting them would invent an address that
/// does not exist.
String inBrand(String copy) =>
    brand == 'CheapestGo' ? copy : copy.split('CheapestGo').join(brand);
