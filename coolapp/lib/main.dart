// lib/main.dart
//
// PURPOSE: The entry point of CampusLink. This file:
//   1. Registers AuthProvider so every screen can access auth state
//   2. Applies the global AppTheme
//   3. Registers all named routes from routes.dart
//   4. Decides the first screen based on auth state
//
// KEEP THIS FILE SMALL — its only job is wiring things together.
// No business logic, no UI building, no Firebase calls here.
//
// [PETRONILO & ERIC: When you are ready to connect Firebase:
//   1. Add google-services.json to android/app/
//   2. Add GoogleService-Info.plist to ios/Runner/
//   3. Uncomment the firebase_core import below
//   4. Uncomment await Firebase.initializeApp() in main()
//   5. Replace all stub implementations in auth_service.dart]

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// [PETRONILO & ERIC: uncomment when Firebase is configured]
import 'package:firebase_core/firebase_core.dart';

import 'core/constants.dart';
import 'core/routes.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/welcome_screen.dart';

void main() async {
  // 1. This tells Flutter to wait until the core engine is ready
  WidgetsFlutterBinding.ensureInitialized();

  // 2. This wakes up Firebase before the app starts
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // If Petronilo hasn't given you the Firebase config files yet,
    // this catch block prevents the app from crashing so you can still see your UI!
    debugPrint('Firebase not fully configured yet: $e');
  }

  // 3. Start the app
  runApp(
      const CampusLinkApp()); // (Make sure this matches your main class name)
}

class CampusLinkApp extends StatelessWidget {
  const CampusLinkApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        title: 'CampusLink',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,

        // 1. We tell the app exactly which route string to start on
        initialRoute: AppRoutes.welcome,

        // 2. We provide the map of all our routes
        routes: appRoutes,
        onGenerateRoute: onGenerateRoute,

        // 3. We completely removed the `home:` property so it doesn't conflict!
      ),
    );
  }
}

// =============================================================================
// AUTH GATE
// =============================================================================
// Runs silently on every app launch.
// Reads AuthStatus from AuthProvider and routes to the correct screen.
//
// FLOW:
//   uninitialized   → SplashScreen (checking existing session)
//   unauthenticated → WelcomeScreen
//   pendingKyc      → PendingApprovalScreen (sprint 1 — built next)
//   rejectedKyc     → KycScreen (resubmit)
//   authenticated   → SeekerHomeScreen or ProviderDashboard (sprint 2)

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.uninitialized:
        // Firebase is still checking the existing session
        return const _SplashScreen();

      case AuthStatus.unauthenticated:
        // No user logged in — show welcome screen
        return const WelcomeScreen();

      case AuthStatus.pendingKyc:
        // Logged in but KYC not yet approved
        // Uncomment when PendingApprovalScreen is built (next file):
        // return const PendingApprovalScreen();
        return const WelcomeScreen();

      case AuthStatus.rejectedKyc:
        // KYC was rejected — send them back to resubmit
        // Uncomment when KycScreen route is ready:
        // return const KycScreen();
        return const WelcomeScreen();

      case AuthStatus.authenticated:
        // Fully verified — route based on role
        final user = auth.currentUser;
        if (user == null) return const WelcomeScreen();
        // Uncomment when sprint 2 screens are built:
        // if (user.isProvider && !user.isSeeker) {
        //   return const ProviderDashboardScreen();
        // }
        // return const SeekerHomeScreen();
        return const WelcomeScreen();
    } // end switch

    // Dart requires this fallback even though the switch is exhaustive
    // because it can't always infer that all enum cases are covered
  }
}

// =============================================================================
// SPLASH SCREEN
// =============================================================================
// Shown while Firebase checks the existing auth session on app launch.
// Replaced by the real screen once AuthStatus resolves.

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
