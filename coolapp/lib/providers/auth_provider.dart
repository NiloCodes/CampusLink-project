// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import '../models/user_model.dart';
// Notice we removed the auth_service.dart import so Firebase stays asleep!

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
  pendingKyc,
  rejectedKyc,
}

class AuthProvider extends ChangeNotifier {
  // ── Private state ──────────────────────────────────────────────────────────
  UserModel? _currentUser;
  AuthStatus _status =
      AuthStatus.unauthenticated; // Start unauthenticated for UI testing
  bool _isLoading = false;
  String? _errorMessage;

  // ── Public getters ─────────────────────────────────────────────────────────
  UserModel? get currentUser => _currentUser;
  AuthStatus get status => _status;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isPendingKyc => _status == AuthStatus.pendingKyc;
  bool get isRejectedKyc => _status == AuthStatus.rejectedKyc;
  bool get isUnauthenticated => _status == AuthStatus.unauthenticated;

  // ── Constructor ────────────────────────────────────────────────────────────
  AuthProvider() {
    // Firebase stream listener removed for UI testing
  }

  // ── FAKE REGISTER ──────────────────────────────────────────────────────────
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required List<String> roles,
  }) async {
    _setLoading(true);
    _clearError();

    // Fake network delay
    await Future.delayed(const Duration(seconds: 2));

    // Create a fake user object to keep the UI happy
    _currentUser = UserModel(
      uid: 'dummy_uid_123',
      fullName: fullName,
      universityEmail: email, // FIXED
      roles: roles,
      kycStatus: 'pending',
      // FIXED: Removed createdAt
    );

    _status = AuthStatus.pendingKyc;
    _setLoading(false);
    return true;
  }

  // ── FAKE LOGIN ─────────────────────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    // Fake network delay
    await Future.delayed(const Duration(seconds: 2));

    // Create a fake user object
    _currentUser = UserModel(
      uid: 'dummy_uid_123',
      fullName: 'Kwesi Manteaw',
      universityEmail: email, // FIXED
      roles: ['seeker'],
      kycStatus: 'verified',
      // FIXED: Removed createdAt
    );

    _status = AuthStatus.pendingKyc;
    _setLoading(false);
    return true;
  }

  // ── FAKE SIGN OUT ──────────────────────────────────────────────────────────
  Future<void> signOut() async {
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _setLoading(false);
  }

  // ── UPDATE KYC STATUS ──────────────────────────────────────────────────────
  void updateKycStatus(String newStatus) {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(kycStatus: newStatus);
    _status = _resolveStatus(_currentUser!);
    notifyListeners();
  }

  // ── UPDATE ROLES ───────────────────────────────────────────────────────────
  void updateRoles(List<String> newRoles) {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(roles: newRoles);
    notifyListeners();
  }

  // ── CLEAR ERROR ────────────────────────────────────────────────────────────
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // ── PRIVATE HELPERS ────────────────────────────────────────────────────────
  AuthStatus _resolveStatus(UserModel user) {
    switch (user.kycStatus) {
      case 'verified':
        return AuthStatus.authenticated;
      case 'pending':
        return AuthStatus.pendingKyc;
      case 'rejected':
        return AuthStatus.rejectedKyc;
      default:
        return AuthStatus.pendingKyc;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
