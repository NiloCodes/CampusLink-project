// lib/services/firestore_service.dart
//
// PURPOSE: The ONLY place in the CampusLink frontend that reads and writes
// to Firestore for services and bookings.
//
// ─────────────────────────────────────────────────────────────────────────────
// TEAM RESPONSIBILITIES
// ─────────────────────────────────────────────────────────────────────────────
//
// FRONTEND (you):
//   - Define function signatures and return types
//   - Write stub implementations so screens compile and run
//   - Call these functions from providers only — never from screens directly
//
// BACKEND — Petronilo & Eric:
//   - Replace every stub marked [PETRONILO & ERIC: IMPLEMENT FROM HERE]
//   - Write Firestore security rules for services and bookings collections
//   - Ensure booking escrowStatus is ONLY updated via Cloud Functions
//   - Never allow client to write escrowStatus directly
//
// SECURITY RULES REMINDER (for Petronilo & Eric):
//   services:
//     - read: any authenticated + verified user
//     - create: authenticated + verified + role contains 'provider'
//     - update/delete: only the providerUid == request.auth.uid
//   bookings:
//     - read: seekerUid == auth.uid OR providerUid == auth.uid
//     - create: authenticated + verified seeker
//     - update bookingStatus: provider only (accept/decline)
//     - update escrowStatus: Cloud Functions ONLY — never client
//
// ─────────────────────────────────────────────────────────────────────────────
//
// ARCHITECTURAL NOTE (for your defense):
// This follows the Repository Pattern. Providers call this service.
// Screens call providers. Nothing in the UI layer touches Firestore directly.
// This means if Firestore is replaced with another database, only this
// file changes — zero UI changes needed.

// import 'package:cloud_firestore/cloud_firestore.dart';
// [PETRONILO & ERIC: uncomment when Firebase is configured]
import '../models/service_model.dart';
import '../models/booking_model.dart';

class FirestoreService {
  // [PETRONILO & ERIC: uncomment when Firebase is configured]
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection name constants — change once here if Firestore renames them
  static const String _servicesCol = 'services';
  static const String _bookingsCol = 'bookings';
  static const String _reviewsCol = 'reviews';

  // ===========================================================================
  // SERVICES — READ
  // ===========================================================================

  // ---------------------------------------------------------------------------
  // GET ALL ACTIVE SERVICES (Home Feed)
  // ---------------------------------------------------------------------------
  // Returns a real-time stream of all active service listings.
  // Used by ServiceProvider to populate the home feed.
  // Real-time means new listings appear instantly without refresh.
  //
  // [PETRONILO & ERIC: IMPLEMENT FROM HERE]
  // Replace stub with:
  // return _firestore
  //     .collection(_servicesCol)
  //     .where('isActive', isEqualTo: true)
  //     .orderBy('createdAt', descending: true)
  //     .snapshots()
  //     .map((snap) => snap.docs
  //         .map((doc) => ServiceModel.fromFirestore(doc))
  //         .toList());

  Stream<List<ServiceModel>> getActiveServices() {
    // STUB — returns hardcoded services for UI development
    return Stream.value(_stubServices);
  }

  // ---------------------------------------------------------------------------
  // GET SERVICES BY CATEGORY
  // ---------------------------------------------------------------------------
  // Filters the home feed by category when user taps a category chip.
  //
  // [PETRONILO & ERIC: IMPLEMENT FROM HERE]
  // return _firestore
  //     .collection(_servicesCol)
  //     .where('isActive', isEqualTo: true)
  //     .where('category', isEqualTo: category.firestoreValue)
  //     .orderBy('createdAt', descending: true)
  //     .snapshots()
  //     .map((snap) => snap.docs
  //         .map((doc) => ServiceModel.fromFirestore(doc))
  //         .toList());

