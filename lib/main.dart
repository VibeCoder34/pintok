import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/saved_places_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/auth_view.dart';
import 'screens/landing_view.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_view.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FLUTTER_ERROR: ${details.exception}\n${details.stack}');
    };

    await Supabase.initialize(
      url: 'https://irbmniebwetgwiflnvpg.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlyYm1uaWVid2V0Z3dpZmxudnBnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE5NjUxNjQsImV4cCI6MjA4NzU0MTE2NH0.CtmbfLKaYFPK3nNBwl9fMdm8R-XqFnVId7f5EL6DW64',
    );

    runApp(const PinTokApp());
  }, (error, stack) {
    debugPrint('ZONE_ERROR: $error\n$stack');
  });
}

class PinTokApp extends StatelessWidget {
  const PinTokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SavedPlacesProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        navigatorKey: _rootNavigatorKey,
        title: 'PinTok',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const _AppHome(),
      ),
    );
  }
}

class _AppHome extends StatefulWidget {
  const _AppHome();

  @override
  State<_AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<_AppHome> {
  bool? _showOnboarding;
  bool _showAuth = true;
  bool _showLanding = true;

  @override
  void initState() {
    super.initState();
    _check();
    Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      _check();
    });
  }

  Future<void> _check() async {
    final completed = await isOnboardingCompleted();
    final hasSession =
        Supabase.instance.client.auth.currentSession != null;
    if (!mounted) return;
    setState(() {
      if (hasSession) {
        _showOnboarding = false;
        _showAuth = false;
        _showLanding = false;
      } else {
        _showOnboarding = !completed;
        _showAuth = true;
        _showLanding = true;
      }
    });
    // When logged out, pop all routes so user sees landing/auth instead of Settings.
    if (!hasSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
      });
    }
  }

  void _onOnboardingComplete() {
    setState(() {
      _showOnboarding = false;
      _showAuth = true;
    });
  }

  void _onAuthComplete() {
    setState(() {
      _showAuth = false;
    });
  }

   void _onLandingComplete() {
    setState(() {
      _showLanding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = Builder(
      builder: (context) {
        if (_showOnboarding == null) {
          return const Scaffold(
            body: ColoredBox(
              color: Color(0xFF0A0A0A),
            ),
          );
        }
        if (_showLanding) {
          return LandingView(onGetStarted: _onLandingComplete);
        }
        if (_showOnboarding!) {
          return OnboardingView(onComplete: _onOnboardingComplete);
        }
        if (_showAuth) {
          return AuthView(onAuthenticated: _onAuthComplete);
        }
        return const MainShell();
      },
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
      child: body,
    );
  }
}
