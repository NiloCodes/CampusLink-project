// lib/screens/auth/register_screen.dart
//
// PURPOSE: Registration screen for new CampusLink users.
// Collects full name, UCC email, password, confirm password,
// and role selection (Seeker / Provider / Both).
//
// WHAT CHANGED FROM YOUR ORIGINAL VERSION:
//   - Wired into AuthProvider (replaces manual _isLoading state)
//   - Uses CustomTextField (replaces raw TextFormField)
//   - Uses PrimaryButton (replaces raw ElevatedButton)
//   - Uses Validators.validateEmail etc (replaces inline regex)
//   - Added confirm password field
//   - Added role selector (Seeker / Provider / Both)
//   - Added CampusLinkLogo header
//   - Added TrustBadge at bottom
//   - Styled to match constants.dart (AppColors, AppTextStyles, AppSpacing)
//
// ARCHITECTURAL NOTE (for your defense):
// This screen contains ZERO business logic. It only:
//   1. Collects user input
//   2. Validates it (via Validators class)
//   3. Passes it to AuthProvider
//   4. Reacts to the result (navigate or show error)
// All Firebase logic lives in auth_service.dart — this screen never
// touches Firebase directly.

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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers — one per field
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  // Role selection state
  // A user can be seeker only, provider only, or both.
  bool _isSeeker = true; // default: seeker selected
  bool _isProvider = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // Returns the roles list based on checkbox state
  // e.g. ['seeker'] or ['provider'] or ['seeker', 'provider']
  List<String> get _selectedRoles {
    final roles = <String>[];
    if (_isSeeker) roles.add('seeker');
    if (_isProvider) roles.add('provider');
    return roles;
  }

  // Validates that at least one role is selected
  bool get _rolesValid => _isSeeker || _isProvider;

  // ── REGISTRATION HANDLER ──────────────────────────────────────────────────
  Future<void> _handleRegistration() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    // Validate all form fields first
    if (!_formKey.currentState!.validate()) return;

    // Validate role selection separately (not a TextFormField)
    if (!_rolesValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one role.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mdRadius,
          ),
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();

    final success = await auth.register(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      roles: _selectedRoles,
    );

    if (!mounted) return;

    if (success) {
      // Registration succeeded — move to KYC screen
      Navigator.pushNamed(context, AppRoutes.kyc);
    }
    // If failed, auth.errorMessage is set and the error widget below rebuilds
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
                      // Logo mark
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
                      // Screen title
                      const Text(
                        'Create your account',
                        style: AppTextStyles.heading1,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Join your university gig marketplace.',
                        style: AppTextStyles.subtitle,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── FULL NAME ──────────────────────────────────────────────
                CustomTextField(
                  label: 'FULL NAME',
                  hint: 'e.g. Alex Mensah',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: Validators.validateFullName,
                  onChanged: (_) => context.read<AuthProvider>().clearError(),
                ),

                const SizedBox(height: AppSpacing.md),

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
                  hint: 'Min 8 chars, 1 uppercase, 1 number',
                  controller: _passwordController,
                  isPassword: true,
                  validator: Validators.validatePassword,
                  onChanged: (_) => context.read<AuthProvider>().clearError(),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── CONFIRM PASSWORD ───────────────────────────────────────
                CustomTextField(
                  label: 'CONFIRM PASSWORD',
                  hint: 'Re-enter your password',
                  controller: _confirmController,
                  isPassword: true,
                  // Passes the original password to compare against
                  validator: (value) => Validators.validateConfirmPassword(
                    value,
                    _passwordController.text,
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── ROLE SELECTOR ──────────────────────────────────────────
                // Users can be seekers, providers, or both.
                // This maps directly to the 'roles' field in Firestore.
                _buildRoleSelector(),

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

                // ── REGISTER BUTTON ────────────────────────────────────────
                PrimaryButton(
                  label: 'Create Account',
                  isLoading: auth.isLoading,
                  onPressed: auth.isLoading ? null : _handleRegistration,
                ),

                const SizedBox(height: AppSpacing.md),

                // ── LOGIN LINK ─────────────────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.login,
                    ),
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: AppTextStyles.caption,
                        children: [
                          TextSpan(
                            text: 'Sign in',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

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

  // ── ROLE SELECTOR WIDGET ─────────────────────────────────────────────────
  // Built as a private method to keep build() clean and readable.
  // Uses checkboxes so the user can select both roles simultaneously.

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label — same ALL CAPS style as field labels
        Text('I WANT TO', style: AppTextStyles.fieldLabel),
        const SizedBox(height: AppSpacing.sm),

        // Role cards container
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            borderRadius: AppRadius.lgRadius,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              // ── SEEKER ROLE ──────────────────────────────────────────────
              _buildRoleTile(
                icon: Icons.search_rounded,
                title: 'Hire services',
                subtitle: 'Browse and book services from other students',
                isSelected: _isSeeker,
                onTap: () => setState(() => _isSeeker = !_isSeeker),
              ),

              // Divider between role tiles
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.border,
                indent: 16,
                endIndent: 16,
              ),

              // ── PROVIDER ROLE ─────────────────────────────────────────────
              _buildRoleTile(
                icon: Icons.work_outline_rounded,
                title: 'Offer my services',
                subtitle: 'List your skills and earn from fellow students',
                isSelected: _isProvider,
                onTap: () => setState(() => _isProvider = !_isProvider),
              ),
            ],
          ),
        ),

        // Helper text — shows when nothing is selected
        if (!_rolesValid) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Select at least one option to continue.',
            style: AppTextStyles.caption.copyWith(color: AppColors.error),
          ),
        ],

        // Helper text — shows when both are selected
        if (_isSeeker && _isProvider) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'You can switch between roles anytime after verification.',
            style: AppTextStyles.caption.copyWith(color: AppColors.accent),
          ),
        ],
      ],
    );
  }

  // Builds a single tappable role tile with icon, title, subtitle, and checkbox
  Widget _buildRoleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            // Icon in a tinted circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.backgroundField,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Checkbox — custom styled to match brand
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
