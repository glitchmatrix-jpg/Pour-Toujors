import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'app/pour_toujours_app.dart';
import 'core/release/v1_platform_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await V1PlatformServices.instance.initialize();
  runApp(const ProviderScope(child: PourToujoursApp()));
}
