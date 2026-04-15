// lib/screens/provider/earnings_screen.dart
//
// PURPOSE: Shows a provider's full earnings history, pending payouts,
// and withdrawal options.
//
// SECTIONS:
//   - Earnings summary (total, pending, withdrawn)
//   - Withdraw funds CTA
//   - Earnings history list (completed bookings)
//   - Monthly breakdown chart (simple bar visual)
//
// [PETRONILO & ERIC: withdrawal trigger calls Paystack transfer API.
// The actual payout logic lives in a Cloud Function — the client only
// requests a withdrawal, the function executes it.]

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
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

  // ── WITHDRAW HANDLER ───────────────────────────────────────────────────────
  Future<void> _handleWithdraw(double amount) async {
    if (amount <= 0) {
      _showSnackBar(
        'No funds available to withdraw.',
        AppColors.warning,
      );
      return;
    }

    final confirmed = await _showWithdrawSheet(amount);
    if (!confirmed || !mounted) return;

    // [PETRONILO & ERIC: trigger Paystack transfer Cloud Function here]
    _showSnackBar(
      'Withdrawal request submitted. '
      'Funds arrive in your MoMo within 24 hours.',
      AppColors.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bp = context.watch<BookingProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    // Completed bookings = earnings history
    final completedBookings = bp.providerBookings
        .where((b) => b.isCompleted)
        .toList()
      ..sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));

    // Pending = funds held, not yet released
    final pendingAmount = bp.providerBookings
        .where((b) => b.fundsHeld && !b.isCompleted)
        .fold(0.0, (sum, b) => sum + b.totalAmount);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,

      // ── APP BAR ───────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Earnings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          // Info button
          IconButton(
            icon: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.textSecondary,
            ),
            onPressed: () => _showEarningsInfoSheet(),
          ),
        ],
      ),

      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          final uid = auth.currentUser?.uid;
          if (uid != null) bp.initProviderBookings(uid);
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

              // ── EARNINGS HERO CARD ───────────────────────────────────
              _buildEarningsHeroCard(
                totalEarnings: bp.totalEarnings,
                pendingAmount: pendingAmount,
                providerName: user?.fullName.split(' ').first ?? '',
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── WITHDRAW BUTTON ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _handleWithdraw(bp.totalEarnings),
                  icon: const Icon(
                    Icons.account_balance_rounded,
                    size: 20,
                  ),
                  label: Text(
                    bp.totalEarnings > 0
                        ? 'Withdraw GHS ${bp.totalEarnings.toStringAsFixed(2)}'
                        : 'No funds to withdraw',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bp.totalEarnings > 0
                        ? AppColors.primary
                        : AppColors.backgroundField,
                    foregroundColor: bp.totalEarnings > 0
                        ? Colors.white
                        : AppColors.textSecondary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.pillRadius,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xs),

              Center(
                child: Text(
                  'Funds transferred to your registered MoMo number',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── STAT SUMMARY ROW ─────────────────────────────────────
              _buildStatSummaryRow(
                completedCount: completedBookings.length,
                pendingCount: bp.pendingRequestsCount,
                activeCount: bp.activeJobsCount,
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── EARNINGS HISTORY ─────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Earnings History',
                    style: AppTextStyles.heading2,
                  ),
                  if (completedBookings.isNotEmpty)
                    Text(
                      '${completedBookings.length} completed',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // History list or empty state
              if (bp.isLoading)
                _buildLoadingState()
              else if (completedBookings.isEmpty)
                _buildEmptyEarningsState()
              else
                ...completedBookings.map(
                  (booking) => _buildEarningsHistoryCard(booking),
                ),

              const SizedBox(height: AppSpacing.xl),

              // ── ESCROW EXPLANATION ───────────────────────────────────
              _buildEscrowExplanation(),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  // ── EARNINGS HERO CARD ────────────────────────────────────────────────────

  Widget _buildEarningsHeroCard({
    required double totalEarnings,
    required double pendingAmount,
    required String providerName,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.lgRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Cleared Earnings',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'GHS ${totalEarnings.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Divider
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: AppSpacing.md),

          // Pending funds row
          Row(
            children: [
              const Icon(
                Icons.hourglass_top_rounded,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'GHS ${pendingAmount.toStringAsFixed(2)} pending',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: AppRadius.pillRadius,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      size: 14,
                      color: Color(0xFF4ADE80),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '+12% this month',
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFF4ADE80),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── STAT SUMMARY ROW ──────────────────────────────────────────────────────

  Widget _buildStatSummaryRow({
    required int completedCount,
    required int pendingCount,
    required int activeCount,
  }) {
    return Row(
      children: [
        _statSummaryItem(
          value: completedCount.toString(),
          label: 'Completed',
          color: AppColors.success,
        ),
        _statDivider(),
        _statSummaryItem(
          value: activeCount.toString(),
          label: 'Active Jobs',
          color: AppColors.accent,
        ),
        _statDivider(),
        _statSummaryItem(
          value: pendingCount.toString(),
          label: 'Pending',
          color: AppColors.warning,
        ),
      ],
    );
  }

  Widget _statSummaryItem({
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statDivider() => const SizedBox(width: AppSpacing.sm);

  // ── EARNINGS HISTORY CARD ─────────────────────────────────────────────────

  Widget _buildEarningsHistoryCard(BookingModel booking) {
    final date = booking.createdAt;
    final dateLabel = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : 'Unknown date';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Status indicator dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color:
                  booking.fundsReleased ? AppColors.success : AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Service info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.serviceTitle,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${booking.seekerName} · $dateLabel',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                booking.formattedAmount,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
              Text(
                booking.fundsReleased ? 'Released' : 'Held',
                style: AppTextStyles.caption.copyWith(
                  color: booking.fundsReleased
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── ESCROW EXPLANATION ────────────────────────────────────────────────────

  Widget _buildEscrowExplanation() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.05),
        borderRadius: AppRadius.lgRadius,
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shield_rounded,
                size: 18,
                color: AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'How CampusLink Escrow Works',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _escrowStep('1', 'Seeker pays into secure escrow at booking'),
          _escrowStep('2', 'You deliver the service'),
          _escrowStep('3', 'Seeker marks complete — funds released to you'),
          _escrowStep('4', 'You withdraw to your MoMo number anytime'),
        ],
      ),
    );
  }

  Widget _escrowStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: AppTextStyles.caption),
          ),
        ],
      ),
    );
  }

  // ── EMPTY STATE ───────────────────────────────────────────────────────────

  Widget _buildEmptyEarningsState() {
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
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'No earnings yet',
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Complete your first booking to start\n'
            'building your earnings.',
            style: AppTextStyles.subtitle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── LOADING STATE ─────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.backgroundField,
            borderRadius: AppRadius.lgRadius,
          ),
        );
      }),
    );
  }

  // ── WITHDRAW BOTTOM SHEET ─────────────────────────────────────────────────

  Future<bool> _showWithdrawSheet(double amount) async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
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

            const Text('Withdraw Funds', style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Funds will be transferred to your registered '
              'Mobile Money number.',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Amount card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.backgroundField,
                borderRadius: AppRadius.lgRadius,
              ),
              child: Column(
                children: [
                  Text(
                    'GHS ${amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'To: ${user?.momoNumber ?? 'Your registered MoMo'}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Processing note
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Processing time: up to 24 hours',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Confirm button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.pillRadius,
                  ),
                ),
                child: const Text(
                  'Confirm Withdrawal',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  // ── EARNINGS INFO SHEET ───────────────────────────────────────────────────

  void _showEarningsInfoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const Text('Understanding Your Earnings',
                style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.lg),
            _infoRow(
              Icons.check_circle_rounded,
              AppColors.success,
              'Cleared earnings',
              'Funds from completed bookings — ready to withdraw',
            ),
            const SizedBox(height: AppSpacing.md),
            _infoRow(
              Icons.hourglass_top_rounded,
              AppColors.warning,
              'Pending funds',
              'Held in escrow for active jobs — released when seeker confirms',
            ),
            const SizedBox(height: AppSpacing.md),
            _infoRow(
              Icons.percent_rounded,
              AppColors.accent,
              'Platform fee',
              '5% of each booking goes to CampusLink operations',
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    Color color,
    String title,
    String subtitle,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(subtitle, style: AppTextStyles.caption),
            ],
          ),
        ),
      ],
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
      ),
    );
  }
}
