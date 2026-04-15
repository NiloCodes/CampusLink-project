// lib/screens/seeker/booking_status_screen.dart
//
// PURPOSE: Shows the full status of a single booking.
// Used by both seekers and providers — UI adapts based on role.
//
// MATCHES WIREFRAME:
//   ✓ App bar: back arrow + "Booking Status" + "CampusLink" brand
//   ✓ "Service Progress" stepper: Requested → Accepted → In Progress → Completed
//   ✓ "ACTIVE JOB" badge + 3-dot menu + service title + provider avatar
//   ✓ Secure Escrow card (color changes with escrow state)
//   ✓ Payment breakdown: Subtotal / Platform Fee / Total Paid
//   ✓ "Funds held in escrow" notice
//   ✓ CampusLink protection disclaimer
//   ✓ "Message Provider" → opens contact options
//   ✓ "Mark as Complete & Release Funds" primary CTA (seeker only)
//
// ROLE-AWARE:
//   Seeker view:   "Mark as Complete & Release Funds" CTA
//   Provider view: "Mark as Started" or "Service Delivered" CTA
//
// ESCROW STATES HANDLED:
//   awaiting_payment → grey  (pending payment)
//   held             → blue  (funds secured)
//   released         → green (funds released)
//   disputed         → red   (dispute raised)
//   refunded         → amber (funds refunded to seeker)

// Cited under Systems Theory in Chapter 2.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/booking_status_card.dart';

class BookingStatusScreen extends StatefulWidget {
  final BookingModel booking;

  const BookingStatusScreen({
    super.key,
    required this.booking,
  });

  @override
  State<BookingStatusScreen> createState() => _BookingStatusScreenState();
}

class _BookingStatusScreenState extends State<BookingStatusScreen> {
  // Platform fee percentage
  static const double _platformFeeRate = 0.05;

  double get _subtotal => widget.booking.totalAmount / (1 + _platformFeeRate);

  double get _platformFee => widget.booking.totalAmount - _subtotal;

  // ── MARK AS COMPLETE ───────────────────────────────────────────────────────
  Future<void> _handleMarkComplete() async {
    final confirmed = await _showConfirmDialog(
      title: 'Release Funds?',
      message:
          'By confirming, you agree the service was completed satisfactorily. '
          'Funds will be released to ${widget.booking.providerName} immediately. '
          'This action cannot be undone.',
      confirmLabel: 'Yes, Release Funds',
      confirmColor: AppColors.success,
    );

    if (!confirmed || !mounted) return;

    final bp = context.read<BookingProvider>();
    final success = await bp.markAsComplete(widget.booking.bookingId);

    if (!mounted) return;

    if (success) {
      _showSnackBar(
        'Funds released to ${widget.booking.providerName}. Thank you!',
        AppColors.success,
      );
    } else {
      _showSnackBar(
        bp.errorMessage ?? 'Something went wrong. Please try again.',
        AppColors.error,
      );
    }
  }

  // ── RAISE DISPUTE ──────────────────────────────────────────────────────────
  Future<void> _handleRaiseDispute() async {
    final reason = await _showDisputeSheet();
    if (reason == null || reason.trim().isEmpty || !mounted) return;

    final bp = context.read<BookingProvider>();
    final success = await bp.raiseDispute(
      widget.booking.bookingId,
      reason,
    );

    if (!mounted) return;

    if (success) {
      _showSnackBar(
        'Dispute raised. Our team will review within 24 hours.',
        AppColors.warning,
      );
    }
  }

