// Stub file for flutter_local_notifications on web
// This file provides empty implementations to prevent compilation errors on web platform

class FlutterLocalNotificationsPlugin {
  Future<void> initialize(dynamic settings, {Function? onDidReceiveNotificationResponse}) async {}
  Future<void> show(int id, String? title, String? body, dynamic details, {String? payload}) async {}
  Future<void> cancel(int id) async {}
  Future<void> cancelAll() async {}
  T? resolvePlatformSpecificImplementation<T>() => null;
}

class AndroidFlutterLocalNotificationsPlugin {
  Future<void> createNotificationChannel(AndroidNotificationChannel channel) async {}
}

class AndroidInitializationSettings {
  final String? defaultIcon;
  const AndroidInitializationSettings({this.defaultIcon});
}

class DarwinInitializationSettings {
  const DarwinInitializationSettings();
}

class InitializationSettings {
  final dynamic android;
  final dynamic iOS;
  const InitializationSettings({this.android, this.iOS});
}

class AndroidNotificationChannel {
  final String id;
  final String name;
  final String? description;
  final dynamic importance;
  final bool? playSound;
  final bool? enableVibration;
  const AndroidNotificationChannel(
    this.id,
    this.name, {
    this.description,
    this.importance,
    this.playSound,
    this.enableVibration,
  });
}

class AndroidNotificationDetails {
  final String channelId;
  final String channelName;
  final String? channelDescription;
  final dynamic importance;
  final dynamic priority;
  final bool playSound;
  final bool enableVibration;
  final String? icon;
  const AndroidNotificationDetails({
    required this.channelId,
    required this.channelName,
    this.channelDescription,
    this.importance,
    this.priority,
    this.playSound = true,
    this.enableVibration = true,
    this.icon,
  });
}

class DarwinNotificationDetails {
  final bool presentAlert;
  final bool presentBadge;
  final bool presentSound;
  const DarwinNotificationDetails({
    this.presentAlert = true,
    this.presentBadge = true,
    this.presentSound = true,
  });
}

class NotificationDetails {
  final dynamic android;
  final dynamic iOS;
  const NotificationDetails({this.android, this.iOS});
}

class NotificationResponse {
  final String? payload;
  final int? id;
  final String? actionId;
  final int? input;
  const NotificationResponse({
    this.payload,
    this.id,
    this.actionId,
    this.input,
  });
}

enum Importance { low, defaultImportance, high, max }
enum Priority { min, low, defaultPriority, high, max }

