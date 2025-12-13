import 'dart:math';
import 'package:flutter/foundation.dart';
import 'payment_gateway_interface.dart';

/// Simüle edilmiş ödeme gateway (test/development için)
class MockPaymentGateway implements PaymentGateway {
  @override
  String get name => 'Mock Payment Gateway';

  @override
  bool get isAvailable => true;

  @override
  Future<PaymentGatewayResult> processPayment({
    required Map<String, dynamic> paymentData,
    required double amount,
    required String description,
    String? orderId,
  }) async {
    try {
      // Ödeme validasyonu
      if (!_validatePaymentData(paymentData)) {
        return PaymentGatewayResult(
          success: false,
          paymentId: null,
          message: 'Geçersiz ödeme bilgileri',
        );
      }

      // İşlem süresi simülasyonu
      await Future.delayed(const Duration(seconds: 2));

      // Ödeme başarı simülasyonu (%95 başarı oranı)
      final random = Random();
      final isSuccess = random.nextDouble() > 0.05; // %95 başarı şansı

      final paymentId = DateTime.now().millisecondsSinceEpoch.toString();
      final transactionId = 'TXN_${paymentId}_${random.nextInt(10000)}';

      if (isSuccess) {
        return PaymentGatewayResult(
          success: true,
          paymentId: paymentId,
          transactionId: transactionId,
          message: 'Ödeme başarıyla tamamlandı',
          metadata: {
            'gateway': 'mock',
            'simulated': true,
            'amount': amount,
            'orderId': orderId,
          },
        );
      } else {
        return PaymentGatewayResult(
          success: false,
          paymentId: paymentId,
          transactionId: transactionId,
          message: 'Ödeme işlemi başarısız oldu. Lütfen tekrar deneyin.',
          metadata: {
            'gateway': 'mock',
            'simulated': true,
            'error': 'simulated_failure',
          },
        );
      }
    } catch (e) {
      debugPrint('Mock payment gateway error: $e');
      return PaymentGatewayResult(
        success: false,
        paymentId: null,
        message: 'Ödeme işlemi sırasında bir hata oluştu: $e',
      );
    }
  }

  @override
  Future<PaymentGatewayResult> checkPaymentStatus(String paymentId) async {
    // Mock gateway için her zaman başarılı döner
    await Future.delayed(const Duration(milliseconds: 500));
    return PaymentGatewayResult(
      success: true,
      paymentId: paymentId,
      message: 'Ödeme durumu kontrol edildi',
      metadata: {'status': 'success'},
    );
  }

  @override
  Future<PaymentGatewayResult> refundPayment({
    required String paymentId,
    required double amount,
    String? reason,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    final random = Random();
    final isSuccess = random.nextDouble() > 0.1; // %90 başarı şansı

    if (isSuccess) {
      return PaymentGatewayResult(
        success: true,
        paymentId: paymentId,
        transactionId: 'REFUND_${DateTime.now().millisecondsSinceEpoch}',
        message: 'İade işlemi başarıyla tamamlandı',
        metadata: {
          'refundAmount': amount,
          'reason': reason,
        },
      );
    } else {
      return PaymentGatewayResult(
        success: false,
        paymentId: paymentId,
        message: 'İade işlemi başarısız oldu',
      );
    }
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
}

