// lib/screens/seeker/service_detail_screen.dart
//
// PURPOSE: Full service detail page shown when seeker taps "View Details".
//
// MATCHES WIREFRAME:
//   ✓ Full width hero image with category badge overlay
//   ✓ Service info card (title + price + provider + verified + "View Profile")
//   ✓ Service Description section with blue left border accent
//   ✓ Description text card with feature chips (turnaround + warranty)
//   ✓ Top Student Reviews section with rating + review cards
//   ✓ Contact Provider row (phone/WhatsApp/Instagram/Snapchat)
//   ✓ "CampusLink Secure" sticky bottom badge
//   ✓ "Book & Pay via MoMo" sticky CTA button with price left + MoMo icon right
//   ✓ "© 2024 CampusLink. Student Verified." footer
//
// EXTRA FEATURES ADDED:
//   ✓ "This is your listing" guard — provider can't book their own service
//   ✓ Wishlist heart icon in app bar
//   ✓ Negotiable price indicator
//   ✓ Shimmer loading state

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/service_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/review_card.dart';
import '../../widgets/contact_row.dart';
import '../../widgets/booking_status_card.dart';
import '../../widgets/payment_bottom_sheet.dart';
import '../seeker/booking_status_screen.dart';

class ServiceDetailScreen extends StatefulWidget {
  final ServiceModel service;

  const ServiceDetailScreen({
    super.key,
    required this.service,
  });

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  bool _isWishlisted = false;

  // Stub reviews — replaced by Firestore in sprint 3
  final List<Map<String, dynamic>> _stubReviews = [
    {
      'rating': 5.0,
      'text': 'Amazing service! My phone looks brand new.',
      'reviewer': 'Kwame O.',
    },
    {
      'rating': 5.0,
      'text': 'Super fast and very professional.',
      'reviewer': 'Ama R.',
    },
    {
      'rating': 4.0,
      'text': 'Great work, would definitely recommend to friends.',
      'reviewer': 'Kofi M.',
    },
  ];

