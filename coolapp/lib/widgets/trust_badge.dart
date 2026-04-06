// lib/widgets/trust_badge.dart
//
// PURPOSE: The "University Verified — Only .edu accounts permitted" card
// visible at the bottom of the Login screen in your wireframe.
// Also reused on the KYC screen and anywhere trust needs to be signalled.
//
// This widget reinforces CampusLink's core value proposition at the UI level:
// every interaction is between verified UCC students. Showing it on the
// login screen is a deliberate trust-building UX decision — you can cite
// this in your defense under "Perceived Trust" in the TAM framework.
//
// USAGE EXAMPLE:
//   // Default (verified state):
//   const TrustBadge()
//
//   // Pending state:
//   const TrustBadge(
//     title: 'Verification Pending',
//     subtitle: 'We are reviewing your student ID',
//     status: TrustBadgeStatus.pending,
//   )
//
//   // Rejected state:
//   const TrustBadge(
//     title: 'Verification Failed',
//     subtitle: 'Your ID could not be verified. Please resubmit.',
//     status: TrustBadgeStatus.rejected,
//   )

import 'package:flutter/material.dart';
import '../core/constants.dart';

// Enum defines the three possible trust states — maps to kyc_status in Firestore
enum TrustBadgeStatus { verified, pending, rejected }

class TrustBadge extends StatelessWidget {
  final String title;
  final String subtitle;
  final TrustBadgeStatus status;

  const TrustBadge({
    super.key,
    this.title = 'University Verified',
    this.subtitle = 'Only .edu accounts permitted',
    this.status = TrustBadgeStatus.verified,
  });

  // Returns the right color for each status state
  Color get _statusColor {
    switch (status) {
      case TrustBadgeStatus.verified:
        return AppColors.accent;
      case TrustBadgeStatus.pending:
        return AppColors.warning;
      case TrustBadgeStatus.rejected:
        return AppColors.error;
    }
  }

  // Returns the right icon for each status state
  IconData get _statusIcon {
    switch (status) {
      case TrustBadgeStatus.verified:
        return Icons.verified_user_rounded;
      case TrustBadgeStatus.pending:
        return Icons.hourglass_top_rounded;
      case TrustBadgeStatus.rejected:
        return Icons.gpp_bad_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 4,
      ),
      decoration: BoxDecoration(
        color: _statusColor.withValues(
            alpha: 0.08), // very light tinted background
        borderRadius: AppRadius.lgRadius,
        border: Border.all(
          color: _statusColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // -- Shield icon in a circular tinted container --
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(_statusIcon, size: 20, color: _statusColor),
          ),

          const SizedBox(width: AppSpacing.md),

          // -- Text column --
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
