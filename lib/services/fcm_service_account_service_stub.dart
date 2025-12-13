/// FCM Service Account Service stub for web platform
/// Web'de FCM Service Account kullanılmaz

class FCMServiceAccountService {
  static final FCMServiceAccountService _instance = FCMServiceAccountService._internal();
  factory FCMServiceAccountService() => _instance;
  FCMServiceAccountService._internal();

  Future<void> sendNotification({
    String? token,
    String? fcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? type,
  }) async {
    // Web'de çalışmaz
  }
}

