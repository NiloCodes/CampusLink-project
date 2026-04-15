// lib/widgets/booking_status_card.dart
//
// PURPOSE: The escrow status card shown on BookingStatusScreen.
// Changes color and icon based on escrow state:
//   held            → blue  (funds secured)
//   released        → green (funds released to provider)
//   disputed        → red   (dispute raised)
//   awaitingPayment → grey  (waiting for payment)
//   refunded        → amber (funds refunded to seeker)

import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/booking_model.dart';

class BookingStatusCard extends StatelessWidget {
  final EscrowStatus escrowStatus;

  const BookingStatusCard({
    super.key,
    required this.escrowStatus,
  });

  Color get _color {
    switch (escrowStatus) {
      case EscrowStatus.held:
        return AppColors.accent;
      case EscrowStatus.released:
        return AppColors.success;
      case EscrowStatus.disputed:
        return AppColors.error;
      case EscrowStatus.awaitingPayment:
        return AppColors.textSecondary;
      case EscrowStatus.refunded:
        return AppColors.warning;
    }
  }

  IconData get _icon {
    switch (escrowStatus) {
      case EscrowStatus.held:
        return Icons.lock_rounded;
      case EscrowStatus.released:
        return Icons.check_circle_rounded;
      case EscrowStatus.disputed:
        return Icons.warning_rounded;
      case EscrowStatus.awaitingPayment:
        return Icons.schedule_rounded;
      case EscrowStatus.refunded:
        return Icons.replay_rounded;
    }
  }

  String get _title {
    switch (escrowStatus) {
      case EscrowStatus.held:
        return 'Secure Escrow';
      case EscrowStatus.released:
        return 'Payment Released';
      case EscrowStatus.disputed:
        return 'Dispute Raised';
      case EscrowStatus.awaitingPayment:
        return 'Awaiting Payment';
      case EscrowStatus.refunded:
        return 'Funds Refunded';
    }
  }

  String get _subtitle {
    switch (escrowStatus) {
      case EscrowStatus.held:
        return 'Funds are held safely in CampusLink Escrow\n'
            'until you confirm the work is complete.';
      case EscrowStatus.released:
        return 'Funds have been released to the provider.\n'
            'We hope you enjoyed the service!';
      case EscrowStatus.disputed:
        return 'Your dispute has been raised. Our team\n'
            'will review and respond within 24 hours.';
      case EscrowStatus.awaitingPayment:
        return 'Booking confirmed. Complete payment\n'
            'to secure your funds in escrow.';
      case EscrowStatus.refunded:
        return 'Your funds have been refunded\n'
            'to your Mobile Money account.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.08),
        borderRadius: AppRadius.lgRadius,
        border: Border.all(
          color: _color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Icon in circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, size: 28, color: _color),
          ),
          const SizedBox(height: AppSpacing.md),

          // Title
          Text(
            _title,
            style: AppTextStyles.heading2.copyWith(color: _color),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Subtitle
          Text(
            _subtitle,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
