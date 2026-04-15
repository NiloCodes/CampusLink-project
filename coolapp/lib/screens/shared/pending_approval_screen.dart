// lib/screens/shared/pending_approval_screen.dart
//
// PURPOSE: Shown after KYC submission while the team reviews the student ID.
// The user is logged in but cannot access the marketplace until verified.
//
// STATES HANDLED:
//   pending  → "We're reviewing your ID" — estimated 24 hours
//   rejected → "Your ID was rejected" — resubmit CTA
//
// FLOW:
//   KycScreen → submit → PendingApprovalScreen
//   (AuthGate watches kycStatus in real time — when it flips to
//    'verified', the app automatically navigates to BottomNavShell)
//
// [PETRONILO & ERIC: your Cloud Function updates kycStatus in Firestore
// after reviewing the ID upload. The AuthProvider stream picks this up
// automatically and the AuthGate re-routes without any client action.]

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/campuslink_logo.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isRejected = auth.isRejectedKyc;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,

      // No app bar — this is a full-screen gate
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Column(
            children: [
              const Spacer(),

              // ── LOGO ─────────────────────────────────────────────────
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  borderRadius: AppRadius.lgRadius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: CampusLinkLogo(
                    size: 64,
                    variant: LogoVariant.markOnly,
                    scheme: LogoScheme.onLight,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── STATUS ICON ───────────────────────────────────────────
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isRejected
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.warning.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRejected
                      ? Icons.gpp_bad_rounded
                      : Icons.hourglass_top_rounded,
                  size: 40,
                  color: isRejected ? AppColors.error : AppColors.warning,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── HEADING ───────────────────────────────────────────────
              Text(
                isRejected ? 'Verification Failed' : 'Verification Pending',
                style: AppTextStyles.heading1,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.sm),

              // ── SUBTITLE ──────────────────────────────────────────────
              Text(
                isRejected
                    ? 'We could not verify your student ID.\n'
                        'Please resubmit with a clearer photo.'
                    : 'We\'re reviewing your student ID.\n'
                        'This usually takes less than 24 hours.',
                style: AppTextStyles.subtitle,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── STATUS CARD ───────────────────────────────────────────
              _buildStatusCard(isRejected),

              const SizedBox(height: AppSpacing.xl),

              // ── WHAT HAPPENS NEXT ─────────────────────────────────────
              if (!isRejected) _buildWhatHappensNext(),

              const Spacer(),

              // ── CTA BUTTONS ───────────────────────────────────────────
              if (isRejected) ...[
                // Resubmit KYC
                PrimaryButton(
                  label: 'Resubmit Verification',
                  icon: Icons.upload_rounded,
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.kyc,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Sign out
                _buildSignOutButton(context),
              ] else ...[
                // Check status (refreshes auth stream)
                PrimaryButton(
                  label: 'Check Status',
                  icon: Icons.refresh_rounded,
                  onPressed: () {
                    // AuthProvider's stream auto-updates —
                    // this just gives user feedback
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Checking your verification status...',
                        ),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.mdRadius,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _buildSignOutButton(context),
              ],

              const SizedBox(height: AppSpacing.lg),

              // ── FOOTER ────────────────────────────────────────────────
              Text(
                'Need help? Contact support@campuslink.com',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  // ── STATUS CARD ───────────────────────────────────────────────────────────

  Widget _buildStatusCard(bool isRejected) {
    final color = isRejected ? AppColors.error : AppColors.warning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: AppRadius.lgRadius,
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: isRejected
            ? [
                _statusRow(
                  Icons.image_not_supported_outlined,
                  AppColors.error,
                  'ID photo was unclear or unreadable',
                ),
                const SizedBox(height: AppSpacing.sm),
                _statusRow(
                  Icons.crop_outlined,
                  AppColors.error,
                  'Ensure the full card is in frame',
                ),
                const SizedBox(height: AppSpacing.sm),
                _statusRow(
                  Icons.wb_sunny_outlined,
                  AppColors.error,
                  'Good lighting — no glare or shadows',
                ),
              ]
            : [
                _statusRow(
                  Icons.check_circle_outline_rounded,
                  AppColors.warning,
                  'ID submitted successfully',
                ),
                const SizedBox(height: AppSpacing.sm),
                _statusRow(
                  Icons.access_time_rounded,
                  AppColors.warning,
                  'Review in progress — up to 24 hours',
                ),
                const SizedBox(height: AppSpacing.sm),
                _statusRow(
                  Icons.email_outlined,
                  AppColors.warning,
                  'You\'ll get an email when approved',
                ),
              ],
      ),
    );
  }

  Widget _statusRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(text, style: AppTextStyles.body),
        ),
      ],
    );
  }

  // ── WHAT HAPPENS NEXT ─────────────────────────────────────────────────────

  Widget _buildWhatHappensNext() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What happens next?',
          style: AppTextStyles.heading2,
        ),
        const SizedBox(height: AppSpacing.md),
        _nextStep(
          '1',
          AppColors.primary,
          'Our team reviews your student ID',
          'Usually within a few hours during the day',
        ),
        const SizedBox(height: AppSpacing.sm),
        _nextStep(
          '2',
          AppColors.accent,
          'You receive a confirmation email',
          'Check your UCC institutional inbox',
        ),
        const SizedBox(height: AppSpacing.sm),
        _nextStep(
          '3',
          AppColors.success,
          'Full access unlocked automatically',
          'Browse services, book, and start earning',
        ),
      ],
    );
  }

  Widget _nextStep(
    String number,
    Color color,
    String title,
    String subtitle,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step number circle
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),

        // Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(subtitle, style: AppTextStyles.caption),
            ],
          ),
        ),
      ],
    );
  }

  // ── SIGN OUT BUTTON ───────────────────────────────────────────────────────

  Widget _buildSignOutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () async {
          await context.read<AuthProvider>().signOut();
          // AuthGate will automatically navigate to WelcomeScreen
        },
        icon: const Icon(
          Icons.logout_rounded,
          size: 18,
          color: AppColors.textSecondary,
        ),
        label: const Text(
          'Sign Out',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.pillRadius,
          ),
        ),
      ),
    );
  }
}
