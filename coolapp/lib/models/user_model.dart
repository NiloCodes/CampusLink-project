// lib/models/user_model.dart
//
// PURPOSE: Represents a CampusLink user in memory (Dart side).
// This is the agreed contract between frontend and backend.
//
// ─────────────────────────────────────────────────────────────────────────────
// TEAM AGREEMENT — ALL THREE OF YOU MUST AGREE BEFORE CHANGING ANY FIELD NAME
// ─────────────────────────────────────────────────────────────────────────────
// Field names here MUST match Firestore document field names exactly.
// If Petronilo or Eric rename a field in Firestore, update it here too.
// If you rename a field here, tell Petronilo and Eric immediately.
// ─────────────────────────────────────────────────────────────────────────────
//
// FIRESTORE DOCUMENT STRUCTURE (users collection):
// {
//   uid:              "firebase-auth-uid",
//   fullName:         "Alex Mensah",
//   universityEmail:  "alex@stu.ucc.edu.gh",
//   roles:            ["seeker"]  OR  ["provider"]  OR  ["seeker", "provider"],
//   kycStatus:        "pending" | "verified" | "rejected",
//   momoNumber:       "0241234567" | null,
//   createdAt:        Timestamp,
// }

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String universityEmail;
  final List<String>
      roles; // ['seeker'], ['provider'], or ['seeker','provider']
  final String kycStatus; // 'pending' | 'verified' | 'rejected'
  final String? momoNumber; // nullable — added during KYC flow

  const UserModel({
    required this.uid,
    required this.fullName,
    required this.universityEmail,
    required this.roles,
    required this.kycStatus,
    this.momoNumber,
  });

  // -- Convenience getters --
  // Use these in your screens instead of checking roles list manually

  bool get isSeeker => roles.contains('seeker');
  bool get isProvider => roles.contains('provider');
  bool get isBoth => isSeeker && isProvider;
  bool get isVerified => kycStatus == 'verified';
  bool get isPending => kycStatus == 'pending';
  bool get isRejected => kycStatus == 'rejected';

  // -- fromFirestore --
  // [PETRONILO & ERIC: this factory is what converts a Firestore document
  // snapshot into a Dart UserModel object. Review and confirm field names
  // match what you store in Firestore exactly.]
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      fullName: data['fullName'] ?? '',
      universityEmail: data['universityEmail'] ?? '',
      roles: List<String>.from(data['roles'] ?? ['seeker']),
      kycStatus: data['kycStatus'] ?? 'pending',
      momoNumber: data['momoNumber'],
    );
  }

  // -- toFirestore --
  // [PETRONILO & ERIC: used when creating/updating a user document]
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'fullName': fullName,
      'universityEmail': universityEmail,
      'roles': roles,
      'kycStatus': kycStatus,
      'momoNumber': momoNumber,
    };
  }

  // -- copyWith --
  // Creates a new UserModel with some fields changed.
  // Used when updating user state without mutating the original object.
  // Example: when KYC gets approved, update kycStatus without rebuilding everything.
  UserModel copyWith({
    String? fullName,
    List<String>? roles,
    String? kycStatus,
    String? momoNumber,
  }) {
    return UserModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      universityEmail: universityEmail,
      roles: roles ?? this.roles,
      kycStatus: kycStatus ?? this.kycStatus,
      momoNumber: momoNumber ?? this.momoNumber,
    );
  }
}
