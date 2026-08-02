import 'package:flutter/material.dart';

import '../features/today/today_screen.dart';
import 'theme/pour_toujours_theme.dart';

class PourToujoursApp extends StatelessWidget {
  const PourToujoursApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pour Toujours',
      debugShowCheckedModeBanner: false,
      theme: PourToujoursTheme.light,
      home: const TodayScreen(),
    );
  }
}
