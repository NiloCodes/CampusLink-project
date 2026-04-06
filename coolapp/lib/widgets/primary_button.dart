// lib/widgets/primary_button.dart
//
// PURPOSE: The dark navy pill button used for primary actions across
// CampusLink. Examples: "Login with University Email", "Submit for
// Verification", "Book & Pay via Escrow".
//
// WHY A REUSABLE WIDGET (for your defense):
// This implements the DRY principle (Don't Repeat Yourself). This button
// appears on 8+ screens. Without this widget, changing the border radius
// or color means editing 8 files. With this widget, you change 1 line.
//
// USAGE EXAMPLE:
//   PrimaryButton(
//     label: 'Login with University Email',
//     icon: Icons.email_outlined,
//     onPressed: () => handleLogin(),
//   )
//
//   // Loading state (during Firebase call):
//   PrimaryButton(
//     label: 'Signing in...',
//     isLoading: true,
//     onPressed: null,
//   )

import 'package:flutter/material.dart';
import '../core/constants.dart';

class PrimaryButton extends StatelessWidget {
  // -- Required --
  final String label;
  final VoidCallback? onPressed; // null automatically disables the button

  // -- Optional --
  final IconData? icon; // optional leading icon (e.g. envelope icon)
  final bool isLoading; // shows spinner instead of label during async ops
  final double? width; // defaults to full width if null
  final double height;

  const PrimaryButton({
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
      width: width ?? double.infinity, // full width by default
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonPrimary,
          disabledBackgroundColor:
              AppColors.buttonPrimary.withValues(alpha: 0.6),
          foregroundColor: AppColors.buttonPrimaryText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.pillRadius,
          ),
        ),
        child: isLoading
            // -- Loading state: show a small white spinner --
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            // -- Normal state: optional icon + label --
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: AppColors.buttonPrimaryText),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(label, style: AppTextStyles.buttonPrimary),
                ],
              ),
      ),
    );
  }
}
