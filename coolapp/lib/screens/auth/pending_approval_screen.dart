// lib/screens/auth/pending_approval_screen.dart
// ⚠️ DEV MODE: Redirects immediately to home screen
// Restore full implementation before production

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/bottom_nav_shell.dart';
import '../../providers/auth_provider.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  @override
  void initState() {
    super.initState();
    // Force status to authenticated and go straight to home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().updateKycStatus('verified');
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isAuthenticated) {
      return const BottomNavShell();
    }
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
