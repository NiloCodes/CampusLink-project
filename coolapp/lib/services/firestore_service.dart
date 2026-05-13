// lib/services/firestore_service.dart
//
// ✅ PRODUCTION IMPLEMENTATION — All stubs replaced with real Firestore calls
//
// ARCHITECTURE REMINDER:
//   Screens → Providers → FirestoreService → Firestore
//   Nothing in the UI layer touches Firestore directly.
//
// SECURITY NOTE ON ESCROW:
//   The client can ONLY write bookingStatus (accept/decline/complete).
//   escrowStatus is written ONLY by Cloud Functions.
//   Firestore Security Rules enforce this — see firestore.rules.
//
// INDEXES REQUIRED (create in Firebase Console → Firestore → Indexes):
//   Collection: bookings
//     Field 1: seekerUid  (Ascending)
//     Field 2: createdAt  (Descending)
//   Collection: bookings
//     Field 1: providerUid (Ascending)
//     Field 2: createdAt   (Descending)
//   Collection: services
//     Field 1: isActive   (Ascending)
//     Field 2: createdAt  (Descending)
//   Collection: services
//     Field 1: providerUid (Ascending)
//     Field 2: createdAt   (Descending)
//   Collection: services
//     Field 1: isActive    (Ascending)
//     Field 2: category    (Ascending)
//     Field 3: createdAt   (Descending)

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_model.dart';
import '../models/booking_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection constants
  static const String _servicesCol = 'services';
  static const String _bookingsCol = 'bookings';

  // ===========================================================================
  // SERVICES — READ
  // ===========================================================================

  // ---------------------------------------------------------------------------
  // GET ALL ACTIVE SERVICES (Home Feed)
  // ---------------------------------------------------------------------------
  // Real-time stream — new listings appear instantly.
  // Ordered by createdAt descending so newest services appear first.

  Stream<List<ServiceModel>> getActiveServices() {
    return _firestore
        .collection(_servicesCol)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => ServiceModel.fromFirestore(doc)).toList());
  }

  // ---------------------------------------------------------------------------
  // GET SERVICES BY CATEGORY
  // ---------------------------------------------------------------------------
  // Note: Still a real-time stream so new services in the category appear live.
  // Requires composite index: isActive + category + createdAt

  Stream<List<ServiceModel>> getServicesByCategory(ServiceCategory category) {
    return _firestore
        .collection(_servicesCol)
        .where('isActive', isEqualTo: true)
        .where('category', isEqualTo: category.firestoreValue)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => ServiceModel.fromFirestore(doc)).toList());
  }

  // ---------------------------------------------------------------------------
  // SEARCH SERVICES (client-side)
  // ---------------------------------------------------------------------------
  // Firestore does not support native full-text search.
  // For MVP we filter the already-loaded list in memory.
  // For production: integrate Algolia or Typesense via a Cloud Function.

  List<ServiceModel> searchServices(
    List<ServiceModel> allServices,
    String query,
  ) {
    if (query.trim().isEmpty) return allServices;
    final q = query.toLowerCase();
    return allServices.where((s) {
      return s.title.toLowerCase().contains(q) ||
          s.description.toLowerCase().contains(q) ||
          s.providerName.toLowerCase().contains(q) ||
          s.tags.any((tag) => tag.toLowerCase().contains(q)) ||
          s.category.displayName.toLowerCase().contains(q);
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // GET SINGLE SERVICE BY ID
  // ---------------------------------------------------------------------------
  // One-time fetch (not real-time) — used by ServiceDetailScreen.

  Future<ServiceModel?> getServiceById(String serviceId) async {
    try {
      final doc =
          await _firestore.collection(_servicesCol).doc(serviceId).get();

      if (!doc.exists || doc.data() == null) return null;
      return ServiceModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // GET SERVICES BY PROVIDER
  // ---------------------------------------------------------------------------
  // Real-time stream — ProviderDashboard updates when a service is added/toggled.

  Stream<List<ServiceModel>> getServicesByProvider(String providerUid) {
    return _firestore
        .collection(_servicesCol)
        .where('providerUid', isEqualTo: providerUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => ServiceModel.fromFirestore(doc)).toList());
  }

  // ===========================================================================
  // SERVICES — WRITE
  // ===========================================================================

  // ---------------------------------------------------------------------------
  // CREATE SERVICE
  // ---------------------------------------------------------------------------
  // Returns the auto-generated Firestore document ID, or null on failure.
  // Called from ServiceProvider.createService() after image upload.

  Future<String?> createService(ServiceModel service) async {
    try {
      final ref =
          await _firestore.collection(_servicesCol).add(service.toFirestore());
      return ref.id;
    } catch (e) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // UPDATE SERVICE
  // ---------------------------------------------------------------------------
  // Generic update — used for isActive toggling and future edit screens.

  Future<bool> updateService(
    String serviceId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection(_servicesCol).doc(serviceId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // DEACTIVATE SERVICE (soft delete)
  // ---------------------------------------------------------------------------
  // Sets isActive: false so the listing disappears from the feed.
  // Document is preserved to maintain booking history integrity.

  Future<bool> deactivateService(String serviceId) async {
    return updateService(serviceId, {'isActive': false});
  }

  // ===========================================================================
  // BOOKINGS — READ
  // ===========================================================================

  // ---------------------------------------------------------------------------
  // GET BOOKINGS AS SEEKER
  // ---------------------------------------------------------------------------
  // Real-time stream — BookingsScreen (seeker tab) updates instantly when
  // a provider accepts or the escrow state changes.

  Stream<List<BookingModel>> getBookingsAsSeeker(String seekerUid) {
    return _firestore
        .collection(_bookingsCol)
        .where('seekerUid', isEqualTo: seekerUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => BookingModel.fromFirestore(doc)).toList());
  }

  // ---------------------------------------------------------------------------
  // GET BOOKINGS AS PROVIDER
  // ---------------------------------------------------------------------------
  // Real-time stream — ProviderDashboard updates when new requests arrive.

  Stream<List<BookingModel>> getBookingsAsProvider(String providerUid) {
    return _firestore
        .collection(_bookingsCol)
        .where('providerUid', isEqualTo: providerUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => BookingModel.fromFirestore(doc)).toList());
  }

  // ---------------------------------------------------------------------------
  // GET SINGLE BOOKING (real-time)
  // ---------------------------------------------------------------------------
  // BookingStatusScreen subscribes to this stream so escrow status changes
  // (triggered by Cloud Functions) are reflected immediately in the UI.

  Stream<BookingModel?> getBookingById(String bookingId) {
    return _firestore
        .collection(_bookingsCol)
        .doc(bookingId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return BookingModel.fromFirestore(doc);
    });
  }

  // ===========================================================================
  // BOOKINGS — WRITE
  // ===========================================================================

  // ---------------------------------------------------------------------------
  // CREATE BOOKING
  // ---------------------------------------------------------------------------
  // Called when seeker confirms in PaymentBottomSheet.
  // Sets initial escrowStatus = 'awaitingPayment'.
  //
  // PAYMENT FLOW (after this call):
  //   1. Client calls Paystack initialize API (via Cloud Function)
  //   2. Paystack redirects user to MoMo prompt
  //   3. Paystack webhook fires → Cloud Function updates escrowStatus to 'held'
  //   4. Provider sees the booking appear in their dashboard
  //
  // Returns the new booking ID, or null on failure.

  Future<String?> createBooking(BookingModel booking) async {
    try {
      final ref =
          await _firestore.collection(_bookingsCol).add(booking.toFirestore());
      return ref.id;
    } catch (e) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // ACCEPT BOOKING (Provider action)
  // ---------------------------------------------------------------------------
  // Updates bookingStatus to 'confirmed'.
  // The Cloud Function watching for 'confirmed' sends a push notification
  // to the seeker.
  //
  // CLIENT WRITES: bookingStatus only
  // CLOUD FUNCTION WRITES: escrowStatus (never the client)

  Future<bool> acceptBooking(String bookingId) async {
    try {
      await _firestore.collection(_bookingsCol).doc(bookingId).update({
        'bookingStatus': 'confirmed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // DECLINE BOOKING (Provider action)
  // ---------------------------------------------------------------------------
  // Sets bookingStatus to 'cancelled' and records the reason.
  // The Cloud Function watching for 'cancelled' triggers a Paystack refund
  // if funds were already held in escrow.

  Future<bool> declineBooking(String bookingId, String reason) async {
    try {
      await _firestore.collection(_bookingsCol).doc(bookingId).update({
        'bookingStatus': 'cancelled',
        'declineReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // MARK AS IN PROGRESS (Provider action)
  // ---------------------------------------------------------------------------
  // Provider taps "Mark as Started" on BookingStatusScreen.
  // Updates bookingStatus to 'inProgress'.

  Future<bool> markAsInProgress(String bookingId) async {
    try {
      await _firestore.collection(_bookingsCol).doc(bookingId).update({
        'bookingStatus': 'inProgress',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // MARK AS COMPLETE (Seeker action)
  // ---------------------------------------------------------------------------
  // Seeker taps "Mark as Complete & Release Funds".
  //
  // CLIENT WRITES: bookingStatus = 'completed'
  //
  // CLOUD FUNCTION THEN:
  //   1. Detects bookingStatus == 'completed'
  //   2. Calls Paystack Transfer API to release funds to provider's MoMo
  //   3. Updates escrowStatus = 'released'
  //   4. Sends push notifications to both parties
  //
  // The client NEVER writes escrowStatus = 'released' directly.

  Future<bool> markAsComplete(String bookingId) async {
    try {
      await _firestore.collection(_bookingsCol).doc(bookingId).update({
        'bookingStatus': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // RAISE DISPUTE (Seeker action)
  // ---------------------------------------------------------------------------
  // Seeker raises a dispute — freezes escrow.
  //
  // CLIENT WRITES: escrowStatus = 'disputed', disputeReason
  //
  // NOTE: This is the ONE case where the client writes escrowStatus directly.
  // The Cloud Function watching for 'disputed' freezes the Paystack transfer
  // and notifies the admin team.
  //
  // Security Rule allows this write ONLY if:
  //   request.auth.uid == resource.data.seekerUid
  //   AND resource.data.escrowStatus == 'held'   (can't dispute unpaid bookings)

  Future<bool> raiseDispute(String bookingId, String reason) async {
    try {
      await _firestore.collection(_bookingsCol).doc(bookingId).update({
        'escrowStatus': 'disputed',
        'disputeReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
