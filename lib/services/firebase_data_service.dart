import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase Firestore veri yönetimi servisi
/// Favoriler, sepet ve kullanıcı verilerini yönetir
class FirebaseDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Kullanıcının favori ürün ID'lerini getir
  Future<List<String>> getFavoriteProductIds() async {
    final user = _auth.currentUser;
    if (user == null) {
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Error getting favorite product IDs: $e');
      return [];
    }
  }

  /// Favorilere ürün ekle
  Future<void> addToFavorites(String productId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı giriş yapmamış');
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(productId)
          .set({
        'productId': productId,
        'addedAt': FieldValue.serverTimestamp(),
      });
      
      // Ürünün favoriteCount'unu artır
      await _incrementProductFavoriteCount(productId);
    } catch (e) {
      debugPrint('Error adding to favorites: $e');
      rethrow;
    }
  }

  /// Favorilerden ürün çıkar
  Future<void> removeFromFavorites(String productId) async {
    final user = _auth.currentUser;
    if (user == null) {
throw Exception('Kullanıcı giriş yapmamış');
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(productId)
          .delete();
      
      // Ürünün favoriteCount'unu azalt
      await _decrementProductFavoriteCount(productId);
    } catch (e) {
      debugPrint('Error removing from favorites: $e');
      rethrow;
    }
  }

  /// Kullanıcının sepet öğelerini getir
  Future<List<Map<String, dynamic>>> getCartItems() async {
    final user = _auth.currentUser;
    if (user == null) {
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'productId': doc.id,
          'quantity': data['quantity'] ?? 1,
          ...data,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting cart items: $e');
      return [];
    }
  }

  /// Sepete ürün ekle
  Future<void> addToCart(String productId, int quantity) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı giriş yapmamış');
    }

    try {
      // Önce sepette var mı kontrol et
      final cartDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(productId)
          .get();
      
      final wasInCart = cartDoc.exists;
      
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(productId)
          .set({
        'productId': productId,
        'quantity': quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Eğer sepette yoksa, cartCount'u artır
      if (!wasInCart) {
        await _incrementProductCartCount(productId);
      }
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      rethrow;
    }
  }

  /// Sepetten ürün çıkar
  Future<void> removeFromCart(String productId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı giriş yapmamış');
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(productId)
          .delete();
      
      // Ürünün cartCount'unu azalt
      await _decrementProductCartCount(productId);
    } catch (e) {
      debugPrint('Error removing from cart: $e');
      rethrow;
    }
  }

  /// Sepetteki ürün miktarını güncelle
  Future<void> updateCartQuantity(String productId, int quantity) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı giriş yapmamış');
    }

    try {
      if (quantity <= 0) {
        // Miktar 0 veya negatifse sepetten çıkar
        await removeFromCart(productId);
      } else {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .doc(productId)
            .update({
          'quantity': quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error updating cart quantity: $e');
      rethrow;
    }
  }

  /// Sepeti temizle
  Future<void> clearCart() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı giriş yapmamış');
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing cart: $e');
      rethrow;
    }
  }

  /// Kullanıcı profil bilgilerini getir
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      // Timestamp'leri string'e çevir
      final result = <String, dynamic>{...data};
      if (data['createdAt'] is Timestamp) {
        result['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
      }
      if (data['updatedAt'] is Timestamp) {
        result['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
      }
      if (data['birthDate'] is Timestamp) {
        result['birthDate'] = (data['birthDate'] as Timestamp).toDate().toIso8601String();
      }

      return result;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  /// Kullanıcı istatistiklerini getir
  Future<Map<String, dynamic>> getUserStats() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {};
    }

    try {
      // Favori sayısı
      final favoritesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .get();

      // Sepet öğe sayısı
      final cartSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .get();

      // Sipariş sayısı
      final ordersSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .get();

      return {
        'favoriteCount': favoritesSnapshot.docs.length,
        'cartItemCount': cartSnapshot.docs.length,
        'orderCount': ordersSnapshot.docs.length,
      };
    } catch (e) {
      debugPrint('Error getting user stats: $e');
      return {};
    }
  }

  /// Ürünün cartCount'unu artır
  Future<void> _incrementProductCartCount(String productId) async {
    try {
      await _firestore
          .collection('products')
          .doc(productId)
          .update({
        'cartCount': FieldValue.increment(1),
      });
    } catch (e) {
      // Ürün bulunamadıysa veya hata varsa sessizce devam et
      debugPrint('⚠️ cartCount artırılamadı: $e');
    }
  }

  /// Ürünün cartCount'unu azalt
  Future<void> _decrementProductCartCount(String productId) async {
    try {
      final productDoc = await _firestore
          .collection('products')
          .doc(productId)
          .get();
      
      if (productDoc.exists) {
        final currentCount = (productDoc.data()?['cartCount'] ?? 0) as int;
        if (currentCount > 0) {
          await _firestore
              .collection('products')
              .doc(productId)
              .update({
            'cartCount': FieldValue.increment(-1),
          });
        }
      }
    } catch (e) {
      // Ürün bulunamadıysa veya hata varsa sessizce devam et
      debugPrint('⚠️ cartCount azaltılamadı: $e');
    }
  }

  /// Ürünün favoriteCount'unu artır
  Future<void> _incrementProductFavoriteCount(String productId) async {
    try {
      await _firestore
          .collection('products')
          .doc(productId)
          .update({
        'favoriteCount': FieldValue.increment(1),
      });
    } catch (e) {
      // Ürün bulunamadıysa veya hata varsa sessizce devam et
      debugPrint('⚠️ favoriteCount artırılamadı: $e');
    }
  }

  /// Ürünün favoriteCount'unu azalt
  Future<void> _decrementProductFavoriteCount(String productId) async {
    try {
      final productDoc = await _firestore
          .collection('products')
          .doc(productId)
          .get();
      
      if (productDoc.exists) {
        final currentCount = (productDoc.data()?['favoriteCount'] ?? 0) as int;
        if (currentCount > 0) {
          await _firestore
              .collection('products')
              .doc(productId)
              .update({
            'favoriteCount': FieldValue.increment(-1),
          });
        }
      }
    } catch (e) {
      // Ürün bulunamadıysa veya hata varsa sessizce devam et
      debugPrint('⚠️ favoriteCount azaltılamadı: $e');
    }
  }

  /// Kullanıcı profil bilgilerini kaydet
  Future<void> saveUserProfile({
    required String fullName,
    required String username,
    required String email,
    String? phone,
    String? address,
    String? profileImageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı giriş yapmamış');
    }

    try {
      final updateData = <String, dynamic>{
        'fullName': fullName,
        'displayName': fullName,
        'username': username,
        'usernameLower': username.toLowerCase(),
        'email': email.toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (phone != null && phone.isNotEmpty) {
        updateData['phone'] = phone;
      }
      
      if (address != null && address.isNotEmpty) {
        updateData['address'] = address;
      }
      
      if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
        updateData['profileImageUrl'] = profileImageUrl;
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(updateData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving user profile: $e');
      rethrow;
    }
  }

  /// Kullanıcı verilerini güncelle
  Future<void> updateUserData(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı giriş yapmamış');
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating user data: $e');
      rethrow;
    }
  }

  /// Kullanıcının adreslerini getir
  Future<List<Map<String, dynamic>>> getAddresses() async {
    final user = _auth.currentUser;
    if (user == null) {
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting addresses: $e');
      return [];
    }
  }

  /// Kullanıcının ödeme yöntemlerini getir
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    final user = _auth.currentUser;
    if (user == null) {
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('paymentMethods')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting payment methods: $e');
      return [];
    }
  }

  /// Ödeme yöntemi ekle (kart kaydet)
  Future<void> savePaymentMethod({
    required String name,
    required String cardNumber,
    required String expiryDate,
    String? cvv,
    bool isDefault = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı giriş yapmamış');
    }

    try {
      // Kart numarasını temizle (sadece rakamlar)
      final cleanCardNumber = cardNumber.replaceAll(RegExp(r'[^0-9]'), '');
      
      // Eğer varsayılan kart yapılıyorsa, diğer kartların isDefault'ını false yap
      if (isDefault) {
        final existingMethods = await getPaymentMethods();
        for (final method in existingMethods) {
          if (method['isDefault'] == true) {
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('paymentMethods')
                .doc(method['id'])
                .update({'isDefault': false});
          }
        }
      }

      // Yeni kartı kaydet
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('paymentMethods')
          .add({
        'name': name,
        'cardNumber': cleanCardNumber, // Tam kart numarası (güvenlik için şifrelenebilir)
        'expiryDate': expiryDate,
        'isDefault': isDefault,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving payment method: $e');
      rethrow;
    }
  }

  /// Ödeme yöntemini sil
  Future<void> deletePaymentMethod(String methodId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı giriş yapmamış');
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('paymentMethods')
          .doc(methodId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting payment method: $e');
      rethrow;
    }
  }

  /// Ödeme yöntemini varsayılan yap
  Future<void> setDefaultPaymentMethod(String methodId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı giriş yapmamış');
    }

    try {
      // Önce tüm kartların isDefault'ını false yap
      final existingMethods = await getPaymentMethods();
      for (final method in existingMethods) {
        if (method['isDefault'] == true) {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('paymentMethods')
              .doc(method['id'])
              .update({'isDefault': false});
        }
      }

      // Seçilen kartı varsayılan yap
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('paymentMethods')
          .doc(methodId)
          .update({
        'isDefault': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error setting default payment method: $e');
      rethrow;
    }
  }
}

