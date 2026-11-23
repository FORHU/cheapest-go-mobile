import 'package:flutter/services.dart';

/// Tells Android which language the app is being read in.
///
/// `MaterialApp.locale` only reaches what Flutter paints. Stripe's payment sheet is an
/// Android activity of its own and takes its strings from the platform, which is why a
/// traveller reading a Korean app was asked to pay in English: the handset was still in
/// whatever language the phone itself is set to.
///
/// `setApplicationLocales` is the per-app language Android 13 added and AppCompat backports
/// to older handsets. It applies to every activity the process opens afterwards, the sheet
/// among them — which overriding this activity's own `Configuration` would not do, because
/// the sheet is a different activity reading a different resource table.
///
/// ponytail: nothing is stored on the Android side. AppCompat can persist this itself given
/// an `autoStoreLocales` service in the manifest, but `UiSettingsStore` already holds the
/// language and calls this on every launch, so a second copy would only be one more thing
/// that can disagree.
const localeChannel = MethodChannel('cheapest_go/device');

Future<void> applyPlatformLocale(String languageTag) async {
  try {
    await localeChannel.invokeMethod<void>('setLocale', {
      'languageTag': languageTag,
    });
  } on Object {
    // iOS, a test, or any build without the host side — where there is no platform locale
    // to set. The app's own copy renders either way, so this is never worth an error in
    // front of a traveller.
  }
}
