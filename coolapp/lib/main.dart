// lib/main.dart
//
// PURPOSE: The entry point of CampusLink.
// 1. Registers Providers (Auth, Service, Booking)
// 2. Applies the global AppTheme
// 3. Handles the "Auth Gate" to decouple the navigation bar from Auth screens.
//
// ⚠️ DEV MODE BYPASSES (remove before production):
//   - Firebase.initializeApp() is wrapped in try/catch (no google-services.json yet)
//   - pendingKyc routes to BottomNavShell instead of PendingApprovalScreen
//   - rejectedKyc routes to BottomNavShell instead of KycScreen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'core/constants.dart';
import 'core/routes.dart';
import 'providers/auth_provider.dart';
import 'providers/service_provider.dart';
import 'providers/booking_provider.dart';
import 'widgets/bottom_nav_shell.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // [PETRONILO & ERIC: uncomment when Firebase is configured]
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CampusLinkApp());
}

class CampusLinkApp extends StatelessWidget {
  const CampusLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: MaterialApp(
        title: 'CampusLink',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
        routes: appRoutes,
        onGenerateRoute: onGenerateRoute,
      ),
    );
  }
}

// =============================================================================
// AUTH GATE
// =============================================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.uninitialized:
        return const _SplashScreen();

      case AuthStatus.unauthenticated:
        return const _OnboardingGate();

      case AuthStatus.pendingKyc:
        // ⚠️ DEV BYPASS — change to PendingApprovalScreen() for production
        return const BottomNavShell();

      case AuthStatus.rejectedKyc:
        // ⚠️ DEV BYPASS — change to KycScreen() for production
        return const BottomNavShell();

      case AuthStatus.authenticated:
        return const BottomNavShell();
    }
  }
}

// =============================================================================
// ONBOARDING GATE
// =============================================================================
// Checks shared_preferences on first launch.
// Shows OnboardingScreen once, then WelcomeScreen forever after.

class _OnboardingGate extends StatefulWidget {
  const _OnboardingGate();

  @override
  State<_OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<_OnboardingGate> {
  bool? _hasSeenOnboarding;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final seen = await hasSeenOnboarding();
    if (mounted) setState(() => _hasSeenOnboarding = seen);
  }

  @override
  Widget build(BuildContext context) {
    // Still checking shared_preferences
    if (_hasSeenOnboarding == null) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.primary,
            ),
            strokeWidth: 2.5,
          ),
        ),
      );
    }
    // Already seen — go straight to welcome
    if (_hasSeenOnboarding!) {
      return const WelcomeScreen();
    }
    // First launch — show onboarding
    return const OnboardingScreen();
  }
}

// =============================================================================
// SPLASH SCREEN
// =============================================================================

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: AppRadius.lgRadius,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.link_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
