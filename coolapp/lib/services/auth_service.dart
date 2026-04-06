// lib/services/auth_service.dart
//
// PURPOSE: This file is the ONLY place in the entire CampusLink frontend
// that communicates with Firebase Authentication and Firestore for
// user-related operations.
//
// ─────────────────────────────────────────────────────────────────────────────
// TEAM RESPONSIBILITIES — PLEASE READ BEFORE EDITING
// ─────────────────────────────────────────────────────────────────────────────
//
// FRONTEND (you):
//   - Define function signatures (names, parameters, return types)
//   - Write stub implementations so screens compile and run
//   - Call these functions from screens and providers
//   - Handle the AuthResult responses in the UI
//
// BACKEND — Petronilo & Eric:
//   - Replace every stub body marked with [PETRONILO/ERIC: IMPLEMENT HERE]
//   - Set up Firebase Auth in the Firebase Console
//   - Write Firestore security rules that match the UserModel fields
//   - Configure Firebase Auth to restrict to @stu.ucc.edu.gh / @ucc.edu.gh
//   - Handle email verification sending after registration
//
// SHARED AGREEMENT (discuss before either side changes):
//   - UserModel field names must match Firestore document structure exactly
//   - The 'role' field is List<String> — agreed values: 'seeker', 'provider'
//   - The 'kycStatus' field agreed values: 'pending', 'verified', 'rejected'
//
// ─────────────────────────────────────────────────────────────────────────────
//
// ARCHITECTURAL NOTE (for your defense):
// This implements the Repository Pattern — all data access logic lives here,
// completely isolated from the UI. If you switch from Firebase to Supabase
// tomorrow, you only edit this file. No screen changes at all.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/validators.dart';

// =============================================================================
// AUTH RESULT — Standardised response wrapper
// =============================================================================
// Every function in this service returns an AuthResult instead of throwing
// raw Firebase exceptions at your screens.
//
// WHY: Firebase error codes like 'auth/email-already-in-use' are not
// user-friendly. This wrapper lets us translate them into clean messages
// before they reach the UI.
//
// USAGE IN A SCREEN:
//   final result = await AuthService().registerUser(...);
//   if (result.success) {
//     Navigator.pushNamed(context, AppRoutes.kyc);
//   } else {
//     setState(() => _errorMessage = result.errorMessage);
//   }

class AuthResult {
  final bool success;
  final String? errorMessage; // human-readable, shown directly in the UI
  final UserModel? user; // populated on success

  const AuthResult({
    required this.success,
    this.errorMessage,
    this.user,
  });

  // Convenience constructors — makes call sites cleaner to read
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
  // Private Firebase instances — only this class accesses them directly
  // [PETRONILO & ERIC: these are the Firebase SDK entry points you will use]
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firestore collection name — centralised so a rename is one-line change
  static const String _usersCollection = 'users';

  // ---------------------------------------------------------------------------
  // CURRENT USER STREAM
  // ---------------------------------------------------------------------------
  // A real-time stream of the Firebase auth state.
  // Emits a User object when logged in, null when logged out.
  //
  // Used by AuthProvider (providers/auth_provider.dart) to reactively
  // update the entire app when login state changes.
  //
  // [PETRONILO & ERIC: this is a direct Firebase SDK call — no changes needed]

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Returns the currently signed-in Firebase user (or null if not signed in)
  User? get currentFirebaseUser => _auth.currentUser;

  // ---------------------------------------------------------------------------
  // REGISTER USER
  // ---------------------------------------------------------------------------
  // Creates a new CampusLink account. Steps:
  //   1. Client-side email domain validation (runs instantly, free)
  //   2. Firebase Auth — creates the auth account
  //   3. Firestore — creates the user document in the 'users' collection
  //   4. Sends email verification
  //
  // PARAMETERS:
  //   fullName      → stored in Firestore, used throughout the app
  //   email         → must be @stu.ucc.edu.gh or @ucc.edu.gh
  //   password      → min 8 chars, 1 uppercase, 1 number (see validators.dart)
  //   roles         → e.g. ['seeker'] or ['seeker', 'provider']
  //
  // RETURNS: AuthResult.success with UserModel, or AuthResult.failure with
  // a human-readable error message.

  Future<AuthResult> registerUser({
    required String fullName,
    required String email,
    required String password,
    required List<String> roles,
  }) async {
    // -- Step 1: Client-side domain validation --
    // Run this BEFORE calling Firebase to avoid unnecessary API calls.
    // validators.dart already has this logic — we reuse it here.
    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      return AuthResult.failure(emailError);
    }

