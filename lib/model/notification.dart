import 'package:cloud_firestore/cloud_firestore.dart';

/// Push notification modeli
class AppNotification {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final String type; // 'order', 'promotion', 'system', 'stock'
  final Map<String, dynamic>? data;
  final String? userId; // null ise tüm kullanıcılara gönderilir
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final bool isRead;
  final String? actionUrl;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.type,
    this.data,
    this.userId,
    required this.createdAt,
    this.scheduledAt,
    this.isRead = false,
    this.actionUrl,
  });

  /// Firestore'dan model oluştur
  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // createdAt için güvenli parsing
    DateTime createdAt;
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is DateTime) {
        createdAt = data['createdAt'] as DateTime;
      } else {
        // Fallback: şimdi
        createdAt = DateTime.now();
      }
    } else {
      // createdAt yoksa şimdi kullan
      createdAt = DateTime.now();
    }
    
    // scheduledAt için güvenli parsing
    DateTime? scheduledAt;
    if (data['scheduledAt'] != null) {
      if (data['scheduledAt'] is Timestamp) {
        scheduledAt = (data['scheduledAt'] as Timestamp).toDate();
      } else if (data['scheduledAt'] is DateTime) {
        scheduledAt = data['scheduledAt'] as DateTime;
      }
    }
    
    return AppNotification(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      imageUrl: data['imageUrl'],
      type: data['type'] ?? 'system',
      data: data['data'],
      userId: data['userId'],
      createdAt: createdAt,
      scheduledAt: scheduledAt,
      isRead: data['isRead'] ?? false,
      actionUrl: data['actionUrl'],
    );
  }

  /// Firestore'a gönderilecek map
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'type': type,
      'data': data,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'scheduledAt': scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
      'isRead': isRead,
      'actionUrl': actionUrl,
    };
  }

  /// Kopyalama metodu
  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? imageUrl,
    String? type,
    Map<String, dynamic>? data,
    String? userId,
    DateTime? createdAt,
    DateTime? scheduledAt,
    bool? isRead,
    String? actionUrl,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      data: data ?? this.data,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      isRead: isRead ?? this.isRead,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }
}

/// Bildirim kategorileri
enum NotificationType {
  order('Sipariş'),
  promotion('Promosyon'),
  system('Sistem'),
  stock('Stok'),
  payment('Ödeme'),
  shipping('Kargo');

  const NotificationType(this.displayName);
  final String displayName;
}

/// Bildirim durumları
enum NotificationStatus {
  pending('Beklemede'),
  sent('Gönderildi'),
  delivered('Teslim Edildi'),
  failed('Başarısız');

  const NotificationStatus(this.displayName);
  final String displayName;
}

