// lib/core/routes.dart
//
// PURPOSE: This file is the single source of truth for ALL navigation
// in CampusLink. Every screen name is defined here as a constant string,
// and every route is registered in one map.
//
// WHY THIS MATTERS (for your defense):
// This implements the "Named Routes" pattern in Flutter. The alternative —
// pushing routes directly with MaterialPageRoute scattered across files —
// becomes unmaintainable fast. With this pattern:
//   1. You never mistype a route string (it's a constant, not "'/login'")
//   2. Adding a new screen means adding 2 lines here, nothing else changes
//   3. Your panel sees a clear map of the entire app's navigation structure
//
// USAGE EXAMPLE (from any screen):
//   Navigator.pushNamed(context, AppRoutes.login);
//   Navigator.pushReplacementNamed(context, AppRoutes.home);
//   Navigator.pushNamedAndRemoveUntil(
//     context, AppRoutes.welcome, (route) => false
//   );

import 'package:flutter/material.dart';

// -- Screen imports --
// As you build each screen, uncomment its import line here.
// Keeping them all in one place makes it easy to see what's been built.
import '../screens/auth/welcome_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/kyc_screen.dart';
import '../screens/auth/pending_approval_screen.dart';
// import '../screens/seeker/home_screen.dart';
// import '../screens/provider/provider_dashboard_screen.dart';

// =============================================================================
// ROUTE NAME CONSTANTS
// =============================================================================
// Each route is a static const string. Using these constants everywhere
// means a typo causes a compile-time error, not a silent runtime crash.

class AppRoutes {
  AppRoutes._(); // prevent instantiation

  // -- Auth Flow --
  static const String welcome = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String kyc = '/kyc';
  static const String pendingApproval = '/pending-approval';

  // -- Seeker Flow --
  static const String seekerHome = '/seeker/home';
  static const String serviceDetail = '/seeker/service-detail';
  static const String bookingStatus = '/seeker/booking-status';

  // -- Provider Flow --
  static const String providerDashboard = '/provider/dashboard';
  static const String addService = '/provider/add-service';

  // -- Shared --
  static const String profile = '/profile';
  static const String messages = '/messages';
}

// =============================================================================
// ROUTE MAP
// =============================================================================
// This function returns the full route table used by MaterialApp.
// Each entry maps a route string → a builder function that returns a Widget.
//
// HOW FLUTTER USES THIS:
// When you call Navigator.pushNamed(context, '/login'), Flutter looks up
// '/login' in this map and builds the corresponding screen widget.

Map<String, WidgetBuilder> get appRoutes => {
      // -- Auth Flow --
      AppRoutes.welcome: (context) => const WelcomeScreen(),

      // Uncomment each route as you build its screen:
      AppRoutes.login: (context) => const LoginScreen(),
      AppRoutes.register: (context) => const RegisterScreen(),
      AppRoutes.kyc: (context) => const KycScreen(),
      AppRoutes.pendingApproval: (context) => const PendingApprovalScreen(),

      // -- Seeker Flow --
      // AppRoutes.seekerHome:      (context) => const SeekerHomeScreen(),
      // AppRoutes.serviceDetail:   (context) => const ServiceDetailScreen(),
      // AppRoutes.bookingStatus:   (context) => const BookingStatusScreen(),

      // -- Provider Flow --
      // AppRoutes.providerDashboard: (context) => const ProviderDashboardScreen(),
      // AppRoutes.addService:        (context) => const AddServiceScreen(),
    };

// =============================================================================
// ROUTE GUARD (Auth Gate)
// =============================================================================
// This function is called by MaterialApp's onGenerateRoute as a fallback.
// It handles two important cases:
//   1. Unknown routes — shows a clear error screen instead of crashing
//   2. Future auth guards — you can add KYC status checks here later
//
// USAGE IN main.dart:
//   onGenerateRoute: AppRoutes.onGenerateRoute,

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  // Check if the route exists in our map
  final builder = appRoutes[settings.name];

  if (builder != null) {
    return MaterialPageRoute(
      builder: builder,
      settings: settings, // preserves route name for debugging
    );
  }

  // Unknown route fallback — never shows a blank screen
  return MaterialPageRoute(
    builder: (context) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Route "${settings.name}" not found.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.welcome,
                (route) => false, // clears entire navigation stack
              ),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
