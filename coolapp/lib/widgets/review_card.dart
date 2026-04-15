// lib/widgets/review_card.dart
//
// PURPOSE: Individual review card shown on ServiceDetailScreen.
// Matches wireframe: star rating row + quoted review text + reviewer name.

import 'package:flutter/material.dart';
import '../core/constants.dart';

class ReviewCard extends StatelessWidget {
  final double rating;
  final String reviewText;
  final String reviewerName;
  final DateTime? date;

  const ReviewCard({
    super.key,
    required this.rating,
    required this.reviewText,
    required this.reviewerName,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Star rating row
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < rating.floor()
                    ? Icons.star_rounded
                    : i < rating
                        ? Icons.star_half_rounded
                        : Icons.star_outline_rounded,
                size: 18,
                color: const Color(0xFFF59E0B),
              );
            }),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Review text
          Text(
            '"$reviewText"',
            style: AppTextStyles.body.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Reviewer name + date
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.backgroundField,
                child: Text(
                  reviewerName.isNotEmpty ? reviewerName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                reviewerName,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
