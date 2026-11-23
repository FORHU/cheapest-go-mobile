import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/shared/lib/platform_locale.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(localeChannel, null));

  test('hands the chosen language to Android', () async {
    MethodCall? seen;
    messenger.setMockMethodCallHandler(localeChannel, (call) async {
      seen = call;
      return null;
    });

    await applyPlatformLocale('ko');

    expect(seen?.method, 'setLocale');
    expect(seen?.arguments, {'languageTag': 'ko'});
  });

  test('a host that cannot set one is not an error the app has to show', () async {
    messenger.setMockMethodCallHandler(
      localeChannel,
      (call) async => throw MissingPluginException('no host side'),
    );

    // iOS and the test host both land here. Nothing is thrown at the caller.
    await applyPlatformLocale('ko');
  });
}
