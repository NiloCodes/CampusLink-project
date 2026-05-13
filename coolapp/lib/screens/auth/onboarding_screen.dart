// lib/screens/auth/onboarding_screen.dart
//
// PURPOSE: First-time user onboarding carousel.
// Shows 3 slides explaining CampusLink before registration.
//
// FLOW:
//   First launch → OnboardingScreen → WelcomeScreen
//   Subsequent launches → WelcomeScreen directly
//   (uses shared_preferences to track if seen)
//
// SLIDES:
//   1. Find Student Services
//   2. Pay Safely with MoMo Escrow
//   3. UCC Students Only
//
// NAVIGATION:
//   Next button    → advances to next slide
//   Skip link      → jumps to WelcomeScreen
//   Get Started    → goes to WelcomeScreen (last slide only)
//   Dot indicators → show current position

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../core/routes.dart';

// Key used to store onboarding completion in shared_preferences
const String _kOnboardingComplete = 'onboarding_complete';

// Static method to check if onboarding has been seen
// Called from main.dart AuthGate to decide which screen to show
Future<bool> hasSeenOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingComplete) ?? false;
}

Future<void> markOnboardingComplete() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingComplete, true);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingSlide> _slides = const [
    _OnboardingSlide(
      icon: Icons.storefront_rounded,
      iconColor: AppColors.primary,
      heading: 'Find Trusted\nStudent Services',
      subtitle: 'Browse services offered by verified UCC '
          'students — tutoring, tech repair, food, '
          'beauty and more.',
      bgColor: Color(0xFFEEF2FF),
    ),
    _OnboardingSlide(
      icon: Icons.lock_rounded,
      iconColor: Color(0xFF0D9488),
      heading: 'Pay Safely with\nMoMo Escrow',
      subtitle: 'Your money is held securely until you '
          'confirm the service is complete. '
          'No risk, no stress.',
      bgColor: Color(0xFFECFDF5),
    ),
    _OnboardingSlide(
      icon: Icons.verified_user_rounded,
      iconColor: Color(0xFF7C3AED),
      heading: 'UCC Students\nOnly',
      subtitle: 'Every user is verified with a valid UCC '
          'student ID. Your campus marketplace, '
          'your community.',
      bgColor: Color(0xFFF5F3FF),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finish() async {
    await markOnboardingComplete();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // ── SKIP BUTTON ──────────────────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.md,
                  right: AppSpacing.screenPadding,
                ),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Skip',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // ── PAGE VIEW ────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return _SlideView(slide: _slides[index]);
                },
              ),
            ),

            // ── DOT INDICATORS ───────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                  ),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.primary
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── ACTION BUTTONS ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Column(
                children: [
                  // Primary button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLastPage ? _finish : _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.pillRadius,
                        ),
                      ),
                      child: Text(
                        isLastPage ? 'Get Started' : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Already have account link — last slide only
                  if (isLastPage)
                    GestureDetector(
                      onTap: _finish,
                      child: Text(
                        'Already have an account? Login',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SLIDE VIEW
// =============================================================================

class _SlideView extends StatelessWidget {
  final _OnboardingSlide slide;

  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── ILLUSTRATION CARD ────────────────────────────────────────
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: slide.bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              slide.icon,
              size: 90,
              color: slide.iconColor,
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // ── HEADING ──────────────────────────────────────────────────
          Text(
            slide.heading,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.md),

          // ── SUBTITLE ─────────────────────────────────────────────────
          Text(
            slide.subtitle,
            style: AppTextStyles.subtitle.copyWith(
              fontSize: 15,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SLIDE DATA MODEL
// =============================================================================

class _OnboardingSlide {
  final IconData icon;
  final Color iconColor;
  final String heading;
  final String subtitle;
  final Color bgColor;

  const _OnboardingSlide({
    required this.icon,
    required this.iconColor,
    required this.heading,
    required this.subtitle,
    required this.bgColor,
  });
}
