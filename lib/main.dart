import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/saved_places_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/reset_password_screen.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FLUTTER_ERROR: ${details.exception}\n${details.stack}');
    };

    const supabaseUrl = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: '',
    );
    const supabaseAnonKey = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: '',
    );
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw AssertionError(
        'SUPABASE_URL and SUPABASE_ANON_KEY must be set via --dart-define. '
        'Example: flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co '
        '--dart-define=SUPABASE_ANON_KEY=eyJ...',
      );
    }
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    // Bootstrap: first frame is minimal (no theme/fonts/providers) to avoid ANR / "Skipped N frames" / crash.
    runApp(const _BootstrapApp());
  }, (error, stack) {
    debugPrint('ZONE_ERROR: $error\n$stack');
  });
}

/// Shows a minimal first frame (no Google Fonts, no providers), then the real app after a short delay.
class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    // Let first frame paint (minimal tree), then load full app after a short delay so the UI thread can breathe.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) setState(() => _ready = true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: const Scaffold(
          body: ColoredBox(color: Color(0xFF0A0A0A)),
        ),
      );
    }
    return const PinTokApp();
  }
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
  bool _showResetPassword = false;
  Uri? _pendingResetPasswordUri;
  bool _deferredReady = false;
  final AppLinks _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    // Defer heavy UI to next frame so first frame is light (avoids "Skipped N frames" / ANR / crash).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _deferredReady = true);
    });
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        if (mounted) {
          setState(() {
            _showResetPassword = true;
            _pendingResetPasswordUri = null;
          });
        }
        return;
      }
      // On sign out, pop to root so we show LoginScreen instead of staying on Settings (or any pushed route).
      if (data.session == null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
        });
      }
    });
  }

  Future<void> _initDeepLinks() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handleDeepLink(initial);
      _appLinks.uriLinkStream.listen((uri) => _handleDeepLink(uri));
    } catch (_) {}
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'pintok' &&
        (uri.host == 'reset-password' || uri.path == 'reset-password')) {
      if (!mounted) return;
      setState(() {
        _showResetPassword = true;
        _pendingResetPasswordUri = uri;
      });
    }
  }

  void _onForgotPassword() {
    setState(() {
      _showResetPassword = true;
      _pendingResetPasswordUri = null;
    });
  }

  void _onResetPasswordDone() {
    setState(() {
      _showResetPassword = false;
      _pendingResetPasswordUri = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_deferredReady) {
      return const Scaffold(
        body: ColoredBox(color: AppColors.background),
      );
    }
    if (_showResetPassword) {
      return ResetPasswordScreen(
        initialUri: _pendingResetPasswordUri,
        onDone: _onResetPasswordDone,
      );
    }

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        Supabase.instance.client.auth.currentSession,
      ),
      builder: (context, snapshot) {
        // Prefer stream session; fallback to currentSession so UI updates immediately after sign-in (e.g. Google)
        final session = snapshot.data?.session ?? Supabase.instance.client.auth.currentSession;
        final isLoggedIn = session != null;

        if (!isLoggedIn) {
          return LoginScreen(
            onAuthenticated: () {
              if (!mounted) return;
              _rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
              // Force rebuild so StreamBuilder/currentSession shows MainShell right after sign-in
              setState(() {});
            },
            onForgotPassword: _onForgotPassword,
          );
        }

        return const MainShell();
      },
    );
  }
}