  Stream<List<ServiceModel>> getServicesByCategory(ServiceCategory category) {
    // STUB
    return Stream.value(
      _stubServices.where((s) => s.category == category).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // SEARCH SERVICES
  // ---------------------------------------------------------------------------
  // Basic search by title — used by the search bar on home screen.
  // NOTE: Firestore doesn't support full-text search natively.
  //
  // [PETRONILO & ERIC: for production, integrate Algolia or Typesense.
  // For MVP, use client-side filtering on the already-loaded services list
  // in ServiceProvider — no extra Firestore query needed.]

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
  // Used by ServiceDetailScreen to load a specific service.
  //
  // [PETRONILO & ERIC: IMPLEMENT FROM HERE]
  // final doc = await _firestore
  //     .collection(_servicesCol)
  //     .doc(serviceId)
  //     .get();
  // if (!doc.exists) return null;
  // return ServiceModel.fromFirestore(doc);

  Future<ServiceModel?> getServiceById(String serviceId) async {
    // STUB
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _stubServices.firstWhere((s) => s.serviceId == serviceId);
    } catch (_) {
      return _stubServices.first;
    }
  }

  // ---------------------------------------------------------------------------
  // GET SERVICES BY PROVIDER
  // ---------------------------------------------------------------------------
  // Used by ProviderDashboard to show a provider's own listings.
  //
  // [PETRONILO & ERIC: IMPLEMENT FROM HERE]
  // return _firestore
  //     .collection(_servicesCol)
  //     .where('providerUid', isEqualTo: providerUid)
  //     .snapshots()
  //     .map((snap) => snap.docs
  //         .map((doc) => ServiceModel.fromFirestore(doc))
  //         .toList());

  Stream<List<ServiceModel>> getServicesByProvider(String providerUid) {
    // STUB
    return Stream.value(
      _stubServices.where((s) => s.providerUid == providerUid).toList(),
    );
  }

  // ===========================================================================
  // SERVICES — WRITE
  // ===========================================================================

  // ---------------------------------------------------------------------------
  // CREATE SERVICE
  // ---------------------------------------------------------------------------
  // Called from AddServiceScreen when provider submits a new listing.
  // Returns the new document ID on success.
  //
  // [PETRONILO & ERIC: IMPLEMENT FROM HERE]
  // final ref = await _firestore
  //     .collection(_servicesCol)
  //     .add(service.toFirestore());
  // return ref.id;

  Future<String?> createService(ServiceModel service) async {
    // STUB
    await Future.delayed(const Duration(seconds: 1));
    return 'stub-service-${DateTime.now().millisecondsSinceEpoch}';
  }

  // ---------------------------------------------------------------------------
  // UPDATE SERVICE
  // ---------------------------------------------------------------------------
  // Called when provider edits a listing or toggles isActive.
  //
  // [PETRONILO & ERIC: IMPLEMENT FROM HERE]
  // await _firestore
  //     .collection(_servicesCol)
  //     .doc(serviceId)
  //     .update(updates);

  Future<bool> updateService(
    String serviceId,
    Map<String, dynamic> updates,
  ) async {
    // STUB
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  // ---------------------------------------------------------------------------
  // DELETE SERVICE
  // ---------------------------------------------------------------------------
  // Soft delete — sets isActive to false rather than deleting the document.
  // Preserves booking history that references this service.
  //
  // [PETRONILO & ERIC: IMPLEMENT FROM HERE]
  // await _firestore
  //     .collection(_servicesCol)
  //     .doc(serviceId)
  //     .update({'isActive': false});

  Future<bool> deactivateService(String serviceId) async {
    // STUB
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  // ===========================================================================
  // BOOKINGS — READ
  // ===========================================================================

  // ---------------------------------------------------------------------------
  // GET BOOKINGS AS SEEKER
  // ---------------------------------------------------------------------------
  // Real-time stream of all bookings where current user is the seeker.
  // Used by BookingProvider and BookingsScreen (seeker tab).
  //
  // [PETRONILO & ERIC: IMPLEMENT FROM HERE]
  // return _firestore
  //     .collection(_bookingsCol)
  //     .where('seekerUid', isEqualTo: seekerUid)
  //     .orderBy('createdAt', descending: true)
  //     .snapshots()
  //     .map((snap) => snap.docs
  //         .map((doc) => BookingModel.fromFirestore(doc))
  //         .toList());

  Stream<List<BookingModel>> getBookingsAsSeeker(String seekerUid) {
    // STUB
    return Stream.value(
      _stubBookings.where((b) => b.seekerUid == seekerUid).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // GET BOOKINGS AS PROVIDER
  // ---------------------------------------------------------------------------
  // Real-time stream of all bookings where current user is the provider.
  // Used by BookingProvider and BookingsScreen (provider tab).
  //
  // [PETRONILO & ERIC: IMPLEMENT FROM HERE]
  // return _firestore
  //     .collection(_bookingsCol)
  //     .where('providerUid', isEqualTo: providerUid)
  //     .orderBy('createdAt', descending: true)
  //     .snapshots()
  //     .map((snap) => snap.docs
  //         .map((doc) => BookingModel.fromFirestore(doc))
  //         .toList());

  Stream<List<BookingModel>> getBookingsAsProvider(String providerUid) {
    // STUB
    return Stream.value(
      _stubBookings.where((b) => b.providerUid == providerUid).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // GET SINGLE BOOKING
  // ---------------------------------------------------------------------------
  // Real-time stream for BookingStatusScreen — updates instantly when
  // provider accepts, escrow changes, etc.
  //
  // [PETRONILO & ERIC: IMPLEMENT FROM HERE]
  // return _firestore
  //     .collection(_bookingsCol)
  //     .doc(bookingId)
  //     .snapshots()
  //     .map((doc) => doc.exists
  //         ? BookingModel.fromFirestore(doc)
  //         : null);

  Stream<BookingModel?> getBookingById(String bookingId) {
    // STUB
    try {
      final booking = _stubBookings.firstWhere((b) => b.bookingId == bookingId);
      return Stream.value(booking);
    } catch (_) {
      return Stream.value(_stubBookings.first);
    }
  }

  // ===========================================================================
  // BOOKINGS — WRITE
  // ===========================================================================

  // ---------------------------------------------------------------------------
  // CREATE BOOKING
  // ---------------------------------------------------------------------------
  // Called when seeker confirms booking on ServiceDetailScreen.
  // Creates the booking document with escrowStatus = 'awaiting_payment'.
  // Payment is handled separately via Paystack.
  //
  // [PETRONILO & ERIC: IMPLEMENT FROM HERE]
  // final ref = await _firestore
  //     .collection(_bookingsCol)
  //     .add(booking.toFirestore());
  // return ref.id;

  Future<String?> createBooking(BookingModel booking) async {
    // STUB
    await Future.delayed(const Duration(seconds: 1));
    return 'stub-booking-${DateTime.now().millisecondsSinceEpoch}';
  }

  // ---------------------------------------------------------------------------
  // ACCEPT BOOKING (Provider action)
  // ---------------------------------------------------------------------------
  // Provider taps "Accept" on ProviderDashboard.
  // Updates bookingStatus to 'confirmed'.
  //
  // [PETRONILO & ERIC: IMPLEMENT FROM HERE]
  // await _firestore
  //     .collection(_bookingsCol)
  //     .doc(bookingId)
  //     .update({
  //   'bookingStatus': 'confirmed',
  //   'updatedAt': FieldValue.serverTimestamp(),
  // });

  Future<bool> acceptBooking(String bookingId) async {
    // STUB
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  // ---------------------------------------------------------------------------
  // DECLINE BOOKING (Provider action)
  // ---------------------------------------------------------------------------
  // Provider taps "Decline" — booking is cancelled, no funds moved.
  //
  // [PETRONILO & ERIC: IMPLEMENT FROM HERE]
  // await _firestore
  //     .collection(_bookingsCol)
  //     .doc(bookingId)
  //     .update({
  //   'bookingStatus': 'cancelled',
  //   'declineReason': reason,
  //   'updatedAt': FieldValue.serverTimestamp(),
  // });

  Future<bool> declineBooking(String bookingId, String reason) async {
    // STUB
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  // ---------------------------------------------------------------------------
  // MARK AS COMPLETE (Seeker action)
  // ---------------------------------------------------------------------------
  // Seeker taps "Mark as Complete & Release Funds".
  // Updates bookingStatus to 'completed'.
  // IMPORTANT: escrowStatus is updated to 'released' by a Cloud Function
  // that triggers on this status change — NOT by the client directly.
  //
  // [PETRONILO & ERIC: IMPLEMENT FROM HERE]
  // Step 1 (client): update bookingStatus to 'completed'
  // Step 2 (Cloud Function): watch for bookingStatus == 'completed'
  //   → call Paystack to release funds to provider
  //   → update escrowStatus to 'released'
  //
  // await _firestore
  //     .collection(_bookingsCol)
  //     .doc(bookingId)
  //     .update({
  //   'bookingStatus': 'completed',
  //   'updatedAt': FieldValue.serverTimestamp(),
  // });

  Future<bool> markAsComplete(String bookingId) async {
    // STUB
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  // ---------------------------------------------------------------------------
  // RAISE DISPUTE
  // ---------------------------------------------------------------------------
  // Seeker raises a dispute — freezes escrow until resolved.
  // Cloud Function watches for this and freezes the Paystack transfer.
  //
  // [PETRONILO & ERIC: IMPLEMENT FROM HERE]
  // await _firestore
  //     .collection(_bookingsCol)
  //     .doc(bookingId)
  //     .update({
  //   'escrowStatus': 'disputed',
  //   'disputeReason': reason,
  //   'updatedAt': FieldValue.serverTimestamp(),
  // });

  Future<bool> raiseDispute(String bookingId, String reason) async {
    // STUB
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  // ===========================================================================
  // STUB DATA
  // ===========================================================================
  // Realistic sample data for UI development.
  // Remove entirely once Petronilo & Eric connect real Firestore.
  // Uses real category values, realistic GHS prices, and UCC-style names.

  static final List<ServiceModel> _stubServices = [
    ServiceModel(
      serviceId: 'service-001',
      providerUid: 'provider-uid-001',
      providerName: 'Derrick Mensah',
      isVerified: true,
      title: 'Advanced Calculus Tutoring & Exam Prep',
      description: 'I offer personalised one-on-one tutoring for '
          'Calculus 1, 2, and 3. Past exam questions covered. '
          'Sessions held in the library or online via Google Meet.',
      category: ServiceCategory.academicsTutoring,
      tags: ['calculus', 'maths', 'tutoring', 'exam'],
      basePrice: 50,
      isPriceNegotiable: true,
      rating: 4.8,
      reviewCount: 24,
      providerPhone: '0241234567',
      providerWhatsapp: '0241234567',
      providerInstagram: 'derrick.tutors',
    ),
    ServiceModel(
      serviceId: 'service-002',
      providerUid: 'provider-uid-002',
      providerName: 'Abena Boateng',
      isVerified: true,
      title: 'iPhone & Android Screen Replacement',
      description: 'Quick and reliable screen replacement for all major '
          'mobile brands. High-quality parts and 30-day warranty. '
          'Most repairs done within 2 hours on campus.',
      category: ServiceCategory.techDigital,
      tags: ['phone', 'repair', 'screen', 'iphone', 'android'],
      basePrice: 120,
      isPriceNegotiable: false,
      rating: 4.9,
      reviewCount: 12,
      providerPhone: '0557654321',
      providerWhatsapp: '0557654321',
      providerInstagram: 'abena.repairs',
      providerSnapchat: 'abena_fix',
    ),
    ServiceModel(
      serviceId: 'service-003',
      providerUid: 'provider-uid-003',
      providerName: 'Sarah Quansah',
      isVerified: true,
      title: 'Professional Makeup Artist for Events',
      description: 'Bridal, graduation, and event makeup. '
          'I use high-quality products suitable for all skin tones. '
          'Home service available on campus.',
      category: ServiceCategory.beautyPersonalCare,
      tags: ['makeup', 'beauty', 'events', 'graduation'],
      basePrice: 80,
      isPriceNegotiable: true,
      rating: 4.7,
      reviewCount: 31,
      providerPhone: '0201122334',
      providerWhatsapp: '0201122334',
      providerInstagram: 'sarah.glam',
    ),
    ServiceModel(
      serviceId: 'service-004',
      providerUid: 'provider-uid-004',
      providerName: 'Kofi Acheampong',
      isVerified: true,
      title: 'Event Photography — Graduation & Campus Events',
      description: 'Professional photography for your graduation, '
          'departmental events, and portraits. '
          'Edited photos delivered within 48 hours.',
      category: ServiceCategory.eventsEntertainment,
      tags: ['photography', 'graduation', 'events', 'portraits'],
      basePrice: 200,
      isPriceNegotiable: true,
      rating: 4.6,
      reviewCount: 8,
      providerPhone: '0269988776',
      providerInstagram: 'kofi.lens',
    ),
    ServiceModel(
      serviceId: 'service-005',
      providerUid: 'provider-uid-005',
      providerName: 'Ama Sarpong',
      isVerified: true,
      title: 'Homemade Shito & Ghanaian Snacks Delivery',
      description: 'Fresh homemade shito, kelewele, and local snacks. '
          'Delivered to your hostel or department. '
          'Orders placed before 12pm delivered same day.',
      category: ServiceCategory.foodCulinary,
      tags: ['food', 'shito', 'snacks', 'delivery', 'kelewele'],
      basePrice: 25,
      isPriceNegotiable: false,
      rating: 4.9,
      reviewCount: 47,
      providerPhone: '0244556677',
      providerWhatsapp: '0244556677',
    ),
    ServiceModel(
      serviceId: 'service-006',
      providerUid: 'provider-uid-006',
      providerName: 'Emmanuel Asante',
      isVerified: true,
      title: 'Custom Department Branded Merch & Tailoring',
      description: 'Custom T-shirts, hoodies, and branded items '
          'for your department or group. '
          'Also offer general tailoring and alterations.',
      category: ServiceCategory.fashionApparel,
      tags: ['fashion', 'tailoring', 'merch', 'custom', 'branded'],
      basePrice: 60,
      isPriceNegotiable: true,
      rating: 4.5,
      reviewCount: 15,
      providerPhone: '0277889900',
      providerWhatsapp: '0277889900',
      providerInstagram: 'emma.stitch',
    ),
    ServiceModel(
      serviceId: 'service-007',
      providerUid: 'provider-uid-007',
      providerName: 'Nana Yaw Frimpong',
      isVerified: true,
      title: 'Laundry & Ironing Service — Campus Pickup',
      description: 'Drop off your laundry and get it back clean '
          'and ironed within 24 hours. '
          'Pickup and delivery within campus.',
      category: ServiceCategory.errandsLogistics,
      tags: ['laundry', 'ironing', 'errands', 'pickup'],
      basePrice: 30,
      isPriceNegotiable: false,
      rating: 4.4,
      reviewCount: 22,
      providerPhone: '0233445566',
      providerWhatsapp: '0233445566',
    ),
  ];

  static final List<BookingModel> _stubBookings = [
    BookingModel(
      bookingId: 'booking-001',
      seekerUid: 'stub-uid-001',
      seekerName: 'Kwesi Asante',
      providerUid: 'provider-uid-002',
      providerName: 'Abena Boateng',
      serviceId: 'service-002',
      serviceTitle: 'iPhone & Android Screen Replacement',
      totalAmount: 126.0,
      bookingStatus: BookingStatus.inProgress,
      escrowStatus: EscrowStatus.held,
      paymentRef: 'PAY-REF-001',
      notes: 'iPhone 13 Pro Max screen cracked on both sides.',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    BookingModel(
      bookingId: 'booking-002',
      seekerUid: 'stub-uid-001',
      seekerName: 'Kwesi Asante',
      providerUid: 'provider-uid-001',
      providerName: 'Derrick Mensah',
      serviceId: 'service-001',
      serviceTitle: 'Advanced Calculus Tutoring & Exam Prep',
      totalAmount: 52.5,
      bookingStatus: BookingStatus.pending,
      escrowStatus: EscrowStatus.awaitingPayment,
      notes: 'Need help with integration techniques before finals.',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    BookingModel(
      bookingId: 'booking-003',
      seekerUid: 'other-uid-001',
      seekerName: 'Sarah Mensah',
      providerUid: 'stub-uid-001',
      providerName: 'Kwesi Asante',
      serviceId: 'service-001',
      serviceTitle: 'Advanced Calculus Tutoring & Exam Prep',
      totalAmount: 50.0,
      bookingStatus: BookingStatus.pending,
      escrowStatus: EscrowStatus.awaitingPayment,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    BookingModel(
      bookingId: 'booking-004',
      seekerUid: 'other-uid-002',
      seekerName: 'Kwesi Arthur',
      providerUid: 'stub-uid-001',
      providerName: 'Kwesi Asante',
      serviceId: 'service-001',
      serviceTitle: 'Advanced Calculus Tutoring & Exam Prep',
      totalAmount: 75.0,
      bookingStatus: BookingStatus.confirmed,
      escrowStatus: EscrowStatus.held,
      paymentRef: 'PAY-REF-004',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];
}
