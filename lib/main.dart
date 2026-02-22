import 'dart:async';
import 'package:flutter/material.dart';

import 'screens/main_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FLUTTER_ERROR: ${details.exception}\n${details.stack}');
    };
    runApp(const PinTokApp());
  }, (error, stack) {
    debugPrint('ZONE_ERROR: $error\n$stack');
  });
}

class PinTokApp extends StatelessWidget {
  const PinTokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PinTok',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const MainShell(),
    );
  }
}
