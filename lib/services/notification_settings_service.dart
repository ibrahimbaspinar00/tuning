import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationSettingsService {
  static final NotificationSettingsService _instance = NotificationSettingsService._internal();
  factory NotificationSettingsService() => _instance;
  NotificationSettingsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Kullanıcının bildirim ayarlarını kaydet
  Future<void> saveNotificationSettings(Map<String, bool> settings) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('notification_settings')
          .doc(user.uid)
          .set({
        ...settings,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Bildirim ayarları kaydedildi');
    } catch (e) {
      print('❌ Bildirim ayarları kaydedilemedi: $e');
      rethrow;
    }
  }

  /// Kullanıcının bildirim ayarlarını getir
  Future<Map<String, bool>> getNotificationSettings() async {
    final user = _auth.currentUser;
    if (user == null) return _getDefaultSettings();

    try {
      final doc = await _firestore
          .collection('notification_settings')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return {
          'pushNotifications': data['pushNotifications'] ?? true,
          'emailNotifications': data['emailNotifications'] ?? true,
          'smsNotifications': data['smsNotifications'] ?? false,
          'orderUpdates': data['orderUpdates'] ?? true,
          'promotionalOffers': data['promotionalOffers'] ?? false,
          'priceAlerts': data['priceAlerts'] ?? true,
          'newProductAlerts': data['newProductAlerts'] ?? true,
          'securityAlerts': data['securityAlerts'] ?? true,
        };
      } else {
        // Varsayılan ayarları kaydet
        final defaultSettings = _getDefaultSettings();
        await saveNotificationSettings(defaultSettings);
        return defaultSettings;
      }
    } catch (e) {
      print('❌ Bildirim ayarları alınamadı: $e');
      return _getDefaultSettings();
    }
  }

  /// Varsayılan bildirim ayarları
  Map<String, bool> _getDefaultSettings() {
    return {
      'pushNotifications': true,
      'emailNotifications': true,
      'smsNotifications': false,
      'orderUpdates': true,
      'promotionalOffers': false,
      'priceAlerts': true,
      'newProductAlerts': true,
      'securityAlerts': true,
    };
  }

  /// Bildirim ayarlarını dinle (gerçek zamanlı)
  Stream<Map<String, bool>> watchNotificationSettings() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(_getDefaultSettings());

    return _firestore
        .collection('notification_settings')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'pushNotifications': data['pushNotifications'] ?? true,
          'emailNotifications': data['emailNotifications'] ?? true,
          'smsNotifications': data['smsNotifications'] ?? false,
          'orderUpdates': data['orderUpdates'] ?? true,
          'promotionalOffers': data['promotionalOffers'] ?? false,
          'priceAlerts': data['priceAlerts'] ?? true,
          'newProductAlerts': data['newProductAlerts'] ?? true,
          'securityAlerts': data['securityAlerts'] ?? true,
        };
      } else {
        return _getDefaultSettings();
      }
    });
  }
}
