// lib/widgets/category_chip.dart
//
// PURPOSE: The circular category filter chip shown on the home screen.
// Matches wireframe: circular icon container + label below.
// Tapping selects/deselects the category filter.
//
// UPDATED: Replaced emoji Text with Flutter IconData for consistent
// rendering on all devices including real Android hardware.

import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/service_model.dart';

class CategoryChip extends StatelessWidget {
  final ServiceCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── CIRCLE ICON CONTAINER ────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.backgroundWhite,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Icon(
                category.icon,
                size: 26,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 6),

          // ── CATEGORY LABEL ───────────────────────────────────────────────
          Text(
            category.displayName,
            style: AppTextStyles.caption.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
