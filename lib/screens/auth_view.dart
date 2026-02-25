import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Beautiful minimalist Auth screen shown after onboarding.
/// Purely UI for now — buttons just navigate into the MainShell.
class AuthView extends StatefulWidget {
  const AuthView({
    super.key,
    required this.onAuthenticated,
  });

  final VoidCallback onAuthenticated;

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService.instance;

  bool _isSignIn = true;
  bool _isObscured = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    HapticFeedback.selectionClick();
    setState(() => _isSignIn = !_isSignIn);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _primaryAction() async {
    HapticFeedback.lightImpact();

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final fullName = _fullNameController.text.trim();

    if (email.isEmpty || password.isEmpty || (!_isSignIn && fullName.isEmpty)) {
      _showSnackBar('Please fill in all fields.');
      return;
    }

    if (password.length < 6) {
      _showSnackBar('Password must be at least 6 characters.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isSignIn) {
        await _authService.signIn(email: email, password: password);
      } else {
        final username = _deriveUsername(fullName: fullName, email: email);
        await _authService.signUp(
          email: email,
          password: password,
          username: username,
          fullName: fullName,
        );
      }

      widget.onAuthenticated();
    } on AuthException catch (e) {
      final message = _mapAuthErrorMessage(e);
      _showSnackBar(message);
    } catch (e) {
      _showSnackBar('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _deriveUsername({required String fullName, required String email}) {
    var base = fullName.trim().toLowerCase();
    if (base.isEmpty) {
      base = email.split('@').first.toLowerCase();
    }
    base = base.replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'_+'), '_');
    base = base.replaceAll(RegExp(r'^_+|_+$'), '');
    return base.isEmpty ? 'user_${DateTime.now().millisecondsSinceEpoch}' : base;
  }

  String _mapAuthErrorMessage(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
      return 'Invalid email or password.';
    }
    if (msg.contains('user already registered') ||
        msg.contains('already exists') ||
        msg.contains('duplicate key')) {
      return 'An account with this email already exists.';
    }
    return e.message;
  }

  void _googleAction() {
    HapticFeedback.lightImpact();
    widget.onAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final isTall = size.height > 720;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image with dark overlay and subtle blur.
          DecoratedBox(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=1200',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    isTall ? 32 : 24,
                    20,
                    24 + media.viewInsets.bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight -
                          (isTall ? 56 : 40) -
                          media.viewInsets.bottom,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildAuthCard(context),
                          const SizedBox(height: 18),
                          _buildFooterToggle(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          'assets/onboarding/pintoklogo.png',
          height: 56,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_rounded, color: Colors.white, size: 32),
              const SizedBox(width: 10),
              Text(
                'PinTok',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isSignIn
              ? 'Turn screenshots into journeys.'
              : 'Create your travel identity.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white.withValues(alpha: 0.10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
              width: 1.2,
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      _isSignIn ? 'Sign In' : 'Sign Up',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    _ModePill(isSignIn: _isSignIn, onToggle: _toggleMode),
                  ],
                ),
                const SizedBox(height: 18),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _isSignIn
                      ? _buildSignInFields(key: const ValueKey('sign-in'))
                      : _buildSignUpFields(key: const ValueKey('sign-up')),
                ),
                const SizedBox(height: 18),
                _buildPrimaryButton(),
                const SizedBox(height: 10),
                _buildGoogleButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInFields({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GlassTextField(
          controller: _emailController,
          label: 'Email',
          hintText: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _GlassTextField(
          controller: _passwordController,
          label: 'Password',
          hintText: 'Enter your password',
          obscureText: _isObscured,
          onToggleObscure: () {
            setState(() => _isObscured = !_isObscured);
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password reset coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: Colors.white.withValues(alpha: 0.9),
            ),
            child: Text(
              'Forgot password?',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpFields({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GlassTextField(
          controller: _fullNameController,
          label: 'Full Name',
          hintText: 'Your name',
        ),
        const SizedBox(height: 12),
        _GlassTextField(
          controller: _emailController,
          label: 'Email',
          hintText: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _GlassTextField(
          controller: _passwordController,
          label: 'Password',
          hintText: 'Create a password',
          obscureText: _isObscured,
          onToggleObscure: () {
            setState(() => _isObscured = !_isObscured);
          },
        ),
      ],
    );
  }

  Widget _buildPrimaryButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _primaryAction,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 10,
          shadowColor: const Color(0xFF2196F3).withValues(alpha: 0.6),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [
                Color(0xFF2196F3),
                Color(0xFF7C4DFF),
              ],
            ),
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          child: Center(
            child: Text(
              _isLoading
                  ? 'Please wait...'
                  : (_isSignIn ? 'Enter PinTok' : 'Get Started'),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: _googleAction,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          backgroundColor: Colors.black.withValues(alpha: 0.15),
          foregroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Center(
                child: Text(
                  'G',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4285F4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Continue with Google',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _isSignIn
                ? "Don't have an account? "
                : 'Already a traveler? ',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          TextButton(
            onPressed: _toggleMode,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: Colors.white,
            ),
            child: Text(
              _isSignIn ? 'Sign Up' : 'Sign In',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({
    required this.isSignIn,
    required this.onToggle,
  });

  final bool isSignIn;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.black.withValues(alpha: 0.35),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(active: isSignIn),
            const SizedBox(width: 6),
            Text(
              isSignIn ? 'Sign In' : 'Sign Up',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot({required bool active}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: active
            ? const LinearGradient(
                colors: [
                  Color(0xFF2196F3),
                  Color(0xFF7C4DFF),
                ],
              )
            : null,
        color: active
            ? null
            : Colors.white.withValues(alpha: 0.4),
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.onToggleObscure,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final VoidCallback? onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.black.withValues(alpha: 0.35),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                obscureText: obscureText,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                cursorColor: AppColors.primaryAccent,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  suffixIcon: onToggleObscure == null
                      ? null
                      : IconButton(
                          onPressed: onToggleObscure,
                          icon: Icon(
                            obscureText
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 18,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

