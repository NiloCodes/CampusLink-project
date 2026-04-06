// lib/screens/auth/login_screen.dart
//
// PURPOSE: Signs in an existing CampusLink user.
// After successful login, routes to the correct screen based on kycStatus:
//   verified  → SeekerHomeScreen (or ProviderDashboard)
//   pending   → PendingApprovalScreen
//   rejected  → KycScreen (resubmit)
//
// WHAT THIS SCREEN DOES:
//   1. Collects UCC email + password
//   2. Validates both fields via Validators class
//   3. Calls AuthProvider.login()
//   4. Reads AuthStatus to decide where to navigate
//
// WHAT THIS SCREEN DOES NOT DO:
//   - No Firebase calls (that's auth_service.dart)
//   - No state management logic (that's auth_provider.dart)
//   - No hardcoded colors or styles (that's constants.dart)
//
// [PETRONILO & ERIC: no changes needed here — when auth_service.dart
// stubs are replaced with real Firebase, this screen works automatically]

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/routes.dart';
import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/trust_badge.dart';
import '../../widgets/campuslink_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── LOGIN HANDLER ──────────────────────────────────────────────────────────
  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();

    final success = await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      _navigateAfterLogin(auth);
    }
  }

  // Routes the user to the correct screen based on their KYC status.
  // This is the ONLY place in the app that contains this routing logic —
  // clean, findable, and easy to explain to your panel.
  void _navigateAfterLogin(AuthProvider auth) {
    switch (auth.status) {
      case AuthStatus.authenticated:
        // Fully verified — route based on role
        final user = auth.currentUser;
        if (user != null && user.isProvider && !user.isSeeker) {
          // Provider-only users go straight to their dashboard
          // Uncomment when ProviderDashboardScreen is built in sprint 2:
          // Navigator.pushReplacementNamed(context, AppRoutes.providerDashboard);
          _showSnackBar('Welcome back, ${user.fullName}!');
        } else {
          // Seekers and dual-role users go to home feed
          // Uncomment when SeekerHomeScreen is built in sprint 2:
          // Navigator.pushReplacementNamed(context, AppRoutes.seekerHome);
          _showSnackBar('Welcome back, ${auth.currentUser?.fullName}!');
        }
        break;

      case AuthStatus.pendingKyc:
        // KYC submitted but not yet approved — hold here
        // Uncomment when PendingApprovalScreen is built:
        // Navigator.pushReplacementNamed(context, AppRoutes.pendingApproval);
        _showSnackBar('Your verification is still pending.');
        break;

      case AuthStatus.rejectedKyc:
        // KYC was rejected — send them back to resubmit
        // Uncomment when KycScreen is built:
        // Navigator.pushReplacementNamed(context, AppRoutes.kyc);
        _showSnackBar('Your ID was rejected. Please resubmit.');
        break;

      default:
        break;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,

      // ── APP BAR ────────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.accent),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'CampusLink',
          style: TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),

                // ── HEADER ─────────────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      // Logo mark in white card
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundWhite,
                          borderRadius: AppRadius.lgRadius,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: CampusLinkLogo(
                            size: 52,
                            variant: LogoVariant.markOnly,
                            scheme: LogoScheme.onLight,
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      const Text(
                        'Welcome back',
                        style: AppTextStyles.heading1,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Sign in with your university email.',
                        style: AppTextStyles.subtitle,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── UNIVERSITY EMAIL ───────────────────────────────────────
                CustomTextField(
                  label: 'UNIVERSITY EMAIL',
                  hint: 'student@stu.ucc.edu.gh',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: Validators.validateEmail,
                  onChanged: (_) => context.read<AuthProvider>().clearError(),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── PASSWORD ───────────────────────────────────────────────
                CustomTextField(
                  label: 'PASSWORD',
                  hint: '••••••••',
                  controller: _passwordController,
                  isPassword: true,
                  validator: Validators.validatePassword,
                  onChanged: (_) => context.read<AuthProvider>().clearError(),
                ),

                const SizedBox(height: AppSpacing.sm),

                // ── FORGOT PASSWORD ────────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      // TODO: ForgotPasswordScreen — Sprint 2
                      _showSnackBar('Password reset coming in Sprint 2.');
                    },
                    child: const Text(
                      'Forgot password?',
                      style: AppTextStyles.link,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── AUTH ERROR MESSAGE ─────────────────────────────────────
                if (auth.errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 18,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            auth.errorMessage!,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // ── LOGIN BUTTON ───────────────────────────────────────────
                PrimaryButton(
                  label: 'Sign In',
                  icon: Icons.email_outlined,
                  isLoading: auth.isLoading,
                  onPressed: auth.isLoading ? null : _handleLogin,
                ),

                const SizedBox(height: AppSpacing.md),

                // ── DIVIDER ────────────────────────────────────────────────
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: AppColors.divider, thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Text(
                        'NEW TO CAMPUSLINK?',
                        style: AppTextStyles.fieldLabel.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: AppColors.divider, thickness: 1),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // ── CREATE ACCOUNT LINK ────────────────────────────────────
                // Secondary action — pushes to RegisterScreen
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.register,
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.pillRadius,
                      ),
                    ),
                    child: Text(
                      'Create Account',
                      style: AppTextStyles.buttonSecondary.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── TRUST BADGE ────────────────────────────────────────────
                const TrustBadge(),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
