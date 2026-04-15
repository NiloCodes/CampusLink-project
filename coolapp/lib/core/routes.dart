// lib/core/routes.dart
//
// PURPOSE: This file is the single source of truth for ALL navigation in CampusLink.
// 1. Defines Route Name Constants (Prevents typos)
// 2. Registers the Route Map
// 3. Handles Unknown Routes (onGenerateRoute)

import 'package:flutter/material.dart';

// -- Screen imports --
import '../screens/auth/welcome_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/kyc_screen.dart';
import '../screens/auth/pending_approval_screen.dart';
import '../screens/seeker/home_screen.dart';
import '../screens/provider/provider_dashboard_screen.dart';

// =============================================================================
// ROUTE NAME CONSTANTS
// =============================================================================
class AppRoutes {
  AppRoutes._(); // prevent instantiation

  // -- Auth Flow --
  // We use '/welcome' instead of '/' to avoid clashing with 'home: AuthGate()' in main.dart
  static const String welcome = '/welcome';
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
Map<String, WidgetBuilder> get appRoutes => {
      // Auth Flow
      AppRoutes.welcome: (context) => const WelcomeScreen(),
      AppRoutes.login: (context) => const LoginScreen(),
      AppRoutes.register: (context) => const RegisterScreen(),
      AppRoutes.kyc: (context) => const KycScreen(),
      AppRoutes.pendingApproval: (context) => const PendingApprovalScreen(),

      // Seeker Flow
      AppRoutes.seekerHome: (context) => const HomeScreen(),

      // Provider Flow
      AppRoutes.providerDashboard: (context) => const ProviderDashboardScreen(),
    };

// =============================================================================
// ROUTE GUARD / DYNAMIC ROUTING
// =============================================================================
Route<dynamic> onGenerateRoute(RouteSettings settings) {
  final builder = appRoutes[settings.name];

  if (builder != null) {
    return MaterialPageRoute(
      builder: builder,
      settings: settings,
    );
  }

  // Fallback for Page Not Found
  return MaterialPageRoute(
    builder: (context) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Route "${settings.name}" not found.'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.welcome,
                (route) => false,
              ),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
