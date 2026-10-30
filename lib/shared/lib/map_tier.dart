import 'dart:collection';
import 'dart:ffi';
import 'package:flutter/services.dart';

/// Which map a phone gets (the device ladder).
enum MapTier {
  /// 2D Equirectangular / Mercator projection with dark basemap; for weak phones / battery saving.
  lite,

  /// Mapbox Standard 3D Globe with dynamic lighting and atmosphere.
  standard,
}

/// Basemap style mode (Light vs Dark).
enum MapThemeMode {
  light,
  dark,
}

/// What the phone reports about itself; null when unknown.
class DeviceCapabilities {
  const DeviceCapabilities({
    required this.is64Bit,
    this.totalRamMb,
    this.lowRam,
    this.sdk,
  });

  final bool is64Bit;
  final int? totalRamMb;

  /// Android's own low-RAM device flag.
  final bool? lowRam;

  /// Android API level.
  final int? sdk;
}

/// Why a phone can't run the 3D map; Settings/Dropdown says so under the option.
enum No3dReason {
  /// The 3D map was measured too slow here before (FrameBudgetMonitor).
  measuredTooSlow,
  is32Bit,
  lowMemory,
  oldAndroid,
}

/// User-facing explanation matching Gate Closes device ladder.
String no3dReasonText(No3dReason reason) => switch (reason) {
      No3dReason.is32Bit => "This phone can't run it (needs 64-bit Android)",
      No3dReason.lowMemory => "This phone can't run it (needs 6 GB of memory)",
      No3dReason.oldAndroid =>
        "This phone can't run it (needs Android 10 or newer)",
      No3dReason.measuredTooSlow => 'Turned off: it ran too slowly here',
    };

/// Whether the map can be shown on this phone.
enum MapRenderStatus {
  /// Show the map.
  tryMap,

  /// The last attempt crashed or never finished loading: show unsupported notice.
  unsupported,
}

/// Picks the map for a phone: the 2D lite map by default on low-end hardware,
/// or 3D globe only when the phone can run it smoothly.
class MapTierPolicy {
  MapTierPolicy._();

  /// Memory as Android reports it; a phone sold as "6 GB" reports ~5.5 GB.
  static const int minRamMb = 5000;

  /// Android 10 (API 29).
  static const int minSdk = 29;

  /// Decides which tier to pick based on capabilities.
  static MapTier decide(
    DeviceCapabilities device, {
    bool wants3d = true,
    bool measuredTooSlow = false,
  }) {
    if (!wants3d) return MapTier.lite;
    final no3d = why3dUnavailable(device, measuredTooSlow: measuredTooSlow);
    return no3d == null ? MapTier.standard : MapTier.lite;
  }

  /// Why this phone can't run the 3D map, or null when it can.
  static No3dReason? why3dUnavailable(
    DeviceCapabilities device, {
    bool measuredTooSlow = false,
  }) {
    final ram = device.totalRamMb;
    final sdk = device.sdk;
    if (!device.is64Bit) return No3dReason.is32Bit;
    if (device.lowRam == true || (ram != null && ram < minRamMb)) {
      return No3dReason.lowMemory;
    }
    if (sdk != null && sdk < minSdk) return No3dReason.oldAndroid;
    if (measuredTooSlow) return No3dReason.measuredTooSlow;
    return null;
  }
}

/// Reads what the phone reports about itself from `MainActivity` on Android (`cheapest_go/device`).
class DeviceCapabilitiesSource {
  const DeviceCapabilitiesSource();

  static const _channel = MethodChannel('cheapest_go/device');

  Future<DeviceCapabilities> read() async {
    final abi = Abi.current();
    final is64Bit = abi != Abi.androidArm && abi != Abi.androidIA32;
    try {
      final info =
          await _channel.invokeMapMethod<String, Object?>('mapCapabilities');
      return DeviceCapabilities(
        is64Bit: is64Bit,
        totalRamMb: info?['totalRamMb'] as int?,
        lowRam: info?['lowRam'] as bool?,
        sdk: info?['sdk'] as int?,
      );
    } on Object {
      // Tests, iOS, or uninstrumented emulator fallback.
      return DeviceCapabilities(is64Bit: is64Bit);
    }
  }
}

/// Watches frame times on the 3D map and says when the phone is clearly too slow.
class FrameBudgetMonitor {
  FrameBudgetMonitor({
    this.window = 300,
    this.slowFrame = const Duration(milliseconds: 33),
    this.maxSlowShare = 0.5,
  });

  final int window;
  final Duration slowFrame;
  final double maxSlowShare;

  final Queue<bool> _frames = Queue<bool>();
  int _slow = 0;

  bool add(Duration frame) {
    final isSlow = frame > slowFrame;
    _frames.addLast(isSlow);
    if (isSlow) _slow++;
    if (_frames.length > window && _frames.removeFirst()) _slow--;
    return _frames.length == window && _slow >= window * maxSlowShare;
  }
}
