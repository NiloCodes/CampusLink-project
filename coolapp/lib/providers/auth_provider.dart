// lib/providers/auth_provider.dart
//
// PURPOSE: Manages the global authentication STATE of CampusLink.
// Sits between auth_service.dart (data layer) and screens (UI layer).
//
// ⚠️ DEV MODE: Firebase stream removed. Login/Register use fake data.
// kycStatus is 'verified' so the app routes straight to BottomNavShell.
// When Petronilo & Eric connect Firebase, restore the full implementation.

import 'package:flutter/material.dart';
import '../models/user_model.dart';

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
  AuthStatus _status = AuthStatus.unauthenticated;
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
  AuthProvider();
  // [PETRONILO & ERIC: restore _init() and Firebase stream here]

  // ── REGISTER ───────────────────────────────────────────────────────────────

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required List<String> roles,
  }) async {
    _setLoading(true);
    _clearError();

    await Future.delayed(const Duration(seconds: 1));

    _currentUser = UserModel(
      uid: 'stub-uid-001',
      fullName: fullName,
      universityEmail: email,
      roles: roles,
      kycStatus:
          'verified', // ⚠️ DEV BYPASS — change to 'pending' for production
    );

    // _resolveStatus reads kycStatus — 'verified' → AuthStatus.authenticated
    _status = _resolveStatus(_currentUser!);
    _setLoading(false);
    return true;
  }

  // ── LOGIN ──────────────────────────────────────────────────────────────────

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    await Future.delayed(const Duration(seconds: 1));

    _currentUser = UserModel(
      uid: 'stub-uid-001',
      fullName: 'Kwesi Manteaw',
      universityEmail: email,
      roles: const ['seeker'],
      kycStatus:
          'verified', // ⚠️ DEV BYPASS — change to 'pending' for production
    );

    // _resolveStatus reads kycStatus — 'verified' → AuthStatus.authenticated
    _status = _resolveStatus(_currentUser!);
    _setLoading(false);
    return true;
  }

  // ── SIGN OUT ───────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 300));
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
