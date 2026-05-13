// lib/models/service_model.dart
//
// PURPOSE: Represents a CampusLink service listing in memory (Dart side).
// Mirrors the Firestore 'services' collection exactly.
//
// UPDATES FROM V1:
//   - Added provider contact fields (phone, whatsapp, instagram, snapchat)
//   - Added isPriceNegotiable toggle
//   - Added tags list for search
//
// ─────────────────────────────────────────────────────────────────────────────
// TEAM AGREEMENT — PETRONILO & ERIC
// ─────────────────────────────────────────────────────────────────────────────
// Field names here MUST match Firestore document field names exactly.
//
// FIRESTORE DOCUMENT STRUCTURE (services collection):
// {
//   serviceId:          "auto-generated",
//   providerUid:        "firebase-auth-uid",
//   providerName:       "Abena Boateng",
//   providerAvatarUrl:  "https://firebasestorage...",
//   isVerified:         true,
//   title:              "Professional iPhone Screen Replacement",
//   description:        "Quick and reliable...",
//   category:           "tech_digital",
//   basePrice:          120.0,
//   isPriceNegotiable:  true,
//   imageUrl:           "https://firebasestorage...",
//   rating:             4.9,
//   reviewCount:        12,
//   isActive:           true,
//   tags:               ["repair", "phone", "screen"],
//   providerPhone:      "0241234567",
//   providerWhatsapp:   "https://wa.me/233241234567",
//   providerInstagram:  "abena.repairs",
//   providerSnapchat:   "abena_snap",
//   createdAt:          Timestamp,
// }
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// =============================================================================
// SERVICE CATEGORY ENUM
// =============================================================================

enum ServiceCategory {
  techDigital,
  academicsTutoring,
  foodCulinary,
  beautyPersonalCare,
  eventsEntertainment,
  fashionApparel,
  errandsLogistics,
}

extension ServiceCategoryExtension on ServiceCategory {
  // Short label — shown under category chips on home screen
  String get displayName {
    switch (this) {
      case ServiceCategory.techDigital:
        return 'Tech & Digital';
      case ServiceCategory.academicsTutoring:
        return 'Tutoring';
      case ServiceCategory.foodCulinary:
        return 'Food & Culinary';
      case ServiceCategory.beautyPersonalCare:
        return 'Beauty';
      case ServiceCategory.eventsEntertainment:
        return 'Events';
      case ServiceCategory.fashionApparel:
        return 'Fashion';
      case ServiceCategory.errandsLogistics:
        return 'Errands';
    }
  }

  // Full label — shown in category filter bottom sheet
  String get fullDisplayName {
    switch (this) {
      case ServiceCategory.techDigital:
        return 'Tech & Digital';
      case ServiceCategory.academicsTutoring:
        return 'Academics & Tutoring';
      case ServiceCategory.foodCulinary:
        return 'Food & Culinary';
      case ServiceCategory.beautyPersonalCare:
        return 'Beauty & Personal Care';
      case ServiceCategory.eventsEntertainment:
        return 'Events & Entertainment';
      case ServiceCategory.fashionApparel:
        return 'Fashion & Apparel';
      case ServiceCategory.errandsLogistics:
        return 'Errands & Logistics';
    }
  }

  // Flutter icon — used in category chips on home screen
  // Replaces emojis for consistent rendering on all devices
  IconData get icon {
    switch (this) {
      case ServiceCategory.techDigital:
        return Icons.computer_rounded;
      case ServiceCategory.academicsTutoring:
        return Icons.school_rounded;
      case ServiceCategory.foodCulinary:
        return Icons.restaurant_rounded;
      case ServiceCategory.beautyPersonalCare:
        return Icons.face_retouching_natural_rounded;
      case ServiceCategory.eventsEntertainment:
        return Icons.camera_alt_rounded;
      case ServiceCategory.fashionApparel:
        return Icons.checkroom_rounded;
      case ServiceCategory.errandsLogistics:
        return Icons.delivery_dining_rounded;
    }
  }

  // Emoji — kept for dropdown selector in add_service_screen only
  String get emoji {
    switch (this) {
      case ServiceCategory.techDigital:
        return '💻';
      case ServiceCategory.academicsTutoring:
        return '🎓';
      case ServiceCategory.foodCulinary:
        return '🍱';
      case ServiceCategory.beautyPersonalCare:
        return '💅';
      case ServiceCategory.eventsEntertainment:
        return '📸';
      case ServiceCategory.fashionApparel:
        return '👗';
      case ServiceCategory.errandsLogistics:
        return '🛵';
    }
  }

  // Firestore string value — snake_case
  String get firestoreValue {
    switch (this) {
      case ServiceCategory.techDigital:
        return 'tech_digital';
      case ServiceCategory.academicsTutoring:
        return 'academics_tutoring';
      case ServiceCategory.foodCulinary:
        return 'food_culinary';
      case ServiceCategory.beautyPersonalCare:
        return 'beauty_personal_care';
      case ServiceCategory.eventsEntertainment:
        return 'events_entertainment';
      case ServiceCategory.fashionApparel:
        return 'fashion_apparel';
      case ServiceCategory.errandsLogistics:
        return 'errands_logistics';
    }
  }

