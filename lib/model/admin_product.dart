import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Admin paneli için ürün modeli
class AdminProduct {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String description;
  final String category;
  final int stock;
  final double discountPercentage;
  final double averageRating;
  final int reviewCount;
  final int salesCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final List<String>? colors;
  final List<String>? sizes;

  AdminProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.category,
    required this.stock,
    this.discountPercentage = 0.0,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.salesCount = 0,
    DateTime? createdAt,
    this.updatedAt,
    this.isActive = true,
    this.colors,
    this.sizes,
  }) : createdAt = createdAt ?? DateTime.now();

  // Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'description': description,
      'category': category,
      'stock': stock,
      'discountPercentage': discountPercentage,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'salesCount': salesCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
      'isActive': isActive,
      'colors': colors,
      'sizes': sizes,
    };
  }

  // Map'ten oluşturma
  factory AdminProduct.fromMap(Map<String, dynamic> map, String id) {
    double safeToDouble(dynamic value) {
      if (value == null) return 0.0;
      final doubleVal = value.toDouble();
      if (doubleVal.isNaN || doubleVal.isInfinite) return 0.0;
      return doubleVal;
    }

    int safeToInt(dynamic value) {
      if (value == null) return 0;
      final intVal = value.toInt();
      if (intVal.isNaN || intVal.isInfinite) return 0;
      return intVal;
    }

    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) {
        try {
          return value.toDate();
        } catch (e) {
          return null;
        }
      }
      if (value is String) {
        return DateTime.tryParse(value);
      }
      if (value is DateTime) {
        return value;
      }
      return null;
    }

    List<String>? parseStringList(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return null;
    }

    return AdminProduct(
      id: id,
      name: map['name'] ?? '',
      price: safeToDouble(map['price']),
      imageUrl: map['imageUrl'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      stock: safeToInt(map['stock']),
      discountPercentage: safeToDouble(map['discountPercentage']),
      averageRating: safeToDouble(map['averageRating']),
      reviewCount: safeToInt(map['reviewCount'] ?? map['totalReviews']),
      salesCount: safeToInt(map['salesCount']),
      createdAt: parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: parseDateTime(map['updatedAt']),
      isActive: map['isActive'] ?? true,
      colors: parseStringList(map['colors']),
      sizes: parseStringList(map['sizes']),
    );
  }

  // Firestore'dan oluşturma
  factory AdminProduct.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data();
      if (data == null || data is! Map<String, dynamic>) {
        throw Exception('Geçersiz doküman verisi');
      }
      return AdminProduct.fromMap(data, doc.id);
    } catch (e) {
      debugPrint('⚠️ AdminProduct.fromFirestore hatası: $e');
      rethrow;
    }
  }

  // CopyWith metodu
  AdminProduct copyWith({
    String? id,
    String? name,
    double? price,
    String? imageUrl,
    String? description,
    String? category,
    int? stock,
    double? discountPercentage,
    double? averageRating,
    int? reviewCount,
    int? salesCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    List<String>? colors,
    List<String>? sizes,
  }) {
    return AdminProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      salesCount: salesCount ?? this.salesCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      colors: colors ?? this.colors,
      sizes: sizes ?? this.sizes,
    );
  }
}

/// Kategori modeli
class ProductCategory {
  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ProductCategory({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description ?? '',
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  // Map'ten oluşturma
  factory ProductCategory.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) {
        try {
          return value.toDate();
        } catch (e) {
          return null;
        }
      }
      if (value is String) {
        return DateTime.tryParse(value);
      }
      if (value is DateTime) {
        return value;
      }
      return null;
    }

    return ProductCategory(
      id: id,
      name: map['name'] ?? '',
      description: map['description'],
      isActive: map['isActive'] ?? true,
      createdAt: parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: parseDateTime(map['updatedAt']),
    );
  }

  // Firestore'dan oluşturma (güvenli parsing)
  factory ProductCategory.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data();
      
      // Null kontrolü
      if (data == null) {
        debugPrint('⚠️ ProductCategory.fromFirestore: data null');
        throw Exception('Doküman verisi null');
      }

      // Tip kontrolü
      if (data is! Map<String, dynamic>) {
        debugPrint('⚠️ ProductCategory.fromFirestore: data tipi geçersiz');
        throw Exception('Doküman verisi geçersiz tip');
      }

      // Boş data kontrolü
      if (data.isEmpty) {
        debugPrint('⚠️ ProductCategory.fromFirestore: data boş');
        throw Exception('Doküman verisi boş');
      }

      // Güvenli parsing
      try {
        return ProductCategory.fromMap(data, doc.id);
      } catch (e) {
        debugPrint('⚠️ ProductCategory.fromFirestore parse hatası: $e');
        debugPrint('   Doküman ID: ${doc.id}');
        debugPrint('   Data: $data');
        rethrow;
      }
    } catch (e) {
      debugPrint('❌ ProductCategory.fromFirestore kritik hata: $e');
      rethrow;
    }
  }

  // CopyWith metodu
  ProductCategory copyWith({
    String? id,
    String? name,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

