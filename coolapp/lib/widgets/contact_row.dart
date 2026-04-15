// lib/widgets/contact_row.dart
//
// PURPOSE: Row of tappable contact buttons on ServiceDetailScreen.
// Shows only the contact methods the provider has filled in.
// Tapping opens the appropriate external app via url_launcher.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../models/service_model.dart';

class ContactRow extends StatelessWidget {
  final ServiceModel service;

  const ContactRow({super.key, required this.service});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _callPhone(String phone) => _launch('tel:$phone');

  void _openWhatsApp(String number) {
    // Strip leading zero and add Ghana country code
    final cleaned =
        number.startsWith('0') ? '233${number.substring(1)}' : number;
    _launch('https://wa.me/$cleaned');
  }

  void _openInstagram(String username) =>
      _launch('https://instagram.com/$username');

  void _openSnapchat(String username) =>
      _launch('https://snapchat.com/add/$username');

  @override
  Widget build(BuildContext context) {
    if (!service.hasContacts) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CONTACT PROVIDER', style: AppTextStyles.fieldLabel),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            if (service.providerPhone != null)
              _ContactButton(
                icon: Icons.phone_rounded,
                label: 'Call',
                color: AppColors.success,
                onTap: () => _callPhone(service.providerPhone!),
              ),
            if (service.providerWhatsapp != null) ...[
              if (service.providerPhone != null)
                const SizedBox(width: AppSpacing.sm),
              _ContactButton(
                icon: Icons.chat_rounded,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () => _openWhatsApp(service.providerWhatsapp!),
              ),
            ],
            if (service.providerInstagram != null) ...[
              const SizedBox(width: AppSpacing.sm),
              _ContactButton(
                icon: Icons.camera_alt_rounded,
                label: 'Instagram',
                color: const Color(0xFFE1306C),
                onTap: () => _openInstagram(service.providerInstagram!),
              ),
            ],
            if (service.providerSnapchat != null) ...[
              const SizedBox(width: AppSpacing.sm),
              _ContactButton(
                icon: Icons.snapchat_rounded,
                label: 'Snapchat',
                color: const Color(0xFFFFFC00),
                onTap: () => _openSnapchat(service.providerSnapchat!),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
