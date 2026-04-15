// lib/screens/auth/welcome_screen.dart
//
// PURPOSE: The first screen a new user sees.
// - New users → "Create Account" (primary, filled blue)
// - Returning users → "Login" (outlined, secondary)
// - No bottom navigation bar on auth screens

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/trust_badge.dart';
import '../../core/validators.dart';
import '../../widgets/campuslink_logo.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

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
    if (success) _handlePostLoginNavigation(auth);
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

      // ── APP BAR ─────────────────────────────────────────────────────────
      // No back arrow on the entry screen — nothing to go back to
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'CampusLink',
          style: TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),

      // ── NO BOTTOM NAV BAR ────────────────────────────────────────────────
      // Nav bar only appears inside BottomNavShell for authenticated users

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppSpacing.xl),

                // ── LOGO CARD ──────────────────────────────────────────────
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

                // ── APP TITLE ──────────────────────────────────────────────
                const Text('CampusLink', style: AppTextStyles.appTitle),
                const SizedBox(height: AppSpacing.sm),

                // ── SUBTITLE ───────────────────────────────────────────────
                const Text(
                  'The exclusive marketplace for university talent.',
                  style: AppTextStyles.subtitle,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── PRIMARY BUTTON: Create Account ─────────────────────────
                // Filled navy — the action we want new users to take first
                PrimaryButton(
                  label: 'Create Account',
                  icon: Icons.person_add_outlined,
                  isLoading: false,
                  onPressed: auth.isLoading
                      ? null
                      : () => Navigator.pushNamed(
                            context,
                            AppRoutes.register,
                          ),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── SECONDARY BUTTON: Login ────────────────────────────────
                // Outlined — for returning users who already have an account
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: auth.isLoading ? null : _handleLogin,
                    icon: const Icon(
                      Icons.email_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    label: const Text(
                      'Login with University Email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
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
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── OR SIGN IN DIVIDER ─────────────────────────────────────
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
                        'OR SIGN IN',
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

                const SizedBox(height: AppSpacing.lg),

                // ── EMAIL FIELD ────────────────────────────────────────────
                CustomTextField(
                  label: 'UNIVERSITY EMAIL',
                  hint: 'student@stu.ucc.edu.gh',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                  onChanged: (_) => context.read<AuthProvider>().clearError(),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── PASSWORD FIELD ─────────────────────────────────────────
                CustomTextField(
                  label: 'PASSWORD',
                  hint: '••••••••',
                  controller: _passwordController,
                  isPassword: true,
                  validator: Validators.validatePassword,
                  onChanged: (_) => context.read<AuthProvider>().clearError(),
                ),

                const SizedBox(height: AppSpacing.sm),

                // ── FORGOT PASSWORD LINK ───────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => _showSnackBar(
                      'Password reset coming in Sprint 3.',
                    ),
                    child: const Text(
                      'Forgot password?',
                      style: AppTextStyles.link,
                    ),
                  ),
                ),

                // ── AUTH ERROR MESSAGE ─────────────────────────────────────
                if (auth.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
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
                ],

                const SizedBox(height: AppSpacing.lg),

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
