import 'dart:async';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Google OAuth client IDs (official identity).
/// Web Client ID; Android Client ID 84675114871-ttgo3cc45nljnu24e1s9f8thgggebopl.apps.googleusercontent.com
/// is configured in Google Cloud Console for the Android app.
class _GoogleOAuthIds {
  static const String webClientId =
      '84675114871-bcmnk1igbokj44pjf6svu3frgins5u9e.apps.googleusercontent.com';
  /// iOS client ID (URL scheme: com.googleusercontent.apps.84675114871-29nhrgdm2ho5k19t9gqjfn9tftfrpfa0)
  static const String iosClientId =
      '84675114871-29nhrgdm2ho5k19t9gqjfn9tftfrpfa0.apps.googleusercontent.com';
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  static GoogleSignIn get _googleSignIn {
    if (Platform.isIOS) {
      return GoogleSignIn(
        serverClientId: _GoogleOAuthIds.webClientId,
        clientId: _GoogleOAuthIds.iosClientId,
      );
    }
    return GoogleSignIn(serverClientId: _GoogleOAuthIds.webClientId);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: <String, dynamic>{
        'full_name': fullName,
      },
    );
    if (res.user != null) await _ensureProfileWithFuel();
    return res;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    await _ensureProfileWithFuel();
    return res;
  }

  /// Sign in with Google using Web + Android/iOS client IDs. Creates/updates profile with ai_scans_limit 5 on first login.
  Future<AuthResponse> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw AuthException('Google sign-in was cancelled');
    }
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;
    if (idToken == null) {
      throw AuthException('No Google ID token received');
    }
    final res = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken ?? '',
    );
    // Run profile/fuel setup in background so UI can update immediately (avoids "Skipped N frames" on main thread)
    unawaited(_ensureProfileWithFuel());
    return res;
  }

  /// Ensures the current user has a profile row with ai_scans_limit set to 5 (new user fuel). Call after any successful sign-in/sign-up.
  Future<void> _ensureProfileWithFuel() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      final existing = await _client
          .from('profiles')
          .select('id, ai_scans_limit')
          .eq('id', user.id)
          .maybeSingle();
      if (existing == null) {
        await _client.from('profiles').insert(<String, dynamic>{
          'id': user.id,
          'full_name': user.userMetadata?['full_name'] ?? user.email?.split('@').first ?? 'Traveler',
          'ai_scans_limit': 5,
        });
      } else {
        final limit = existing['ai_scans_limit'];
        if (limit == null) {
          await _client
              .from('profiles')
              .update(<String, dynamic>{'ai_scans_limit': 5}).eq('id', user.id);
        }
      }
    } catch (_) {
      // Non-fatal: trigger may have already created profile with default
    }
  }

  /// Signs out from Supabase and from Google so the next "Continue with Google" is a clean flow (avoids crash/stale token after re-login).
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();
    } catch (_) {
      // Ignore: user may have signed in with email.
    }
    await _client.auth.signOut();
  }

  /// Sends a password reset email. Configure redirect in Supabase to e.g. pintok://reset-password.
  Future<void> requestPasswordReset({required String email}) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'pintok://reset-password',
    );
  }

  /// Updates the current user's password (e.g. after recovery from reset link).
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }
}

