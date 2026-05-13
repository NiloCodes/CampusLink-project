// lib/core/constants.dart
//
// PURPOSE: Single source of truth for all visual design tokens in CampusLink.
// Updated with Ursula's color (#0F57E7) and Inter font.

import 'package:flutter/material.dart';

// =============================================================================
// COLORS
// =============================================================================

class AppColors {
  AppColors._();

  // -- Primary Brand Color (Ursula's blue) --
  static const Color primary = Color(0xFF0F57E7);

  // -- Accent / Interactive Blue --
  static const Color accent = Color(0xFF0F57E7);

  // -- Background Colors --
  static const Color backgroundLight  = Color(0xFFF5F6FA);
  static const Color backgroundWhite  = Color(0xFFFFFFFF);
  static const Color backgroundField  = Color(0xFFEEF0F5);

  // -- Text Colors --
  static const Color textPrimary   = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint      = Color(0xFF9CA3AF);

  // -- Status Colors --
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFDC2626);
  static const Color info    = Color(0xFF2563EB);

  // -- Escrow Status Colors --
  static const Color escrowHeld      = Color(0xFFF59E0B);
  static const Color escrowReleased  = Color(0xFF16A34A);
  static const Color escrowDisputed  = Color(0xFFDC2626);

  // -- Border & Divider --
  static const Color border  = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFD1D5DB);

  // -- Button Colors --
  static const Color buttonPrimary      = primary;
  static const Color buttonPrimaryText  = Color(0xFFFFFFFF);
  static const Color buttonSecondary    = Color(0xFFE8EAF6);
  static const Color buttonSecondaryText = textPrimary;

  // -- Bottom Nav --
  static const Color navActive   = primary;
  static const Color navInactive = Color(0xFF9CA3AF);
}

// =============================================================================
// TYPOGRAPHY
// =============================================================================
// Uses Inter font (Ursula's choice — closest to SF Pro on Android)
// Font files are in assets/fonts/

class AppTextStyles {
  AppTextStyles._();

  static const String _font = 'Inter';

  // -- App Title --
  static const TextStyle appTitle = TextStyle(
    fontFamily:   _font,
    fontSize:     36,
    fontWeight:   FontWeight.w800,
    color:        AppColors.primary,
    letterSpacing: -0.5,
  );

  // -- Screen Heading --
  static const TextStyle heading1 = TextStyle(
    fontFamily:  _font,
    fontSize:    24,
    fontWeight:  FontWeight.w700,
    color:       AppColors.textPrimary,
  );

  // -- Section Heading --
  static const TextStyle heading2 = TextStyle(
    fontFamily:  _font,
    fontSize:    18,
    fontWeight:  FontWeight.w600,
    color:       AppColors.textPrimary,
  );

  // -- Body Text --
  static const TextStyle body = TextStyle(
    fontFamily:  _font,
    fontSize:    15,
    fontWeight:  FontWeight.w400,
    color:       AppColors.textPrimary,
    height:      1.5,
  );

  // -- Subtitle --
  static const TextStyle subtitle = TextStyle(
    fontFamily:  _font,
    fontSize:    15,
    fontWeight:  FontWeight.w400,
    color:       AppColors.textSecondary,
    height:      1.5,
  );

  // -- Form Field Label --
  static const TextStyle fieldLabel = TextStyle(
    fontFamily:    _font,
    fontSize:      11,
    fontWeight:    FontWeight.w600,
    color:         AppColors.textSecondary,
    letterSpacing: 1.2,
  );

  // -- Button Text --
  static const TextStyle buttonPrimary = TextStyle(
    fontFamily:    _font,
    fontSize:      16,
    fontWeight:    FontWeight.w600,
    color:         AppColors.buttonPrimaryText,
    letterSpacing: 0.3,
  );

  static const TextStyle buttonSecondary = TextStyle(
    fontFamily:  _font,
    fontSize:    16,
    fontWeight:  FontWeight.w600,
    color:       AppColors.buttonSecondaryText,
  );

  // -- Caption --
  static const TextStyle caption = TextStyle(
    fontFamily:  _font,
    fontSize:    12,
    fontWeight:  FontWeight.w400,
    color:       AppColors.textSecondary,
  );

  // -- Link Text --
  static const TextStyle link = TextStyle(
    fontFamily:  _font,
    fontSize:    14,
    fontWeight:  FontWeight.w500,
    color:       AppColors.primary,
    decoration:  TextDecoration.underline,
  );

  // -- Badge / Status Label --
  static const TextStyle badge = TextStyle(
    fontFamily:    _font,
    fontSize:      11,
    fontWeight:    FontWeight.w600,
    letterSpacing: 0.5,
  );
}

// =============================================================================
// SPACING
// =============================================================================

class AppSpacing {
  AppSpacing._();

  static const double xs            = 4.0;
  static const double sm            = 8.0;
  static const double md            = 16.0;
  static const double lg            = 24.0;
  static const double xl            = 32.0;
  static const double xxl           = 48.0;
  static const double screenPadding = 24.0;
}

// =============================================================================
// BORDER RADIUS
// =============================================================================

class AppRadius {
  AppRadius._();

  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 24.0;
  static const double pill = 100.0;

  static final BorderRadius smRadius   = BorderRadius.circular(sm);
  static final BorderRadius mdRadius   = BorderRadius.circular(md);
  static final BorderRadius lgRadius   = BorderRadius.circular(lg);
  static final BorderRadius pillRadius = BorderRadius.circular(pill);
}

// =============================================================================
// THEME
// =============================================================================

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        fontFamily:   'Inter',

        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary:   AppColors.primary,
          secondary: AppColors.accent,
          surfaceBright: AppColors.backgroundLight,
          surface:   AppColors.backgroundWhite,
          error:     AppColors.error,
        ),

        scaffoldBackgroundColor: AppColors.backgroundLight,

        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundWhite,
          foregroundColor: AppColors.textPrimary,
          elevation:       0,
          centerTitle:     true,
          titleTextStyle:  TextStyle(
            fontFamily:  'Inter',
            fontSize:    18,
            fontWeight:  FontWeight.w600,
            color:       AppColors.primary,
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled:    true,
          fillColor: AppColors.backgroundField,
          hintStyle: const TextStyle(
            fontFamily: 'Inter',
            color:      AppColors.textHint,
          ),
          border: OutlineInputBorder(
            borderRadius: AppRadius.mdRadius,
            borderSide:   BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.mdRadius,
            borderSide:   BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.mdRadius,
            borderSide:   const BorderSide(
              color: AppColors.primary,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppRadius.mdRadius,
            borderSide:   const BorderSide(
              color: AppColors.error,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppRadius.mdRadius,
            borderSide:   const BorderSide(
              color: AppColors.error,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical:   AppSpacing.md,
          ),
        ),
      );
}