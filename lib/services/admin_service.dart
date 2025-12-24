import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../model/admin_product.dart';

/// Admin paneli için servis sınıfı
class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== KATEGORİ İŞLEMLERİ ====================

  /// Yeni kategori ekle
  Future<String> addCategory(ProductCategory category) async {
    try {
      debugPrint('📝 Kategori ekleniyor: ${category.name}');
      final docRef = await _firestore.collection('categories').add(category.toMap());
      debugPrint('✅ Kategori eklendi: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Kategori ekleme hatası: $e');
      rethrow;
    }
  }

  /// Tüm kategorileri getir (aktif ve pasif)
  Stream<List<ProductCategory>> getAllCategories() {
    try {
      return _firestore
          .collection('categories')
          .snapshots(includeMetadataChanges: false)
          .map((snapshot) {
        final categories = <ProductCategory>[];
        for (final doc in snapshot.docs) {
          try {
            final category = ProductCategory.fromFirestore(doc);
            categories.add(category);
          } catch (e) {
            debugPrint('⚠️ Kategori parse hatası (${doc.id}): $e');
            // Geçersiz dokümanları atla
            continue;
          }
        }
        return categories;
      }).handleError((error) {
        debugPrint('❌ Stream hatası: $error');
        return <ProductCategory>[];
      });
    } catch (e) {
      debugPrint('❌ getAllCategories hatası: $e');
      return Stream.value([]);
    }
  }

  /// Sadece aktif kategorileri getir
  Stream<List<ProductCategory>> getCategories() {
    try {
      return _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .snapshots(includeMetadataChanges: false)
          .map((snapshot) {
        final categories = <ProductCategory>[];
        for (final doc in snapshot.docs) {
          try {
            final category = ProductCategory.fromFirestore(doc);
            categories.add(category);
          } catch (e) {
            debugPrint('⚠️ Kategori parse hatası (${doc.id}): $e');
            continue;
          }
        }
        return categories;
      }).handleError((error) {
        debugPrint('❌ Stream hatası: $error');
        return <ProductCategory>[];
      });
    } catch (e) {
      debugPrint('❌ getCategories hatası: $e');
      return Stream.value([]);
    }
  }

  /// Kategori güncelle
  Future<void> updateCategory(ProductCategory category) async {
    try {
      debugPrint('📝 Kategori güncelleniyor: ${category.id}');
      final updatedCategory = category.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('categories')
          .doc(category.id)
          .update(updatedCategory.toMap());
      debugPrint('✅ Kategori güncellendi: ${category.id}');
    } catch (e) {
      debugPrint('❌ Kategori güncelleme hatası: $e');
      rethrow;
    }
  }

  /// Kategori sil
  Future<void> deleteCategory(String categoryId) async {
    try {
      debugPrint('🗑️ Kategori siliniyor: $categoryId');
      
      // Server-side doğrulama
      final doc = await _firestore
          .collection('categories')
          .doc(categoryId)
          .get(const GetOptions(source: Source.server));
      
      if (!doc.exists) {
        debugPrint('⚠️ Kategori zaten silinmiş: $categoryId');
        return;
      }

      await _firestore.collection('categories').doc(categoryId).delete();
      
      // Silme işlemini doğrula
      final verifyDoc = await _firestore
          .collection('categories')
          .doc(categoryId)
          .get(const GetOptions(source: Source.server));
      
      if (verifyDoc.exists) {
        debugPrint('⚠️ UYARI: Kategori silme işlemi başarısız görünüyor');
        throw Exception('Kategori silme işlemi başarısız');
      }
      
      debugPrint('✅ Kategori silindi: $categoryId');
    } catch (e) {
      debugPrint('❌ Kategori silme hatası: $e');
      rethrow;
    }
  }

  // ==================== ÜRÜN İŞLEMLERİ ====================

  /// Tüm ürünleri server'dan getir (cache bypass)
  Future<List<AdminProduct>> getProductsFromServer() async {
    try {
      debugPrint('📡 Server\'dan ürünler getiriliyor...');
      final snapshot = await _firestore
          .collection('products')
          .get(const GetOptions(source: Source.server));
      
      debugPrint('📦 ${snapshot.docs.length} adet ürün bulundu');
      
      final products = <AdminProduct>[];
      for (final doc in snapshot.docs) {
        try {
          final product = AdminProduct.fromFirestore(doc);
          products.add(product);
        } catch (e) {
          debugPrint('⚠️ Ürün parse hatası (${doc.id}): $e');
          continue;
        }
      }
      
      return products;
    } catch (e) {
      debugPrint('❌ getProductsFromServer hatası: $e');
      return [];
    }
  }

  /// Ürün güncelle
  Future<void> updateProduct(String productId, AdminProduct product) async {
    try {
      debugPrint('📝 Ürün güncelleniyor: $productId');
      final updatedProduct = product.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('products')
          .doc(productId)
          .update(updatedProduct.toMap());
      debugPrint('✅ Ürün güncellendi: $productId');
    } catch (e) {
      debugPrint('❌ Ürün güncelleme hatası: $e');
      rethrow;
    }
  }

  /// Ürünün belirli alanlarını güncelle
  Future<void> updateProductFields(String productId, Map<String, dynamic> updates) async {
    try {
      debugPrint('📝 Ürün alanları güncelleniyor: $productId');
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection('products')
          .doc(productId)
          .update(updates);
      debugPrint('✅ Ürün alanları güncellendi: $productId');
    } catch (e) {
      debugPrint('❌ Ürün alanları güncelleme hatası: $e');
      rethrow;
    }
  }

  /// Kategorideki ürünleri getir
  Future<List<AdminProduct>> getProductsByCategory(String categoryName) async {
    try {
      debugPrint('📡 Kategori ürünleri getiriliyor: $categoryName');
      final snapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: categoryName)
          .get(const GetOptions(source: Source.server));
      
      debugPrint('📦 ${snapshot.docs.length} adet ürün bulundu');
      
      final products = <AdminProduct>[];
      for (final doc in snapshot.docs) {
        try {
          final product = AdminProduct.fromFirestore(doc);
          products.add(product);
        } catch (e) {
          debugPrint('⚠️ Ürün parse hatası (${doc.id}): $e');
          continue;
        }
      }
      
      return products;
    } catch (e) {
      debugPrint('❌ getProductsByCategory hatası: $e');
      return [];
    }
  }
}

