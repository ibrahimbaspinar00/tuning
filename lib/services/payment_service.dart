import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

/// Dijital ödeme işlemleri için servis
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  /// Ödeme işlemini gerçekleştir
  /// [paymentData] Ödeme bilgileri (kart numarası, CVV, vb.)
  /// [amount] Ödeme tutarı
  /// [description] Ödeme açıklaması
  /// [orderId] Sipariş ID'si (opsiyonel)
  Future<PaymentResult> processPayment({
    required Map<String, dynamic> paymentData,
    required double amount,
    required String description,
    String? orderId,
  }) async {
    try {
      // Ödeme işlemini başlat
      final paymentId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Ödeme kaydı oluştur
      await _createPaymentRecord(
        paymentId: paymentId,
        amount: amount,
        description: description,
        orderId: orderId,
        status: 'processing',
        paymentMethod: paymentData['method'] ?? 'credit_card',
      );

      // Ödeme validasyonu
      if (!_validatePaymentData(paymentData)) {
        await _updatePaymentStatus(paymentId, 'failed', 'Geçersiz ödeme bilgileri');
        return PaymentResult(
          success: false,
          paymentId: paymentId,
          message: 'Geçersiz ödeme bilgileri',
        );
      }

      // Simüle edilmiş ödeme işlemi (test modunda)
      // Gerçek uygulamada burada ödeme gateway API'si çağrılır
      await Future.delayed(const Duration(seconds: 2)); // İşlem süresi simülasyonu

      // Ödeme başarı simülasyonu (%95 başarı oranı)
      final random = Random();
      final isSuccess = random.nextDouble() > 0.05; // %95 başarı şansı

      if (isSuccess) {
        await _updatePaymentStatus(paymentId, 'success', 'Ödeme başarıyla tamamlandı');
        
        // Ödeme geçmişine ekle
        await _addPaymentHistory(
          paymentId: paymentId,
          amount: amount,
          description: description,
          orderId: orderId,
          paymentMethod: paymentData['method'] ?? 'credit_card',
        );

        return PaymentResult(
          success: true,
          paymentId: paymentId,
          message: 'Ödeme başarıyla tamamlandı',
        );
      } else {
        await _updatePaymentStatus(paymentId, 'failed', 'Ödeme işlemi başarısız oldu');
        return PaymentResult(
          success: false,
          paymentId: paymentId,
          message: 'Ödeme işlemi başarısız oldu. Lütfen tekrar deneyin.',
        );
      }
    } catch (e) {
      debugPrint('Payment processing error: $e');
      return PaymentResult(
        success: false,
        paymentId: null,
        message: 'Ödeme işlemi sırasında bir hata oluştu: $e',
      );
    }
  }

  /// Kart ile ödeme (3D Secure simülasyonu)
  Future<PaymentResult> processCardPayment({
    required String cardNumber,
    required String cardHolderName,
    required String expiryDate,
    required String cvv,
    required double amount,
    required String description,
    String? orderId,
  }) async {
    // Kart numarasını temizle (sadece rakamlar)
    final cleanCardNumber = cardNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Test kartları kontrolü
    if (_isTestCard(cleanCardNumber)) {
      // Test kartı - otomatik başarılı
      return await processPayment(
        paymentData: {
          'method': 'credit_card',
          'cardNumber': cleanCardNumber,
          'cardHolderName': cardHolderName,
          'expiryDate': expiryDate,
          'cvv': cvv,
        },
        amount: amount,
        description: description,
        orderId: orderId,
      );
    }

    // Gerçek kart ödeme işlemi (simülasyon)
    return await processPayment(
      paymentData: {
        'method': 'credit_card',
        'cardNumber': cleanCardNumber,
        'cardHolderName': cardHolderName,
        'expiryDate': expiryDate,
        'cvv': cvv,
      },
      amount: amount,
      description: description,
      orderId: orderId,
    );
  }

  /// Kapıda ödeme kaydı oluştur
  Future<PaymentResult> processCashOnDelivery({
    required double amount,
    required String description,
    required String orderId,
  }) async {
    try {
      final paymentId = DateTime.now().millisecondsSinceEpoch.toString();
      
      await _createPaymentRecord(
        paymentId: paymentId,
        amount: amount,
        description: description,
        orderId: orderId,
        status: 'pending',
        paymentMethod: 'cash_on_delivery',
      );

      return PaymentResult(
        success: true,
        paymentId: paymentId,
        message: 'Kapıda ödeme kaydı oluşturuldu',
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        paymentId: null,
        message: 'Kapıda ödeme kaydı oluşturulamadı: $e',
      );
    }
  }

  /// Banka havalesi kaydı oluştur
  Future<PaymentResult> processBankTransfer({
    required double amount,
    required String description,
    required String orderId,
  }) async {
    try {
      final paymentId = DateTime.now().millisecondsSinceEpoch.toString();
      
      await _createPaymentRecord(
        paymentId: paymentId,
        amount: amount,
        description: description,
        orderId: orderId,
        status: 'pending',
        paymentMethod: 'bank_transfer',
      );

      return PaymentResult(
        success: true,
        paymentId: paymentId,
        message: 'Banka havalesi kaydı oluşturuldu. Ödeme onayı bekleniyor.',
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        paymentId: null,
        message: 'Banka havalesi kaydı oluşturulamadı: $e',
      );
    }
  }

  /// Ödeme kaydı oluştur
  Future<void> _createPaymentRecord({
    required String paymentId,
    required double amount,
    required String description,
    String? orderId,
    required String status,
    required String paymentMethod,
  }) async {
    if (_currentUserId == null) throw Exception('Kullanıcı giriş yapmamış');

    await _firestore.collection('payments').doc(paymentId).set({
      'id': paymentId,
      'userId': _currentUserId,
      'amount': amount,
      'description': description,
      'orderId': orderId,
      'status': status,
      'paymentMethod': paymentMethod,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Ödeme durumunu güncelle
  Future<void> _updatePaymentStatus(String paymentId, String status, String message) async {
    await _firestore.collection('payments').doc(paymentId).update({
      'status': status,
      'message': message,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Ödeme geçmişine ekle
  Future<void> _addPaymentHistory({
    required String paymentId,
    required double amount,
    required String description,
    String? orderId,
    required String paymentMethod,
  }) async {
    if (_currentUserId == null) return;

    await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('paymentHistory')
        .doc(paymentId)
        .set({
      'paymentId': paymentId,
      'amount': amount,
      'description': description,
      'orderId': orderId,
      'paymentMethod': paymentMethod,
      'status': 'success',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Ödeme bilgilerini doğrula
  bool _validatePaymentData(Map<String, dynamic> paymentData) {
    final cardNumber = paymentData['cardNumber']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    final expiryDate = paymentData['expiryDate']?.toString() ?? '';
    final cvv = paymentData['cvv']?.toString() ?? '';
    final cardHolderName = paymentData['cardHolderName']?.toString() ?? '';

    // Kart numarası kontrolü (Luhn algoritması)
    if (cardNumber.length < 13 || cardNumber.length > 19) return false;
    if (!_luhnCheck(cardNumber)) return false;

    // CVV kontrolü
    if (cvv.length < 3 || cvv.length > 4) return false;

    // Son kullanma tarihi kontrolü
    if (!_validateExpiryDate(expiryDate)) return false;

    // Kart sahibi adı kontrolü
    if (cardHolderName.trim().isEmpty) return false;

    return true;
  }

  /// Luhn algoritması ile kart numarası kontrolü
  bool _luhnCheck(String cardNumber) {
    int sum = 0;
    bool alternate = false;
    
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int n = int.parse(cardNumber[i]);
      
      if (alternate) {
        n *= 2;
        if (n > 9) {
          n = (n % 10) + 1;
        }
      }
      
      sum += n;
      alternate = !alternate;
    }
    
    return (sum % 10) == 0;
  }

  /// Son kullanma tarihi kontrolü
  bool _validateExpiryDate(String expiryDate) {
    try {
      final parts = expiryDate.split('/');
      if (parts.length != 2) return false;

      final month = int.parse(parts[0]);
      final year = int.parse(parts[1]);

      if (month < 1 || month > 12) return false;

      final now = DateTime.now();
      final currentYear = now.year % 100;
      final currentMonth = now.month;

      if (year < currentYear) return false;
      if (year == currentYear && month < currentMonth) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Test kartı kontrolü
  bool _isTestCard(String cardNumber) {
    // Test kartları (her zaman başarılı)
    final testCards = [
      '4111111111111111', // Visa test
      '5555555555554444', // Mastercard test
      '378282246310005',  // Amex test
    ];
    return testCards.contains(cardNumber);
  }

  /// Ödeme geçmişini getir
  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    if (_currentUserId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('paymentHistory')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting payment history: $e');
      return [];
    }
  }

  /// Ödeme durumunu kontrol et
  Future<Map<String, dynamic>?> getPaymentStatus(String paymentId) async {
    try {
      final doc = await _firestore.collection('payments').doc(paymentId).get();
      return doc.data();
    } catch (e) {
      debugPrint('Error getting payment status: $e');
      return null;
    }
  }
}

/// Ödeme sonucu
class PaymentResult {
  final bool success;
  final String? paymentId;
  final String message;

  PaymentResult({
    required this.success,
    this.paymentId,
    required this.message,
  });
}