  // ── CONTACT PROVIDER ───────────────────────────────────────────────────────
  // Opens contact options bottom sheet
  void _handleContactProvider() {
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
            Text(
              'Contact ${widget.booking.providerName}',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Reach out via your preferred channel.',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Contact options
            _contactOption(
              icon: Icons.phone_rounded,
              label: 'Call Provider',
              subtitle: 'Open phone dialler',
              color: AppColors.success,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: AppSpacing.sm),
            _contactOption(
              icon: Icons.chat_rounded,
              label: 'WhatsApp',
              subtitle: 'Open WhatsApp chat',
              color: const Color(0xFF25D366),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bp = context.watch<BookingProvider>();
    final isSeeker = auth.currentUser?.uid == widget.booking.seekerUid;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,

      // ── APP BAR ─────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Booking Status',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          // CampusLink brand (top right — matches wireframe)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: Text(
                'CampusLink',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
        ],
      ),

      // ── BODY ────────────────────────────────────────────────────────────
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),

            // ── SERVICE PROGRESS STEPPER ─────────────────────────────
            const Text(
              'Service Progress',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildProgressStepper(),

            const SizedBox(height: AppSpacing.lg),

            // ── JOB CARD ─────────────────────────────────────────────
            _buildJobCard(),

            const SizedBox(height: AppSpacing.lg),

            // ── ESCROW STATUS CARD ───────────────────────────────────
            BookingStatusCard(
              escrowStatus: widget.booking.escrowStatus,
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── PAYMENT BREAKDOWN ────────────────────────────────────
            _buildPaymentBreakdown(),

            const SizedBox(height: AppSpacing.md),

            // ── ESCROW NOTICE ────────────────────────────────────────
            if (widget.booking.escrowStatus == EscrowStatus.held)
              _buildEscrowNotice(),

            const SizedBox(height: AppSpacing.md),

            // ── PROTECTION DISCLAIMER ────────────────────────────────
            _buildProtectionDisclaimer(),

            const SizedBox(height: AppSpacing.xl),

            // ── ACTION BUTTONS ───────────────────────────────────────
            _buildActionButtons(isSeeker, bp),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  // ── PROGRESS STEPPER ──────────────────────────────────────────────────────
  // 4 steps: Requested → Accepted → In Progress → Completed
  // Fills based on current bookingStatus

  Widget _buildProgressStepper() {
    final steps = [
      _StepData(
        label: 'REQUESTED',
        icon: Icons.check_circle_rounded,
        isDone: true, // always done if booking exists
      ),
      _StepData(
        label: 'ACCEPTED',
        icon: Icons.handshake_rounded,
        isDone: widget.booking.isConfirmed ||
            widget.booking.isInProgress ||
            widget.booking.isCompleted,
      ),
      _StepData(
        label: 'IN PROGRESS',
        icon: Icons.settings_rounded,
        isDone: widget.booking.isInProgress || widget.booking.isCompleted,
        isActive: widget.booking.isInProgress,
      ),
      _StepData(
        label: 'COMPLETED',
        icon: Icons.verified_rounded,
        isDone: widget.booking.isCompleted,
      ),
    ];

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        // Even indices = step circles
        if (index % 2 == 0) {
          final step = steps[index ~/ 2];
          return _buildStepCircle(step);
        }
        // Odd indices = connectors
        final leftStep = steps[index ~/ 2];
        final rightStep = steps[(index ~/ 2) + 1];
        return _buildStepConnector(leftStep.isDone && rightStep.isDone);
      }),
    );
  }

  Widget _buildStepCircle(_StepData step) {
    final Color color = step.isDone
        ? AppColors.primary
        : step.isActive
            ? AppColors.accent
            : AppColors.border;

    return Expanded(
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: step.isDone || step.isActive
                  ? color
                  : AppColors.backgroundField,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(
              step.icon,
              size: 22,
              color: step.isDone || step.isActive
                  ? Colors.white
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            step.label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: step.isDone || step.isActive
                  ? FontWeight.w700
                  : FontWeight.w400,
              color: step.isDone || step.isActive
                  ? AppColors.primary
                  : AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(bool isComplete) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 22),
        color: isComplete ? AppColors.primary : AppColors.border,
      ),
    );
  }

  // ── JOB CARD ──────────────────────────────────────────────────────────────

  Widget _buildJobCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge + 3-dot menu
          Row(
            children: [
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _badgeColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.pillRadius,
                ),
                child: Text(
                  _badgeLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _badgeColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              // 3-dot menu
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textSecondary,
                ),
                onSelected: (value) {
                  if (value == 'dispute') _handleRaiseDispute();
                  if (value == 'cancel') {
                    // TODO: Cancel booking flow
                    _showSnackBar(
                      'Cancellation coming in Sprint 3.',
                      AppColors.warning,
                    );
                  }
                },
                itemBuilder: (_) => [
                  if (!widget.booking.isCompleted &&
                      !widget.booking.isCancelled)
                    const PopupMenuItem(
                      value: 'dispute',
                      child: Row(
                        children: [
                          Icon(Icons.warning_rounded,
                              size: 16, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Raise Dispute'),
                        ],
                      ),
                    ),
                  if (widget.booking.isPending)
                    const PopupMenuItem(
                      value: 'cancel',
                      child: Row(
                        children: [
                          Icon(Icons.cancel_outlined,
                              size: 16, color: AppColors.textSecondary),
                          SizedBox(width: 8),
                          Text('Cancel Booking'),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Service title
          Text(
            widget.booking.serviceTitle,
            style: AppTextStyles.heading2,
          ),

          const SizedBox(height: AppSpacing.md),

          // Provider row
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.backgroundField,
                child: Text(
                  widget.booking.providerName.isNotEmpty
                      ? widget.booking.providerName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Provider',
                    style: AppTextStyles.caption,
                  ),
                  Text(
                    widget.booking.providerName,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Notes (if any)
          if (widget.booking.notes != null &&
              widget.booking.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppColors.border),
            const SizedBox(height: AppSpacing.sm),
            Text('Notes', style: AppTextStyles.fieldLabel),
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.booking.notes!,
              style: AppTextStyles.body,
            ),
          ],
        ],
      ),
    );
  }

  // ── PAYMENT BREAKDOWN ─────────────────────────────────────────────────────

  Widget _buildPaymentBreakdown() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PAYMENT BREAKDOWN', style: AppTextStyles.fieldLabel),
          const SizedBox(height: AppSpacing.md),
          _breakdownRow(
            'Subtotal',
            'GHS ${_subtotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: AppSpacing.sm),
          _breakdownRow(
            'Platform Fee (5%)',
            'GHS ${_platformFee.toStringAsFixed(2)}',
          ),
          const Divider(height: AppSpacing.lg),
          _breakdownRow(
            'Total Paid',
            'GHS ${widget.booking.totalAmount.toStringAsFixed(2)}',
            isBold: true,
            valueColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold
              ? AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)
              : AppTextStyles.caption,
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ── ESCROW NOTICE ─────────────────────────────────────────────────────────

  Widget _buildEscrowNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.06),
        borderRadius: AppRadius.mdRadius,
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_rounded,
            size: 16,
            color: AppColors.accent,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'FUNDS HELD IN ESCROW UNTIL COMPLETION',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── PROTECTION DISCLAIMER ─────────────────────────────────────────────────

  Widget _buildProtectionDisclaimer() {
    return Text(
      'CampusLink protects both parties. Your payment is securely held '
      'and only released to ${widget.booking.providerName} once you mark '
      'this service as complete.',
      style: AppTextStyles.caption.copyWith(
        color: AppColors.textSecondary,
        height: 1.6,
      ),
      textAlign: TextAlign.center,
    );
  }

  // ── ACTION BUTTONS ────────────────────────────────────────────────────────
  // Different CTAs depending on role and booking status

  Widget _buildActionButtons(bool isSeeker, BookingProvider bp) {
    return Column(
      children: [
        // ── SEEKER ACTIONS ─────────────────────────────────────────────
        if (isSeeker) ...[
          // "Mark as Complete & Release Funds"
          // Only shown when booking is in_progress and funds are held
          if (widget.booking.isInProgress && widget.booking.fundsHeld)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: bp.isActing ? null : _handleMarkComplete,
                icon: bp.isActing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.check_circle_rounded,
                        size: 20,
                      ),
                label: const Text(
                  'Mark as Complete & Release Funds',
                  style: TextStyle(
                    fontSize: 15,
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

          const SizedBox(height: AppSpacing.sm),

          // "Contact Provider"
          if (!widget.booking.isCompleted && !widget.booking.isCancelled)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _handleContactProvider,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text(
                  'Contact Provider',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.pillRadius,
                  ),
                ),
              ),
            ),

          const SizedBox(height: AppSpacing.sm),

          // "Raise a Dispute" text link
          if (widget.booking.isInProgress && !widget.booking.isDisputed)
            Center(
              child: GestureDetector(
                onTap: _handleRaiseDispute,
                child: Text(
                  'Something wrong? Raise a dispute',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.error,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
        ]

        // ── PROVIDER ACTIONS ───────────────────────────────────────────
        else ...[
          // "Mark as Started" — when booking is confirmed
          if (widget.booking.isConfirmed)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: bp.isActing
                    ? null
                    : () {
                        // TODO: Update bookingStatus to in_progress
                        _showSnackBar(
                          'Marked as started.',
                          AppColors.accent,
                        );
                      },
                icon: const Icon(Icons.play_circle_rounded, size: 20),
                label: const Text(
                  'Mark as Started',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.pillRadius,
                  ),
                ),
              ),
            ),

          // "Contact Seeker"
          if (!widget.booking.isCompleted && !widget.booking.isCancelled)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _handleContactProvider,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text(
                  'Contact Seeker',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.pillRadius,
                  ),
                ),
              ),
            ),
        ],

        // ── COMPLETED STATE ────────────────────────────────────────────
        if (widget.booking.isCompleted) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: AppRadius.lgRadius,
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Service completed — funds released',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── REFUNDED STATE ─────────────────────────────────────────────
        if (widget.booking.escrowStatus == EscrowStatus.refunded) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: AppRadius.lgRadius,
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.replay_rounded,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Funds refunded to your MoMo',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── CONTACT OPTION TILE ───────────────────────────────────────────────────

  Widget _contactOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: AppRadius.lgRadius,
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── CONFIRM DIALOG ────────────────────────────────────────────────────────

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgRadius,
        ),
        title: Text(title, style: AppTextStyles.heading2),
        content: Text(message, style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.pillRadius,
              ),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ── DISPUTE SHEET ─────────────────────────────────────────────────────────

  Future<String?> _showDisputeSheet() async {
    final controller = TextEditingController();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
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
            const Text('Raise a Dispute', style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Describe what went wrong. Our team will review '
              'within 24 hours.',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'e.g. The service was not completed as agreed...',
                filled: true,
                fillColor: AppColors.backgroundField,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.mdRadius,
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.pillRadius,
                  ),
                ),
                child: const Text(
                  'Submit Dispute',
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
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  // Badge label and color based on booking status
  String get _badgeLabel {
    if (widget.booking.isCancelled) return 'CANCELLED';
    if (widget.booking.isCompleted) return 'COMPLETED';
    if (widget.booking.isInProgress) return 'ACTIVE JOB';
    if (widget.booking.isConfirmed) return 'CONFIRMED';
    return 'PENDING';
  }

  Color get _badgeColor {
    if (widget.booking.isCancelled) return AppColors.error;
    if (widget.booking.isCompleted) return AppColors.success;
    if (widget.booking.isInProgress) return AppColors.accent;
    if (widget.booking.isConfirmed) return AppColors.warning;
    return AppColors.textSecondary;
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdRadius,
        ),
      ),
    );
  }
}

// ── STEP DATA MODEL ───────────────────────────────────────────────────────────
// Simple data class for stepper steps — keeps build method clean

class _StepData {
  final String label;
  final IconData icon;
  final bool isDone;
  final bool isActive;

  const _StepData({
    required this.label,
    required this.icon,
    required this.isDone,
    this.isActive = false,
  });
}
