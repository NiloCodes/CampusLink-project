// lib/screens/provider/add_service_screen.dart
//
// PURPOSE: Lets a verified provider create a new service listing.
//
// FORM FIELDS:
//   - Service title
//   - Category selector
//   - Description
//   - Base price + negotiable toggle
//   - Cover image picker
//   - Provider contacts (phone, WhatsApp, Instagram, Snapchat)
//   - Feature tags (turnaround time, warranty, etc.)
//
// FLOW:
//   Provider fills form → taps "Publish Service" →
//   ServiceProvider.createService() → navigates back to dashboard

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/validators.dart';
import '../../models/service_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/custom_text_field.dart';

class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({super.key});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _instagramController = TextEditingController();
  final _snapchatController = TextEditingController();
  final _tagController = TextEditingController();

  // Form state
  ServiceCategory _selectedCategory = ServiceCategory.techDigital;
  bool _isPriceNegotiable = false;
  File? _coverImage;
  List<String> _tags = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _instagramController.dispose();
    _snapchatController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  // ── PICK COVER IMAGE ───────────────────────────────────────────────────────
  Future<void> _pickCoverImage() async {
    final source = await _showImageSourceSheet();
    if (source == null) return;

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 800,
      );
      if (picked == null) return;
      setState(() => _coverImage = File(picked.path));
    } catch (e) {
      _showSnackBar(
        'Could not access camera or gallery.',
        AppColors.error,
      );
    }
  }

  Future<ImageSource?> _showImageSourceSheet() {
    return showModalBottomSheet<ImageSource>(
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
            const Text('Add cover photo', style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              onTap: () => Navigator.pop(context, ImageSource.camera),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: AppColors.primary),
              ),
              title: const Text('Take a photo', style: AppTextStyles.body),
              subtitle: const Text('Use camera for best quality',
                  style: AppTextStyles.caption),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              onTap: () => Navigator.pop(context, ImageSource.gallery),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_rounded,
                    color: AppColors.accent),
              ),
              title:
                  const Text('Choose from gallery', style: AppTextStyles.body),
              subtitle: const Text('Select an existing photo',
                  style: AppTextStyles.caption),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  // ── ADD TAG ────────────────────────────────────────────────────────────────
  void _addTag(String tag) {
    final cleaned = tag.trim().toLowerCase();
    if (cleaned.isEmpty || _tags.contains(cleaned)) return;
    if (_tags.length >= 8) {
      _showSnackBar('Maximum 8 tags allowed.', AppColors.warning);
      return;
    }
    setState(() {
      _tags.add(cleaned);
      _tagController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  // ── SUBMIT ─────────────────────────────────────────────────────────────────
  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final sp = context.read<ServiceProvider>();
    final user = auth.currentUser!;

    final price = double.tryParse(_priceController.text) ?? 0;

    final service = ServiceModel(
      serviceId: '',
      providerUid: user.uid,
      providerName: user.fullName,
      isVerified: user.isVerified,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      tags: _tags,
      basePrice: price,
      isPriceNegotiable: _isPriceNegotiable,
      providerPhone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      providerWhatsapp: _whatsappController.text.trim().isEmpty
          ? null
          : _whatsappController.text.trim(),
      providerInstagram: _instagramController.text.trim().isEmpty
          ? null
          : _instagramController.text.trim(),
      providerSnapchat: _snapchatController.text.trim().isEmpty
          ? null
          : _snapchatController.text.trim(),
    );

    final success = await sp.createService(
      service: service,
      imageFile: _coverImage,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Service published! Students can now find you.',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
        ),
      );
      Navigator.pop(context);
    } else {
      _showSnackBar(
        sp.errorMessage ?? 'Could not publish. Please try again.',
        AppColors.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<ServiceProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,

      // ── APP BAR ───────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Service',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          // Save draft — Sprint 3
          TextButton(
            onPressed: () => _showSnackBar(
              'Draft saving coming in Sprint 3.',
              AppColors.accent,
            ),
            child: const Text(
              'Save Draft',
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),

      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),

              // ── COVER IMAGE ──────────────────────────────────────────
              _buildSectionLabel('COVER PHOTO'),
              const SizedBox(height: AppSpacing.sm),
              _buildCoverImagePicker(),

              const SizedBox(height: AppSpacing.xl),

              // ── BASIC INFO ───────────────────────────────────────────
              _buildSectionLabel('SERVICE DETAILS'),
              const SizedBox(height: AppSpacing.sm),

              // Title
              CustomTextField(
                label: 'SERVICE TITLE',
                hint: 'e.g. iPhone & Android Screen Repair',
                controller: _titleController,
                validator: (v) =>
                    Validators.validateRequired(v, 'Service title'),
              ),
              const SizedBox(height: AppSpacing.md),

              // Category selector
              _buildCategorySelector(),
              const SizedBox(height: AppSpacing.md),

              // Description
              CustomTextField(
                label: 'DESCRIPTION',
                hint: 'Describe your service in detail — '
                    'what you offer, your experience, '
                    'turnaround time, any guarantees...',
                controller: _descriptionController,
                maxLines: 5,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please describe your service';
                  }
                  if (v.trim().length < 30) {
                    return 'Description must be at least 30 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── PRICING ──────────────────────────────────────────────
              _buildSectionLabel('PRICING'),
              const SizedBox(height: AppSpacing.sm),
              _buildPricingSection(),

              const SizedBox(height: AppSpacing.xl),

              // ── CONTACT DETAILS ──────────────────────────────────────
              _buildSectionLabel('YOUR CONTACT DETAILS'),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'At least one contact method is required so '
                'seekers can reach you.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildContactFields(),

              const SizedBox(height: AppSpacing.xl),

              // ── TAGS ─────────────────────────────────────────────────
              _buildSectionLabel('SEARCH TAGS'),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Add keywords that help students find your service.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildTagsSection(),

              const SizedBox(height: AppSpacing.xl),

              // ── ERROR MESSAGE ────────────────────────────────────────
              if (sp.errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 18, color: AppColors.error),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          sp.errorMessage!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // ── PUBLISH BUTTON ───────────────────────────────────────
              PrimaryButton(
                label: 'Publish Service',
                isLoading: sp.isSubmitting,
                onPressed: sp.isSubmitting ? null : _handleSubmit,
              ),

              const SizedBox(height: AppSpacing.sm),

              Center(
                child: Text(
                  'Your listing will be visible to all verified '
                  'UCC students immediately.',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  // ── COVER IMAGE PICKER ────────────────────────────────────────────────────

  Widget _buildCoverImagePicker() {
    return GestureDetector(
      onTap: _pickCoverImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.backgroundField,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(
            color: _coverImage != null
                ? AppColors.success.withValues(alpha: 0.5)
                : AppColors.border,
            width: _coverImage != null ? 2 : 1,
          ),
        ),
        child: _coverImage != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.lgRadius,
                    child: Image.file(
                      _coverImage!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.refresh_rounded,
                              size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'Tap to change photo',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.check_rounded,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_photo_alternate_rounded,
                        size: 28, color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Add a cover photo',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A good photo gets 3x more bookings',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
      ),
    );
  }

  // ── CATEGORY SELECTOR ─────────────────────────────────────────────────────

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CATEGORY', style: AppTextStyles.fieldLabel),
        const SizedBox(height: AppSpacing.xs),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundField,
            borderRadius: AppRadius.mdRadius,
          ),
          child: DropdownButtonFormField<ServiceCategory>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
            items: ServiceCategory.values.map((cat) {
              return DropdownMenuItem(
                value: cat,
                child: Row(
                  children: [
                    Text(cat.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: AppSpacing.sm),
                    Text(cat.fullDisplayName, style: AppTextStyles.body),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCategory = value);
              }
            },
          ),
        ),
      ],
    );
  }

  // ── PRICING SECTION ───────────────────────────────────────────────────────

  Widget _buildPricingSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Base price field
          CustomTextField(
            label: 'BASE PRICE (GHS)',
            hint: '0.00',
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            validator: (value) {
              final price = double.tryParse(value ?? '');
              if (price == null || price <= 0) {
                return 'Please enter a valid price';
              }
              if (price < 5) {
                return 'Minimum price is GHS 5';
              }
              return null;
            },
          ),

          const SizedBox(height: AppSpacing.md),

          // Negotiable toggle
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Negotiable price',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Seekers can agree a different amount with you',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isPriceNegotiable,
                onChanged: (value) =>
                    setState(() => _isPriceNegotiable = value),
                activeColor: AppColors.primary,
              ),
            ],
          ),

          // Negotiable hint
          if (_isPriceNegotiable) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.06),
                borderRadius: AppRadius.mdRadius,
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: AppColors.accent),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Your listing will show "From GHS X". '
                      'Seekers contact you first to agree the final amount.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── CONTACT FIELDS ────────────────────────────────────────────────────────

  Widget _buildContactFields() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Phone (required)
          _contactField(
            controller: _phoneController,
            label: 'PHONE NUMBER',
            hint: '024 XXX XXXX',
            icon: Icons.phone_rounded,
            color: AppColors.success,
            isRequired: true,
            validator: Validators.validateMomoNumber,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.border),
          const SizedBox(height: AppSpacing.md),

          // WhatsApp
          _contactField(
            controller: _whatsappController,
            label: 'WHATSAPP NUMBER',
            hint: '024 XXX XXXX (optional)',
            icon: Icons.chat_rounded,
            color: const Color(0xFF25D366),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppSpacing.md),

          // Instagram
          _contactField(
            controller: _instagramController,
            label: 'INSTAGRAM USERNAME',
            hint: 'your.username (optional)',
            icon: Icons.camera_alt_rounded,
            color: const Color(0xFFE1306C),
          ),
          const SizedBox(height: AppSpacing.md),

          // Snapchat
          _contactField(
            controller: _snapchatController,
            label: 'SNAPCHAT USERNAME',
            hint: 'your_username (optional)',
            icon: Icons.snapchat_rounded,
            color: const Color(0xFFFFFC00),
          ),
        ],
      ),
    );
  }

  Widget _contactField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
    bool isRequired = false,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label + (isRequired ? ' *' : ''),
              style: AppTextStyles.fieldLabel,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.backgroundField,
            border: OutlineInputBorder(
              borderRadius: AppRadius.mdRadius,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.mdRadius,
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
        ),
      ],
    );
  }

  // ── TAGS SECTION ──────────────────────────────────────────────────────────

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tag input
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _tagController,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: _addTag,
                decoration: InputDecoration(
                  hintText: 'e.g. calculus, repair, braiding...',
                  filled: true,
                  fillColor: AppColors.backgroundField,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.mdRadius,
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: () => _addTag(_tagController.text),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppRadius.mdRadius,
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 24),
              ),
            ),
          ],
        ),

        // Tag chips
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.pillRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _removeTag(tag),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: AppSpacing.xs),
        Text(
          '${_tags.length}/8 tags added',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTextStyles.fieldLabel),
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
