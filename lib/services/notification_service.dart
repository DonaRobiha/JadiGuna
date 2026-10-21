import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  NotificationService._init();

  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    try {
      await _notifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Can handle notification tap routing
        },
      );
      _isInitialized = true;
    } catch (e) {
      // In case running on platform without notification support
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'jadiguna_channel',
      'jadiGuna Notifications',
      channelDescription: 'Notifikasi aktivitas marketplace jadiGuna',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const platformDetails = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _notifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: platformDetails,
        payload: payload,
      );
    } catch (_) {}
  }

  Future<void> showNewMessageNotification({
    required String senderName,
    required String message,
    required String itemTitle,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Pesan Baru dari $senderName ($itemTitle)',
      body: message,
    );
  }

  Future<void> showListingStatusNotification({
    required String itemTitle,
    required String newStatus,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Status Iklan Diperbarui',
      body: 'Barang "$itemTitle" kini berstatus "$newStatus".',
    );
  }

  Future<void> showRegistrationSuccessNotification({
    required String name,
    required String email,
  }) async {
    await showNotification(
      id: 1001,
      title: 'Pendaftaran Berhasil 🎉',
      body: 'Selamat datang di jadiGuna, $name! Notifikasi dan rincian akun telah dikirim ke $email.',
    );
  }
}
