import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Kullanıcı kimlik doğrulama servisi
/// Firebase Authentication ve Firestore entegrasyonu
class UserAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isInitialized = false;

  /// Servisi başlat (isteğe bağlı, ön yükleme için)
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Firebase'in hazır olduğundan emin ol
      await _auth.authStateChanges().first.timeout(
        const Duration(seconds: 5),
      );
      _isInitialized = true;
    } on TimeoutException {
      debugPrint('Firebase Auth initialization timeout');
      // Timeout olsa bile devam et
      _isInitialized = true;
    } catch (e) {
      debugPrint('UserAuthService initialization error: $e');
      // Hata olsa bile devam et
      _isInitialized = true;
    }
  }

  /// E-posta ve şifre ile giriş yap
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      // Email'i lowercase'e çevir
      final normalizedEmail = email.trim().toLowerCase();
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('signInWithEmail error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('signInWithEmail unexpected error: $e');
      rethrow;
    }
  }

  /// Kullanıcı adı ve şifre ile giriş yap
  /// Firestore'da kullanıcı adına göre email'i bulur ve giriş yapar
  Future<User?> signInWithUsername(String username, String password) async {
    try {
      // Kullanıcı adını lowercase'e çevir
      final normalizedUsername = username.trim().toLowerCase();
      
      // Firestore'da kullanıcı adına göre email'i bul
      final userQuery = await _firestore
          .collection('users')
          .where('usernameLower', isEqualTo: normalizedUsername)
          .limit(1)
          .get();
      
      if (userQuery.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Bu kullanıcı adı ile kayıtlı kullanıcı bulunamadı.',
        );
      }
      
      final userData = userQuery.docs.first.data();
      final email = userData['email'] as String?;
      
      if (email == null || email.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Kullanıcı e-posta adresi bulunamadı.',
        );
      }
      
      // Bulunan email ile giriş yap
      return await signInWithEmail(email, password);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint('signInWithUsername error: $e');
      throw FirebaseAuthException(
        code: 'sign-in-failed',
        message: 'Giriş yapılırken bir hata oluştu: $e',
      );
    }
  }

  /// Kullanıcı adı, e-posta ve şifre ile kayıt ol
  /// Firestore'da kullanıcı dokümanı oluşturur
  Future<User?> signUpWithUsername(
    String fullName,
    String username,
    String email,
    String password,
  ) async {
    try {
      // Normalize et
      final normalizedEmail = email.trim().toLowerCase();
      final normalizedUsername = username.trim().toLowerCase();
      final trimmedFullName = fullName.trim();
      
      // Kullanıcı adı kontrolü - Firestore'da var mı?
      final usernameCheck = await _firestore
          .collection('users')
          .where('usernameLower', isEqualTo: normalizedUsername)
          .limit(1)
          .get();
      
      if (usernameCheck.docs.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'username-already-in-use',
          message: 'Bu kullanıcı adı zaten kullanılıyor.',
        );
      }
      
      // Email kontrolü - Firebase Auth'ta var mı?
      // (Firebase Auth'ta direkt kontrol yapamayız, ama kayıt sırasında hata alırız)
      
      // Firebase Authentication'da kullanıcı oluştur
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      
      final user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-creation-failed',
          message: 'Kullanıcı oluşturulamadı.',
        );
      }
      
      // Firestore'da kullanıcı dokümanı oluştur
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'email': normalizedEmail,
          'username': username.trim(),
          'usernameLower': normalizedUsername,
          'fullName': trimmedFullName,
          'displayName': trimmedFullName,
          'role': 'user',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: false)); // merge: false = doküman yoksa oluştur, varsa hata ver
        
        debugPrint('✅ Firestore kullanıcı dokümanı oluşturuldu: ${user.uid}');
      } catch (e) {
        debugPrint('❌ Firestore kullanıcı dokümanı oluşturma hatası: $e');
        
        // Firestore kaydı başarısız oldu, ama Auth kaydı başarılı
        // Kullanıcıyı sil ve hata fırlat
        try {
          await user.delete();
        } catch (deleteError) {
          debugPrint('Kullanıcı silme hatası: $deleteError');
        }
        
        throw FirebaseAuthException(
          code: 'firestore-write-failed',
          message: 'Kullanıcı oluşturuldu ancak veriler kaydedilemedi. Lütfen tekrar deneyin.',
        );
      }
      
      return user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint('signUpWithUsername error: $e');
      if (e is FirebaseAuthException) {
        rethrow;
      }
      throw FirebaseAuthException(
        code: 'sign-up-failed',
        message: 'Kayıt olunurken bir hata oluştu: $e',
      );
    }
  }

  /// Şifre sıfırlama e-postası gönder
  Future<void> resetPassword(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      await _auth.sendPasswordResetEmail(email: normalizedEmail);
    } on FirebaseAuthException catch (e) {
      debugPrint('resetPassword error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('resetPassword unexpected error: $e');
      throw FirebaseAuthException(
        code: 'password-reset-failed',
        message: 'Şifre sıfırlama e-postası gönderilemedi: $e',
      );
    }
  }

  /// Mevcut kullanıcıyı getir
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Çıkış yap
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Hesabı sil
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı giriş yapmamış');
    }

    try {
      // Firestore'daki kullanıcı verilerini sil
      final userDocRef = _firestore.collection('users').doc(user.uid);
      
      // Alt koleksiyonları da sil
      final batch = _firestore.batch();
      
      // Favoriler
      final favoritesSnapshot = await userDocRef.collection('favorites').get();
      for (var doc in favoritesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Sepet
      final cartSnapshot = await userDocRef.collection('cart').get();
      for (var doc in cartSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Adresler
      final addressesSnapshot = await userDocRef.collection('addresses').get();
      for (var doc in addressesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Ödeme yöntemleri
      final paymentMethodsSnapshot = await userDocRef.collection('paymentMethods').get();
      for (var doc in paymentMethodsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Ana kullanıcı dokümanını sil
      batch.delete(userDocRef);
      
      // Tüm işlemleri commit et
      await batch.commit();
      
      // Firebase Auth'tan kullanıcıyı sil
      await user.delete();
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }
}

