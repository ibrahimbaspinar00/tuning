import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'enhanced_notification_service.dart';

/// Otomatik kampanya bildirim servisi
/// Periyodik olarak kampanya bildirimleri gönderir
class CampaignNotificationService {
  static final CampaignNotificationService _instance = CampaignNotificationService._internal();
  factory CampaignNotificationService() => _instance;
  CampaignNotificationService._internal();

  final EnhancedNotificationService _notificationService = EnhancedNotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _campaignTimer;
  DateTime? _lastCampaignSent;

  // Kampanya mesajları havuzu
  final List<Map<String, dynamic>> _campaigns = [
    {
      'title': '🎉 Özel İndirim Fırsatı!',
      'description': 'Tüm ürünlerde geçerli özel indirimler sizi bekliyor!',
      'discountPercentage': 15.0,
    },
    {
      'title': '⚡ Flash Sale Başladı!',
      'description': 'Seçili ürünlerde %30\'a varan indirimler!',
      'discountPercentage': 30.0,
    },
    {
      'title': '🛍️ Kategorilerde Büyük İndirim!',
      'description': 'Sevdiğiniz kategorilerde özel fırsatlar!',
      'discountPercentage': 20.0,
    },
    {
      'title': '🎁 Ücretsiz Kargo Fırsatı!',
      'description': '150₺ ve üzeri alışverişlerde ücretsiz kargo!',
      'discountPercentage': 0.0,
    },
    {
      'title': '🔥 Sınırlı Süre!',
      'description': 'Bugüne özel özel fırsatlar kaçmasın!',
      'discountPercentage': 25.0,
    },
    {
      'title': '💎 Premium Üyelere Özel',
      'description': 'Premium üyelere özel ekstra indirimler!',
      'discountPercentage': 18.0,
    },
  ];

  /// Servisi başlat
  void start() {
    // Her 4-6 saatte bir kampanya gönder (rastgele)
    _scheduleNextCampaign();
  }

  /// Servisi durdur
  void stop() {
    _campaignTimer?.cancel();
    _campaignTimer = null;
  }

  /// Bir sonraki kampanyayı planla
  void _scheduleNextCampaign() {
    if (_campaignTimer != null) {
      _campaignTimer?.cancel();
    }

    // Rastgele süre: 4-6 saat arası
    final random = Random();
    final hours = 4 + random.nextDouble() * 2; // 4-6 saat
    final minutes = (hours * 60).round();
    final duration = Duration(minutes: minutes);

    _campaignTimer = Timer(duration, () {
      _sendRandomCampaign();
      _scheduleNextCampaign(); // Bir sonraki kampanyayı planla
    });
  }

  /// Rastgele kampanya gönder
  Future<void> _sendRandomCampaign() async {
    // Son kampanyadan 2 saatten az geçmişse gönderme
    if (_lastCampaignSent != null) {
      final hoursSinceLastCampaign = DateTime.now().difference(_lastCampaignSent!).inHours;
      if (hoursSinceLastCampaign < 2) {
        _scheduleNextCampaign();
        return;
      }
    }

    // Kullanıcı giriş yapmamışsa gönderme
    if (_auth.currentUser == null) {
      _scheduleNextCampaign();
      return;
    }

    try {
      final random = Random();
      final campaign = _campaigns[random.nextInt(_campaigns.length)];

      await _notificationService.sendCampaignNotification(
        title: campaign['title'] as String,
        description: campaign['description'] as String,
        discountPercentage: campaign['discountPercentage'] as double,
        validUntil: DateTime.now().add(const Duration(days: 3)),
      );

      _lastCampaignSent = DateTime.now();
    } catch (e) {
      // Hata olsa bile devam et
    }
  }

  /// Manuel kampanya gönder (test için)
  Future<void> sendTestCampaign() async {
    final random = Random();
    final campaign = _campaigns[random.nextInt(_campaigns.length)];

    await _notificationService.sendCampaignNotification(
      title: campaign['title'] as String,
      description: campaign['description'] as String,
      discountPercentage: campaign['discountPercentage'] as double,
      validUntil: DateTime.now().add(const Duration(days: 3)),
    );
  }

  /// Özel kampanya ekle
  void addCustomCampaign({
    required String title,
    required String description,
    required double discountPercentage,
  }) {
    _campaigns.add({
      'title': title,
      'description': description,
      'discountPercentage': discountPercentage,
    });
  }
}
