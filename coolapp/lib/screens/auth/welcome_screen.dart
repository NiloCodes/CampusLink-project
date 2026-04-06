// lib/screens/auth/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/trust_badge.dart';
import '../../core/validators.dart';
import '../../widgets/campuslink_logo.dart'; // Add this import!

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  int _currentNavIndex = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
      _handlePostLoginNavigation(auth);
    }
  }

  void _handlePostLoginNavigation(AuthProvider auth) {
    switch (auth.status) {
      case AuthStatus.authenticated:
        _showSnackBar('Welcome back, ${auth.currentUser?.fullName}!');
        break;
      case AuthStatus.pendingKyc:
        _showSnackBar('Your KYC is pending approval.');
        break;
      case AuthStatus.rejectedKyc:
        _showSnackBar('Your KYC was rejected. Please resubmit.');
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
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.accent),
          onPressed: () {},
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppSpacing.xl),

                // ── LOGO CARD (UPDATED) ──────────────────────────────────────
                // Swapped the placeholder container for your actual code logo
                Container(
                  width: 90,
                  height: 90,
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
                    padding: EdgeInsets.all(13),
                    child: CampusLinkLogo(
                      size: 64,
                      variant: LogoVariant.markOnly,
                      scheme: LogoScheme.onLight,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── APP TITLE ───────────────────────────────────────────────
                const Text('CampusLink', style: AppTextStyles.appTitle),
                const SizedBox(height: AppSpacing.sm),

                // ── SUBTITLE ────────────────────────────────────────────────
                const Text(
                  'The exclusive marketplace for university talent.',
                  style: AppTextStyles.subtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── PRIMARY BUTTON: Login ────────────────────────────────────
                PrimaryButton(
                  label: 'Login with University Email',
                  icon: Icons.email_outlined,
                  isLoading: auth.isLoading,
                  onPressed: auth.isLoading ? null : _handleLogin,
                ),
                const SizedBox(height: AppSpacing.md),

                // ── SECONDARY BUTTON: Create Account ────────────────────────
                SecondaryButton(
                  label: 'Create Account',
                  onPressed: auth.isLoading
                      ? null
                      : () => Navigator.pushNamed(context, AppRoutes.register),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── OR SIGN IN DIVIDER ───────────────────────────────────────
                Row(
                  children: [
                    const Expanded(
                        child: Divider(color: AppColors.divider, thickness: 1)),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text(
                        'OR SIGN IN',
                        style: AppTextStyles.fieldLabel
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    const Expanded(
                        child: Divider(color: AppColors.divider, thickness: 1)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── EMAIL FIELD ─────────────────────────────────────────────
                CustomTextField(
                  label: 'UNIVERSITY EMAIL',
                  hint: 'student@stu.ucc.edu.gh',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                  onChanged: (_) => context.read<AuthProvider>().clearError(),
                ),
                const SizedBox(height: AppSpacing.md),

                // ── PASSWORD FIELD ──────────────────────────────────────────
                CustomTextField(
                  label: 'PASSWORD',
                  hint: '••••••••',
                  controller: _passwordController,
                  isPassword: true,
                  validator: Validators.validatePassword,
                  onChanged: (_) => context.read<AuthProvider>().clearError(),
                ),
                const SizedBox(height: AppSpacing.sm),

                // ── FORGOT PASSWORD LINK ────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () =>
                        _showSnackBar('Password reset coming in Sprint 2.'),
                    child: const Text('Forgot password?',
                        style: AppTextStyles.link),
                  ),
                ),

                // ── AUTH ERROR MESSAGE ──────────────────────────────────────
                if (auth.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 18, color: AppColors.error),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            auth.errorMessage!,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),

                // ── TRUST BADGE ─────────────────────────────────────────────
                const TrustBadge(),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),

      // ── BOTTOM NAVIGATION BAR ───────────────────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) => setState(() => _currentNavIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.backgroundWhite,
        selectedItemColor: AppColors.navActive,
        unselectedItemColor: AppColors.navInactive,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'Services'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              activeIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Messages'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile'),
        ],
      ),
    );
  }
}
