// lib/core/constants.dart
//
// PURPOSE: This file is the single source of truth for all visual design
// tokens in CampusLink — colors, text styles, spacing, and border radii.
//
// WHY THIS MATTERS (for your defense):
// This implements the "Design Token" pattern. If your team decides to change
// the primary blue color, you change ONE line here and it updates across
// every screen automatically. Without this, you'd hunt through 20 files.
//
// USAGE EXAMPLE:
//   Container(color: AppColors.primary)
//   Text('Hello', style: AppTextStyles.heading1)
//   SizedBox(height: AppSpacing.md)

import 'package:flutter/material.dart';

// =============================================================================
// COLORS
// =============================================================================
// Derived directly from your Figma wireframe.
// Every color in CampusLink should come from this class — never hardcode
// a color value like Color(0xFF1A237E) directly in a screen file.

class AppColors {
  // Private constructor — prevents anyone from instantiating this class.
  // It's a pure namespace, not an object.
  AppColors._();

  // -- Primary Brand Color --
  // The dark navy blue used for primary buttons and the app title.
  // Sampled from your "Login with University Email" button in the wireframe.
  static const Color primary = Color(0xFF1A237E);

  // -- Accent / Interactive Blue --
  // Lighter blue used for the "CampusLink" title text and links.
  // Also used for the shield icon in the trust badge.
  static const Color accent = Color(0xFF1565C0);

  // -- Background Colors --
  static const Color backgroundLight =
      Color(0xFFF5F6FA); // page background (off-white/grey)
  static const Color backgroundWhite =
      Color(0xFFFFFFFF); // card and modal backgrounds
  static const Color backgroundField =
      Color(0xFFEEF0F5); // rounded input field background

  // -- Text Colors --
  static const Color textPrimary =
      Color(0xFF1A1A2E); // headings, important text
  static const Color textSecondary =
      Color(0xFF6B7280); // subtitles, placeholders
  static const Color textHint =
      Color(0xFF9CA3AF); // placeholder text inside fields

  // -- Status Colors --
  // Used for KYC status badges and booking state indicators
  static const Color success = Color(0xFF16A34A); // verified / released
  static const Color warning = Color(0xFFF59E0B); // pending
  static const Color error = Color(0xFFDC2626); // rejected / disputed
  static const Color info = Color(0xFF2563EB); // informational

  // -- Escrow Status Colors --
  // Specific to your Transaction Layer — maps to escrow_status in Firestore
  static const Color escrowHeld = Color(0xFFF59E0B); // funds are held
  static const Color escrowReleased =
      Color(0xFF16A34A); // funds released to provider
  static const Color escrowDisputed = Color(0xFFDC2626); // dispute raised

  // -- Border & Divider --
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFD1D5DB);

  // -- Button Colors --
  static const Color buttonPrimary = primary;
  static const Color buttonPrimaryText = Color(0xFFFFFFFF);
  static const Color buttonSecondary = Color(0xFFE8EAF6);
  static const Color buttonSecondaryText = textPrimary;

  // -- Bottom Nav --
  static const Color navActive = primary;
  static const Color navInactive = Color(0xFF9CA3AF);
}

// =============================================================================
// TYPOGRAPHY
// =============================================================================
// Text styles derived from your wireframe hierarchy.
// Uses Flutter's default font (Roboto on Android, SF Pro on iOS) for now.
// You can swap in a custom font later by updating pubspec.yaml and
// changing fontFamily here — nothing else needs to change.

class AppTextStyles {
  AppTextStyles._();

  // -- App Title (e.g. "CampusLink" on WelcomeScreen) --
  static const TextStyle appTitle = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: AppColors.accent,
    letterSpacing: -0.5,
  );

  // -- Screen Heading (e.g. "Verify Your Student Identity") --
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // -- Section Heading (e.g. card titles, form section labels) --
  static const TextStyle heading2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // -- Body Text (e.g. service descriptions, general content) --
  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5, // line height for readability
  );

  // -- Subtitle / Secondary Text (e.g. "The exclusive marketplace for...") --
  static const TextStyle subtitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // -- Form Field Label (e.g. "UNIVERSITY EMAIL", "PASSWORD") --
  // All caps, small, tracking — matches your wireframe exactly
  static const TextStyle fieldLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 1.2,
  );

  // -- Button Text --
  static const TextStyle buttonPrimary = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.buttonPrimaryText,
    letterSpacing: 0.3,
  );

  static const TextStyle buttonSecondary = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.buttonSecondaryText,
  );

  // -- Small / Caption (e.g. "Only .edu accounts permitted") --
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // -- Link Text (e.g. "Forgot password?") --
  static const TextStyle link = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.accent,
    decoration: TextDecoration.underline,
  );

  // -- Badge / Status Label --
  static const TextStyle badge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}

// =============================================================================
// SPACING
// =============================================================================
// A consistent spacing scale prevents random magic numbers (padding: 13,
// margin: 27) scattered across your codebase. Based on a base unit of 4px —
// the same scale used by Material Design and Tailwind CSS.

class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0; // tiny gaps
  static const double sm = 8.0; // tight padding
  static const double md = 16.0; // standard padding (most used)
  static const double lg = 24.0; // section spacing
  static const double xl = 32.0; // large gaps between sections
  static const double xxl = 48.0; // hero/splash spacing

  // Horizontal screen padding — consistent left/right margin on all screens
  static const double screenPadding = 24.0;
}

// =============================================================================
// BORDER RADIUS
// =============================================================================
// Your wireframe uses pill-shaped buttons and rounded input fields.
// Defining these here keeps the rounded aesthetic consistent.

class AppRadius {
  AppRadius._();

  static const double sm = 8.0; // small cards
  static const double md = 12.0; // input fields, small buttons
  static const double lg = 16.0; // cards
  static const double xl = 24.0; // large cards, modals
  static const double pill =
      100.0; // fully rounded buttons (your wireframe style)

  // Reusable BorderRadius objects (saves typing BorderRadius.circular every time)
  static final BorderRadius smRadius = BorderRadius.circular(sm);
  static final BorderRadius mdRadius = BorderRadius.circular(md);
  static final BorderRadius lgRadius = BorderRadius.circular(lg);
  static final BorderRadius pillRadius = BorderRadius.circular(pill);
}

// =============================================================================
// THEME
// =============================================================================
// The global MaterialApp theme. This is applied once in main.dart and
// automatically styles AppBar, buttons, inputs across the whole app.
// Individual screens can still override specific values where needed.

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surfaceBright: AppColors.backgroundLight,
          surface: AppColors.backgroundWhite,
          error: AppColors.error,
        ),

        // Scaffold (screen) background
        scaffoldBackgroundColor: AppColors.backgroundLight,

        // AppBar styling
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundWhite,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.accent, // "CampusLink" in blue — matches wireframe
          ),
        ),

        // Input field styling — rounded, grey background, no harsh border
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.backgroundField,
          hintStyle: const TextStyle(color: AppColors.textHint),
          border: OutlineInputBorder(
            borderRadius: AppRadius.mdRadius,
            borderSide: BorderSide.none, // no border by default
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.mdRadius,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.mdRadius,
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppRadius.mdRadius,
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppRadius.mdRadius,
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
        ),
      );
}
