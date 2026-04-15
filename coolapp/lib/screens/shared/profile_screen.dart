// lib/screens/shared/profile_screen.dart
//
// PURPOSE: User profile screen. Shows account details, role management,
// KYC status, and app settings.
//
// KEY FEATURES:
//   - Profile header with avatar + name + email + KYC badge
//   - Role display with "Switch to Provider Hub" button (dual-role users)
//   - Account settings section
//   - KYC status card
//   - Sign out button
//
// ROLE-AWARE:
//   Seeker only   → shows "Become a Provider" upgrade option
//   Provider only → shows provider stats summary
//   Both roles    → shows "Switch to Provider Hub" prominently

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/campuslink_logo.dart';
import '../../widgets/trust_badge.dart';

class ProfileScreen extends StatelessWidget {
  // Called when dual-role user taps "Switch to Provider Hub"
  // Passed in from BottomNavShell
  final VoidCallback? onSwitchMode;

  const ProfileScreen({
    super.key,
    this.onSwitchMode,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bp = context.watch<BookingProvider>();
    final user = auth.currentUser;

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,

      // ── APP BAR ───────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          // Settings icon — Sprint 3
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textSecondary,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings coming in Sprint 3'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),

            // ── PROFILE HEADER ───────────────────────────────────────────
            _buildProfileHeader(context, auth),

            const SizedBox(height: AppSpacing.lg),

            // ── KYC STATUS CARD ──────────────────────────────────────────
            _buildKycCard(user.kycStatus),

            const SizedBox(height: AppSpacing.lg),

            // ── STATS ROW (provider only) ────────────────────────────────
            if (user.isProvider) _buildProviderStatsRow(bp),

            if (user.isProvider) const SizedBox(height: AppSpacing.lg),

            // ── SWITCH TO PROVIDER HUB ───────────────────────────────────
            // Shown for dual-role users in seeker mode
            if (user.isProvider && onSwitchMode != null)
              _buildSwitchToProviderCard(context),

            if (user.isProvider && onSwitchMode != null)
              const SizedBox(height: AppSpacing.lg),

            // ── BECOME A PROVIDER ────────────────────────────────────────
            // Shown for seeker-only verified users
            if (user.isSeeker && !user.isProvider && user.isVerified)
              _buildBecomeProviderCard(context),

            if (user.isSeeker && !user.isProvider && user.isVerified)
              const SizedBox(height: AppSpacing.lg),

            // ── ACCOUNT SECTION ──────────────────────────────────────────
            _buildSectionHeader('Account'),
            const SizedBox(height: AppSpacing.sm),
            _buildAccountSection(context, user),

            const SizedBox(height: AppSpacing.lg),

            // ── SUPPORT SECTION ──────────────────────────────────────────
            _buildSectionHeader('Support'),
            const SizedBox(height: AppSpacing.sm),
            _buildSupportSection(context),

            const SizedBox(height: AppSpacing.lg),

            // ── SIGN OUT ─────────────────────────────────────────────────
            _buildSignOutButton(context, auth),

            const SizedBox(height: AppSpacing.lg),

            // ── FOOTER ───────────────────────────────────────────────────
            _buildFooter(),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  // ── PROFILE HEADER ────────────────────────────────────────────────────────

  Widget _buildProfileHeader(BuildContext context, AuthProvider auth) {
    final user = auth.currentUser!;

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
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  user.fullName.isNotEmpty
                      ? user.fullName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              // Edit avatar button
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Photo upload coming in Sprint 3'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Name
          Text(
            user.fullName,
            style: AppTextStyles.heading2,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          // Email
          Text(
            user.universityEmail,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.md),

          // Role badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (user.isSeeker) _roleBadge('Seeker', AppColors.accent),
              if (user.isSeeker && user.isProvider)
                const SizedBox(width: AppSpacing.sm),
              if (user.isProvider) _roleBadge('Provider', AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roleBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.pillRadius,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
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

  // ── KYC STATUS CARD ───────────────────────────────────────────────────────

  Widget _buildKycCard(String kycStatus) {
    TrustBadgeStatus status;
    switch (kycStatus) {
      case 'verified':
        status = TrustBadgeStatus.verified;
        break;
      case 'rejected':
        status = TrustBadgeStatus.rejected;
        break;
      default:
        status = TrustBadgeStatus.pending;
    }

    return TrustBadge(
      title: kycStatus == 'verified'
          ? 'Identity Verified'
          : kycStatus == 'rejected'
              ? 'Verification Failed'
              : 'Verification Pending',
      subtitle: kycStatus == 'verified'
          ? 'Your UCC student ID has been verified'
          : kycStatus == 'rejected'
              ? 'Your ID was rejected — tap to resubmit'
              : 'Your student ID is being reviewed',
      status: status,
    );
  }

  // ── PROVIDER STATS ROW ────────────────────────────────────────────────────

  Widget _buildProviderStatsRow(BookingProvider bp) {
    return Row(
      children: [
        _miniStatCard(
          value: bp.activeJobsCount.toString(),
          label: 'Active Jobs',
          color: AppColors.accent,
        ),
        const SizedBox(width: AppSpacing.sm),
        _miniStatCard(
          value: bp.formattedEarnings,
          label: 'Earnings',
          color: AppColors.success,
        ),
        const SizedBox(width: AppSpacing.sm),
        _miniStatCard(
          value: bp.pendingRequestsCount.toString(),
          label: 'Pending',
          color: AppColors.warning,
        ),
      ],
    );
  }

  Widget _miniStatCard({
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
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
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

  // ── SWITCH TO PROVIDER HUB ────────────────────────────────────────────────

  Widget _buildSwitchToProviderCard(BuildContext context) {
    return GestureDetector(
      onTap: onSwitchMode,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: AppRadius.lgRadius,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Switch to Provider Hub',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Manage your services and requests',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ── BECOME A PROVIDER ─────────────────────────────────────────────────────

  Widget _buildBecomeProviderCard(BuildContext context) {
    return Container(
      width: double.infinity,
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_business_rounded,
              color: AppColors.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offer your skills on CampusLink',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
                Text(
                  'Become a provider and start earning',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              // TODO: Upgrade to provider flow — Sprint 3
              // Updates roles field in Firestore to include 'provider'
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Provider upgrade coming in Sprint 3',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: AppRadius.pillRadius,
              ),
              child: const Text(
                'Upgrade',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ACCOUNT SECTION ───────────────────────────────────────────────────────

  Widget _buildAccountSection(BuildContext context, dynamic user) {
    return _buildMenuCard([
      _menuItem(
        icon: Icons.person_outline_rounded,
        label: 'Edit Profile',
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Edit profile coming in Sprint 3'),
            behavior: SnackBarBehavior.floating,
          ),
        ),
      ),
      _menuDivider(),
      _menuItem(
        icon: Icons.phone_android_rounded,
        label: 'Mobile Money Number',
        trailing: Text(
          user.momoNumber ?? 'Not set',
          style: AppTextStyles.caption.copyWith(
            color:
                user.momoNumber != null ? AppColors.success : AppColors.warning,
          ),
        ),
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('MoMo settings coming in Sprint 3'),
            behavior: SnackBarBehavior.floating,
          ),
        ),
      ),
      _menuDivider(),
      _menuItem(
        icon: Icons.verified_user_outlined,
        label: 'KYC Documents',
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KYC management coming in Sprint 3'),
            behavior: SnackBarBehavior.floating,
          ),
        ),
      ),
      _menuDivider(),
      _menuItem(
        icon: Icons.notifications_outlined,
        label: 'Notifications',
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification settings coming in Sprint 3'),
            behavior: SnackBarBehavior.floating,
          ),
        ),
      ),
    ]);
  }

  // ── SUPPORT SECTION ───────────────────────────────────────────────────────

  Widget _buildSupportSection(BuildContext context) {
    return _buildMenuCard([
      _menuItem(
        icon: Icons.help_outline_rounded,
        label: 'Help & FAQ',
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Help centre coming in Sprint 3'),
            behavior: SnackBarBehavior.floating,
          ),
        ),
      ),
      _menuDivider(),
      _menuItem(
        icon: Icons.email_outlined,
        label: 'Contact Support',
        trailing: const Text(
          'support@campuslink.gh',
          style: AppTextStyles.caption,
        ),
        onTap: () {},
      ),
      _menuDivider(),
      _menuItem(
        icon: Icons.privacy_tip_outlined,
        label: 'Privacy Policy',
        onTap: () {},
      ),
      _menuDivider(),
      _menuItem(
        icon: Icons.description_outlined,
        label: 'Terms of Service',
        onTap: () {},
      ),
    ]);
  }

  // ── SIGN OUT BUTTON ───────────────────────────────────────────────────────

  Widget _buildSignOutButton(BuildContext context, AuthProvider auth) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _showSignOutDialog(context, auth),
        icon: const Icon(
          Icons.logout_rounded,
          size: 18,
          color: AppColors.error,
        ),
        label: const Text(
          'Sign Out',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: AppColors.error.withValues(alpha: 0.3),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.pillRadius,
          ),
        ),
      ),
    );
  }

  Future<void> _showSignOutDialog(
      BuildContext context, AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgRadius,
        ),
        title: const Text(
          'Sign Out',
          style: AppTextStyles.heading2,
        ),
        content: const Text(
          'Are you sure you want to sign out of CampusLink?',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.pillRadius,
              ),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await auth.signOut();
    }
  }

  // ── FOOTER ────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          const CampusLinkLogo(
            size: 40,
            variant: LogoVariant.withWordmark,
            scheme: LogoScheme.onLight,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Version 1.0.0 · University of Cape Coast',
            style: AppTextStyles.caption.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            '© 2024 CampusLink. All rights reserved.',
            style: AppTextStyles.caption.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ── SHARED HELPERS ────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String label) {
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

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(label, style: AppTextStyles.body),
            ),
            if (trailing != null) ...[
              trailing,
              const SizedBox(width: AppSpacing.xs),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuDivider() => const Divider(
        height: 1,
        thickness: 1,
        color: AppColors.border,
        indent: 52,
      );
}
