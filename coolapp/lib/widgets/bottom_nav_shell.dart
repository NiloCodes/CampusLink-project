// lib/widgets/bottom_nav_shell.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core & Providers
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/service_provider.dart';
import '../providers/booking_provider.dart';

// Screens
import '../screens/seeker/home_screen.dart';
import '../screens/provider/provider_dashboard_screen.dart';
import '../screens/provider/earnings_screen.dart';
import '../screens/shared/bookings_screen.dart';
import '../screens/shared/profile_screen.dart';

class BottomNavShell extends StatefulWidget {
  final bool isProviderMode;

  const BottomNavShell({
    super.key,
    this.isProviderMode = false,
  });

  @override
  State<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends State<BottomNavShell> {
  int _currentIndex = 0;
  late bool _isProviderMode;

  @override
  void initState() {
    super.initState();
    _isProviderMode = widget.isProviderMode;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final user = auth.currentUser;
      final uid = user?.uid;

      if (uid == null) return;

      context.read<ServiceProvider>().initFeed();

      // Role-based booking initialisation
      if (user!.isSeeker && user.isProvider) {
        context.read<BookingProvider>().initBothBookings(uid);
      } else if (user.isSeeker) {
        context.read<BookingProvider>().initSeekerBookings(uid);
      } else if (user.isProvider) {
        context.read<BookingProvider>().initProviderBookings(uid);
      }
    });
  }

  // Returns the list of screens based on current mode
  List<Widget> get _screens {
    if (_isProviderMode) {
      return [
        const ProviderDashboardScreen(),
        const EarningsScreen(),
        ProfileScreen(
          onSwitchMode: () => setState(() {
            _isProviderMode = false;
            _currentIndex = 0;
          }),
        ),
      ];
    }

    // Seeker Mode screens
    final user = context.read<AuthProvider>().currentUser;
    return [
      const HomeScreen(),
      const BookingsScreen(), // This is fine as const
      ProfileScreen(
        onSwitchMode: user?.isProvider == true
            ? () => setState(() {
                  _isProviderMode = true;
                  _currentIndex = 0;
                })
            : null,
      ),
    ];
  }

  // Returns nav items based on current mode
  List<BottomNavigationBarItem> get _navItems {
    if (_isProviderMode) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.grid_view_outlined),
          activeIcon: Icon(Icons.grid_view_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_outlined),
          activeIcon: Icon(Icons.account_balance_wallet_rounded),
          label: 'Earnings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded),
          activeIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ];
    }
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home_rounded),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.calendar_today_outlined),
        activeIcon: Icon(Icons.calendar_today_rounded),
        label: 'Bookings',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline_rounded),
        activeIcon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Calling the getter to get the current screen set
    final screens = _screens;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.backgroundWhite,
        selectedItemColor: AppColors.navActive,
        unselectedItemColor: AppColors.navInactive,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 8,
        items: _navItems,
      ),
    );
  }
}
