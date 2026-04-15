// lib/providers/booking_provider.dart
//
// PURPOSE: Manages the state of all bookings in CampusLink.
// Handles both seeker bookings and provider requests in one place.
//
// STATE THIS PROVIDER MANAGES:
//   - Seeker's bookings (services they've booked)
//   - Provider's received requests (people who booked their services)
//   - Currently viewed booking (detail/status screen)
//   - Counts for dashboard stats (pending, active, completed)
//   - Total earnings for provider dashboard
//   - Loading and error states
//
// ROLE-AWARE DESIGN:
//   Seeker:   loads seekerBookings only
//   Provider: loads providerBookings only
//   Both:     loads both streams simultaneously
//
// USAGE IN A SCREEN:
//   final bp = context.watch<BookingProvider>();
//
//   // Seeker
//   bp.seekerBookings        // list of bookings made as seeker
//   bp.activeBookingsCount   // for seeker summary
//
//   // Provider
//   bp.providerBookings      // list of requests received
//   bp.pendingRequestsCount  // for dashboard stat card
//   bp.activeJobsCount       // for dashboard stat card
//   bp.totalEarnings         // for dashboard earnings card

import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../services/firestore_service.dart';

class BookingProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  // ── PRIVATE STATE ──────────────────────────────────────────────────────────
  List<BookingModel> _seekerBookings = [];
  List<BookingModel> _providerBookings = [];
  BookingModel? _selectedBooking;
  bool _isLoading = false;
  bool _isActing = false; // accept/decline/complete
  String? _errorMessage;

  // ── PUBLIC GETTERS ─────────────────────────────────────────────────────────

  List<BookingModel> get seekerBookings => _seekerBookings;
  List<BookingModel> get providerBookings => _providerBookings;
  BookingModel? get selectedBooking => _selectedBooking;
  bool get isLoading => _isLoading;
  bool get isActing => _isActing;
  String? get errorMessage => _errorMessage;

  // ── SEEKER STATS ───────────────────────────────────────────────────────────

  // Active = confirmed or in_progress
  int get activeBookingsCount =>
      _seekerBookings.where((b) => b.isConfirmed || b.isInProgress).length;

  int get completedBookingsCount =>
      _seekerBookings.where((b) => b.isCompleted).length;

  int get pendingBookingsCount =>
      _seekerBookings.where((b) => b.isPending).length;

  // ── PROVIDER STATS ─────────────────────────────────────────────────────────

  // Pending requests waiting for provider to accept or decline
  int get pendingRequestsCount =>
      _providerBookings.where((b) => b.isPending).length;

  // Active jobs = confirmed or in_progress
  int get activeJobsCount =>
      _providerBookings.where((b) => b.isConfirmed || b.isInProgress).length;

  // Total earnings = sum of all completed bookings
  // Only counts released escrow — not pending or in-progress
  double get totalEarnings => _providerBookings
      // .where((b) => b.isCompleted && b.fundsReleased)
      .fold(0.0, (sum, b) => sum + b.totalAmount);

  // Pending requests list — shown on provider dashboard
  List<BookingModel> get pendingRequests =>
      _providerBookings.where((b) => b.isPending).toList()
        ..sort((a, b) => (a.createdAt ?? DateTime.now())
            .compareTo(b.createdAt ?? DateTime.now()));

  // Formatted total earnings for display
  String get formattedEarnings => 'GHS ${totalEarnings.toStringAsFixed(2)}';

  // ── INIT SEEKER BOOKINGS ───────────────────────────────────────────────────
  // Called when BookingsScreen loads for a seeker.
  // Subscribes to real-time stream — updates instantly when booking changes.

  void initSeekerBookings(String seekerUid) {
    _setLoading(true);
    _firestoreService.getBookingsAsSeeker(seekerUid).listen(
      (bookings) {
        _seekerBookings = bookings;
        _setLoading(false);
      },
      onError: (_) {
        _setError('Could not load your bookings.');
        _setLoading(false);
      },
    );
  }

  // ── INIT PROVIDER BOOKINGS ─────────────────────────────────────────────────
  // Called when ProviderDashboard or BookingsScreen (provider tab) loads.

  void initProviderBookings(String providerUid) {
    _firestoreService.getBookingsAsProvider(providerUid).listen(
      (bookings) {
        _providerBookings = bookings;
        notifyListeners();
      },
      onError: (_) {
        _setError('Could not load booking requests.');
      },
    );
  }

  // ── INIT BOTH ──────────────────────────────────────────────────────────────
  // Called for dual-role users — loads both streams simultaneously.

  void initBothBookings(String uid) {
    initSeekerBookings(uid);
    initProviderBookings(uid);
  }

  // ── LOAD SINGLE BOOKING ────────────────────────────────────────────────────
  // Called when navigating to BookingStatusScreen.
  // Real-time stream — escrow status updates appear instantly.

  void loadBookingById(String bookingId) {
    _firestoreService.getBookingById(bookingId).listen(
      (booking) {
        _selectedBooking = booking;
        notifyListeners();
      },
      onError: (_) {
        _setError('Could not load booking details.');
      },
    );
  }

  void setSelectedBooking(BookingModel booking) {
    _selectedBooking = booking;
    notifyListeners();
  }

  // ── CREATE BOOKING ─────────────────────────────────────────────────────────
  // Called from PaymentBottomSheet when seeker confirms booking + payment.
  // Returns the new booking ID on success, null on failure.

  Future<String?> createBooking(BookingModel booking) async {
    _setActing(true);
    _clearError();

    final bookingId = await _firestoreService.createBooking(booking);

    if (bookingId != null) {
      _setActing(false);
      return bookingId;
    } else {
      _setError('Could not create booking. Please try again.');
      _setActing(false);
      return null;
    }
  }

  // ── ACCEPT BOOKING ─────────────────────────────────────────────────────────
  // Provider taps "Accept" on dashboard.
  // Returns true on success.

  Future<bool> acceptBooking(String bookingId) async {
    _setActing(true);
    _clearError();

    final success = await _firestoreService.acceptBooking(bookingId);

    if (!success) {
      _setError('Could not accept booking. Please try again.');
    }

    _setActing(false);
    return success;
  }

  // ── DECLINE BOOKING ────────────────────────────────────────────────────────
  // Provider taps "Decline" — requires a reason.

  Future<bool> declineBooking(String bookingId, String reason) async {
    _setActing(true);
    _clearError();

    final success = await _firestoreService.declineBooking(bookingId, reason);

    if (!success) {
      _setError('Could not decline booking. Please try again.');
    }

    _setActing(false);
    return success;
  }

  // ── MARK AS COMPLETE ───────────────────────────────────────────────────────
  // Seeker taps "Mark as Complete & Release Funds".
  // This triggers the Cloud Function that releases escrow to provider.

  Future<bool> markAsComplete(String bookingId) async {
    _setActing(true);
    _clearError();

    final success = await _firestoreService.markAsComplete(bookingId);

    if (!success) {
      _setError('Could not mark as complete. Please try again.');
    }

    _setActing(false);
    return success;
  }

  // ── RAISE DISPUTE ──────────────────────────────────────────────────────────
  // Seeker raises a dispute — freezes escrow.

  Future<bool> raiseDispute(String bookingId, String reason) async {
    _setActing(true);
    _clearError();

    final success = await _firestoreService.raiseDispute(bookingId, reason);

    if (!success) {
      _setError('Could not raise dispute. Please try again.');
    }

    _setActing(false);
    return success;
  }

  // ── CLEAR SELECTED BOOKING ─────────────────────────────────────────────────
  // Called when navigating away from BookingStatusScreen.

  void clearSelectedBooking() {
    _selectedBooking = null;
    notifyListeners();
  }

  void clearError() => _clearError();

  // ── PRIVATE HELPERS ────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setActing(bool value) {
    _isActing = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
