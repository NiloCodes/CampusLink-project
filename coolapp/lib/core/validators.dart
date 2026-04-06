// lib/core/validators.dart
//
// PURPOSE: This file contains ALL form validation logic for CampusLink.
// Keeping validation here (separate from the UI) means:
//   1. You can test it independently without running the app
//   2. Every screen imports from ONE place — change a rule here, it updates everywhere
//   3. Your panel can see clean "Separation of Concerns" architecture
//
// ARCHITECTURAL NOTE (for Chapter 3):
// This follows the Single Responsibility Principle — this file's only job
// is to validate input. It has no UI code, no Firebase calls, nothing else.

class Validators {
  // --------------------------------------------------------------------------
  // UCC EMAIL VALIDATION
  // --------------------------------------------------------------------------
  // CampusLink restricts registration to two official UCC email domains:
  //   @stu.ucc.edu.gh  → for students
  //   @ucc.edu.gh      → for staff/postgrads (optional, but good to include)
  //
  // The regex below breaks down as:
  //   ^                     → start of string
  //   [a-zA-Z0-9._%+-]+     → one or more valid email characters before @
  //   @                     → the literal @ symbol
  //   (stu\.ucc\.edu\.gh|ucc\.edu\.gh)  → EITHER of the two allowed domains
  //   $                     → end of string
  //
  // WHY REGEX? It runs instantly on the client side, giving the user
  // immediate feedback before any Firebase call is made — saving API costs
  // and improving perceived performance.

  static const String _uccEmailPattern =
      r'^[a-zA-Z0-9._%+-]+@(stu\.ucc\.edu\.gh|ucc\.edu\.gh)$';

  /// Validates a UCC institutional email address.
  /// Returns null if valid (Flutter's FormField convention — null = no error).
  /// Returns an error STRING if invalid (Flutter displays this below the field).
  static String? validateEmail(String? value) {
    // Check 1: Field must not be empty
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your university email';
    }

    // Check 2: Must match the UCC domain pattern
    final regex = RegExp(_uccEmailPattern);
    if (!regex.hasMatch(value.trim())) {
      return 'Use your UCC email (e.g. name@stu.ucc.edu.gh)';
    }

    // null = valid — this is Flutter's built-in FormField validation contract
    return null;
  }

  // --------------------------------------------------------------------------
  // PASSWORD VALIDATION
  // --------------------------------------------------------------------------
  // Rules chosen for a good balance of security and usability:
  //   - Minimum 8 characters (industry standard)
  //   - At least 1 uppercase letter (prevents all-lowercase lazy passwords)
  //   - At least 1 number (adds entropy without being too strict)
  //
  // We deliberately avoid requiring special characters (@#$!) for now —
  // research shows overly strict rules increase password reuse, which is
  // worse for security. You can cite this in your defense if asked.

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    // Check for at least one uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for at least one digit
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    return null; // valid
  }

  // --------------------------------------------------------------------------
  // CONFIRM PASSWORD VALIDATION
  // --------------------------------------------------------------------------
  // Used on the RegisterScreen to ensure both password fields match.
  // Takes the ORIGINAL password as a parameter to compare against.

  static String? validateConfirmPassword(
      String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != originalPassword) {
      return 'Passwords do not match';
    }

    return null; // valid
  }

  // --------------------------------------------------------------------------
  // FULL NAME VALIDATION
  // --------------------------------------------------------------------------
  // Simple check — must have at least two words (first + last name).
  // This reduces fake/troll account names and matches your KYC expectations.

  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }

    // Split by spaces and filter out empty strings
    final parts = value.trim().split(' ').where((p) => p.isNotEmpty).toList();

    if (parts.length < 2) {
      return 'Please enter your first and last name';
    }

    if (value.trim().length < 5) {
      return 'Name is too short';
    }

    return null; // valid
  }

  // --------------------------------------------------------------------------
  // PHONE NUMBER VALIDATION (for MoMo number)
  // --------------------------------------------------------------------------
  // Ghanaian mobile numbers are 10 digits, starting with:
  //   024, 054, 055, 059 → MTN
  //   020, 050           → Vodafone
  //   026, 056, 027, 057 → AirtelTigo
  //
  // We validate the format here — actual MoMo verification happens
  // server-side via Paystack, so we keep this check lightweight.

  static String? validateMomoNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your Mobile Money number';
    }

    // Remove any spaces or dashes the user may have typed
    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');

    // Must be exactly 10 digits
    if (!RegExp(r'^\d{10}$').hasMatch(cleaned)) {
      return 'Enter a valid 10-digit Ghanaian mobile number';
    }

    // Must start with a known Ghanaian network prefix
    final validPrefixes = [
      '024',
      '054',
      '055',
      '059',
      '020',
      '050',
      '026',
      '056',
      '027',
      '057',
      '023',
      '053'
    ];
    final prefix = cleaned.substring(0, 3);

    if (!validPrefixes.contains(prefix)) {
      return 'Enter a valid MTN, Vodafone, or AirtelTigo number';
    }

    return null; // valid
  }

  // --------------------------------------------------------------------------
  // GENERIC REQUIRED FIELD
  // --------------------------------------------------------------------------
  // A simple reusable validator for any field that just must not be empty.
  // Pass a custom fieldName so the error message is specific.
  //
  // Usage: validator: (v) => Validators.validateRequired(v, 'Service title')

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
