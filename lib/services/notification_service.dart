import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  NotificationService._init();

  static const String channelId = 'jadiguna_channel_v2';
  static const String channelName = 'jadiGuna Notifications';
  static const String channelDesc = 'Notifikasi aktivitas marketplace jadiGuna';

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

      // Create notification channel with MAX priority on Android
      if (!kIsWeb && Platform.isAndroid) {
        final androidPlugin = _notifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

        const channel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );
        await androidPlugin?.createNotificationChannel(channel);
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Notification init error: $e');
    }
  }

  /// Request runtime notification permission (especially Android 13+ / API 33+)
  Future<bool> requestPermission() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final androidPlugin = _notifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidPlugin?.requestNotificationsPermission();
        return granted ?? true;
      }
      return true;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  Future<bool> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (!_isInitialized) {
        await init();
      }

      // Automatically request permission on Android 13+
      if (!kIsWeb && Platform.isAndroid) {
        await requestPermission();
      }

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const platformDetails = NotificationDetails(
        android: androidDetails,
      );

      await _notifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: platformDetails,
        payload: payload,
      );
      return true;
    } catch (e) {
      debugPrint('showNotification error: $e');
      return false;
    }
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