    try {
      // ── [PETRONILO & ERIC: IMPLEMENT FROM HERE] ───────────────────────────
      //
      // Step 2: Create Firebase Auth account
      // Replace the stub below with:
      //
      // final credential = await _auth.createUserWithEmailAndPassword(
      //   email: email.trim(),
      //   password: password,
      // );
      //
      // Step 3: Create Firestore user document
      // The document ID must equal the Firebase Auth UID for security rules.
      //
      // await _firestore
      //     .collection(_usersCollection)
      //     .doc(credential.user!.uid)
      //     .set({
      //   'uid':             credential.user!.uid,
      //   'fullName':        fullName.trim(),
      //   'universityEmail': email.trim().toLowerCase(),
      //   'roles':           roles,               // List<String>
      //   'kycStatus':       'pending',           // all new users start here
      //   'momoNumber':      null,                // added during KYC
      //   'createdAt':       FieldValue.serverTimestamp(),
      // });
      //
      // Step 4: Send email verification
      // await credential.user!.sendEmailVerification();
      //
      // Step 5: Return success with the new UserModel
      // return AuthResult.success(
      //   user: UserModel(
      //     uid:              credential.user!.uid,
      //     fullName:         fullName.trim(),
      //     universityEmail:  email.trim().toLowerCase(),
      //     roles:            roles,
      //     kycStatus:        'pending',
      //     momoNumber:       null,
      //   ),
      // );
      //
      // ── [END PETRONILO & ERIC SECTION] ────────────────────────────────────

      // STUB — simulates a successful registration for UI development
      // Remove this entire stub block once Petronilo & Eric implement above
      await Future.delayed(const Duration(seconds: 1));
      return AuthResult.success(
        user: UserModel(
          uid: 'stub-uid-001',
          fullName: fullName.trim(),
          universityEmail: email.trim().toLowerCase(),
          roles: roles,
          kycStatus: 'pending',
          momoNumber: null,
        ),
      );
    } on FirebaseAuthException catch (e) {
      // [PETRONILO & ERIC: keep this error handler — it catches real errors]
      return AuthResult.failure(_handleFirebaseError(e.code));
    } catch (e) {
      return AuthResult.failure('Something went wrong. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // LOGIN USER
  // ---------------------------------------------------------------------------
  // Signs in an existing user with email and password.
  // After sign-in, fetches the full UserModel from Firestore so the app
  // has access to kycStatus, roles, etc. — not just the auth token.
  //
  // [PETRONILO & ERIC: IMPLEMENT THE FIREBASE CALLS INSIDE THE TRY BLOCK]

  Future<AuthResult> loginUser({
    required String email,
    required String password,
  }) async {
    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      return AuthResult.failure(emailError);
    }

    try {
      // ── [PETRONILO & ERIC: IMPLEMENT FROM HERE] ───────────────────────────
      //
      // Step 1: Sign in with Firebase Auth
      // final credential = await _auth.signInWithEmailAndPassword(
      //   email: email.trim(),
      //   password: password,
      // );
      //
      // Step 2: Fetch the user document from Firestore
      // final doc = await _firestore
      //     .collection(_usersCollection)
      //     .doc(credential.user!.uid)
      //     .get();
      //
      // if (!doc.exists) {
      //   return const AuthResult.failure(
      //     'Account not found. Please register first.'
      //   );
      // }
      //
      // Step 3: Return the full UserModel
      // return AuthResult.success(
      //   user: UserModel.fromFirestore(doc),
      // );
      //
      // ── [END PETRONILO & ERIC SECTION] ────────────────────────────────────

      // STUB — simulates login for UI development
      await Future.delayed(const Duration(seconds: 1));
      return AuthResult.success(
        user: UserModel(
          uid: 'stub-uid-001',
          fullName: 'Alex Mensah',
          universityEmail: email.trim().toLowerCase(),
          roles: const ['seeker'],
          kycStatus: 'verified',
          momoNumber: '0241234567',
        ),
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_handleFirebaseError(e.code));
    } catch (e) {
      return AuthResult.failure('Something went wrong. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // FETCH USER MODEL
  // ---------------------------------------------------------------------------
  // Fetches a full UserModel from Firestore by UID.
  // Called on app launch to restore session state.
  //
  // [PETRONILO & ERIC: IMPLEMENT THE FIRESTORE FETCH BELOW]

  Future<UserModel?> fetchUserModel(String uid) async {
    try {
      // ── [PETRONILO & ERIC: IMPLEMENT FROM HERE] ───────────────────────────
      //
      // final doc = await _firestore
      //     .collection(_usersCollection)
      //     .doc(uid)
      //     .get();
      //
      // if (!doc.exists) return null;
      // return UserModel.fromFirestore(doc);
      //
      // ── [END PETRONILO & ERIC SECTION] ────────────────────────────────────

      // STUB
      await Future.delayed(const Duration(milliseconds: 500));
      return UserModel(
        uid: uid,
        fullName: 'Alex Mensah',
        universityEmail: 'alex@stu.ucc.edu.gh',
        roles: const ['seeker'],
        kycStatus: 'verified',
        momoNumber: '0241234567',
      );
    } catch (e) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // SIGN OUT
  // ---------------------------------------------------------------------------
  // Signs the user out of Firebase Auth.
  // AuthProvider listens to authStateChanges and will automatically
  // redirect to WelcomeScreen when this completes.
  //
  // [PETRONILO & ERIC: uncomment the real implementation below]

  Future<void> signOut() async {
    // ── [PETRONILO & ERIC: IMPLEMENT FROM HERE] ─────────────────────────────
    // await _auth.signOut();
    // ── [END PETRONILO & ERIC SECTION] ──────────────────────────────────────

    // STUB
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // ---------------------------------------------------------------------------
  // FIREBASE ERROR TRANSLATOR
  // ---------------------------------------------------------------------------
  // Converts raw Firebase error codes into human-friendly messages.
// ---------------------------------------------------------------------------
  // FIREBASE ERROR TRANSLATOR
  // ---------------------------------------------------------------------------
  String _handleFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists. Try logging in.';
      case 'invalid-email':
        return 'This email address is not valid.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'user-not-found':
        return 'No account found with this email. Please register first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return 'Something went wrong. Please try again. (Code: $code)';
    }
  }
}
