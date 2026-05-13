// lib/widgets/empty_state.dart
//
// PURPOSE: Reusable empty state widget used across all screens.
// Shows an icon, title, subtitle and optional action button.
//
// USAGE:
//   EmptyState(
//     icon:        Icons.calendar_today_outlined,
//     title:       'No bookings yet',
//     subtitle:    'Services you book will appear here.',
//     actionLabel: 'Browse Services',
//     onAction:    () => ...,
//   )

import 'package:flutter/material.dart';
import '../core/constants.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── ICON ──────────────────────────────────────────────────
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.textSecondary)
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 44,
                color: iconColor ?? AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── TITLE ─────────────────────────────────────────────────
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.sm),

            // ── SUBTITLE ──────────────────────────────────────────────
            Text(
              subtitle,
              style: AppTextStyles.subtitle.copyWith(
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),

            // ── ACTION BUTTON ─────────────────────────────────────────
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.pillRadius,
                    ),
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// PRESET EMPTY STATES
// =============================================================================
// Ready-made empty states for each screen — just call the static method

class EmptyStates {
  // ── NO BOOKINGS (Seeker) ──────────────────────────────────────────────────
  static Widget noBookings({VoidCallback? onBrowse}) {
    return EmptyState(
      icon: Icons.calendar_today_outlined,
      iconColor: AppColors.accent,
      title: 'No bookings yet',
      subtitle: 'Services you book will appear here.\n'
          'Browse the home feed to find something.',
      actionLabel: onBrowse != null ? 'Browse Services' : null,
      onAction: onBrowse,
    );
  }

  // ── NO REQUESTS (Provider) ────────────────────────────────────────────────
  static Widget noRequests({VoidCallback? onAddService}) {
    return EmptyState(
      icon: Icons.inbox_rounded,
      iconColor: AppColors.primary,
      title: 'No requests yet',
      subtitle: 'Booking requests from students\n'
          'will appear here once you add a service.',
      actionLabel: onAddService != null ? 'Add a Service' : null,
      onAction: onAddService,
    );
  }

  // ── NO SERVICES (Home Feed) ───────────────────────────────────────────────
  static Widget noServices({VoidCallback? onClear}) {
    return EmptyState(
      icon: Icons.storefront_outlined,
      iconColor: AppColors.accent,
      title: 'No services found',
      subtitle: 'Try a different category\n'
          'or clear your filters.',
      actionLabel: onClear != null ? 'Clear Filters' : null,
      onAction: onClear,
    );
  }

  // ── NO SEARCH RESULTS ─────────────────────────────────────────────────────
  static Widget noSearchResults({
    required String query,
    VoidCallback? onClear,
  }) {
    return EmptyState(
      icon: Icons.search_off_rounded,
      iconColor: AppColors.textSecondary,
      title: 'No results found',
      subtitle: 'No services match "$query".\n'
          'Try a different keyword.',
      actionLabel: onClear != null ? 'Clear Search' : null,
      onAction: onClear,
    );
  }

  // ── NO EARNINGS ───────────────────────────────────────────────────────────
  static Widget noEarnings() {
    return const EmptyState(
      icon: Icons.account_balance_wallet_outlined,
      title: 'No earnings yet',
      subtitle: 'Complete your first booking to start\n'
          'building your earnings.',
    );
  }

  // ── NO NOTIFICATIONS ──────────────────────────────────────────────────────
  static Widget noNotifications() {
    return const EmptyState(
      icon: Icons.notifications_none_rounded,
      title: 'No notifications',
      subtitle: 'You\'re all caught up!\n'
          'We\'ll notify you of new activity.',
    );
  }

  // ── NO REVIEWS ────────────────────────────────────────────────────────────
  static Widget noReviews() {
    return const EmptyState(
      icon: Icons.star_outline_rounded,
      iconColor: AppColors.warning,
      title: 'No reviews yet',
      subtitle: 'Reviews will appear here after\n'
          'your first completed booking.',
    );
  }
}
