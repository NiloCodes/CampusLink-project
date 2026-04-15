// lib/screens/shared/bookings_screen.dart
//
// PURPOSE: Role-aware bookings screen.
// Shows different content based on the user's role:
//
//   Seeker only   → "My Bookings" list
//   Provider only → "My Requests" list
//   Both roles    → Two tabs: "Hired" + "Requests"
//
// ARCHITECTURAL NOTE (for your defense):
// This is a single screen that adapts its UI based on the user's
// roles list from Firestore. This implements Role-Based UI Rendering —
// same route, same file, contextually different interface.
// Cited under Systems Theory in Chapter 2.
// Cited under Systems Theory in Chapter 2.
import '../seeker/booking_status_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final user = auth.currentUser;
      if (user == null) return;

      // Init correct streams based on role
      final bp = context.read<BookingProvider>();
      if (user.isSeeker && user.isProvider) {
        bp.initBothBookings(user.uid);
      } else if (user.isSeeker) {
        bp.initSeekerBookings(user.uid);
      } else if (user.isProvider) {
        bp.initProviderBookings(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    if (user == null) return const SizedBox.shrink();

    // Dual role — show tabbed view
    if (user.isSeeker && user.isProvider) {
      return _buildDualRoleView();
    }

    // Seeker only
    if (user.isSeeker) {
      return _buildSeekerView();
    }

    // Provider only
    if (user.isProvider) {
      return _buildProviderView();
    }

    return const SizedBox.shrink();
  }

  // ── DUAL ROLE VIEW ────────────────────────────────────────────────────────
  // Two tabs: "Hired" (seeker bookings) + "Requests" (provider bookings)

  Widget _buildDualRoleView() {
    final bp = context.watch<BookingProvider>();

    // Initialise tab controller only once
    _tabController ??= TabController(length: 2, vsync: this);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Bookings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(
              text: 'Hired (${bp.seekerBookings.length})',
            ),
            Tab(
              text: 'Requests (${bp.providerBookings.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSeekerBookingsList(bp.seekerBookings, bp.isLoading),
          _buildProviderBookingsList(bp.providerBookings, bp.isLoading),
        ],
      ),
    );
  }

  // ── SEEKER ONLY VIEW ──────────────────────────────────────────────────────

  Widget _buildSeekerView() {
    final bp = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar('My Bookings'),
      body: Column(
        children: [
          // Summary bar
          _buildSeekerSummaryBar(bp),
          // Bookings list
          Expanded(
            child: _buildSeekerBookingsList(
              bp.seekerBookings,
              bp.isLoading,
            ),
          ),
        ],
      ),
    );
  }

  // ── PROVIDER ONLY VIEW ────────────────────────────────────────────────────

  Widget _buildProviderView() {
    final bp = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar('My Requests'),
      body: Column(
        children: [
          // Summary bar
          _buildProviderSummaryBar(bp),
          // Requests list
          Expanded(
            child: _buildProviderBookingsList(
              bp.providerBookings,
              bp.isLoading,
            ),
          ),
        ],
      ),
    );
  }

  // ── SEEKER BOOKINGS LIST ──────────────────────────────────────────────────

  Widget _buildSeekerBookingsList(
    List<BookingModel> bookings,
    bool isLoading,
  ) {
    if (isLoading) return _buildLoadingState();

    if (bookings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.calendar_today_outlined,
        title: 'No bookings yet',
        subtitle: 'Services you book will appear here.\n'
            'Browse the home feed to find something.',
        actionLabel: 'Browse Services',
        onAction: () {
          // Navigate to home tab via BottomNavShell
          // index 0 = home in seeker nav
        },
      );
    }

    // Group bookings by status
    final active =
        bookings.where((b) => b.isInProgress || b.isConfirmed).toList();
    final pending = bookings.where((b) => b.isPending).toList();
    final completed = bookings.where((b) => b.isCompleted).toList();
    final cancelled = bookings.where((b) => b.isCancelled).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.md,
      ),
      physics: const BouncingScrollPhysics(),
      children: [
        // Active bookings
        if (active.isNotEmpty) ...[
          _buildGroupHeader('Active', AppColors.success, active.length),
          ...active.map((b) => _buildSeekerBookingCard(b)),
          const SizedBox(height: AppSpacing.md),
        ],

        // Pending bookings
        if (pending.isNotEmpty) ...[
          _buildGroupHeader('Pending', AppColors.warning, pending.length),
          ...pending.map((b) => _buildSeekerBookingCard(b)),
          const SizedBox(height: AppSpacing.md),
        ],

        // Completed bookings
        if (completed.isNotEmpty) ...[
          _buildGroupHeader(
              'Completed', AppColors.textSecondary, completed.length),
          ...completed.map((b) => _buildSeekerBookingCard(b)),
          const SizedBox(height: AppSpacing.md),
        ],

        // Cancelled bookings
        if (cancelled.isNotEmpty) ...[
          _buildGroupHeader('Cancelled', AppColors.error, cancelled.length),
          ...cancelled.map((b) => _buildSeekerBookingCard(b)),
        ],

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  // ── PROVIDER BOOKINGS LIST ────────────────────────────────────────────────

  Widget _buildProviderBookingsList(
    List<BookingModel> bookings,
    bool isLoading,
  ) {
    if (isLoading) return _buildLoadingState();

    if (bookings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_rounded,
        title: 'No requests yet',
        subtitle: 'Booking requests from students\n'
            'will appear here.',
        actionLabel: 'Go to Dashboard',
        onAction: () {},
      );
    }

    final pending = bookings.where((b) => b.isPending).toList();
    final active =
        bookings.where((b) => b.isConfirmed || b.isInProgress).toList();
    final completed = bookings.where((b) => b.isCompleted).toList();
    final cancelled = bookings.where((b) => b.isCancelled).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.md,
      ),
      physics: const BouncingScrollPhysics(),
      children: [
        if (pending.isNotEmpty) ...[
          _buildGroupHeader(
              'Awaiting Response', AppColors.warning, pending.length),
          ...pending.map((b) => _buildProviderBookingCard(b)),
          const SizedBox(height: AppSpacing.md),
        ],
        if (active.isNotEmpty) ...[
          _buildGroupHeader('Active Jobs', AppColors.success, active.length),
          ...active.map((b) => _buildProviderBookingCard(b)),
          const SizedBox(height: AppSpacing.md),
        ],
        if (completed.isNotEmpty) ...[
          _buildGroupHeader(
              'Completed', AppColors.textSecondary, completed.length),
          ...completed.map((b) => _buildProviderBookingCard(b)),
          const SizedBox(height: AppSpacing.md),
        ],
        if (cancelled.isNotEmpty) ...[
          _buildGroupHeader('Cancelled', AppColors.error, cancelled.length),
          ...cancelled.map((b) => _buildProviderBookingCard(b)),
        ],
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  // ── SEEKER BOOKING CARD ───────────────────────────────────────────────────

  Widget _buildSeekerBookingCard(BookingModel booking) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingStatusScreen(booking: booking),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Status color indicator
            Container(
              width: 4,
              height: 56,
              decoration: BoxDecoration(
                color: _bookingStatusColor(booking),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service title
                  Text(
                    booking.serviceTitle,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Provider name + escrow badge
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        booking.providerName,
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _escrowBadge(booking.escrowStatus),
                    ],
                  ),
                ],
              ),
            ),

            // Amount + chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'GHS ${booking.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── PROVIDER BOOKING CARD ─────────────────────────────────────────────────

  Widget _buildProviderBookingCard(BookingModel booking) {
    final bp = context.read<BookingProvider>();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingStatusScreen(booking: booking),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Seeker avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.backgroundField,
                  child: Text(
                    booking.seekerName.isNotEmpty
                        ? booking.seekerName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.seekerName,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        booking.serviceTitle,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'GHS ${booking.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    _escrowBadge(booking.escrowStatus),
                  ],
                ),
              ],
            ),

            // Accept / Decline — only for pending
            if (booking.isPending) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: ElevatedButton(
                        onPressed: bp.isActing
                            ? null
                            : () => _handleAccept(booking.bookingId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.pillRadius,
                          ),
                        ),
                        child: const Text(
                          'Accept',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: OutlinedButton(
                        onPressed: bp.isActing
                            ? null
                            : () => _handleDecline(booking.bookingId),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.pillRadius,
                          ),
                        ),
                        child: const Text(
                          'Decline',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── SUMMARY BARS ──────────────────────────────────────────────────────────

  Widget _buildSeekerSummaryBar(BookingProvider bp) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.md,
      ),
      color: AppColors.backgroundWhite,
      child: Row(
        children: [
          _summaryChip(
            '${bp.activeBookingsCount} Active',
            AppColors.success,
          ),
          const SizedBox(width: AppSpacing.sm),
          _summaryChip(
            '${bp.pendingBookingsCount} Pending',
            AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          _summaryChip(
            '${bp.completedBookingsCount} Done',
            AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSummaryBar(BookingProvider bp) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.md,
      ),
      color: AppColors.backgroundWhite,
      child: Row(
        children: [
          _summaryChip(
            '${bp.pendingRequestsCount} Awaiting',
            AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          _summaryChip(
            '${bp.activeJobsCount} Active',
            AppColors.success,
          ),
          const SizedBox(width: AppSpacing.sm),
          _summaryChip(
            bp.formattedEarnings,
            AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.pillRadius,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // ── SHARED COMPONENTS ─────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(String title) {
    return AppBar(
      backgroundColor: AppColors.backgroundWhite,
      elevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildGroupHeader(String label, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$label ($count)',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _escrowBadge(EscrowStatus status) {
    Color color;
    String label;

    switch (status) {
      case EscrowStatus.held:
        color = AppColors.accent;
        label = 'Secured';
        break;
      case EscrowStatus.released:
        color = AppColors.success;
        label = 'Released';
        break;
      case EscrowStatus.disputed:
        color = AppColors.error;
        label = 'Disputed';
        break;
      case EscrowStatus.awaitingPayment:
        color = AppColors.textSecondary;
        label = 'Unpaid';
        break;
      case EscrowStatus.refunded:
        color = AppColors.warning;
        label = 'Refunded';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.pillRadius,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _bookingStatusColor(BookingModel booking) {
    if (booking.isCompleted) return AppColors.success;
    if (booking.isInProgress) return AppColors.accent;
    if (booking.isConfirmed) return AppColors.warning;
    if (booking.isCancelled) return AppColors.error;
    return AppColors.textSecondary;
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: AppTextStyles.subtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.pillRadius,
                ),
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.backgroundField,
          borderRadius: AppRadius.lgRadius,
        ),
      ),
    );
  }

  // ── ACCEPT / DECLINE HANDLERS ─────────────────────────────────────────────

  Future<void> _handleAccept(String bookingId) async {
    final bp = context.read<BookingProvider>();
    final success = await bp.acceptBooking(bookingId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Booking accepted!'
              : bp.errorMessage ?? 'Something went wrong.',
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
      ),
    );
  }

  Future<void> _handleDecline(String bookingId) async {
    final bp = context.read<BookingProvider>();
    final success =
        await bp.declineBooking(bookingId, 'Declined from bookings screen');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Booking declined.' : 'Something went wrong.',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
      ),
    );
  }
}
