import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

const _kOnboardingCompletedKey = 'onboarding_completed';

/// Returns true if onboarding was already completed (should skip).
Future<bool> isOnboardingCompleted() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardingCompletedKey) ?? false;
  } catch (_) {
    return false;
  }
}

/// Call after user taps "Get Started" to never show onboarding again.
Future<void> setOnboardingCompleted() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingCompletedKey, true);
  } catch (_) {}
}

@immutable
class _OnboardingPage {
  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
  });

  final String title;
  final String subtitle;
  final String imageAsset;
}

/// High-end 4-screen onboarding with PageView, dot indicators, Skip/Next, first-launch gate.
class OnboardingView extends StatefulWidget {
  const OnboardingView({
    super.key,
    required this.onComplete,
  });

  final VoidCallback onComplete;

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  static const _pages = [
    _OnboardingPage(
      title: 'See a Place You Love?',
      subtitle:
          'Take a screenshot on Instagram or copy a link from TikTok. PinTok handles the rest.',
      imageAsset: 'assets/onboarding/1.png',
    ),
    _OnboardingPage(
      title: 'AI-Powered Discovery',
      subtitle:
          'Our advanced AI analyzes visual clues and metadata to find the exact coordinates in seconds.',
      imageAsset: 'assets/onboarding/2.png',
    ),
    _OnboardingPage(
      title: 'Build Your Journeys',
      subtitle:
          'Save locations into personalized collections like \'Paris 2026\' or \'Best Coffee Spots\'.',
      imageAsset: 'assets/onboarding/3.png',
    ),
    _OnboardingPage(
      title: 'Your Map, Your Story',
      subtitle:
          'Ready to turn your screenshots into real adventures? Let\'s start pinning.',
      imageAsset: 'assets/onboarding/4.png',
    ),
  ];

  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentPage = index);
  }

  void _skip() {
    HapticFeedback.selectionClick();
    _complete();
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_currentPage >= _pages.length - 1) {
      _complete();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _complete() async {
    await setOnboardingCompleted();
    if (!mounted) return;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D1B2A),
              Color(0xFF0A0A0A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/onboarding/pintoklogo.png',
                      height: 36,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Text(
                        'PinTok',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _skip,
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _OnboardingScreen(page: _pages[index]);
                  },
                ),
              ),
              _DotIndicators(
                count: _pages.length,
                currentIndex: _currentPage,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: SizedBox(
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: FilledButton(
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text(
                          _currentPage >= _pages.length - 1
                              ? 'Get Started'
                              : 'Next',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingScreen extends StatelessWidget {
  const _OnboardingScreen({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Expanded(
            flex: 5,
            child: Center(
              child: Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: Colors.white.withValues(alpha: 0.04),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      page.imageAsset,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  page.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  page.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DotIndicators extends StatelessWidget {
  const _DotIndicators({
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          final isActive = index == currentIndex;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              width: isActive ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isActive
                    ? AppColors.primaryAccent
                    : Colors.white.withValues(alpha: 0.35),
              ),
            ),
          );
        }),
      ),
    );
  }
}
