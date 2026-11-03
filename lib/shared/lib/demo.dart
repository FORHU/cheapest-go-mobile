import 'package:flutter/foundation.dart';

/// Presentation tools (the flight simulator and "Reset demo data"): always on
/// in debug builds, and in a release build made with `--dart-define=DEMO=true`.
/// A normal release build never shows them.
const bool kDemoTools = kDebugMode || bool.fromEnvironment('DEMO');
