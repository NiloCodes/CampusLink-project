// lib/widgets/rating_prompt_sheet.dart
//
// PURPOSE: Bottom sheet shown after a seeker releases funds.
// Prompts them to rate and review the provider's service.
//
// FLOW:
//   Seeker taps "Mark as Complete & Release Funds"
//   → Funds released
//   → This sheet appears automatically
//   → Seeker rates 1-5 stars + optional review text
//   → Taps "Submit Review" → review saved
//   → Sheet closes
//
// USAGE:
//   showRatingPrompt(context, booking: booking);
//
// [PETRONILO & ERIC: when submitted, write to Firestore:
//   reviews/{reviewId} collection with fields:
//   bookingId, serviceId, reviewerUid, reviewerName,
//   providerUid, rating, reviewText, createdAt
//   Then update services/{serviceId}.rating (average)
//   and services/{serviceId}.reviewCount]

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../core/constants.dart';
import '../models/booking_model.dart';

// ── PUBLIC HELPER ─────────────────────────────────────────────────────────────
// Call this after funds are released

Future<void> showRatingPrompt(
  BuildContext context, {
  required BookingModel booking,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: AppColors.backgroundWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _RatingSheet(booking: booking),
  );
}

// =============================================================================
// RATING SHEET
// =============================================================================

class _RatingSheet extends StatefulWidget {
  final BookingModel booking;

  const _RatingSheet({required this.booking});

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  double _rating = 0;
  bool _isSubmitting = false;
  bool _submitted = false;
  final _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  String get _ratingLabel {
    if (_rating == 0) return 'Tap to rate';
    if (_rating <= 1) return 'Poor';
    if (_rating <= 2) return 'Fair';
    if (_rating <= 3) return 'Good';
    if (_rating <= 4) return 'Very Good';
    return 'Excellent!';
  }

  Color get _ratingColor {
    if (_rating == 0) return AppColors.textSecondary;
    if (_rating <= 2) return AppColors.error;
    if (_rating <= 3) return AppColors.warning;
    return AppColors.success;
  }

  Future<void> _handleSubmit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a star rating'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // [PETRONILO & ERIC: write review to Firestore here]
    // await FirestoreService().createReview(
    //   bookingId:    widget.booking.bookingId,
    //   serviceId:    widget.booking.serviceId,
    //   reviewerUid:  currentUser.uid,
    //   reviewerName: currentUser.fullName,
    //   providerUid:  widget.booking.providerUid,
    //   rating:       _rating,
    //   reviewText:   _reviewController.text.trim(),
    // );

    // Simulate network call
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _submitted = true;
    });

    // Auto close after showing success
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.pop(context);
  }

  void _handleSkip() => Navigator.pop(context);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: _submitted ? _buildSuccessState() : _buildRatingForm(),
    );
  }

  // ── RATING FORM ───────────────────────────────────────────────────────────

  Widget _buildRatingForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Provider avatar + name
        CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            widget.booking.providerName.isNotEmpty
                ? widget.booking.providerName[0].toUpperCase()
                : '?',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        Text(
          'Rate ${widget.booking.providerName}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        Text(
          widget.booking.serviceTitle,
          style: AppTextStyles.subtitle,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSpacing.xl),

        // ── STAR RATING ──────────────────────────────────────────────
        RatingBar.builder(
          initialRating: 0,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: false,
          itemCount: 5,
          itemSize: 48,
          glow: false,
          itemPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
          ),
          itemBuilder: (context, index) {
            return Icon(
              Icons.star_rounded,
              color:
                  _rating > index ? const Color(0xFFFBBF24) : AppColors.border,
            );
          },
          onRatingUpdate: (rating) {
            setState(() => _rating = rating);
          },
        ),

        const SizedBox(height: AppSpacing.sm),

        // Rating label
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _ratingLabel,
            key: ValueKey(_rating),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _ratingColor,
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── REVIEW TEXT FIELD ─────────────────────────────────────────
        TextField(
          controller: _reviewController,
          maxLines: 3,
          maxLength: 300,
          decoration: InputDecoration(
            hintText: 'Share your experience (optional)...',
            hintStyle: AppTextStyles.caption.copyWith(
              color: AppColors.textHint,
            ),
            filled: true,
            fillColor: AppColors.backgroundField,
            border: OutlineInputBorder(
              borderRadius: AppRadius.lgRadius,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.lgRadius,
              borderSide: const BorderSide(
                color: AppColors.accent,
                width: 1.5,
              ),
            ),
            counterStyle: AppTextStyles.caption,
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── SUBMIT BUTTON ─────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.pillRadius,
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Submit Review',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Skip button
        TextButton(
          onPressed: _handleSkip,
          child: Text(
            'Skip for now',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // ── SUCCESS STATE ─────────────────────────────────────────────────────────

  Widget _buildSuccessState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpacing.xl),

        // Success icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            size: 48,
            color: AppColors.success,
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        const Text(
          'Review Submitted!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        Text(
          'Thank you for your feedback.\nIt helps the CampusLink community.',
          style: AppTextStyles.subtitle,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSpacing.xl),

        // Stars display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return Icon(
              Icons.star_rounded,
              size: 32,
              color:
                  index < _rating ? const Color(0xFFFBBF24) : AppColors.border,
            );
          }),
        ),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
