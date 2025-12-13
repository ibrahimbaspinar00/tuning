/// Ödeme gateway'leri için abstract interface
/// Gerçek ödeme gateway entegrasyonları bu interface'i implement eder
abstract class PaymentGateway {
  /// Gateway adı
  String get name;

  /// Ödeme işlemini gerçekleştir
  /// [paymentData] Ödeme bilgileri (kart numarası, CVV, vb.)
  /// [amount] Ödeme tutarı
  /// [description] Ödeme açıklaması
  /// [orderId] Sipariş ID'si (opsiyonel)
  Future<PaymentGatewayResult> processPayment({
    required Map<String, dynamic> paymentData,
    required double amount,
    required String description,
    String? orderId,
  });

  /// Ödeme durumunu kontrol et
  Future<PaymentGatewayResult> checkPaymentStatus(String paymentId);

  /// İade işlemini gerçekleştir
  Future<PaymentGatewayResult> refundPayment({
    required String paymentId,
    required double amount,
    String? reason,
  });

  /// Gateway'in aktif olup olmadığını kontrol et
  bool get isAvailable;
}

/// Ödeme gateway sonucu
class PaymentGatewayResult {
  final bool success;
  final String? paymentId;
  final String? transactionId;
  final String message;
  final Map<String, dynamic>? metadata;

  PaymentGatewayResult({
    required this.success,
    this.paymentId,
    this.transactionId,
    required this.message,
    this.metadata,
  });
}

