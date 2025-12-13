import 'package:cloud_firestore/cloud_firestore.dart';

/// Kullanıcı koleksiyon modeli
class Collection {
  final String id;
  final String name;
  final String description;
  final String userId;
  final List<String> productIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? coverImageUrl;

  Collection({
    required this.id,
    required this.name,
    required this.description,
    required this.userId,
    required this.productIds,
    required this.createdAt,
    required this.updatedAt,
    this.coverImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'userId': userId,
      'productIds': productIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
    };
  }

  factory Collection.fromMap(Map<String, dynamic> map) {
    return Collection(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      userId: map['userId'] ?? '',
      productIds: List<String>.from(map['productIds'] ?? []),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      coverImageUrl: map['coverImageUrl'] as String?,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    
    // Firebase Timestamp tipini kontrol et
    if (value is Timestamp) {
      return value.toDate();
    }
    
    // String tipini kontrol et
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    
    // DateTime tipini kontrol et
    if (value is DateTime) {
      return value;
    }
    
    return DateTime.now();
  }
}

