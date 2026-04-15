// lib/widgets/stat_card.dart
//
// PURPOSE: The stat summary cards on the Provider Dashboard.
// Matches wireframe: icon + large number/amount + title + subtitle.
// Supports optional trend label ("+12% vs last month").

import 'package:flutter/material.dart';
import '../core/constants.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String title;
  final String subtitle;
  final Color? valueColor;
  final String? trendLabel; // e.g. "+12% vs last month"
  final bool isTrendPositive; // green if true, red if false
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.title,
    required this.subtitle,
    this.valueColor,
    this.trendLabel,
    this.isTrendPositive = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: AppRadius.lgRadius,
          border: Border(
            left: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 3,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: AppRadius.mdRadius,
              ),
              child: Icon(icon, size: 22, color: AppColors.primary),
            ),

            const SizedBox(width: AppSpacing.md),

            // Text content
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
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),

            // Value + trend
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: valueColor ?? AppColors.primary,
                  ),
                ),
                if (trendLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    trendLabel!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          isTrendPositive ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
