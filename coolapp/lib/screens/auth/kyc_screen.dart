// lib/screens/auth/kyc_screen.dart
//
// PURPOSE: Collects the student ID photos needed to verify a user's
// identity. This is CampusLink's core trust mechanism — no verified ID
// means no access to booking or listing services.
//
// WHAT THIS SCREEN DOES:
//   1. Lets the user pick or capture a front photo of their student ID
//   2. Lets the user pick or capture a back photo of their student ID
//   3. Uploads both images to Firebase Storage
//   4. Updates kycStatus to 'pending' in Firestore
//   5. Navigates to PendingApprovalScreen
//
// WHAT THIS SCREEN DOES NOT DO:
//   - No actual verification logic (that's a Cloud Function — Petronilo & Eric)
//   - No hardcoded colors or styles
//   - No direct Firebase calls (those go through storage_service.dart)
//
// PACKAGE NEEDED:
//   Add to pubspec.yaml under dependencies:
//     image_picker: ^1.0.7
//   Then run: flutter pub get
//
// [PETRONILO & ERIC: see the _submitKyc() method below — that is where
// the Firebase Storage upload and Firestore kycStatus update go.
// The Cloud Function that reviews the submission and flips kycStatus
// from 'pending' to 'verified' or 'rejected' is triggered server-side.]

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/campuslink_logo.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final ImagePicker _picker = ImagePicker();

  // Holds the picked image files — null means not yet picked
  File? _frontImage;
  File? _backImage;

  bool _isSubmitting = false;

  // True only when both images have been picked
  bool get _canSubmit => _frontImage != null && _backImage != null;

  // ── IMAGE PICKER ───────────────────────────────────────────────────────────
  // Shows a bottom sheet letting the user choose Camera or Gallery.
  // isFront determines which state variable gets updated.

  Future<void> _pickImage({required bool isFront}) async {
    // Show source chooser bottom sheet
    final source = await _showImageSourceSheet();
    if (source == null) return;

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85, // compress slightly to reduce upload size
        maxWidth: 1200, // cap resolution — student IDs don't need 4K
        maxHeight: 1200,
      );

      if (picked == null) return; // user cancelled

      setState(() {
        if (isFront) {
          _frontImage = File(picked.path);
        } else {
          _backImage = File(picked.path);
        }
      });
    } catch (e) {
      _showSnackBar('Could not access camera or gallery. Check permissions.');
    }
  }

  // Returns ImageSource.camera or ImageSource.gallery, or null if dismissed
  Future<ImageSource?> _showImageSourceSheet() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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

              const Text('Choose image source', style: AppTextStyles.heading2),
              const SizedBox(height: AppSpacing.lg),

              // Camera option
              ListTile(
                onTap: () => Navigator.pop(context, ImageSource.camera),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                title: const Text('Take a photo', style: AppTextStyles.body),
                subtitle: const Text(
                  'Use your camera for best clarity',
                  style: AppTextStyles.caption,
                ),
                contentPadding: EdgeInsets.zero,
              ),

              // Gallery option
              ListTile(
                onTap: () => Navigator.pop(context, ImageSource.gallery),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.accent,
                    size: 22,
                  ),
                ),
                title: const Text('Choose from gallery',
                    style: AppTextStyles.body),
                subtitle: const Text(
                  'Select an existing photo',
                  style: AppTextStyles.caption,
                ),
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  // ── KYC SUBMISSION ─────────────────────────────────────────────────────────
  // Uploads images and updates Firestore kycStatus to 'pending'.
  //
  // [PETRONILO & ERIC: implement the Firebase Storage uploads inside
  // the try block marked below. The storage paths should follow the
  // convention: kyc/{uid}/front.jpg and kyc/{uid}/back.jpg
  // After upload, update the user's Firestore document:
  //   kycStatus: 'pending'
  //   kycFrontUrl: <download URL>
  //   kycBackUrl: <download URL>
  //   kycSubmittedAt: FieldValue.serverTimestamp()
  // Your Cloud Function then watches for kycStatus == 'pending' and
  // triggers the review process.]

  Future<void> _submitKyc() async {
    if (!_canSubmit) return;

    setState(() => _isSubmitting = true);

    try {
      // ── [PETRONILO & ERIC: IMPLEMENT FROM HERE] ──────────────────────────
      //
      // Step 1: Get current user UID
      // final uid = context.read<AuthProvider>().currentUser!.uid;
      //
      // Step 2: Upload front image to Firebase Storage
      // final frontRef = FirebaseStorage.instance
      //     .ref('kyc/$uid/front.jpg');
      // await frontRef.putFile(_frontImage!);
      // final frontUrl = await frontRef.getDownloadURL();
      //
      // Step 3: Upload back image
      // final backRef = FirebaseStorage.instance
      //     .ref('kyc/$uid/back.jpg');
      // await backRef.putFile(_backImage!);
      // final backUrl = await backRef.getDownloadURL();
      //
      // Step 4: Update Firestore user document
      // await FirebaseFirestore.instance
      //     .collection('users')
      //     .doc(uid)
      //     .update({
      //   'kycStatus':       'pending',
      //   'kycFrontUrl':     frontUrl,
      //   'kycBackUrl':      backUrl,
      //   'kycSubmittedAt':  FieldValue.serverTimestamp(),
      // });
      //
      // ── [END PETRONILO & ERIC SECTION] ───────────────────────────────────

      // STUB — simulates upload delay for UI development
      await Future.delayed(const Duration(seconds: 2));

      // Update local state so the app reflects 'pending' immediately
      if (!mounted) return;
      context.read<AuthProvider>().updateKycStatus('pending');

      // Navigate to pending approval screen
      Navigator.pushReplacementNamed(context, AppRoutes.pendingApproval);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
          'Upload failed. Please check your connection and try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,

      // ── APP BAR ────────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        centerTitle: true,
        // No back button — users must complete KYC to proceed
        automaticallyImplyLeading: false,
        title: const Text(
          'CampusLink',
          style: TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),

              // ── HEADER ───────────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
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
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: CampusLinkLogo(
                          size: 52,
                          variant: LogoVariant.markOnly,
                          scheme: LogoScheme.onLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Text(
                      'Verify your identity',
                      style: AppTextStyles.heading1,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Upload a photo of your UCC Student ID\nto unlock full access to CampusLink.',
                      style: AppTextStyles.subtitle,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── PROGRESS INDICATOR ─────────────────────────────────────
              // Shows the user where they are in the onboarding flow
              _buildProgressSteps(),

              const SizedBox(height: AppSpacing.xl),

              // ── FRONT OF ID ────────────────────────────────────────────
              Text('FRONT OF STUDENT ID', style: AppTextStyles.fieldLabel),
              const SizedBox(height: AppSpacing.sm),
              _buildUploadCard(
                image: _frontImage,
                isFront: true,
                icon: Icons.credit_card_rounded,
                title: 'Tap to upload front',
                subtitle: 'Must show your name, photo, and student number',
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── BACK OF ID ─────────────────────────────────────────────
              Text('BACK OF STUDENT ID', style: AppTextStyles.fieldLabel),
              const SizedBox(height: AppSpacing.sm),
              _buildUploadCard(
                image: _backImage,
                isFront: false,
                icon: Icons.credit_card_rounded,
                title: 'Tap to upload back',
                subtitle: 'Must show the barcode or any institutional marking',
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── GUIDELINES CARD ────────────────────────────────────────
              _buildGuidelinesCard(),

              const SizedBox(height: AppSpacing.xl),

              // ── SUBMIT BUTTON ──────────────────────────────────────────
              PrimaryButton(
                label: _canSubmit
                    ? 'Submit for Verification'
                    : 'Upload both sides to continue',
                isLoading: _isSubmitting,
                // Disabled until both images are picked
                onPressed: (_canSubmit && !_isSubmitting) ? _submitKyc : null,
              ),

              const SizedBox(height: AppSpacing.md),

              // ── SECURITY NOTE ──────────────────────────────────────────
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Your ID is encrypted and stored securely.',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  // ── PROGRESS STEPS ────────────────────────────────────────────────────────
  // Shows: Register → Verify Identity → Start Using CampusLink
  // Step 2 (Verify Identity) is the active step on this screen.

  Widget _buildProgressSteps() {
    return Row(
      children: [
        _buildStep(
            label: 'Register', stepNumber: 1, isDone: true, isActive: false),
        _buildStepConnector(isComplete: true),
        _buildStep(
            label: 'Verify ID', stepNumber: 2, isDone: false, isActive: true),
        _buildStepConnector(isComplete: false),
        _buildStep(
            label: 'Get Started',
            stepNumber: 3,
            isDone: false,
            isActive: false),
      ],
    );
  }

  Widget _buildStep({
    required String label,
    required int stepNumber,
    required bool isDone,
    required bool isActive,
  }) {
    final Color color = isDone
        ? AppColors.success
        : isActive
            ? AppColors.primary
            : AppColors.textSecondary.withValues(alpha: 0.4);

    return Expanded(
      child: Column(
        children: [
          // Circle with step number or checkmark
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDone || isActive
                  ? color.withValues(alpha: 0.12)
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: isDone
                  ? Icon(Icons.check_rounded, size: 16, color: color)
                  : Text(
                      '$stepNumber',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          // Step label
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector({required bool isComplete}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 22),
        color: isComplete
            ? AppColors.success.withValues(alpha: 0.5)
            : AppColors.border,
      ),
    );
  }

  // ── UPLOAD CARD ───────────────────────────────────────────────────────────
  // Tappable card that shows a placeholder when empty and a preview
  // thumbnail once an image has been picked.

  Widget _buildUploadCard({
    required File? image,
    required bool isFront,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final bool hasImage = image != null;

    return GestureDetector(
      onTap: () => _pickImage(isFront: isFront),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color:
              hasImage ? AppColors.backgroundWhite : AppColors.backgroundField,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(
            color: hasImage
                ? AppColors.success.withValues(alpha: 0.5)
                : AppColors.border,
            width: hasImage ? 2 : 1,
          ),
        ),
        child: hasImage
            // ── IMAGE PREVIEW ──────────────────────────────────────────────
            ? Stack(
                children: [
                  // The image fills the card with rounded corners
                  ClipRRect(
                    borderRadius: AppRadius.lgRadius,
                    child: Image.file(
                      image,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Dark overlay at the bottom for the "retake" button
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
                          const Icon(
                            Icons.refresh_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tap to retake',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Green checkmark badge in top-right corner
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
                      child: const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            // ── EMPTY PLACEHOLDER ──────────────────────────────────────────
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
                    child: Icon(icon, size: 26, color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Text(
                      subtitle,
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── GUIDELINES CARD ───────────────────────────────────────────────────────
  // Helps users submit a good photo the first time, reducing rejection rate.
  // Fewer rejections = better UX + less admin work for your team.

  Widget _buildGuidelinesCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.06),
        borderRadius: AppRadius.lgRadius,
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Photo guidelines',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._guidelines.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Expanded(
                    child: Text(tip, style: AppTextStyles.caption),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Guidelines list — separated from build() for readability
  static const List<String> _guidelines = [
    'Place your ID on a flat, well-lit surface',
    'Ensure all text is clearly readable — no blur',
    'Avoid glare from laminate or glass',
    'The entire card must be visible in the frame',
    'Do not cover any part of the card with your fingers',
  ];
}
