# A brand locks its market

**Status:** accepted · 2026-11-20

**Design Parity** says mobile follows V2, behaviour as well as looks. V2's `SettingsPanel` —
its own phone-breakpoint settings sheet — offers four languages and five currencies, and this
app mirrored that: a currency row in Settings, a currency question as the first thing
onboarding asks, and `UiSettingsStore` holding the answer.

It mirrored the control without mirroring the market. The store opened every traveller in
**USD** while opening the same app in **Korean**, so an AirangGo account was offered dollars by
a Korean-language storefront. Worse, the store only ever read its answer from device storage
and wrote it back to the account, never reading the account's value, so the app and the browser
could disagree indefinitely with nothing to reconcile them.

api-v2 had already decided this and said so. `src/lib/pricing.ts` calls KRW a **Charge
Currency** and states that "AirangGo is Korea-locked, so this is not a theoretical currency —
it is a primary market", and `toStripeAmount` carries the zero-decimal handling that only
matters if KRW is real. The decision existed; mobile was the component that had not implemented
it.

**A brand now fixes its market, and a traveller is not asked.** AirangGo prices and charges in
KRW. The currency row leaves Settings, the currency question leaves onboarding, and nothing in
the app writes `displayCurrency` to the account — so a currency chosen in the browser is left
exactly as it was rather than being quietly overwritten by an app that never read it.

Language goes the same way, on a delay. A production build renders Korean and offers no choice;
the picker survives only in builds made for testing, behind a flag that **defaults to locked**,
so forgetting it yields correct production behaviour rather than a shipped control. Test APKs
here are release builds, so `kReleaseMode` cannot be that flag.

This is the second deliberate divergence from the **Design Source**, after ADR-0005, and the
first that removes something a traveller could previously do. The cost is a real one: V2 shows
five currencies at this breakpoint and we show none, so a Korean traveller who genuinely wants
to shop in dollars cannot, and anyone reading the two codebases side by side will see mobile
missing a control for no reason the screen explains. We accept that because the alternative is
worse — a currency picker implies the charge follows it, and the charge is what a brand is for.
What a supplier quotes is still converted for display; that is a different thing, and it stays.

Two consequences worth stating:

**Display currency is no longer a Preference.** The glossary listed it alongside language and
email notifications as account-held and shared with the web. It is now a **Brand** matter, and
`CONTEXT.md` says so. Language remains a Preference until the production lock lands.

**The in-app language has to reach the platform.** Stripe's payment sheet, date pickers and
permission dialogs render in the Android process locale, not in Flutter's. A Korea-locked build
whose payment sheet is in English is the lock failing at the one screen where it matters most,
so the Android application locale follows the chosen language rather than the handset's.
