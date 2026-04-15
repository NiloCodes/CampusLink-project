// lib/screens/provider/provider_dashboard_screen.dart
//
// PURPOSE: The provider's home screen — shows stats, earnings,
// and incoming booking requests.
//
// MATCHES WIREFRAME EXACTLY:
//   ✓ Grid icon + "Provider Hub" title + circular avatar (app bar)
//   ✓ "DASHBOARD OVERVIEW" small blue label
//   ✓ "Welcome back, {name}." large bold heading
//   ✓ "Your campus business is growing..." subtitle
//   ✓ Pending Requests stat card with blue left border + large number
//   ✓ Active Jobs stat card
//   ✓ Total Earnings stat card with GHS amount + green trend label
//   ✓ "+ Add New Service" full width navy pill button
//   ✓ "Recent Booking Requests" section with "View All" link
//   ✓ "Clients waiting for your confirmation" subtitle
//   ✓ BookingRequestCards with Accept/Decline buttons
//   ✓ "VERIFIED PROVIDER — Escrow Protected" sticky bottom badge
//   ✓ Home | Earnings | Profile bottom nav (handled by BottomNavShell)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/booking_request_card.dart';
import '../seeker/booking_status_screen.dart';
import '../provider/add_service_screen.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().currentUser?.uid;
      if (uid != null) {
        context.read<BookingProvider>().initProviderBookings(uid);
      }
    });
  }

  // ── ACCEPT BOOKING ─────────────────────────────────────────────────────────
  Future<void> _handleAccept(String bookingId) async {
    final bp = context.read<BookingProvider>();
    final success = await bp.acceptBooking(bookingId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Booking accepted! The seeker will be notified.'
              : bp.errorMessage ?? 'Something went wrong.',
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
      ),
    );
  }

  // ── DECLINE BOOKING ────────────────────────────────────────────────────────
  Future<void> _handleDecline(String bookingId) async {
    final reason = await _showDeclineSheet();
    if (reason == null || !mounted) return;

    final bp = context.read<BookingProvider>();
    final success = await bp.declineBooking(bookingId, reason);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Booking declined.'
              : bp.errorMessage ?? 'Something went wrong.',
        ),
        backgroundColor: success ? AppColors.textSecondary : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bp = context.watch<BookingProvider>();
    final user = auth.currentUser;
    final firstName = user?.fullName.split(' ').first ?? 'there';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,

      // ── APP BAR ───────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: AppSpacing.screenPadding,
        title: Row(
          children: [
            // Grid/hub icon — matches wireframe
            const Icon(
              Icons.grid_view_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text(
              'Provider Hub',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          // Circular avatar (top right — matches wireframe)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.screenPadding),
            child: GestureDetector(
              onTap: () {
                // Profile navigation handled by BottomNavShell
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  user?.fullName.isNotEmpty == true
                      ? user!.fullName[0].toUpperCase()
                      : 'P',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // ── BODY ──────────────────────────────────────────────────────────────
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          final uid = auth.currentUser?.uid;
          if (uid != null) {
            bp.initProviderBookings(uid);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),

              // ── DASHBOARD OVERVIEW HEADER ──────────────────────────
              Text(
                'DASHBOARD OVERVIEW',
                style: AppTextStyles.fieldLabel.copyWith(
                  color: AppColors.accent,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Welcome back,\n$firstName.',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Your campus business is growing. Here is\n'
                'what needs your attention today.',
                style: AppTextStyles.subtitle,
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── STAT CARDS ─────────────────────────────────────────
              // Pending Requests
              StatCard(
                icon: Icons.inbox_rounded,
                value: bp.pendingRequestsCount.toString(),
                title: 'Pending Requests',
                subtitle: 'Requires immediate response',
                onTap: bp.pendingRequestsCount > 0
                    ? () => _scrollToRequests()
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // Active Jobs
              StatCard(
                icon: Icons.work_rounded,
                value: bp.activeJobsCount.toString(),
                title: 'Active Jobs',
                subtitle: 'Ongoing tasks this week',
              ),
              const SizedBox(height: AppSpacing.md),

              // Total Earnings
              StatCard(
                icon: Icons.account_balance_wallet_rounded,
                value: bp.formattedEarnings,
                title: 'Total Earnings',
                subtitle: 'Cleared and available for withdrawal',
                valueColor: AppColors.accent,
                trendLabel: '+12% vs last month',
                isTrendPositive: true,
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── ADD NEW SERVICE BUTTON ─────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddServiceScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 22),
                  label: const Text(
                    'Add New Service',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.pillRadius,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── RECENT BOOKING REQUESTS ────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent Booking\nRequests',
                          style: AppTextStyles.heading2,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Clients waiting for your confirmation',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  // "View All" link
                  GestureDetector(
                    onTap: () {
                      // TODO: Navigate to full bookings list
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Full bookings list in BookingsScreen'),
                        ),
                      );
                    },
                    child: Text(
                      'View\nAll',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Booking request cards or empty state
              if (bp.isLoading)
                _buildLoadingState()
              else if (bp.pendingRequests.isEmpty)
                _buildEmptyRequestsState()
              else
                ...bp.pendingRequests.map(
                  (booking) => BookingRequestCard(
                    booking: booking,
                    isActing: bp.isActing,
                    onAccept: () => _handleAccept(booking.bookingId),
                    onDecline: () => _handleDecline(booking.bookingId),
                  ),
                ),

              const SizedBox(height: AppSpacing.xl),

              // ── VERIFIED PROVIDER BADGE ────────────────────────────
              // Matches wireframe: shield + "VERIFIED PROVIDER" +
              // "Escrow Protected"
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: AppRadius.pillRadius,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shield_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VERIFIED PROVIDER',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Escrow Protected',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  // ── LOADING STATE ─────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(2, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.backgroundField,
            borderRadius: AppRadius.lgRadius,
          ),
        );
      }),
    );
  }

  // ── EMPTY REQUESTS STATE ──────────────────────────────────────────────────

  Widget _buildEmptyRequestsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inbox_rounded,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'No pending requests',
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'New booking requests will appear here.\n'
            'Make sure your services are active.',
            style: AppTextStyles.subtitle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── DECLINE BOTTOM SHEET ──────────────────────────────────────────────────

  Future<String?> _showDeclineSheet() async {
    final controller = TextEditingController();
    final reasons = [
      'I\'m unavailable at this time',
      'Outside my service area',
      'Not enough details provided',
      'Price disagreement',
    ];
    String? selectedReason;

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.screenPadding,
            right: AppSpacing.screenPadding,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const Text('Decline Request', style: AppTextStyles.heading2),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Select a reason or write your own.',
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Quick reason chips
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: reasons.map((reason) {
                  final isSelected = selectedReason == reason;
                  return GestureDetector(
                    onTap: () {
                      setSheetState(() {
                        selectedReason = reason;
                        controller.text = reason;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.backgroundField,
                        borderRadius: AppRadius.pillRadius,
                      ),
                      child: Text(
                        reason,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppSpacing.md),

              // Custom reason field
              TextField(
                controller: controller,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Or write your own reason...',
                  filled: true,
                  fillColor: AppColors.backgroundField,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.mdRadius,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Confirm decline button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    controller.text.trim().isEmpty
                        ? 'No reason provided'
                        : controller.text.trim(),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.pillRadius,
                    ),
                  ),
                  child: const Text(
                    'Confirm Decline',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Scrolls to requests section — called from pending requests stat card
  void _scrollToRequests() {
    // Simple scroll hint — full scroll controller in Sprint 3
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scroll down to see pending requests'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
