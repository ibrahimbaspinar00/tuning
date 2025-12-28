import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../model/product.dart';
import '../model/product_review.dart';
import 'storage_service.dart';

/// Ürün yönetimi için ana servis
class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcı ID'sini al
  String? get _currentUserId => _auth.currentUser?.uid;

  // ==================== ÜRÜN YÖNETİMİ ====================

  /// Tüm ürünleri getir (Stream - anlık güncelleme)
  Stream<List<Product>> getAllProductsStream() {
    try {
      debugPrint('📡 Firestore products stream başlatılıyor...');
      debugPrint('📡 Koleksiyon: products');
      debugPrint('📡 Platform: Web - Cache bypass aktif');
      
      // Web'de cache sorunlarını önlemek için önce sunucudan çek ve cache'i temizle
      // Stream başlamadan önce sunucudan bir kez çek - cache'i "warm-up" yap
      _firestore.collection('products').limit(1).get(const GetOptions(source: Source.server))
          .then((testSnapshot) {
        debugPrint('🔍 Sunucu bağlantı testi: ${testSnapshot.docs.length} adet ürün bulundu');
        debugPrint('🔍 Metadata: isFromCache=${testSnapshot.metadata.isFromCache}');
        if (testSnapshot.metadata.isFromCache) {
          debugPrint('⚠️ UYARI: Test sorgusu cache\'den geldi!');
        } else {
          debugPrint('✅ Sunucu bağlantısı başarılı - Cache bypass çalışıyor');
        }
      }).catchError((e) {
        debugPrint('❌ Sunucu bağlantı testi hatası: $e');
        debugPrint('💡 Firestore güvenlik kurallarını kontrol edin');
        debugPrint('💡 İnternet bağlantınızı kontrol edin');
      });
      
      // Stream'i başlat - Web'de cache sorunlarını önlemek için
      // Stream her zaman sunucudan veri çekmeye çalışır, cache sadece fallback olarak kullanılır
      return _firestore
          .collection('products')
          .snapshots(includeMetadataChanges: false)
          .asyncMap((snapshot) async {
        debugPrint('📦 Firestore\'dan ${snapshot.docs.length} adet doküman geldi');
        debugPrint('📦 Snapshot metadata: hasPendingWrites=${snapshot.metadata.hasPendingWrites}, isFromCache=${snapshot.metadata.isFromCache}');
        
        // Web'de cache sorunlarını önlemek için kritik kontrol
        // Eğer cache'den geliyorsa ve boşsa, sunucudan zorla çek
        if (snapshot.metadata.isFromCache && snapshot.docs.isEmpty) {
          debugPrint('⚠️ KRİTİK: Cache boş ama stream çalışıyor!');
          debugPrint('💡 Sunucudan zorla çekiliyor...');
          
          try {
            // Sunucudan zorla çek
            final serverSnapshot = await _firestore
                .collection('products')
                .get(const GetOptions(source: Source.server));
            
            debugPrint('🔍 Sunucu sorgusu: ${serverSnapshot.docs.length} adet ürün bulundu');
            debugPrint('🔍 Sunucu metadata: isFromCache=${serverSnapshot.metadata.isFromCache}');
            
            if (serverSnapshot.docs.isNotEmpty) {
              debugPrint('✅ Sunucuda ${serverSnapshot.docs.length} ürün bulundu - Cache sorunu tespit edildi');
              debugPrint('💡 Sunucu verileri kullanılıyor');
              // Sunucudan gelen verileri işle
              return await _processProducts(serverSnapshot.docs);
            } else {
              debugPrint('⚠️ Sunucuda da ürün yok - Gerçekten boş olabilir');
            }
          } catch (e) {
            debugPrint('❌ Sunucu sorgusu hatası: $e');
            // Hata durumunda cache'den gelen verileri kullan (boş olsa bile)
          }
        }
        
        // Normal durumda stream'den gelen verileri işle
        return await _processProducts(snapshot.docs);
      }).handleError((error, stackTrace) {
        debugPrint('❌ Stream asyncMap hatası: $error');
        debugPrint('📋 Stack trace: $stackTrace');
        return <Product>[];
      });
    } catch (e, stackTrace) {
      debugPrint('❌ getAllProductsStream hatası: $e');
      debugPrint('📋 Stack trace: $stackTrace');
      // Hata durumunda boş stream döndür
      return Stream.value([]);
    }
  }
  
  // Ürünleri işle - ortak metod
  Future<List<Product>> _processProducts(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    final products = <Product>[];
    for (final doc in docs) {
      try {
        final data = doc.data();
        debugPrint('📄 Ürün ${doc.id} verisi: ${data.keys.toList()}');
        debugPrint('   - name: ${data['name']}');
        debugPrint('   - isActive: ${data['isActive']}');
        
        data['id'] = doc.id;
        
        // isActive field'ı yoksa veya null ise true olarak kabul et (geriye dönük uyumluluk)
        if (data['isActive'] == null) {
          data['isActive'] = true;
          debugPrint('⚠️ Ürün ${doc.id} için isActive field\'ı eksik, true olarak ayarlandı');
        }
        
        // isActive kontrolü - boolean veya string olabilir
        final isActive = data['isActive'];
        final isActiveBool = isActive is bool ? isActive : (isActive.toString().toLowerCase() == 'true');
        
        if (!isActiveBool) {
          debugPrint('⏭️ Ürün ${doc.id} pasif (isActive: $isActive), atlanıyor');
          continue;
        }
        
        // cartCount ve favoriteCount'u varsayılan olarak 0 yap (Firestore'da yoksa)
        data['cartCount'] = data['cartCount'] ?? 0;
        data['favoriteCount'] = data['favoriteCount'] ?? 0;
        
        final product = Product.fromMap(data);
        if (product.name.isNotEmpty) {
          products.add(product);
          debugPrint('✅ Ürün parse edildi: ${product.name} (${product.id})');
        } else {
          debugPrint('⚠️ Ürün ${doc.id} parse edildi ama name boş');
        }
      } catch (e, stackTrace) {
        debugPrint('❌ Ürün parse hatası (${doc.id}): $e');
        debugPrint('📋 Stack trace: $stackTrace');
        debugPrint('📄 Ürün verisi: ${doc.data()}');
        // Hata durumunda sessizce devam et
      }
    }
    
    debugPrint('✅ Toplam ${products.length} adet ürün başarıyla parse edildi');
    
    // Yeni ürünler en üstte - createdAt'e göre sırala (client-side)
    products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return products;
  }
  

  /// Tüm ürünleri getir (sadece aktif olanlar)
  Future<List<Product>> getAllProducts() async {
    try {
      debugPrint('📡 getAllProducts çağrıldı - sunucudan ürünler getiriliyor...');
      // Önce sunucudan dene, başarısız olursa cache'den al
      GetOptions getOptions = const GetOptions(source: Source.server);
      final snapshot = await _firestore
          .collection('products')
          .limit(100) // Limit artırıldı - daha fazla ürün gösterilebilir
          .get(getOptions)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        debugPrint('⚠️ Sunucu sorgusu zaman aşımına uğradı, cache\'den deneniyor...');
        // Timeout durumunda cache'den dene
        return _firestore.collection('products').limit(100).get(const GetOptions(source: Source.cache));
      }).catchError((e) {
        debugPrint('❌ Sunucu sorgusu hatası: $e, cache\'den deneniyor...');
        // Hata durumunda cache'den dene
        return _firestore.collection('products').limit(100).get(const GetOptions(source: Source.cache));
      });
      
      debugPrint('📦 getAllProducts: ${snapshot.docs.length} adet doküman geldi');
      debugPrint('📦 Metadata: isFromCache=${snapshot.metadata.isFromCache}');

      final products = snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // isActive field'ı yoksa veya null ise true olarak kabul et (geriye dönük uyumluluk)
          if (data['isActive'] == null) {
            data['isActive'] = true;
            debugPrint('⚠️ Ürün ${doc.id} için isActive field\'ı eksik, true olarak ayarlandı');
          }
          
          // Sadece aktif ürünleri döndür
          if (data['isActive'] != true) {
            return null;
          }
          
          return Product.fromMap(data);
        } catch (e, stackTrace) {
          debugPrint('⚠️ Ürün parse hatası (${doc.id}): $e');
          debugPrint('📋 Stack trace: $stackTrace');
          debugPrint('📄 Ürün verisi: ${doc.data()}');
          return null;
        }
      }).where((product) => product != null).cast<Product>().toList();
      
      return products;
    } catch (e) {
      debugPrint('❌ getAllProducts hatası: $e');
      // Hata durumunda dummy products döndür
      return _getDummyProducts();
    }
  }

  /// Tüm ürünleri getir (Admin paneli için - aktif/pasif fark etmez)
  Future<List<Product>> getAllProductsForAdmin({int? limit}) async {
    try {
      debugPrint('📡 Admin paneli: Tüm ürünler getiriliyor...');
      
      // Limit varsa uygula, yoksa tümünü getir
      final snapshot = limit != null && limit > 0
          ? await _firestore.collection('products').limit(limit).get()
          : await _firestore.collection('products').get();
      
      debugPrint('📦 Admin paneli: ${snapshot.docs.length} adet ürün bulundu');

      final products = snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          return Product.fromMap(data);
        } catch (e) {
          debugPrint('⚠️ Admin paneli: Ürün parse hatası (${doc.id}): $e');
          return null;
        }
      }).where((product) => product != null).cast<Product>().toList();
      
      // Yeni ürünler en üstte - createdAt'e göre sırala
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      debugPrint('✅ Admin paneli: ${products.length} adet ürün başarıyla yüklendi');
      
      return products;
    } catch (e) {
      debugPrint('❌ Admin paneli: Ürün yükleme hatası: $e');
      return [];
    }
  }

  /// Tüm ürünleri getir (Stream - Admin paneli için - aktif/pasif fark etmez)
  Stream<List<Product>> getAllProductsStreamForAdmin() {
    try {
      debugPrint('📡 Admin paneli: Ürün stream başlatılıyor...');
      return _firestore
          .collection('products')
          .snapshots()
          .map((snapshot) {
        debugPrint('📦 Admin paneli: Firestore\'dan ${snapshot.docs.length} adet doküman geldi');
        final products = snapshot.docs.map((doc) {
          try {
            final data = doc.data();
            data['id'] = doc.id;
            
            final product = Product.fromMap(data);
            return product;
          } catch (e) {
            debugPrint('⚠️ Admin paneli: Ürün parse hatası (${doc.id}): $e');
            return null;
          }
        }).where((product) => product != null).cast<Product>().toList();
        
        debugPrint('✅ Admin paneli: ${products.length} adet ürün başarıyla parse edildi');
        
        // Yeni ürünler en üstte - createdAt'e göre sırala (client-side)
        products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        return products;
      });
    } catch (e) {
      debugPrint('❌ Admin paneli: getAllProductsStreamForAdmin hatası: $e');
      // Hata durumunda boş stream döndür
      return Stream.value([]);
    }
  }

  /// Kategoriye göre ürünleri getir
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      // GetOptions parametresi vermezsek otomatik olarak önce cache, sonra server dener (offline desteği için)
      // isActive filtresini kaldırdık - client-side'da filtreleyeceğiz (geriye dönük uyumluluk için)
      final snapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: category)
          .limit(50) // Limit artırıldı
          .get();

      final products = snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // isActive field'ı yoksa veya null ise true olarak kabul et (geriye dönük uyumluluk)
          if (data['isActive'] == null) {
            data['isActive'] = true;
          }
          
          // Sadece aktif ürünleri döndür
          if (data['isActive'] != true) {
            return null;
          }
          
          return Product.fromMap(data);
        } catch (e) {
          debugPrint('⚠️ Ürün parse hatası (${doc.id}): $e');
          return null;
        }
      }).where((product) => product != null).cast<Product>().toList();
      
      return products;
    } catch (e) {
      // Hata durumunda boş liste döndür
      return _getDummyProducts().where((p) => p.category == category).toList();
    }
  }

  /// Ürün detayını getir
  Future<Product?> getProductById(String productId) async {
    try {
      // GetOptions parametresi vermezsek otomatik olarak önce cache, sonra server dener (offline desteği için)
      final doc = await _firestore.collection('products').doc(productId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Product.fromMap(data);
      }
      return null;
    } catch (e) {
      // Hata durumunda null döndür
      return _getDummyProducts().firstWhere((p) => p.id == productId);
    }
  }

  /// Ürün ara
  Future<List<Product>> searchProducts(String query) async {
    try {
      // isActive filtresini kaldırdık - client-side'da filtreleyeceğiz (geriye dönük uyumluluk için)
      final snapshot = await _firestore
          .collection('products')
          .get();

      final products = snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // isActive field'ı yoksa veya null ise true olarak kabul et (geriye dönük uyumluluk)
          if (data['isActive'] == null) {
            data['isActive'] = true;
          }
          
          // Sadece aktif ürünleri döndür
          if (data['isActive'] != true) {
            return null;
          }
          
          return Product.fromMap(data);
        } catch (e) {
          debugPrint('⚠️ Ürün parse hatası (${doc.id}): $e');
          return null;
        }
      }).where((product) => product != null).cast<Product>().toList();

      // Client-side filtering for better performance
      return products.where((product) {
        return product.name.toLowerCase().contains(query.toLowerCase()) ||
               product.description.toLowerCase().contains(query.toLowerCase()) ||
               product.category.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      // Hata durumunda boş liste döndür
      return _getDummyProducts().where((p) => 
        p.name.toLowerCase().contains(query.toLowerCase()) ||
        p.description.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
  }

  /// Popüler ürünleri getir - En çok alınan ve yorumu yüksek olan ürünler
  Future<List<Product>> getPopularProducts({int limit = 10}) async {
    try {
      // Offline-first approach
      // isActive filtresini kaldırdık - client-side'da filtreleyeceğiz (geriye dönük uyumluluk için)
      final snapshot = await _firestore
          .collection('products')
          .limit(50) // Daha fazla ürün al ki sıralama daha iyi olsun
          .get();

      // Client-side sorting for better performance
      final products = snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // isActive field'ı yoksa veya null ise true olarak kabul et (geriye dönük uyumluluk)
          if (data['isActive'] == null) {
            data['isActive'] = true;
          }
          
          // Sadece aktif ürünleri döndür
          if (data['isActive'] != true) {
            return null;
          }
          
          return Product.fromMap(data);
        } catch (e) {
          debugPrint('⚠️ Ürün parse hatası (${doc.id}): $e');
          return null;
        }
      }).where((product) => product != null).cast<Product>().toList();

      // Popülerlik skorunu hesapla (satış sayısı + yorum sayısı + ortalama puan)
      products.sort((a, b) {
        // Popülerlik skoru = satış sayısı * 0.4 + yorum sayısı * 0.3 + ortalama puan * 10 * 0.3
        final scoreA = (a.salesCount * 0.4) + (a.reviewCount * 0.3) + (a.averageRating * 10 * 0.3);
        final scoreB = (b.salesCount * 0.4) + (b.reviewCount * 0.3) + (b.averageRating * 10 * 0.3);
        
        return scoreB.compareTo(scoreA);
      });
      
      return products.take(limit).toList();
    } catch (e) {
      // Hata durumunda boş liste döndür
      return _getDummyProducts().take(limit).toList();
    }
  }

  /// Yeni ürünleri getir
  Future<List<Product>> getNewProducts({int limit = 10}) async {
    try {
      // Offline-first approach
      final snapshot = await _firestore
          .collection('products')
          .limit(limit * 2) // Daha fazla ürün al ki aktif ürünler bulunabilsin
          .get();

      // Client-side sorting for better performance
      final products = snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // isActive field'ı yoksa veya null ise true olarak kabul et (geriye dönük uyumluluk)
          if (data['isActive'] == null) {
            data['isActive'] = true;
          }
          
          // Sadece aktif ürünleri döndür
          if (data['isActive'] != true) {
            return null;
          }
          
          return Product.fromMap(data);
        } catch (e) {
          debugPrint('⚠️ Ürün parse hatası (${doc.id}): $e');
          return null;
        }
      }).where((product) => product != null).cast<Product>().toList();

      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return products.take(limit).toList();
    } catch (e) {
      // Hata durumunda boş liste döndür
      return _getDummyProducts().take(limit).toList();
    }
  }

  /// İndirimli ürünleri getir
  Future<List<Product>> getDiscountedProducts() async {
    try {
      // Offline-first approach
      final snapshot = await _firestore
          .collection('products')
          .limit(50) // Limit artırıldı
          .get();

      // Client-side filtering and sorting for better performance
      final products = snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // isActive field'ı yoksa veya null ise true olarak kabul et (geriye dönük uyumluluk)
          if (data['isActive'] == null) {
            data['isActive'] = true;
          }
          
          // Sadece aktif ürünleri döndür
          if (data['isActive'] != true) {
            return null;
          }
          
          return Product.fromMap(data);
        } catch (e) {
          debugPrint('⚠️ Ürün parse hatası (${doc.id}): $e');
          return null;
        }
      }).where((product) => product != null).cast<Product>().toList();

      final discountedProducts = products.where((p) => p.discountPercentage > 0).toList();
      discountedProducts.sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));
      return discountedProducts;
    } catch (e) {
      // Hata durumunda boş liste döndür
      return _getDummyProducts().where((p) => p.discountPercentage > 0).toList();
    }
  }

  /// Ürün ekle (Resim ile)
  Future<String?> uploadProduct({
    required String name,
    required double price,
    Uint8List? imageBytes,
    String? fileName,
    File? imageFile,
    String? description,
    String? category,
    int? stock,
    double? discountPercentage,
    List<String>? colors,
    List<String>? sizes,
  }) async {
    try {
      String imageUrl = '';

      // Resim yükleme (öncelik: imageBytes, sonra imageFile)
      if (imageBytes != null && fileName != null) {
        try {
          final storageService = StorageService();
          imageUrl = await storageService.uploadProductImage(imageBytes, fileName);
        } catch (e) {
          // Resim yüklenemese bile ürün eklenmeye devam edilir
        }
      } else if (imageFile != null) {
        try {
          final storageService = StorageService();
          imageUrl = await storageService.uploadProductImageFile(imageFile);
        } catch (e) {
          // Resim yüklenemese bile ürün eklenmeye devam edilir
        }
      }

      // URL'i temizle ve validate et
      final cleanImageUrl = imageUrl.trim();
      debugPrint('=== ÜRÜN EKLEME ===');
      debugPrint('Ürün Adı: $name');
      debugPrint('Görsel URL: $cleanImageUrl');
      debugPrint('URL Uzunluğu: ${cleanImageUrl.length}');
      debugPrint('URL Boş mu: ${cleanImageUrl.isEmpty}');
      debugPrint('URL HTTP ile başlıyor mu: ${cleanImageUrl.startsWith('http')}');

      // Ürünü Firestore'a ekle - Real-time güncelleme için createdAt zorunlu
      final productData = {
        'name': name,
        'price': price,
        'imageUrl': cleanImageUrl, // Temizlenmiş URL'i kaydet
        'description': description ?? '',
        'category': category ?? 'Genel',
        'stock': stock ?? 0,
        'discountPercentage': discountPercentage ?? 0.0,
        'isActive': true, // MUTLAKA true olarak kaydet
        'averageRating': 0.0,
        'reviewCount': 0,
        'salesCount': 0,
        'createdAt': FieldValue.serverTimestamp(), // Real-time sıralama için zorunlu
        'updatedAt': FieldValue.serverTimestamp(),
        'colors': colors, // Admin panelinden eklenen renkler
        'sizes': sizes, // Admin panelinden eklenen bedenler
      };
      
      debugPrint('📝 Firestore\'a kaydedilecek ürün verisi:');
      debugPrint('   - name: $name');
      debugPrint('   - price: $price');
      debugPrint('   - category: ${category ?? 'Genel'}');
      debugPrint('   - isActive: true');
      debugPrint('   - imageUrl: ${cleanImageUrl.isEmpty ? "BOŞ" : cleanImageUrl.substring(0, cleanImageUrl.length > 50 ? 50 : cleanImageUrl.length)}...');
      
      // Firestore'a ekle - timeout ile
      debugPrint('📤 Firestore\'a ürün ekleniyor...');
      final docRef = await _firestore.collection('products').add(productData)
          .timeout(const Duration(seconds: 30), onTimeout: () {
        debugPrint('❌ Firestore\'a ürün ekleme zaman aşımına uğradı');
        throw Exception('Ürün ekleme zaman aşımına uğradı. Lütfen tekrar deneyin.');
      });

      debugPrint('✅ Ürün Firestore\'a başarıyla eklendi!');
      debugPrint('   - Doküman ID: ${docRef.id}');
      debugPrint('   - Koleksiyon: products');
      
      // Hemen kontrol et - ürünün gerçekten kaydedildiğini doğrula
      try {
        final verifyDoc = await _firestore.collection('products').doc(docRef.id).get()
            .timeout(const Duration(seconds: 10));
        if (verifyDoc.exists) {
          final verifyData = verifyDoc.data()!;
          debugPrint('✅ Ürün doğrulandı - Firestore\'da mevcut');
          debugPrint('   - Ürün adı: ${verifyData['name']}');
          debugPrint('   - isActive: ${verifyData['isActive']}');
          debugPrint('   - Kategori: ${verifyData['category']}');
          
          // Tüm ürünleri say
          final allProductsSnapshot = await _firestore.collection('products').get()
              .timeout(const Duration(seconds: 10));
          debugPrint('📊 Firestore\'da toplam ${allProductsSnapshot.docs.length} adet ürün var');
        } else {
          debugPrint('❌ UYARI: Ürün kaydedildi ama doğrulama başarısız!');
        }
      } catch (e) {
        debugPrint('⚠️ Ürün doğrulama hatası (normal olabilir): $e');
        // Doğrulama hatası olsa bile ürün eklenmiş olabilir, devam et
      }
      
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Ürün stok durumunu güncelle
  Future<void> updateProductStock(String productId, int newStock) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'stock': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  /// Ürün satış sayısını artır
  Future<void> incrementProductSales(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'salesCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error incrementing product sales: $e');
    }
  }

  // ==================== ÜRÜN YORUMLARI ====================

  /// Ürün yorumlarını getir
  Future<List<ProductReview>> getProductReviews(String productId) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ProductReview.fromMap(data);
      }).toList();
    } catch (e) {
      // Hata durumunda boş liste döndür
      return [];
    }
  }

  /// Ürün yorumu ekle
  Future<void> addProductReview({
    required String productId,
    required int rating,
    required String comment,
  }) async {
    if (_currentUserId == null) throw Exception('Kullanıcı giriş yapmamış');

    try {
      await _firestore
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .add({
        'userId': _currentUserId,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Ürünün ortalama puanını güncelle
      await _updateProductAverageRating(productId);
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  /// Ürünün ortalama puanını güncelle
  Future<void> _updateProductAverageRating(String productId) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .get();

      if (reviewsSnapshot.docs.isEmpty) return;

      double totalRating = 0;
      for (final doc in reviewsSnapshot.docs) {
        totalRating += (doc.data()['rating'] ?? 0).toDouble();
      }

      final averageRating = totalRating / reviewsSnapshot.docs.length;

      await _firestore.collection('products').doc(productId).update({
        'averageRating': averageRating,
        'reviewCount': reviewsSnapshot.docs.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  // ==================== KATEGORİLER ====================

  /// Tüm kategorileri getir
  Future<List<String>> getAllCategories() async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) => doc.data()['name'] as String).toList();
    } catch (e) {
      // Hata durumunda boş liste döndür
      return _getDummyCategories();
    }
  }

  /// Kategori detayını getir
  Future<Map<String, dynamic>?> getCategoryDetails(String categoryName) async {
    try {
      final doc = await _firestore
          .collection('categories')
          .where('name', isEqualTo: categoryName)
          .limit(1)
          .get();

      if (doc.docs.isNotEmpty) {
        final data = doc.docs.first.data();
        data['id'] = doc.docs.first.id;
        return data;
      }
      return null;
    } catch (e) {
      // Hata durumunda boş liste döndür
      return null;
    }
  }

  // ==================== DUMMY DATA ====================

  /// Demo ürünleri getir
  List<Product> _getDummyProducts() {
    return [
      Product(
        id: '1',
        name: 'Premium Araç Temizlik Bezi',
        description: 'Yüksek kaliteli mikrofiber araç temizlik bezi. Çizik bırakmaz ve su emme kapasitesi yüksek.',
        price: 25.99,
        imageUrl: '',
        category: 'Araç Temizlik',
        stock: 50,
        discountPercentage: 10,
        averageRating: 4.8,
        reviewCount: 156,
        salesCount: 450,
      ),
      Product(
        id: '2',
        name: 'Araç İçi Hava Temizleyici',
        description: 'Araç içindeki kötü kokuları gideren, doğal içerikli hava temizleyici sprey.',
        price: 18.50,
        imageUrl: '',
        category: 'Araç Temizlik',
        stock: 30,
        discountPercentage: 0,
        averageRating: 4.2,
        reviewCount: 89,
        salesCount: 234,
      ),
      Product(
        id: '3',
        name: 'Telefon Tutucu',
        description: 'Araçta telefonunuzu güvenli şekilde tutan, 360 derece dönebilen tutucu.',
        price: 35.00,
        imageUrl: '',
        category: 'Telefon Aksesuar',
        stock: 100,
        discountPercentage: 15,
        averageRating: 4.9,
        reviewCount: 287,
        salesCount: 678,
      ),
      Product(
        id: '4',
        name: 'Araç Kokusu',
        description: 'Uzun süreli etkili araç kokusu. Doğal içerikli ve sağlıklı.',
        price: 12.99,
        imageUrl: '',
        category: 'Araç Temizlik',
        stock: 75,
        discountPercentage: 20,
        averageRating: 4.6,
        reviewCount: 198,
        salesCount: 567,
      ),
      Product(
        id: '5',
        name: 'Araç Şarj Cihazı',
        description: 'Hızlı şarj destekli araç şarj cihazı. USB-C ve USB-A çıkışları.',
        price: 45.99,
        imageUrl: '',
        category: 'Elektronik',
        stock: 40,
        discountPercentage: 5,
        averageRating: 4.7,
        reviewCount: 134,
        salesCount: 389,
      ),
      Product(
        id: '6',
        name: 'Araç Halısı',
        description: 'Su geçirmez araç halısı. Kolay temizlenir ve dayanıklı.',
        price: 29.99,
        imageUrl: '',
        category: 'Araç Aksesuar',
        stock: 60,
        discountPercentage: 0,
        averageRating: 4.4,
        reviewCount: 67,
        salesCount: 198,
      ),
      Product(
        id: '7',
        name: 'Araç Kamerası',
        description: '4K çözünürlüklü araç kamerası. Gece görüş özellikli.',
        price: 199.99,
        imageUrl: '',
        category: 'Güvenlik',
        stock: 25,
        discountPercentage: 10,
        averageRating: 4.9,
        reviewCount: 312,
        salesCount: 789,
      ),
      Product(
        id: '8',
        name: 'Araç Temizlik Seti',
        description: 'Komplet araç temizlik seti. Tüm gerekli malzemeler dahil.',
        price: 89.99,
        imageUrl: '',
        category: 'Araç Temizlik',
        stock: 45,
        discountPercentage: 15,
        averageRating: 4.8,
        reviewCount: 245,
        salesCount: 623,
      ),
    ];
  }

  /// Demo kategorileri getir
  List<String> _getDummyCategories() {
    return [
      'Araç Temizlik',
      'Telefon Aksesuar',
      'Elektronik',
      'Araç Aksesuar',
      'Güvenlik',
      'Performans',
    ];
  }
}