  // Parse Firestore string back to enum
  static ServiceCategory fromString(String value) {
    switch (value) {
      case 'tech_digital':
        return ServiceCategory.techDigital;
      case 'academics_tutoring':
        return ServiceCategory.academicsTutoring;
      case 'food_culinary':
        return ServiceCategory.foodCulinary;
      case 'beauty_personal_care':
        return ServiceCategory.beautyPersonalCare;
      case 'events_entertainment':
        return ServiceCategory.eventsEntertainment;
      case 'fashion_apparel':
        return ServiceCategory.fashionApparel;
      case 'errands_logistics':
        return ServiceCategory.errandsLogistics;
      default:
        return ServiceCategory.techDigital;
    }
  }

  // All categories as a list — used to build category chips
  static List<ServiceCategory> get all => ServiceCategory.values;
}

// =============================================================================
// SERVICE MODEL
// =============================================================================

class ServiceModel {
  final String serviceId;
  final String providerUid;
  final String providerName;
  final String? providerAvatarUrl;
  final bool isVerified;

  final String title;
  final String description;
  final ServiceCategory category;
  final List<String> tags;

  // ── PRICING ────────────────────────────────────────────────────────────────
  final double basePrice;
  final bool isPriceNegotiable;

  final String? imageUrl;
  final double rating;
  final int reviewCount;
  final bool isActive;
  final DateTime? createdAt;

  // ── PROVIDER CONTACTS ──────────────────────────────────────────────────────
  final String? providerPhone;
  final String? providerWhatsapp;
  final String? providerInstagram;
  final String? providerSnapchat;

  const ServiceModel({
    required this.serviceId,
    required this.providerUid,
    required this.providerName,
    this.providerAvatarUrl,
    required this.isVerified,
    required this.title,
    required this.description,
    required this.category,
    this.tags = const [],
    required this.basePrice,
    this.isPriceNegotiable = false,
    this.imageUrl,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isActive = true,
    this.createdAt,
    this.providerPhone,
    this.providerWhatsapp,
    this.providerInstagram,
    this.providerSnapchat,
  });

  // ── CONVENIENCE GETTERS ────────────────────────────────────────────────────

  String get formattedPrice => isPriceNegotiable
      ? 'From GHS ${basePrice.toStringAsFixed(0)}'
      : 'GHS ${basePrice.toStringAsFixed(0)}';

  String get priceLabel => isPriceNegotiable
      ? 'From GHS ${basePrice.toStringAsFixed(0)} · Negotiable'
      : 'GHS ${basePrice.toStringAsFixed(0)}';

  String get formattedRating => rating.toStringAsFixed(1);

  bool get hasContacts =>
      providerPhone != null ||
      providerWhatsapp != null ||
      providerInstagram != null ||
      providerSnapchat != null;

  double get platformFee => basePrice * 0.05;
  double get totalWithFee => basePrice + platformFee;

  // // ── FROM FIRESTORE ─────────────────────────────────────────────────────────
  // // [PETRONILO & ERIC: confirm all field names match Firestore exactly]
  factory ServiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceModel(
      serviceId: doc.id,
      providerUid: data['providerUid'] ?? '',
      providerName: data['providerName'] ?? '',
      providerAvatarUrl: data['providerAvatarUrl'],
      isVerified: data['isVerified'] ?? false,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: ServiceCategoryExtension.fromString(
          data['category'] ?? 'tech_digital'),
      tags: List<String>.from(data['tags'] ?? []),
      basePrice: (data['basePrice'] ?? 0).toDouble(),
      isPriceNegotiable: data['isPriceNegotiable'] ?? false,
      imageUrl: data['imageUrl'],
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      providerPhone: data['providerPhone'],
      providerWhatsapp: data['providerWhatsapp'],
      providerInstagram: data['providerInstagram'],
      providerSnapchat: data['providerSnapchat'],
    );
  }

  // ── TO FIRESTORE ───────────────────────────────────────────────────────────
  // [PETRONILO & ERIC: used when provider creates or updates a listing]
  Map<String, dynamic> toFirestore() {
    return {
      'providerUid': providerUid,
      'providerName': providerName,
      'providerAvatarUrl': providerAvatarUrl,
      'isVerified': isVerified,
      'title': title,
      'description': description,
      'category': category.firestoreValue,
      'tags': tags,
      'basePrice': basePrice,
      'isPriceNegotiable': isPriceNegotiable,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'providerPhone': providerPhone,
      'providerWhatsapp': providerWhatsapp,
      'providerInstagram': providerInstagram,
      'providerSnapchat': providerSnapchat,
    };
  }

  // ── COPY WITH ──────────────────────────────────────────────────────────────
  ServiceModel copyWith({
    String? title,
    String? description,
    ServiceCategory? category,
    List<String>? tags,
    double? basePrice,
    bool? isPriceNegotiable,
    String? imageUrl,
    double? rating,
    int? reviewCount,
    bool? isActive,
    String? providerPhone,
    String? providerWhatsapp,
    String? providerInstagram,
    String? providerSnapchat,
  }) {
    return ServiceModel(
      serviceId: serviceId,
      providerUid: providerUid,
      providerName: providerName,
      providerAvatarUrl: providerAvatarUrl,
      isVerified: isVerified,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      basePrice: basePrice ?? this.basePrice,
      isPriceNegotiable: isPriceNegotiable ?? this.isPriceNegotiable,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      providerPhone: providerPhone ?? this.providerPhone,
      providerWhatsapp: providerWhatsapp ?? this.providerWhatsapp,
      providerInstagram: providerInstagram ?? this.providerInstagram,
      providerSnapchat: providerSnapchat ?? this.providerSnapchat,
    );
  }
}
