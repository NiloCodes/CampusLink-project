// lib/widgets/secondary_button.dart
//
// PURPOSE: The light grey pill button used for secondary actions.
// Examples: "Create Account" on WelcomeScreen, "Cancel" on booking screens.
//
// USAGE EXAMPLE:
//   SecondaryButton(
//     label: 'Create Account',
//     onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
//   )

import 'package:flutter/material.dart';
import '../core/constants.dart';

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double height;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonSecondary,
          disabledBackgroundColor:
              AppColors.buttonSecondary.withValues(alpha: 0.6),
          foregroundColor: AppColors.buttonSecondaryText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.pillRadius,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.buttonSecondaryText,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(label, style: AppTextStyles.buttonSecondary),
                ],
              ),
      ),
    );
  }
}
