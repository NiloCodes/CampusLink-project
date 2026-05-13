// lib/widgets/skeleton_loader.dart
//
// PURPOSE: Reusable shimmer skeleton loading widgets.
// Used on Home, Bookings, and Profile screens while data loads.
//
// WIDGETS EXPORTED:
//   SkeletonBox          — base shimmer rectangle
//   SkeletonCircle       — base shimmer circle
//   SkeletonServiceCard  — mimics ServiceCard layout
//   SkeletonBookingCard  — mimics BookingCard layout
//   SkeletonProfileCard  — mimics Profile header layout
//   SkeletonList         — renders N skeleton cards in a column

import 'package:flutter/material.dart';
import '../core/constants.dart';

// =============================================================================
// SHIMMER ANIMATION WRAPPER
// =============================================================================

class _Shimmer extends StatefulWidget {
  final Widget child;

  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFEEEEEE),
                Color(0xFFDDDDDD),
                Color(0xFFEEEEEE),
              ],
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// =============================================================================
// BASE SKELETON SHAPES
// =============================================================================

class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFFEEEEEE),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// =============================================================================
// SKELETON SERVICE CARD
// =============================================================================
// Mimics the ServiceCard layout

class SkeletonServiceCard extends StatelessWidget {
  const SkeletonServiceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: AppRadius.lgRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero image placeholder
          SkeletonBox(
            width: double.infinity,
            height: 160,
            borderRadius: 16,
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Provider row
                Row(
                  children: [
                    const SkeletonCircle(size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    SkeletonBox(width: 100, height: 12),
                    const Spacer(),
                    SkeletonBox(width: 60, height: 12),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // Title line 1
                SkeletonBox(
                  width: double.infinity,
                  height: 16,
                ),
                const SizedBox(height: AppSpacing.xs),

                // Title line 2
                SkeletonBox(width: 200, height: 16),

                const SizedBox(height: AppSpacing.md),

                // Button placeholder
                SkeletonBox(
                  width: double.infinity,
                  height: 44,
                  borderRadius: 100,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SKELETON BOOKING CARD
// =============================================================================
// Mimics the booking card in BookingsScreen

class SkeletonBookingCard extends StatelessWidget {
  const SkeletonBookingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Status indicator
          SkeletonBox(width: 4, height: 56, borderRadius: 2),
          const SizedBox(width: AppSpacing.md),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: double.infinity, height: 14),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    SkeletonBox(width: 80, height: 11),
                    const SizedBox(width: AppSpacing.sm),
                    SkeletonBox(width: 60, height: 11),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SkeletonBox(width: 60, height: 14),
              const SizedBox(height: 4),
              SkeletonBox(width: 18, height: 14),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SKELETON PROFILE CARD
// =============================================================================
// Mimics the Profile screen header

class SkeletonProfileCard extends StatelessWidget {
  const SkeletonProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: AppRadius.lgRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          const SkeletonCircle(size: 80),
          const SizedBox(height: AppSpacing.md),

          // Name
          SkeletonBox(width: 160, height: 18),
          const SizedBox(height: AppSpacing.xs),

          // Email
          SkeletonBox(width: 200, height: 13),
          const SizedBox(height: AppSpacing.md),

          // Role badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SkeletonBox(
                width: 80,
                height: 26,
                borderRadius: 100,
              ),
              const SizedBox(width: AppSpacing.sm),
              SkeletonBox(
                width: 80,
                height: 26,
                borderRadius: 100,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SKELETON MENU ITEM
// =============================================================================
// Mimics a profile menu row

class SkeletonMenuItem extends StatelessWidget {
  const SkeletonMenuItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          SkeletonCircle(size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: SkeletonBox(width: double.infinity, height: 14)),
          const SizedBox(width: AppSpacing.md),
          SkeletonBox(width: 18, height: 18),
        ],
      ),
    );
  }
}

// =============================================================================
// SKELETON HOME FEED
// =============================================================================
// Full home screen skeleton — categories + cards

class SkeletonHomeFeed extends StatelessWidget {
  const SkeletonHomeFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),

          // Categories row
          Row(
            children: List.generate(4, (index) {
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: Column(
                  children: [
                    const SkeletonCircle(size: 60),
                    const SizedBox(height: 6),
                    SkeletonBox(width: 56, height: 10),
                  ],
                ),
              );
            }),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Section header
          SkeletonBox(width: 160, height: 18),
          const SizedBox(height: AppSpacing.md),

          // Service cards
          const SkeletonServiceCard(),
          const SkeletonServiceCard(),
          const SkeletonServiceCard(),
        ],
      ),
    );
  }
}

// =============================================================================
// SKELETON LIST
// =============================================================================
// Generic N-item skeleton list

class SkeletonList extends StatelessWidget {
  final int count;
  final Widget Function() itemBuilder;

  const SkeletonList({
    super.key,
    required this.count,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (_) => itemBuilder()),
    );
  }
}
