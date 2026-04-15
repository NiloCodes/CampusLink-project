// lib/widgets/service_card.dart
//
// PURPOSE: The reusable service listing card shown in the home feed.
// Matches the wireframe exactly:
//   - Full width hero image with star rating badge
//   - Provider name + verified badge + price right aligned
//   - Service title bold
//   - "View Details" pill button

import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/service_model.dart';

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;

  const ServiceCard({
    super.key,
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HERO IMAGE ───────────────────────────────────────────────────
          Stack(
            children: [
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: service.imageUrl != null
                    ? Image.network(
                        service.imageUrl!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),

              // Star rating badge (top right)
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.pillRadius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        service.formattedRating,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Negotiable badge (top left) — only shown when negotiable
              if (service.isPriceNegotiable)
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.9),
                      borderRadius: AppRadius.pillRadius,
                    ),
                    child: const Text(
                      'Negotiable',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // ── CARD BODY ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Provider name + verified badge + price
                Row(
                  children: [
                    // Verified badge
                    const Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 4),
                    // Provider name
                    Expanded(
                      child: Text(
                        service.providerName,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Price
                    Text(
                      service.formattedPrice,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xs),

                // Service title
                Text(
                  service.title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: AppSpacing.md),

                // View Details button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.pillRadius,
                      ),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Placeholder shown when image URL is null or fails to load
  Widget _imagePlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      color: AppColors.backgroundField,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            service.category.emoji,
            style: const TextStyle(fontSize: 40),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            service.category.displayName,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}
