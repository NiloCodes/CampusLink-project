// lib/services/auth_service.dart
//
// ✅ PRODUCTION IMPLEMENTATION — Firebase Auth + Firestore
//
// SETUP CHECKLIST (do these before un-commenting):
//   1. Add google-services.json → android/app/
//   2. Add GoogleService-Info.plist → ios/Runner/
//   3. Run: flutter pub get
//   4. In main.dart: await Firebase.initializeApp()
//
// WHAT THIS FILE DOES:
//   - registerUser   → creates FirebaseAuth account + Firestore user doc
//   - loginUser      → signs in + fetches user doc from Firestore
//   - fetchUserModel → loads user doc by UID (used by AuthProvider stream)
//   - signOut        → signs out of FirebaseAuth
//   - authStateChanges → real-time stream (null = logged out, User = logged in)
//
// FIRESTORE DOCUMENT PATH: users/{uid}
// Fields: uid, fullName, universityEmail, roles, kycStatus, momoNumber, createdAt

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../core/validators.dart';

// =============================================================================
// AUTH RESULT
// =============================================================================
// A typed wrapper around success/failure so callers never catch raw exceptions.

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
  // Singletons — one instance shared across the app lifetime
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection constants — change once here if Firestore collection is renamed
  static const String _usersCollection = 'users';

  // ---------------------------------------------------------------------------
  // AUTH STATE STREAM
  // ---------------------------------------------------------------------------
  // Emits a Firebase User whenever auth state changes (login/logout/token refresh).
  // AuthProvider listens to this in its constructor and updates AuthStatus accordingly.
  //
  // IMPORTANT: This stream emits the raw FirebaseAuth User, not our UserModel.
  // AuthProvider must then call fetchUserModel(uid) to get the full profile.

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Returns the currently signed-in FirebaseAuth user (or null if signed out).
  User? get currentFirebaseUser => _auth.currentUser;

  // ---------------------------------------------------------------------------
  // REGISTER USER
  // ---------------------------------------------------------------------------
  // Step 1: Client-side email validation (fast, no network)
  // Step 2: Create FirebaseAuth account (sets up login credentials)
  // Step 3: Write user document to Firestore (stores profile + roles)
  // Step 4: Send email verification to the UCC address
  //
  // kycStatus starts as 'pending' — user must upload ID on KycScreen.

  Future<AuthResult> registerUser({
    required String fullName,
    required String email,
    required String password,
    required List<String> roles,
  }) async {
    // Client-side domain check before any network call (saves API quota)
    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      return AuthResult.failure(emailError);
    }

    try {
      // Step 1: Create the Firebase Auth account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final uid = credential.user!.uid;

      // Step 2: Write the Firestore user document
      // Use set() not add() so the document ID == the Firebase Auth UID
      await _firestore.collection(_usersCollection).doc(uid).set({
        'uid': uid,
        'fullName': fullName.trim(),
        'universityEmail': email.trim().toLowerCase(),
        'roles': roles, // ['seeker'], ['provider'], or ['seeker','provider']
        'kycStatus':
            'pending', // ← must complete KYC before accessing marketplace
        'momoNumber': null, // added during KYC or profile setup
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Step 3: Send email verification
      // Users with unverified emails still get full app access in MVP —
      // the KYC photo upload is the primary trust gate.
      await credential.user!.sendEmailVerification();

      return AuthResult.success(
        user: UserModel(
          uid: uid,
          fullName: fullName.trim(),
          universityEmail: email.trim().toLowerCase(),
          roles: roles,
          kycStatus: 'pending',
          momoNumber: null,
        ),
      );
    } on FirebaseAuthException catch (e) {
      // Map Firebase error codes to user-friendly messages
      return AuthResult.failure(_mapAuthError(e.code));
    } catch (e) {
      return AuthResult.failure('Something went wrong. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // LOGIN USER
  // ---------------------------------------------------------------------------
  // Step 1: Client-side email validation
  // Step 2: Sign in with Firebase Auth
  // Step 3: Fetch the full UserModel from Firestore
  //         (kycStatus, roles, momoNumber are in Firestore, not FirebaseAuth)

  Future<AuthResult> loginUser({
    required String email,
    required String password,
  }) async {
    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      return AuthResult.failure(emailError);
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      // Fetch the Firestore profile to get kycStatus and roles
      final userModel = await fetchUserModel(credential.user!.uid);

      if (userModel == null) {
        // Auth account exists but Firestore doc is missing — data integrity issue
        await _auth.signOut();
        return const AuthResult.failure(
          'Account data not found. Please contact support.',
        );
      }

      return AuthResult.success(user: userModel);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e.code));
    } catch (e) {
      return AuthResult.failure('Something went wrong. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // FETCH USER MODEL
  // ---------------------------------------------------------------------------
  // Called by AuthProvider when the Firebase Auth stream emits a User.
  // Converts the raw Firestore document into a typed UserModel.
  //
  // Returns null if the document doesn't exist (account deleted or never created).

  Future<UserModel?> fetchUserModel(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();

      if (!doc.exists || doc.data() == null) return null;

      return UserModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // REAL-TIME USER STREAM
  // ---------------------------------------------------------------------------
  // Returns a live stream of the user document.
  // AuthProvider can subscribe to this so kycStatus updates appear instantly
  // when the Cloud Function approves a KYC submission.
  //
  // Usage in AuthProvider:
  //   _authService.userStream(uid).listen((user) {
  //     if (user != null) {
  //       _currentUser = user;
  //       _status = _resolveStatus(user);
  //       notifyListeners();
  //     }
  //   });

  Stream<UserModel?> userStream(String uid) {
    return _firestore
        .collection(_usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  // ---------------------------------------------------------------------------
  // UPDATE MOMO NUMBER
  // ---------------------------------------------------------------------------
  // Called from PaymentBottomSheet or ProfileScreen.
  // Stores the MoMo number in Firestore so the provider dashboard can display it.

  Future<bool> updateMomoNumber(String uid, String momoNumber) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'momoNumber': momoNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // UPDATE ROLES
  // ---------------------------------------------------------------------------
  // Called when a seeker upgrades to provider (or vice versa).

  Future<bool> updateRoles(String uid, List<String> roles) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'roles': roles,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // SEND PASSWORD RESET
  // ---------------------------------------------------------------------------
  // Called from ForgotPasswordScreen (Sprint 3).

  Future<AuthResult> sendPasswordReset(String email) async {
    final emailError = Validators.validateEmail(email);
    if (emailError != null) return AuthResult.failure(emailError);

    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
      return const AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e.code));
    } catch (e) {
      return AuthResult.failure('Could not send reset email. Try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // SIGN OUT
  // ---------------------------------------------------------------------------

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ---------------------------------------------------------------------------
  // ERROR CODE MAPPER
  // ---------------------------------------------------------------------------
  // Firebase throws cryptic codes like 'wrong-password'.
  // This translates them into copy that students can actually act on.

  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists. Try signing in.';
      case 'invalid-email':
        return 'Please enter a valid UCC email address.';
      case 'weak-password':
        return 'Password must be at least 8 characters with a number and uppercase.';
      case 'user-not-found':
        return 'No account found with this email. Please register first.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'user-disabled':
        return 'This account has been suspended. Contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'requires-recent-login':
        return 'Please sign in again to complete this action.';
      default:
        return 'Something went wrong ($code). Please try again.';
    }
  }
}
