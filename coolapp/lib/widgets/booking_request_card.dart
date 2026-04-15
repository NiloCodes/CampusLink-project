// lib/widgets/booking_request_card.dart
//
// PURPOSE: The request card shown on Provider Dashboard.
// Matches wireframe: seeker avatar + name + category badge +
// time ago + Accept/Decline buttons.

import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/booking_model.dart';

class BookingRequestCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final bool isActing;

  const BookingRequestCard({
    super.key,
    required this.booking,
    required this.onAccept,
    required this.onDecline,
    this.isActing = false,
  });

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: AppRadius.lgRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Seeker avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.backgroundField,
                child: Text(
                  booking.seekerName.isNotEmpty
                      ? booking.seekerName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Name + badge + time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.seekerName,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Service title badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: AppRadius.pillRadius,
                          ),
                          child: Text(
                            booking.serviceTitle.toUpperCase().substring(
                                  0,
                                  booking.serviceTitle.length > 12
                                      ? 12
                                      : booking.serviceTitle.length,
                                ),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Time ago
                        const Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _timeAgo(booking.createdAt),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount
              Text(
                'GHS ${booking.totalAmount.toStringAsFixed(2)}',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Accept / Decline buttons
          Row(
            children: [
              // Accept button
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: isActing ? null : onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.pillRadius,
                      ),
                    ),
                    child: isActing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Accept',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Decline button
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: isActing ? null : onDecline,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.pillRadius,
                      ),
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
