import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../model/collection.dart';
import '../model/product.dart';

class CollectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcının koleksiyonlarını getir
  Future<List<Collection>> getUserCollections() async {
    final user = _auth.currentUser;
    print('Debug: CollectionService - Getting collections for user: ${user?.uid}');
    
    if (user == null) {
      print('Debug: CollectionService - No user logged in, returning empty list');
      // Kullanıcı giriş yapmamışsa boş liste döndür
      return [];
    }

    try {
      // Sadece server'dan oku (offline destek yok)
      final snapshot = await _firestore
          .collection('collections')
          .where('userId', isEqualTo: user.uid)
          .limit(50)
          .get();
      
      print('Debug: CollectionService - Found ${snapshot.docs.length} collections');
      
      // Client-side parsing with error handling
      final collections = <Collection>[];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Timestamp'leri düzelt
          if (data['createdAt'] is Timestamp) {
            data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
          }
          if (data['updatedAt'] is Timestamp) {
            data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
          }
          
          final collection = Collection.fromMap(data);
          collections.add(collection);
        } catch (e) {
          debugPrint('Error parsing collection ${doc.id}: $e');
          continue;
        }
      }

      // Tarihe göre sırala
      collections.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      print('Debug: CollectionService - Successfully parsed ${collections.length} collections');
      return collections;
    } catch (e) {
      print('Debug: CollectionService - Error getting collections: $e');
      // Hata durumunda boş liste döndür
      return [];
    }
  }

  // Yeni koleksiyon oluştur
  Future<String> createCollection(Collection collection) async {
    final user = _auth.currentUser;
    print('Debug: CollectionService - Current user: ${user?.uid}');
    
    if (user == null) {
      print('Debug: CollectionService - No user logged in, cannot create collection');
      throw Exception('Koleksiyon oluşturmak için giriş yapmalısınız');
    }

    print('Debug: CollectionService - Creating collection with ID: ${collection.id}');
    print('Debug: CollectionService - User ID: ${user.uid}');
    
    try {
      final data = collection.toMap();
      // Timestamp'leri Firestore formatına çevir
      data['createdAt'] = Timestamp.fromDate(collection.createdAt);
      data['updatedAt'] = Timestamp.fromDate(collection.updatedAt);
      
      await _firestore
          .collection('collections')
          .doc(collection.id)
          .set(data);
      
      return collection.id;
    } catch (e) {
      debugPrint('Error saving collection: $e');
      rethrow;
    }
  }

  // Koleksiyona ürün ekle
  Future<void> addProductToCollection(String collectionId, String productId, {String? productImageUrl}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı giriş yapmamış');

    // Koleksiyon bilgilerini al
    final collectionDoc = await _firestore.collection('collections').doc(collectionId).get();
    if (!collectionDoc.exists) {
      throw Exception('Koleksiyon bulunamadı');
    }
    
    final collectionData = collectionDoc.data()!;
    final currentProductIds = List<String>.from(collectionData['productIds'] ?? []);
    final currentCoverImageUrl = collectionData['coverImageUrl'] as String?;
    
    // Eğer koleksiyon boşsa ve ürün imageUrl'i varsa, kapak fotoğrafı olarak ayarla
    Map<String, dynamic> updateData = {
      'productIds': FieldValue.arrayUnion([productId]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
    
    // Eğer koleksiyon boşsa ve kapak fotoğrafı yoksa, ilk ürünün fotoğrafını kapak yap
    if (currentProductIds.isEmpty && 
        (currentCoverImageUrl == null || currentCoverImageUrl.isEmpty) &&
        productImageUrl != null && productImageUrl.isNotEmpty) {
      updateData['coverImageUrl'] = productImageUrl;
      print('Debug: İlk ürün eklendi, kapak fotoğrafı ayarlandı: $productImageUrl');
    }

    await _firestore.collection('collections').doc(collectionId).update(updateData);
  }

  // Koleksiyondan ürün çıkar
  Future<void> removeProductFromCollection(String collectionId, String productId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı giriş yapmamış');

    await _firestore.collection('collections').doc(collectionId).update({
      'productIds': FieldValue.arrayRemove([productId]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Koleksiyonu güncelle
  Future<void> updateCollection(Collection collection) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı giriş yapmamış');

    final data = collection.toMap();
    // Timestamp'leri Firestore formatına çevir
    data['createdAt'] = Timestamp.fromDate(collection.createdAt);
    data['updatedAt'] = Timestamp.fromDate(collection.updatedAt);

    await _firestore
        .collection('collections')
        .doc(collection.id)
        .update(data);
  }

  // Koleksiyonu sil
  Future<void> deleteCollection(String collectionId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı giriş yapmamış');

    await _firestore.collection('collections').doc(collectionId).delete();
  }

  // Koleksiyonun ürünlerini getir
  Future<List<Product>> getCollectionProducts(String collectionId) async {
    // Koleksiyon bilgilerini al
    final doc = await _firestore.collection('collections').doc(collectionId).get();
    if (!doc.exists) return [];

    final data = doc.data()!;
    data['id'] = doc.id;
    
    // Timestamp'leri düzelt
    if (data['createdAt'] is Timestamp) {
      data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
    }
    if (data['updatedAt'] is Timestamp) {
      data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
    }

    final collection = Collection.fromMap(data);
    final products = <Product>[];

    for (final productId in collection.productIds) {
      try {
        // Ürün bilgilerini al
        final productDoc = await _firestore.collection('products').doc(productId).get(
        );
        if (productDoc.exists) {
          final productData = productDoc.data()!;
          productData['id'] = productId;
          final product = Product.fromMap(productData);
          products.add(product);
        }
      } catch (e) {
        debugPrint('Error loading product $productId: $e');
      }
    }

    return products;
  }
}
