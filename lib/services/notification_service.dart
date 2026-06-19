import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'storage_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static const String _channelId = 'hirebuddy_high_priority';
  static const String _channelName = 'HireBuddy Notifications';

  Function(Map<String, dynamic>)? onNotificationTap;
  Function(Map<String, dynamic>)? onNotificationReceived;

  String? _lastNotificationId;
  DateTime? _lastNotificationTime;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/ic_stat_cm');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    await _createHighPriorityChannel();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Anything below can hang on iOS if APNs/Push capability isn't fully
    // configured — fire-and-forget so it never blocks app startup.
    unawaited(_setupFirebaseMessaging());
  }

  Future<void> _setupFirebaseMessaging() async {
    try {
      await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('FCM requestPermission failed: $e');
    }

    try {
      final initialMessage = await _firebaseMessaging
          .getInitialMessage()
          .timeout(const Duration(seconds: 5));
      if (initialMessage != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleMessageOpenedApp(initialMessage);
        });
      }
    } catch (e) {
      debugPrint('FCM getInitialMessage failed: $e');
    }

    try {
      final token = await _firebaseMessaging
          .getToken()
          .timeout(const Duration(seconds: 8));
      if (token != null) {
        await StorageService().saveFcmToken(token);
        debugPrint('FCM Token: $token');
      }
    } catch (e) {
      debugPrint('FCM getToken failed: $e');
    }

    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      StorageService().saveFcmToken(newToken);
    });
  }

  Future<void> _createHighPriorityChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'High priority notifications for HireBuddy',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _onNotificationResponse(NotificationResponse response) {
    if (onNotificationTap == null || response.payload == null) return;
    try {
      final payload = Map<String, String>.fromEntries(
        response.payload!.split('&').where((s) => s.contains('=')).map((item) {
          final parts = item.split('=');
          return MapEntry(parts[0], parts.sublist(1).join('='));
        }),
      );
      onNotificationTap!(payload);
    } catch (e) {
      debugPrint('Error parsing notification payload: $e');
    }
  }

  bool _isDuplicate(RemoteMessage message) {
    final now = DateTime.now();
    final id = '${message.data['bookingId'] ?? message.data['orderId'] ?? ''}_${message.data['type'] ?? ''}';

    if (_lastNotificationId == id && _lastNotificationTime != null) {
      if (now.difference(_lastNotificationTime!).inSeconds < 5) return true;
    }

    _lastNotificationId = id;
    _lastNotificationTime = now;
    return false;
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    if (_isDuplicate(message)) return;

    _showLocalNotification(message);
    if (onNotificationReceived != null) {
      onNotificationReceived!(message.data);
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Notification tapped (background): ${message.data}');
    if (onNotificationTap != null) {
      onNotificationTap!(message.data);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'High priority notifications for HireBuddy',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@drawable/ic_stat_cm',
      color: const Color(0xFF000000),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    final String title = message.notification?.title ?? 'HireBuddy';
    final String body = message.notification?.body ?? '';

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      details,
      payload: message.data.entries.map((e) => '${e.key}=${e.value}').join('&'),
    );
  }

  Future<String?> getToken() async {
    final cached = StorageService().getFcmToken();
    if (cached != null && cached.isNotEmpty) return cached;
    try {
      final token = await _firebaseMessaging
          .getToken()
          .timeout(const Duration(seconds: 3));
      if (token != null && token.isNotEmpty) {
        await StorageService().saveFcmToken(token);
      }
      return token;
    } catch (e) {
      debugPrint('NotificationService.getToken failed: $e');
      return null;
    }
  }
}
