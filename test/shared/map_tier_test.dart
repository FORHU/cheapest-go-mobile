import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cheapest_go_mobile/shared/lib/map_tier.dart';
import 'package:cheapest_go_mobile/shared/stores/ui_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MapTierPolicy & Device Ladder Tests', () {
    test('32-bit devices are denied 3D mode with is32Bit reason', () {
      const device = DeviceCapabilities(
        is64Bit: false,
        totalRamMb: 6000,
        sdk: 33,
      );

      final reason = MapTierPolicy.why3dUnavailable(device);
      expect(reason, No3dReason.is32Bit);
      expect(no3dReasonText(reason!), contains('64-bit'));

      final decision = MapTierPolicy.decide(device);
      expect(decision, MapTier.lite);
    });

    test('Devices with < 5000 MB RAM are denied 3D mode with lowMemory reason', () {
      const device = DeviceCapabilities(
        is64Bit: true,
        totalRamMb: 4000,
        sdk: 33,
      );

      final reason = MapTierPolicy.why3dUnavailable(device);
      expect(reason, No3dReason.lowMemory);
      expect(no3dReasonText(reason!), contains('6 GB'));

      final decision = MapTierPolicy.decide(device);
      expect(decision, MapTier.lite);
    });

    test('Devices marked as lowRam are denied 3D mode with lowMemory reason', () {
      const device = DeviceCapabilities(
        is64Bit: true,
        totalRamMb: 6000,
        lowRam: true,
        sdk: 33,
      );

      final reason = MapTierPolicy.why3dUnavailable(device);
      expect(reason, No3dReason.lowMemory);
    });

    test('Devices with Android SDK < 29 are denied 3D mode with oldAndroid reason', () {
      const device = DeviceCapabilities(
        is64Bit: true,
        totalRamMb: 6000,
        sdk: 28, // Android 9 Pie
      );

      final reason = MapTierPolicy.why3dUnavailable(device);
      expect(reason, No3dReason.oldAndroid);
      expect(no3dReasonText(reason!), contains('Android 10'));

      final decision = MapTierPolicy.decide(device);
      expect(decision, MapTier.lite);
    });

    test('Devices marked as measuredTooSlow receive measuredTooSlow reason', () {
      const device = DeviceCapabilities(
        is64Bit: true,
        totalRamMb: 6000,
        sdk: 33,
      );

      final reason = MapTierPolicy.why3dUnavailable(device, measuredTooSlow: true);
      expect(reason, No3dReason.measuredTooSlow);
      expect(no3dReasonText(reason!), contains('slowly'));

      final decision = MapTierPolicy.decide(device, measuredTooSlow: true);
      expect(decision, MapTier.lite);
    });

    test('Capable 64-bit devices with >= 5000 MB RAM and Android 10+ receive standard 3D', () {
      const device = DeviceCapabilities(
        is64Bit: true,
        totalRamMb: 6000,
        lowRam: false,
        sdk: 33,
      );

      final reason = MapTierPolicy.why3dUnavailable(device);
      expect(reason, isNull);

      final decision = MapTierPolicy.decide(device);
      expect(decision, MapTier.standard);

      // If user specifically requests 2D lite
      final wants2dDecision = MapTierPolicy.decide(device, wants3d: false);
      expect(wants2dDecision, MapTier.lite);
    });
  });

  group('UiSettingsStore Map Tier Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Switching map tier persists preference and notifies listeners', () async {
      final store = UiSettingsStore();
      await store.init();

      expect(store.mapTier, isNotNull);

      int notifyCount = 0;
      store.addListener(() => notifyCount++);

      await store.setMapTier(MapTier.lite);
      expect(store.mapTier, MapTier.lite);
      expect(notifyCount, greaterThanOrEqualTo(1));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('cheapestgo_map_tier'), 'lite');
    });

    test('Switching map theme mode persists preference and notifies listeners', () async {
      final store = UiSettingsStore();
      await store.init();

      expect(store.mapThemeMode, MapThemeMode.dark);

      int notifyCount = 0;
      store.addListener(() => notifyCount++);

      await store.setMapThemeMode(MapThemeMode.light);
      expect(store.mapThemeMode, MapThemeMode.light);
      expect(notifyCount, greaterThanOrEqualTo(1));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('cheapestgo_map_theme_mode'), 'light');

      await store.setMapThemeMode(MapThemeMode.dark);
      expect(store.mapThemeMode, MapThemeMode.dark);
      expect(prefs.getString('cheapestgo_map_theme_mode'), 'dark');
    });
  });
}

