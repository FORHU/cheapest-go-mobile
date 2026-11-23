import 'dart:async';

import 'package:flutter/material.dart';

import 'package:cheapest_go_mobile/app/app.dart';
import 'package:cheapest_go_mobile/app/startup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Started, not awaited. The first frame is the app's own splash, and the work that used to
  // delay it runs behind that instead — see [AppStartup], which the gate holds every route
  // on until it is done.
  unawaited(appStartup.run());

  runApp(const CheapestGoApp());
}
