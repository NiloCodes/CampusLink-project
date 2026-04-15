// lib/models/booking_model.dart
//
// PURPOSE: Represents a CampusLink booking in memory (Dart side).
// Mirrors the Firestore 'bookings' collection exactly.
//
// ─────────────────────────────────────────────────────────────────────────────
// TEAM AGREEMENT — PETRONILO & ERIC
// ─────────────────────────────────────────────────────────────────────────────
// The escrowStatus field is the most critical field in the entire app.
// It must be updated ONLY by Cloud Functions — never directly by the client.
// Client code reads it to display UI state. Cloud Functions write it.
//
// FIRESTORE DOCUMENT STRUCTURE (bookings collection):
// {
//   bookingId:      "auto-generated",
//   seekerUid:      "firebase-auth-uid",
//   seekerName:     "Kwesi Asante",
//   providerUid:    "firebase-auth-uid",
//   providerName:   "Derrick Mensah",
//   serviceId:      "service-doc-id",
//   serviceTitle:   "Advanced Calculus Tutoring",
//   totalAmount:    50.0,
//   bookingStatus:  "pending" | "confirmed" | "inProgress" | "completed" | "cancelled",
//   escrowStatus:   "awaitingPayment" | "held" | "released" | "disputed" | "refunded",
//   paymentRef:     "paystack-reference-id",
//   notes:          "optional seeker notes",
//   declineReason:  "optional decline reason",
//   disputeReason:  "optional dispute reason",
//   createdAt:      Timestamp,
//   updatedAt:      Timestamp,
// }
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

// =============================================================================
// BOOKING STATUS ENUM
// =============================================================================
// Defines the lifecycle of the service itself

enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
}

// =============================================================================
// ESCROW STATUS ENUM
// =============================================================================
// Defines the lifecycle of the money in the Paystack escrow
// [PETRONILO & ERIC: ONLY Cloud Functions should write this field]

enum EscrowStatus {
  awaitingPayment,
  held,
  released,
  disputed,
  refunded,
}

// =============================================================================
// BOOKING MODEL
// =============================================================================

class BookingModel {
  final String bookingId;
  final String seekerUid;
  final String seekerName;
  final String providerUid;
  final String providerName;
  final String serviceId;
  final String serviceTitle;
  final double totalAmount;
  final BookingStatus bookingStatus;
  final EscrowStatus escrowStatus;
  final String? paymentRef;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? declineReason;
  final String? disputeReason;

  const BookingModel({
    required this.bookingId,
    required this.seekerUid,
    required this.seekerName,
    required this.providerUid,
    required this.providerName,
    required this.serviceId,
    required this.serviceTitle,
    required this.totalAmount,
    required this.bookingStatus,
    required this.escrowStatus,
    this.paymentRef,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.declineReason,
    this.disputeReason,
  });

  // ===========================================================================
  // CONVENIENCE GETTERS — BOOKING STATUS
  // ===========================================================================

  bool get isPending => bookingStatus == BookingStatus.pending;
  bool get isConfirmed => bookingStatus == BookingStatus.confirmed;
  bool get isInProgress => bookingStatus == BookingStatus.inProgress;
  bool get isCompleted => bookingStatus == BookingStatus.completed;
  bool get isCancelled => bookingStatus == BookingStatus.cancelled;

  // ===========================================================================
  // CONVENIENCE GETTERS — ESCROW STATUS
  // ===========================================================================

  bool get fundsHeld => escrowStatus == EscrowStatus.held;
  bool get fundsReleased => escrowStatus == EscrowStatus.released;
  bool get isDisputed => escrowStatus == EscrowStatus.disputed;
  bool get isRefunded => escrowStatus == EscrowStatus.refunded;

  // ===========================================================================
  // FORMATTED HELPERS
  // ===========================================================================

  String get formattedAmount => 'GHS ${totalAmount.toStringAsFixed(2)}';

  // ===========================================================================
  // COPY WITH
  // ===========================================================================

  BookingModel copyWith({
    BookingStatus? bookingStatus,
    EscrowStatus? escrowStatus,
    String? paymentRef,
    String? notes,
    String? declineReason,
    String? disputeReason,
  }) {
    return BookingModel(
      bookingId: bookingId,
      seekerUid: seekerUid,
      seekerName: seekerName,
      providerUid: providerUid,
      providerName: providerName,
      serviceId: serviceId,
      serviceTitle: serviceTitle,
      totalAmount: totalAmount,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      escrowStatus: escrowStatus ?? this.escrowStatus,
      paymentRef: paymentRef ?? this.paymentRef,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      declineReason: declineReason ?? this.declineReason,
      disputeReason: disputeReason ?? this.disputeReason,
    );
  }

  // ===========================================================================
  // FIRESTORE SERIALIZATION
  // ===========================================================================

  // [PETRONILO & ERIC: confirm field names match Firestore exactly]
  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      bookingId: doc.id,
      seekerUid: data['seekerUid'] ?? '',
      seekerName: data['seekerName'] ?? '',
      providerUid: data['providerUid'] ?? '',
      providerName: data['providerName'] ?? '',
      serviceId: data['serviceId'] ?? '',
      serviceTitle: data['serviceTitle'] ?? '',
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),

      // Convert String from Firestore back to Enum using .name
      bookingStatus: BookingStatus.values.firstWhere(
        (e) => e.name == data['bookingStatus'],
        orElse: () => BookingStatus.pending,
      ),
      escrowStatus: EscrowStatus.values.firstWhere(
        (e) => e.name == data['escrowStatus'],
        orElse: () => EscrowStatus.awaitingPayment,
      ),

      paymentRef: data['paymentRef'],
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      declineReason: data['declineReason'],
      disputeReason: data['disputeReason'],
    );
  }

  // [PETRONILO & ERIC: used when creating a new booking document]
  Map<String, dynamic> toFirestore() {
    return {
      'seekerUid': seekerUid,
      'seekerName': seekerName,
      'providerUid': providerUid,
      'providerName': providerName,
      'serviceId': serviceId,
      'serviceTitle': serviceTitle,
      'totalAmount': totalAmount,
      'bookingStatus': bookingStatus.name, // stored as string e.g. "pending"
      'escrowStatus': escrowStatus.name, // stored as string e.g. "held"
      'paymentRef': paymentRef,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'declineReason': declineReason,
      'disputeReason': disputeReason,
    };
  }
}
