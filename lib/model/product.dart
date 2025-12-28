import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String description;
  final String category;
  final int stock;
  int quantity; // Sepetteki miktar
  final double discountPercentage;
  final double averageRating;
  final int reviewCount;
  final int salesCount;
  final int cartCount; // Sepete eklenme sayısı
  final int favoriteCount; // Favorilere eklenme sayısı
  final DateTime createdAt;
  final List<String>? colors; // Admin panelinden eklenen renkler
  final List<String>? sizes; // Admin panelinden eklenen bedenler

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.category,
    required this.stock,
    this.quantity = 1,
    this.discountPercentage = 0.0,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.salesCount = 0,
    this.cartCount = 0,
    this.favoriteCount = 0,
    DateTime? createdAt,
    this.colors,
    this.sizes,
  }) : createdAt = createdAt ?? DateTime.now();

  // Toplam fiyat hesaplama
  double get totalPrice {
    if (price.isNaN || quantity.isNaN || price.isInfinite || quantity.isInfinite) {
      return 0.0;
    }
    return price * quantity;
  }

  // İndirimli fiyat
  double get discountedPrice {
    if (discountPercentage > 0) {
      return price * (1 - discountPercentage / 100);
    }
    return price;
  }

  // Ürün kopyalama (miktar ile)
  Product copyWith({
    int? quantity,
    double? discountPercentage,
    double? averageRating,
    int? reviewCount,
    int? salesCount,
    int? cartCount,
    int? favoriteCount,
    DateTime? createdAt,
    List<String>? colors,
    List<String>? sizes,
  }) {
    return Product(
      id: id,
      name: name,
      price: price,
      imageUrl: imageUrl,
      description: description,
      category: category,
      stock: stock,
      quantity: quantity ?? this.quantity,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      salesCount: salesCount ?? this.salesCount,
      cartCount: cartCount ?? this.cartCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      createdAt: createdAt ?? this.createdAt,
      colors: colors ?? this.colors,
      sizes: sizes ?? this.sizes,
    );
  }

  // Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'description': description,
      'category': category,
      'stock': stock,
      'quantity': quantity,
      'discountPercentage': discountPercentage,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'salesCount': salesCount,
      'cartCount': cartCount,
      'favoriteCount': favoriteCount,
      'createdAt': Timestamp.fromDate(createdAt), // Firestore Timestamp olarak kaydet
      'colors': colors,
      'sizes': sizes,
    };
  }

  // Map'ten oluşturma
  factory Product.fromMap(Map<String, dynamic> map) {
    // Güvenli sayı dönüşümü için yardımcı fonksiyonlar
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

    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      
      // Firebase Timestamp tipini kontrol et
      if (value is Timestamp) {
        try {
          return value.toDate();
        } catch (e) {
          return DateTime.now();
        }
      }
      
      // String tipini kontrol et
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      
      // DateTime tipini kontrol et
      if (value is DateTime) {
        return value;
      }
      
      // toString() ile kontrol et (fallback)
      if (value.toString().contains('Timestamp')) {
        try {
          // Timestamp'i DateTime'a çevir
          if (value.toString().contains('millisecondsSinceEpoch')) {
            return DateTime.fromMillisecondsSinceEpoch(value.millisecondsSinceEpoch);
          }
        } catch (e) {
          return DateTime.now();
        }
      }
      
      return DateTime.now();
    }
    
    // imageUrl için alternatif field isimlerini kontrol et
    String getImageUrl() {
      // Öncelik sırası: imageUrl > image_url > image
      String? url;
      
      if (map['imageUrl'] != null) {
        url = map['imageUrl'].toString().trim();
        if (url.isNotEmpty) {
          return url;
        }
      }
      
      if (map['image_url'] != null) {
        url = map['image_url'].toString().trim();
        if (url.isNotEmpty) {
          return url;
        }
      }
      
      if (map['image'] != null) {
        url = map['image'].toString().trim();
        if (url.isNotEmpty) {
          return url;
        }
      }
      
      // Hiçbir field bulunamadı veya boş - debug için
      if (kDebugMode) {
        debugPrint('⚠️ Product.fromMap: imageUrl bulunamadı veya boş');
        debugPrint('  Mevcut field\'lar: ${map.keys.where((k) => k.toLowerCase().contains('image')).toList()}');
        debugPrint('  imageUrl değeri: ${map['imageUrl']}');
        debugPrint('  image_url değeri: ${map['image_url']}');
        debugPrint('  image değeri: ${map['image']}');
      }
      
      return '';
    }
    
    // colors ve sizes listelerini güvenli şekilde parse et
    List<String>? parseStringList(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return null;
    }
    
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: safeToDouble(map['price']),
      imageUrl: getImageUrl(),
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      stock: safeToInt(map['stock']),
      quantity: safeToInt(map['quantity']) > 0 ? safeToInt(map['quantity']) : 1,
      discountPercentage: safeToDouble(map['discountPercentage']),
      averageRating: safeToDouble(map['averageRating']),
      reviewCount: safeToInt(map['reviewCount'] ?? map['totalReviews']), // totalReviews desteği eklendi
      salesCount: safeToInt(map['salesCount']),
      cartCount: safeToInt(map['cartCount']),
      favoriteCount: safeToInt(map['favoriteCount']),
      createdAt: map['createdAt'] != null 
          ? parseDateTime(map['createdAt'])
          : DateTime.now(),
      colors: parseStringList(map['colors']),
      sizes: parseStringList(map['sizes']),
    );
  }

  static List<Product>? get dummyProducts => null;
}

