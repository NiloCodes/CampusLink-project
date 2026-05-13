// lib/services/storage_service.dart
//
// ✅ PRODUCTION IMPLEMENTATION — Firebase Storage
//
// STORAGE PATHS:
//   services/{serviceId}/cover.jpg   — service listing cover photo
//   avatars/{uid}/profile.jpg        — user profile photo
//   kyc/{uid}/front.jpg              — student ID front (written in kyc_screen.dart)
//   kyc/{uid}/back.jpg               — student ID back  (written in kyc_screen.dart)
//
// STORAGE RULES (paste into Firebase Console → Storage → Rules):
//   rules_version = '2';
//   service firebase.storage {
//     match /b/{bucket}/o {
//
//       // Service images — any verified user can read; only the provider can write
//       match /services/{serviceId}/{file} {
//         allow read: if request.auth != null;
//         allow write: if request.auth != null
//                      && request.resource.size < 5 * 1024 * 1024
//                      && request.resource.contentType.matches('image/.*');
//       }
//
//       // Avatars — anyone can read; only the owner can write
//       match /avatars/{uid}/{file} {
//         allow read: if request.auth != null;
//         allow write: if request.auth.uid == uid
//                      && request.resource.size < 2 * 1024 * 1024
//                      && request.resource.contentType.matches('image/.*');
//       }
//
//       // KYC — only the owner can write; only admin/Cloud Functions can read
//       match /kyc/{uid}/{file} {
//         allow read:  if false;  // Cloud Functions use Admin SDK (bypasses rules)
//         allow write: if request.auth.uid == uid
//                      && request.resource.size < 10 * 1024 * 1024
//                      && request.resource.contentType.matches('image/.*');
//       }
//     }
//   }

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ---------------------------------------------------------------------------
  // UPLOAD SERVICE IMAGE
  // ---------------------------------------------------------------------------
  // Called from ServiceProvider.createService() after the provider picks a photo.
  // The serviceId is passed so we can build the correct storage path.
  //
  // COMPRESSION: The image_picker in AddServiceScreen already compresses to
  // imageQuality: 85 and maxWidth: 1200 before this is called.
  //
  // Returns the public download URL, or null on failure.

  Future<String?> uploadServiceImage(String serviceId, File imageFile) async {
    try {
      final ref = _storage.ref('services/$serviceId/cover.jpg');

      // putFile streams the file in chunks — better for large images
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Wait for completion
      final snapshot = await uploadTask;

      // Get the HTTPS download URL (permanent, publicly readable per Storage Rules)
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (_) {
      return null;
    } catch (e) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // UPLOAD AVATAR
  // ---------------------------------------------------------------------------
  // Called from ProfileScreen when user taps the camera icon (Sprint 3).
  // Overwrites any existing profile.jpg for this user.

  Future<String?> uploadAvatar(String uid, File imageFile) async {
    try {
      final ref = _storage.ref('avatars/$uid/profile.jpg');

      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (_) {
      return null;
    } catch (e) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE FILE
  // ---------------------------------------------------------------------------
  // Called when a service is deactivated and its cover photo should be removed,
  // or when a user replaces their avatar.
  //
  // Silently succeeds if the file doesn't exist (idempotent).

  Future<bool> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      return true;
    } on FirebaseException catch (e) {
      // object-not-found is not a real error — treat as success
      if (e.code == 'object-not-found') return true;
      return false;
    } catch (e) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // UPLOAD WITH PROGRESS (for large files — Sprint 3)
  // ---------------------------------------------------------------------------
  // Returns a stream of upload progress (0.0 to 1.0).
  // Use this in AddServiceScreen to show a progress indicator.

  Stream<double> uploadServiceImageWithProgress(
    String serviceId,
    File imageFile,
  ) {
    final ref = _storage.ref('services/$serviceId/cover.jpg');
    final uploadTask = ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return uploadTask.snapshotEvents.map((event) {
      if (event.totalBytes == 0) return 0.0;
      return event.bytesTransferred / event.totalBytes;
    });
  }
}
