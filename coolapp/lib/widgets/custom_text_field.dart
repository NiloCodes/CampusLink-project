// lib/widgets/custom_text_field.dart
//
// PURPOSE: The rounded grey input field used across all forms in CampusLink.
// Matches the rounded, filled style in your wireframe exactly.
//
// FEATURES BUILT IN:
//   - ALL CAPS label above the field (matching wireframe: "UNIVERSITY EMAIL")
//   - Placeholder hint text
//   - Password toggle (show/hide) — enabled automatically when isPassword: true
//   - Error display — Flutter's validator system handles this automatically
//   - Prefix icon support
//
// USAGE EXAMPLES:
//
//   // Email field:
//   CustomTextField(
//     label: 'UNIVERSITY EMAIL',
//     hint: 'student@university.edu',
//     controller: _emailController,
//     keyboardType: TextInputType.emailAddress,
//     validator: Validators.validateEmail,
//   )
//
//   // Password field:
//   CustomTextField(
//     label: 'PASSWORD',
//     hint: '••••••••',
//     controller: _passwordController,
//     isPassword: true,
//     validator: Validators.validatePassword,
//   )

import 'package:flutter/material.dart';
import '../core/constants.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool isPassword;
  final IconData? prefixIcon;
  final int maxLines;
  final bool enabled;
  final void Function(String)? onChanged;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.prefixIcon,
    this.maxLines = 1,
    this.enabled = true,
    this.onChanged,
  });

  // StatefulWidget because password fields need internal toggle state
  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  // Tracks whether the password is currently visible
  // Only relevant when widget.isPassword == true
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // -- Field Label (ALL CAPS, small, spaced — matches wireframe) --
        Text(widget.label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: AppSpacing.xs),

        // -- The actual input field --
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          keyboardType: widget.isPassword
              ? TextInputType.visiblePassword
              : widget.keyboardType,

          // obscureText hides password characters — toggled by the eye icon
          obscureText: widget.isPassword ? _obscureText : false,

          maxLines: widget.isPassword ? 1 : widget.maxLines,
          enabled: widget.enabled,
          onChanged: widget.onChanged,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,

            // -- Optional leading icon --
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon,
                    size: 20, color: AppColors.textSecondary)
                : null,

            // -- Password toggle icon (only shown on password fields) --
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    // Toggle the obscureText state on press
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
