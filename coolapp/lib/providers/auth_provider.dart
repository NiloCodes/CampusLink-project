// lib/providers/auth_provider.dart
//
// ✅ PRODUCTION IMPLEMENTATION — wired to real Firebase stream
//
// WHAT CHANGED FROM THE STUB:
//   - Constructor now calls _init() which subscribes to authStateChanges
//   - _init() listens to Firebase User stream → fetches Firestore UserModel
//   - Then subscribes to the LIVE Firestore userStream(uid) so that when
//     the Cloud Function approves KYC, the UI updates automatically
//   - register() and login() now call real AuthService methods
//   - All DEV BYPASS comments removed
//
// FLOW ON FIRST LAUNCH:
//   1. _auth.authStateChanges() emits null (not signed in)
//   2. _status = unauthenticated → WelcomeScreen shown
//
// FLOW AFTER LOGIN:
//   1. authStateChanges emits a FirebaseAuth User
//   2. We fetchUserModel(uid) from Firestore → get kycStatus + roles
//   3. _resolveStatus() sets the correct AuthStatus
//   4. AuthGate re-routes to the correct screen
//
// LIVE KYC UPDATE FLOW:
//   1. User submits KYC photos (KycScreen)
//   2. Cloud Function reviews → updates kycStatus to 'verified' in Firestore
//   3. userStream emits the updated UserModel
//   4. AuthProvider calls notifyListeners()
//   5. AuthGate auto-routes to BottomNavShell — no user action needed

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
  pendingKyc,
  rejectedKyc,
}

class AuthProvider extends ChangeNotifier {
  // ── Dependencies ───────────────────────────────────────────────────────────
  final AuthService _authService = AuthService();

  // ── Private state ──────────────────────────────────────────────────────────
  UserModel? _currentUser;
  AuthStatus _status = AuthStatus.uninitialized;
  bool _isLoading = false;
  String? _errorMessage;

  // Stream subscriptions — must be cancelled in dispose() to avoid leaks
  StreamSubscription? _authStateSubscription;
  StreamSubscription? _userDocSubscription;

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
    _init();
  }

  // ── INIT ───────────────────────────────────────────────────────────────────
  // Subscribes to Firebase Auth state. This runs once on app launch and
  // keeps running for the entire app lifetime.
  //
  // WHY TWO STREAMS?
  //   Stream 1 (_authStateSubscription): Firebase Auth — tells us if a user
  //     is signed in at all. Fires immediately on launch.
  //   Stream 2 (_userDocSubscription): Firestore user document — gives us
  //     live kycStatus updates. Fires whenever the doc changes.
  //   Separating them means KYC approval triggers a UI update without
  //   needing to sign out and back in.

  void _init() {
    _authStateSubscription = _authService.authStateChanges.listen(
      (firebaseUser) async {
        if (firebaseUser == null) {
          // Signed out — cancel any existing Firestore subscription
          _userDocSubscription?.cancel();
          _userDocSubscription = null;
          _currentUser = null;
          _status = AuthStatus.unauthenticated;
          notifyListeners();
          return;
        }

        // Signed in — fetch the Firestore profile once to get initial state
        final userModel = await _authService.fetchUserModel(firebaseUser.uid);

        if (userModel == null) {
          // Firestore doc missing — edge case (account created but doc failed)
          _status = AuthStatus.unauthenticated;
          notifyListeners();
          return;
        }

        _currentUser = userModel;
        _status = _resolveStatus(userModel);
        notifyListeners();

        // Subscribe to LIVE Firestore updates for this user
        // This is how KYC approval auto-routes the user without sign-in/out
        _userDocSubscription?.cancel();
        _userDocSubscription = _authService.userStream(firebaseUser.uid).listen(
          (updatedUser) {
            if (updatedUser != null) {
              _currentUser = updatedUser;
              _status = _resolveStatus(updatedUser);
              notifyListeners();
            }
          },
        );
      },
    );
  }

  // ── REGISTER ───────────────────────────────────────────────────────────────
  // Returns true on success. On failure, sets errorMessage (shown in UI).
  // After success, AuthGate automatically routes to KycScreen because
  // the new user's kycStatus == 'pending'.

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required List<String> roles,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await _authService.registerUser(
      fullName: fullName,
      email: email,
      password: password,
      roles: roles,
    );

    if (result.success && result.user != null) {
      _currentUser = result.user;
      _status = _resolveStatus(result.user!);
      _setLoading(false);
      return true;
    } else {
      _errorMessage = result.errorMessage;
      _setLoading(false);
      return false;
    }
  }

  // ── LOGIN ──────────────────────────────────────────────────────────────────
  // Returns true on success. The _init() stream will also fire, but we
  // update state here immediately so the UI doesn't lag.

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await _authService.loginUser(
      email: email,
      password: password,
    );

    if (result.success && result.user != null) {
      _currentUser = result.user;
      _status = _resolveStatus(result.user!);
      _setLoading(false);
      return true;
    } else {
      _errorMessage = result.errorMessage;
      _setLoading(false);
      return false;
    }
  }

  // ── SIGN OUT ───────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    _setLoading(true);
    await _authService.signOut();
    // The _authStateSubscription will fire with null and clear state
    _setLoading(false);
  }

  // ── UPDATE KYC STATUS (local optimistic update) ────────────────────────────
  // Called from KycScreen immediately after submission so the UI moves to
  // PendingApprovalScreen without waiting for the Firestore stream.
  // The real update comes from the Cloud Function via the live stream.

  void updateKycStatus(String newStatus) {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(kycStatus: newStatus);
    _status = _resolveStatus(_currentUser!);
    notifyListeners();
  }

  // ── UPDATE ROLES ───────────────────────────────────────────────────────────

  Future<void> updateRoles(List<String> newRoles) async {
    if (_currentUser == null) return;

    // Optimistic UI update
    _currentUser = _currentUser!.copyWith(roles: newRoles);
    notifyListeners();

    // Persist to Firestore
    await _authService.updateRoles(_currentUser!.uid, newRoles);
  }

  // ── UPDATE MOMO NUMBER ─────────────────────────────────────────────────────

  Future<bool> updateMomoNumber(String momoNumber) async {
    if (_currentUser == null) return false;

    final success = await _authService.updateMomoNumber(
      _currentUser!.uid,
      momoNumber,
    );

    if (success) {
      _currentUser = _currentUser!.copyWith(momoNumber: momoNumber);
      notifyListeners();
    }

    return success;
  }

  // ── SEND PASSWORD RESET ────────────────────────────────────────────────────

  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _clearError();

    final result = await _authService.sendPasswordReset(email);

    if (!result.success) {
      _errorMessage = result.errorMessage;
    }

    _setLoading(false);
    return result.success;
  }

  // ── CLEAR ERROR ────────────────────────────────────────────────────────────

  void clearError() {
    _clearError();
    notifyListeners();
  }

  // ── DISPOSE ────────────────────────────────────────────────────────────────
  // CRITICAL: Cancel stream subscriptions to prevent memory leaks.
  // Flutter calls this when the provider is removed from the widget tree.

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _userDocSubscription?.cancel();
    super.dispose();
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
