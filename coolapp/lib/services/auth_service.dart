// lib/services/auth_service.dart
//
// ⚠️ DEV MODE: Firebase imports commented out until google-services.json
// is added by Petronilo & Eric. All methods use stubs.
//
// [PETRONILO & ERIC: to activate real Firebase:]
//   1. Add google-services.json to android/app/
//   2. Uncomment all Firebase imports and instances below
//   3. Replace stub implementations with real Firebase calls
//   4. Change kycStatus from 'verified' back to 'pending' in registerUser

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../core/validators.dart';

// =============================================================================
// AUTH RESULT
// =============================================================================

class AuthResult {
  final bool success;
  final String? errorMessage;
  final UserModel? user;

  const AuthResult({
    required this.success,
    this.errorMessage,
    this.user,
  });

  const AuthResult.success({this.user})
      : success = true,
        errorMessage = null;

  const AuthResult.failure(String message)
      : success = false,
        errorMessage = message,
        user = null;
}

// =============================================================================
// AUTH SERVICE
// =============================================================================

class AuthService {
  // [PETRONILO & ERIC: uncomment when Firebase is configured]
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // static const String _usersCollection = 'users';

  // ── CURRENT USER STREAM ────────────────────────────────────────────────────
  // ⚠️ DEV: returns empty stream — Firebase not connected yet
  // [PETRONILO & ERIC: replace with _auth.authStateChanges()]
  Stream<dynamic> get authStateChanges => Stream.value(null);
  dynamic get currentFirebaseUser => null;

  // ── REGISTER USER ──────────────────────────────────────────────────────────

  Future<AuthResult> registerUser({
    required String fullName,
    required String email,
    required String password,
    required List<String> roles,
  }) async {
    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      return AuthResult.failure(emailError);
    }

    try {
      // ── [PETRONILO & ERIC: IMPLEMENT FROM HERE] ──────────────────────────
      // final credential = await _auth.createUserWithEmailAndPassword(
      //   email: email.trim(),
      //   password: password,
      // );
      // await _firestore
      //     .collection(_usersCollection)
      //     .doc(credential.user!.uid)
      //     .set({
      //   'uid':             credential.user!.uid,
      //   'fullName':        fullName.trim(),
      //   'universityEmail': email.trim().toLowerCase(),
      //   'roles':           roles,
      //   'kycStatus':       'pending',
      //   'momoNumber':      null,
      //   'createdAt':       FieldValue.serverTimestamp(),
      // });
      // await credential.user!.sendEmailVerification();
      // return AuthResult.success(
      //   user: UserModel(
      //     uid:             credential.user!.uid,
      //     fullName:        fullName.trim(),
      //     universityEmail: email.trim().toLowerCase(),
      //     roles:           roles,
      //     kycStatus:       'pending',
      //     momoNumber:      null,
      //   ),
      // );
      // ── [END PETRONILO & ERIC SECTION] ───────────────────────────────────

      // ⚠️ DEV STUB
      await Future.delayed(const Duration(seconds: 1));
      return AuthResult.success(
        user: UserModel(
          uid: 'stub-uid-001',
          fullName: fullName.trim(),
          universityEmail: email.trim().toLowerCase(),
          roles: roles,
          kycStatus: 'verified', // ⚠️ DEV BYPASS
          momoNumber: null,
        ),
      );
    } catch (e) {
      return AuthResult.failure('Something went wrong. Please try again.');
    }
  }

  // ── LOGIN USER ─────────────────────────────────────────────────────────────

  Future<AuthResult> loginUser({
    required String email,
    required String password,
  }) async {
    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      return AuthResult.failure(emailError);
    }

    try {
      // ── [PETRONILO & ERIC: IMPLEMENT FROM HERE] ──────────────────────────
      // final credential = await _auth.signInWithEmailAndPassword(
      //   email: email.trim(),
      //   password: password,
      // );
      // final doc = await _firestore
      //     .collection(_usersCollection)
      //     .doc(credential.user!.uid)
      //     .get();
      // if (!doc.exists) {
      //   return const AuthResult.failure(
      //     'Account not found. Please register first.',
      //   );
      // }
      // return AuthResult.success(user: UserModel.fromFirestore(doc));
      // ── [END PETRONILO & ERIC SECTION] ───────────────────────────────────

      // ⚠️ DEV STUB
      await Future.delayed(const Duration(seconds: 1));
      return AuthResult.success(
        user: UserModel(
          uid: 'stub-uid-001',
          fullName: 'Kwesi Manteaw',
          universityEmail: email.trim().toLowerCase(),
          roles: const ['seeker'],
          kycStatus: 'verified', // ⚠️ DEV BYPASS
          momoNumber: '0241234567',
        ),
      );
    } catch (e) {
      return AuthResult.failure('Something went wrong. Please try again.');
    }
  }

  // ── FETCH USER MODEL ───────────────────────────────────────────────────────

  Future<UserModel?> fetchUserModel(String uid) async {
    try {
      // ── [PETRONILO & ERIC: IMPLEMENT FROM HERE] ──────────────────────────
      // final doc = await _firestore
      //     .collection(_usersCollection)
      //     .doc(uid)
      //     .get();
      // if (!doc.exists) return null;
      // return UserModel.fromFirestore(doc);
      // ── [END PETRONILO & ERIC SECTION] ───────────────────────────────────

      // ⚠️ DEV STUB
      await Future.delayed(const Duration(milliseconds: 500));
      return UserModel(
        uid: uid,
        fullName: 'Kwesi Manteaw',
        universityEmail: 'kwesi@stu.ucc.edu.gh',
        roles: const ['seeker'],
        kycStatus: 'verified', // ⚠️ DEV BYPASS
        momoNumber: '0241234567',
      );
    } catch (e) {
      return null;
    }
  }

  // ── SIGN OUT ───────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    // ── [PETRONILO & ERIC: replace with _auth.signOut()]
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