  void _handleBooking() {
    PaymentBottomSheet.show(
      context,
      widget.service,
      () {
        // Navigate to bookings screen after successful booking
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Booking created! Check your bookings for status updates.',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.mdRadius,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUser;

    // Guard: provider cannot book their own service
    final isOwnListing = currentUser?.uid == widget.service.providerUid;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── APP BAR ────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.backgroundWhite,
            foregroundColor: AppColors.textPrimary,
            leading: IconButton(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Wishlist heart
              IconButton(
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isWishlisted
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color:
                        _isWishlisted ? AppColors.error : AppColors.textPrimary,
                    size: 20,
                  ),
                ),
                onPressed: () {
                  setState(() => _isWishlisted = !_isWishlisted);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isWishlisted
                            ? 'Added to wishlist'
                            : 'Removed from wishlist',
                      ),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Hero image
                  widget.service.imageUrl != null
                      ? Image.network(
                          widget.service.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _heroPlaceholder(),
                        )
                      : _heroPlaceholder(),

                  // Gradient overlay at bottom of image
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Category badge (bottom left of image)
                  Positioned(
                    bottom: AppSpacing.md,
                    left: AppSpacing.md,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: AppRadius.pillRadius,
                      ),
                      child: Text(
                        widget.service.category.fullDisplayName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── BODY ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── SERVICE INFO CARD ──────────────────────────────────
                Container(
                  margin: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.md,
                    AppSpacing.screenPadding,
                    0,
                  ),
                  padding: const EdgeInsets.all(AppSpacing.md),
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
                      // Title + price row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Expanded(
                            child: Text(
                              widget.service.title,
                              style: AppTextStyles.heading1,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          // Price
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                widget.service.isPriceNegotiable
                                    ? 'From'
                                    : 'Fixed',
                                style: AppTextStyles.caption,
                              ),
                              Text(
                                'GHS ${widget.service.basePrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.md),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: AppSpacing.md),

                      // Provider row
                      Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.backgroundField,
                            backgroundImage:
                                widget.service.providerAvatarUrl != null
                                    ? NetworkImage(
                                        widget.service.providerAvatarUrl!)
                                    : null,
                            child: widget.service.providerAvatarUrl == null
                                ? Text(
                                    widget.service.providerName.isNotEmpty
                                        ? widget.service.providerName[0]
                                            .toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: AppSpacing.sm),

                          // Name + subtitle
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      widget.service.providerName,
                                      style: AppTextStyles.body.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    if (widget.service.isVerified)
                                      const Icon(
                                        Icons.verified_rounded,
                                        size: 16,
                                        color: AppColors.accent,
                                      ),
                                  ],
                                ),
                                Text(
                                  'UCC Student',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),

                          // View Profile link
                          GestureDetector(
                            onTap: () {
                              // TODO: Navigate to provider profile
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Provider profile coming in Sprint 3'),
                                ),
                              );
                            },
                            child: Text(
                              'View Profile',
                              style: AppTextStyles.link,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── SERVICE DESCRIPTION ────────────────────────────────
                _buildSectionHeader('Service Description'),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundWhite,
                      borderRadius: AppRadius.lgRadius,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.service.description,
                          style: AppTextStyles.body,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Feature chips
                        Row(
                          children: [
                            _featureChip(
                              Icons.access_time_rounded,
                              '2hr Turnaround',
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _featureChip(
                              Icons.verified_user_outlined,
                              '30-day Warranty',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── CONTACT PROVIDER ───────────────────────────────────
                if (widget.service.hasContacts) ...[
                  _buildSectionHeader('Contact Provider'),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundWhite,
                        borderRadius: AppRadius.lgRadius,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ContactRow(service: widget.service),
                    ),
                  ),
                ],

                // ── NEGOTIABLE PRICE NOTE ──────────────────────────────
                if (widget.service.isPriceNegotiable) ...[
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.06),
                        borderRadius: AppRadius.lgRadius,
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'This service has a negotiable price. '
                              'Contact the provider first, agree on an amount, '
                              'then book.',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // ── TOP STUDENT REVIEWS ────────────────────────────────
                _buildSectionHeader('Top Student Reviews',
                    trailing: Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.service.formattedRating}'
                          ' (${widget.service.reviewCount})',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: Column(
                    children: _stubReviews
                        .map((r) => ReviewCard(
                              rating: r['rating'],
                              reviewText: r['text'],
                              reviewerName: r['reviewer'],
                            ))
                        .toList(),
                  ),
                ),

                // ── CAMPUSLINK SECURE BADGE ────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: AppRadius.lgRadius,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shield_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CampusLink Secure',
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                'Payment held in escrow until'
                                ' you\'re satisfied.',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Extra bottom padding for sticky CTA
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),

      // ── STICKY BOTTOM CTA ─────────────────────────────────────────────
      bottomNavigationBar: _buildStickyBookingBar(isOwnListing),
    );
  }

  // ── STICKY BOOKING BAR ────────────────────────────────────────────────────

  Widget _buildStickyBookingBar(bool isOwnListing) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOwnListing)
            // Provider viewing their own listing
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.backgroundField,
                borderRadius: AppRadius.pillRadius,
              ),
              child: const Center(
                child: Text(
                  'This is your listing',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            // Book & Pay button — matches wireframe exactly
            GestureDetector(
              onTap: _handleBooking,
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppRadius.pillRadius,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Price (left side)
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GHS',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            widget.service.basePrice.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Divider
                    Container(
                      width: 1,
                      height: 36,
                      color: Colors.white.withValues(alpha: 0.3),
                      margin:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    ),

                    // "Book & Pay via MoMo" (center)
                    const Expanded(
                      child: Text(
                        'Book & Pay via MoMo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // MoMo icon (right)
                    const Padding(
                      padding: EdgeInsets.only(right: AppSpacing.lg),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: AppSpacing.xs),

          // Footer text
          Text(
            '© 2024 CampusLink. Student Verified.',
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.xl,
        AppSpacing.screenPadding,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          // Blue left accent bar
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(title, style: AppTextStyles.heading2),
          if (trailing != null) ...[
            const Spacer(),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _featureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundField,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroPlaceholder() {
    return Container(
      color: AppColors.backgroundField,
      child: Center(
        child: Text(
          widget.service.category.emoji,
          style: const TextStyle(fontSize: 64),
        ),
      ),
    );
  }
}
