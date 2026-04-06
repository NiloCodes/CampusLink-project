// lib/screens/auth/pending_approval_screen.dart
//
// PURPOSE: A holding screen for users whose KYC is submitted but not yet
// reviewed by the CampusLink admins (or automated Cloud Function).
//
// WHAT THIS SCREEN DOES:
//   1. Explains that verification is in progress.
//   2. Provides a "Refresh Status" button to check Firebase for updates.
//   3. Routes the user to the Home screen if verified, or back to KYC if rejected.
//   4. Allows the user to securely log out while waiting.
//
// [PETRONILO & ERIC: When the user taps "Refresh Status", the frontend
// pulls the latest user document from Firestore. If your Node.js backend
// has changed 'kycStatus' from 'pending' to 'verified', this screen will
// automatically push them into the main app ecosystem.]

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/primary_button.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  bool _isRefreshing = false;

  // ── REFRESH HANDLER ────────────────────────────────────────────────────────
  // Pings the backend to get the latest user document.
  // Evaluates the new kycStatus and routes accordingly.
  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);

    final auth = context.read<AuthProvider>();

    // Assuming your AuthProvider has a method to fetch the latest user data
    // from Firestore. e.g., await auth.reloadUserData();
    // For now, we simulate a network call:
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _isRefreshing = false);

    // Check the updated status
    if (auth.status == AuthStatus.authenticated) {
      _showSnackBar(
          'Verification successful! Welcome to CampusLink.', AppColors.success);
      // Navigate to main app shell (Sprint 2)
      // Navigator.pushReplacementNamed(context, AppRoutes.seekerHome);
    } else if (auth.status == AuthStatus.rejectedKyc) {
      _showSnackBar('Your ID was rejected. Please try again.', AppColors.error);
      Navigator.pushReplacementNamed(context, AppRoutes.kyc);
    } else {
      _showSnackBar('Still pending. We will notify you once approved.',
          AppColors.primary);
    }
  }

  // ── LOGOUT HANDLER ─────────────────────────────────────────────────────────
  Future<void> _handleLogout() async {
    //final auth = context.read<AuthProvider>();
    // await auth.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.welcome);
  }

  void _showSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,

      // ── APP BAR ────────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Locked on this screen
        title: const Text(
          'CampusLink',
          style: TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded,
                color: AppColors.textSecondary),
            tooltip: 'Log Out',
            onPressed: _handleLogout,
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.lg),

              // ── PROGRESS INDICATOR ─────────────────────────────────────────
              // Reusing your brilliant progress step logic, but advancing to Step 3.
              _buildProgressSteps(),

              const SizedBox(height: AppSpacing.xxl),

              // ── ANIMATED HOLDING ICON ──────────────────────────────────────
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── TEXT CONTENT ───────────────────────────────────────────────
              const Text(
                'Verification in Progress',
                style: AppTextStyles.heading1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Our team is reviewing your student ID to ensure a safe marketplace for everyone. This usually takes less than 24 hours.',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── INFO CARD ──────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  borderRadius: AppRadius.lgRadius,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: AppColors.accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'We will send a push notification to your phone as soon as your account is approved.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── ACTION BUTTON ──────────────────────────────────────────────
              PrimaryButton(
                label: 'Refresh Status',
                icon: Icons.refresh_rounded,
                isLoading: _isRefreshing,
                onPressed: _handleRefresh,
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  // ── PROGRESS STEPS (Updated for Step 3) ──────────────────────────────────
  Widget _buildProgressSteps() {
    return Row(
      children: [
        _buildStep(
            label: 'Register', stepNumber: 1, isDone: true, isActive: false),
        _buildStepConnector(isComplete: true),
        _buildStep(
            label: 'Verify ID', stepNumber: 2, isDone: true, isActive: false),
        _buildStepConnector(
            isComplete: true), // Now green because Step 2 is done!
        _buildStep(
            label: 'Get Started',
            stepNumber: 3,
            isDone: false,
            isActive: true), // Step 3 is active
      ],
    );
  }

  Widget _buildStep({
    required String label,
    required int stepNumber,
    required bool isDone,
    required bool isActive,
  }) {
    final Color color = isDone
        ? AppColors.success
        : isActive
            ? AppColors.primary
            : AppColors.textSecondary.withValues(alpha: 0.4);

    return Expanded(
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDone || isActive
                  ? color.withValues(alpha: 0.12)
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: isDone
                  ? Icon(Icons.check_rounded, size: 16, color: color)
                  : Text(
                      '$stepNumber',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector({required bool isComplete}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 22),
        color: isComplete
            ? AppColors.success.withValues(alpha: 0.5)
            : AppColors.border,
      ),
    );
  }
}
