// lib/providers/service_provider.dart
//
// PURPOSE: Manages the state of service listings across CampusLink.
// Sits between firestore_service.dart (data) and screens (UI).
//
// STATE THIS PROVIDER MANAGES:
//   - Full list of active services (home feed)
//   - Currently selected category filter
//   - Current search query
//   - Filtered/searched results
//   - Currently viewed service (detail screen)
//   - Provider's own listings (dashboard)
//   - Loading and error states
//
// USAGE IN A SCREEN:
//   // Read state:
//   final sp = context.watch<ServiceProvider>();
//   sp.filteredServices  // the list to show in home feed
//   sp.isLoading         // show shimmer loading
//   sp.errorMessage      // show error banner
//
//   // Call actions:
//   context.read<ServiceProvider>().selectCategory(ServiceCategory.techDigital);
//   context.read<ServiceProvider>().search('calculus');
//   context.read<ServiceProvider>().loadServiceById('service-001');

import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'dart:io';

class ServiceProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  // ── PRIVATE STATE ──────────────────────────────────────────────────────────
  List<ServiceModel> _allServices = [];
  List<ServiceModel> _providerServices = [];
  ServiceModel? _selectedService;
  ServiceCategory? _selectedCategory; // null = show all
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isSubmitting = false; // for create/update actions
  String? _errorMessage;

  // ── PUBLIC GETTERS ─────────────────────────────────────────────────────────

  List<ServiceModel> get allServices => _allServices;
  List<ServiceModel> get providerServices => _providerServices;
  ServiceModel? get selectedService => _selectedService;
  ServiceCategory? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  // The filtered + searched list — what the home feed actually displays
  // Applies both category filter AND search query simultaneously
  List<ServiceModel> get filteredServices {
    List<ServiceModel> result = _allServices;

    // Apply category filter if one is selected
    if (_selectedCategory != null) {
      result = result.where((s) => s.category == _selectedCategory).toList();
    }

    // Apply search query if one exists
    if (_searchQuery.trim().isNotEmpty) {
      result = _firestoreService.searchServices(result, _searchQuery);
    }

    return result;
  }

  // Featured services — top 5 by rating for the "Featured for You" section
  List<ServiceModel> get featuredServices {
    final sorted = List<ServiceModel>.from(_allServices)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(5).toList();
  }

  // True when search is active or a category is selected
  bool get isFiltering =>
      _selectedCategory != null || _searchQuery.trim().isNotEmpty;

  // Count of filtered results — shown in search results header
  int get filteredCount => filteredServices.length;

  // ── INITIALISE FEED ────────────────────────────────────────────────────────
  // Called once when the app navigates to HomeScreen.
  // Subscribes to the real-time Firestore stream.

  void initFeed() {
    _setLoading(true);
    _firestoreService.getActiveServices().listen(
      (services) {
        _allServices = services;
        _setLoading(false);
      },
      onError: (e) {
        _setError('Could not load services. Pull down to refresh.');
        _setLoading(false);
      },
    );
  }

  // ── LOAD PROVIDER SERVICES ─────────────────────────────────────────────────
  // Called when ProviderDashboard loads — shows the provider's own listings.

  void loadProviderServices(String providerUid) {
    _firestoreService.getServicesByProvider(providerUid).listen(
      (services) {
        _providerServices = services;
        notifyListeners();
      },
      onError: (_) {
        _setError('Could not load your services.');
      },
    );
  }

  // ── LOAD SINGLE SERVICE ────────────────────────────────────────────────────
  // Called when user taps "View Details" — loads the ServiceDetailScreen.

  Future<void> loadServiceById(String serviceId) async {
    _setLoading(true);
    _clearError();
    final service = await _firestoreService.getServiceById(serviceId);
    if (service != null) {
      _selectedService = service;
    } else {
      _setError('Service not found.');
    }
    _setLoading(false);
  }

  // Set selected service directly if already loaded (avoids extra fetch)
  void setSelectedService(ServiceModel service) {
    _selectedService = service;
    notifyListeners();
  }

  // ── CATEGORY FILTER ────────────────────────────────────────────────────────
  // Called when user taps a category chip on HomeScreen.

  void selectCategory(ServiceCategory? category) {
    // If same category tapped again — deselect (show all)
    if (_selectedCategory == category) {
      _selectedCategory = null;
    } else {
      _selectedCategory = category;
    }
    notifyListeners();
  }

  void clearCategoryFilter() {
    _selectedCategory = null;
    notifyListeners();
  }

  // ── SEARCH ─────────────────────────────────────────────────────────────────
  // Called on every keystroke in the search bar.
  // Client-side filtering — no extra Firestore query needed.

  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  void clearAllFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    notifyListeners();
  }

  // ── CREATE SERVICE ─────────────────────────────────────────────────────────
  // Called from AddServiceScreen when provider submits a new listing.
  // Handles image upload first, then creates the Firestore document.
  //
  // Returns true on success, false on failure.

  Future<bool> createService({
    required ServiceModel service,
    File? imageFile,
  }) async {
    _setSubmitting(true);
    _clearError();

    try {
      String? imageUrl;

      // Step 1: Upload image if provided
      if (imageFile != null) {
        imageUrl = await _storageService.uploadServiceImage(
          'temp-${DateTime.now().millisecondsSinceEpoch}',
          imageFile,
        );
      }

      // Step 2: Create service with image URL
      final serviceWithImage =
          imageUrl != null ? service.copyWith(imageUrl: imageUrl) : service;

      final serviceId = await _firestoreService.createService(serviceWithImage);

      if (serviceId != null) {
        _setSubmitting(false);
        return true;
      } else {
        _setError('Could not create service. Please try again.');
        _setSubmitting(false);
        return false;
      }
    } catch (e) {
      _setError('Something went wrong. Please try again.');
      _setSubmitting(false);
      return false;
    }
  }

  // ── UPDATE SERVICE ─────────────────────────────────────────────────────────
  // Called from EditServiceScreen (sprint 3) or when toggling isActive.

  Future<bool> toggleServiceActive(String serviceId, bool isActive) async {
    _setSubmitting(true);
    final success = await _firestoreService.updateService(
      serviceId,
      {'isActive': isActive},
    );
    _setSubmitting(false);
    return success;
  }

  // ── DELETE SERVICE ─────────────────────────────────────────────────────────
  // Soft delete — sets isActive to false.

  Future<bool> deactivateService(String serviceId) async {
    _setSubmitting(true);
    final success = await _firestoreService.deactivateService(serviceId);
    _setSubmitting(false);
    return success;
  }

  // ── PRIVATE HELPERS ────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setSubmitting(bool value) {
    _isSubmitting = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() => _clearError();
}
