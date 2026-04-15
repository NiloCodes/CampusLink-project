// lib/widgets/payment_bottom_sheet.dart
//
// PURPOSE: The booking confirmation bottom sheet shown when seeker
// taps "Book & Pay via MoMo" on ServiceDetailScreen.
//
// FEATURES:
//   - Editable "Agreed amount" field (pre-filled with base price)
//   - Platform fee calculated live as amount changes
//   - Notes field for special instructions
//   - MoMo number field
//   - Total breakdown before confirming
//   - "Confirm & Pay" button
//
// [PETRONILO & ERIC: the actual Paystack MoMo charge happens in your
// Cloud Function triggered after createBooking() — the client only
// creates the booking document and then polls for payment confirmation]

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/validators.dart';
import '../models/service_model.dart';
import '../models/booking_model.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';

class PaymentBottomSheet extends StatefulWidget {
  final ServiceModel service;
  final VoidCallback onBookingCreated;

  const PaymentBottomSheet({
    super.key,
    required this.service,
    required this.onBookingCreated,
  });

  // Static helper to show the sheet
  static Future<void> show(
    BuildContext context,
    ServiceModel service,
    VoidCallback onBookingCreated,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentBottomSheet(
        service: service,
        onBookingCreated: onBookingCreated,
      ),
    );
  }

  @override
  State<PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<PaymentBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final _notesController = TextEditingController();
  final _momoController = TextEditingController();

  double _agreedAmount = 0;
  double get _platformFee => _agreedAmount * 0.05;
  double get _totalAmount => _agreedAmount + _platformFee;

  @override
  void initState() {
    super.initState();
    _agreedAmount = widget.service.basePrice;
    _amountController = TextEditingController(
      text: widget.service.basePrice.toStringAsFixed(0),
    );
    _amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    final value = double.tryParse(_amountController.text) ?? 0;
    setState(() => _agreedAmount = value);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _momoController.dispose();
    super.dispose();
  }

  Future<void> _confirmBooking() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final booking = context.read<BookingProvider>();
    final user = auth.currentUser!;

    final newBooking = BookingModel(
      bookingId: '',
      seekerUid: user.uid,
      seekerName: user.fullName,
      providerUid: widget.service.providerUid,
      providerName: widget.service.providerName,
      serviceId: widget.service.serviceId,
      serviceTitle: widget.service.title,
      totalAmount: _totalAmount,
      bookingStatus: BookingStatus.pending,
      escrowStatus: EscrowStatus.awaitingPayment,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    final bookingId = await booking.createBooking(newBooking);

    if (!mounted) return;

    if (bookingId != null) {
      Navigator.pop(context);
      widget.onBookingCreated();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bp = context.watch<BookingProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
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

              // Title
              Text(
                'Confirm Booking',
                style: AppTextStyles.heading1,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.service.title,
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── AGREED AMOUNT ──────────────────────────────────────────
              Text('AGREED AMOUNT (GHS)', style: AppTextStyles.fieldLabel),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d+\.?\d{0,2}'),
                  ),
                ],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.backgroundField,
                  hintText: widget.service.basePrice.toStringAsFixed(0),
                  prefixText: 'GHS  ',
                  prefixStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.mdRadius,
                    borderSide: BorderSide.none,
                  ),
                  helperText: widget.service.isPriceNegotiable
                      ? 'Negotiable — enter the amount you agreed with the provider'
                      : 'Fixed price service',
                ),
                validator: (value) {
                  final amount = double.tryParse(value ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  if (amount < 5) {
                    return 'Minimum booking amount is GHS 5';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── MOMO NUMBER ────────────────────────────────────────────
              Text('YOUR MOMO NUMBER', style: AppTextStyles.fieldLabel),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _momoController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.backgroundField,
                  hintText: '024 XXX XXXX',
                  prefixIcon: const Icon(
                    Icons.phone_android_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.mdRadius,
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: Validators.validateMomoNumber,
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── NOTES ──────────────────────────────────────────────────
              Text('SPECIAL INSTRUCTIONS (OPTIONAL)',
                  style: AppTextStyles.fieldLabel),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.backgroundField,
                  hintText: 'Any special instructions for the provider...',
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.mdRadius,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── PAYMENT BREAKDOWN ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.backgroundField,
                  borderRadius: AppRadius.lgRadius,
                ),
                child: Column(
                  children: [
                    Text(
                      'PAYMENT BREAKDOWN',
                      style: AppTextStyles.fieldLabel,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _breakdownRow(
                      'Subtotal',
                      'GHS ${_agreedAmount.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _breakdownRow(
                      'Platform Fee (5%)',
                      'GHS ${_platformFee.toStringAsFixed(2)}',
                    ),
                    const Divider(height: AppSpacing.lg),
                    _breakdownRow(
                      'Total',
                      'GHS ${_totalAmount.toStringAsFixed(2)}',
                      isBold: true,
                      valueColor: AppColors.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xs),

              // Escrow note
              Row(
                children: [
                  const Icon(
                    Icons.lock_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Funds held securely until you confirm completion.',
                      style: AppTextStyles.caption,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── CONFIRM BUTTON ─────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: bp.isActing ? null : _confirmBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.pillRadius,
                    ),
                  ),
                  child: bp.isActing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Confirm & Pay GHS ${_totalAmount.toStringAsFixed(2)} via MoMo',
                          style: const TextStyle(
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
            fontSize: isBold ? 16 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
