// lib/data/services/firebase_messaging_service.dart
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

// Handler untuk background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📱 [BACKGROUND] Handling background message: ${message.messageId}');
  print('📱 [BACKGROUND] Message data: ${message.data}');

  // Store the message for later processing
  FirebaseMessagingService._storePendingNotification(message);
}

class FirebaseMessagingService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Callback untuk navigasi
  static Function(RemoteMessage)? _onMessageTapped;

  // Store pending notification untuk diproses setelah login/app ready
  static RemoteMessage? _pendingNotification;

  // Flag untuk track apakah app sudah ready
  static bool _isAppReady = false;

  // Global navigator key reference
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Initialize Firebase Messaging
  static Future<void> initialize({
    Function(RemoteMessage)? onMessageTapped,
    GlobalKey<NavigatorState>? navigatorKey,
  }) async {
    _onMessageTapped = onMessageTapped;
    _navigatorKey = navigatorKey;

    print('🚀 [INIT] Initializing Firebase Messaging...');

    // Request permission untuk iOS
    await _requestPermission();

    // Setup local notifications
    await _initializeLocalNotifications();

    // Setup background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tapped (app opened from background)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('📱 [OPENED_APP] App opened from background notification');
      print('📱 [OPENED_APP] Message data: ${message.data}');
      _storePendingNotification(message);

      // Process immediately if app is ready
      if (_isAppReady) {
        _processNotificationNavigation(message);
      }
    });

    // Check if app was opened from a terminated state
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print(
        '📱 [TERMINATED] App opened from terminated state via notification',
      );
      print('📱 [TERMINATED] Initial message data: ${initialMessage.data}');
      _storePendingNotification(initialMessage);
    }

    print('✅ [INIT] Firebase Messaging initialized successfully');
  }

  /// Mark app as ready to handle navigation
  static void markAppReady() {
    print('✅ [READY] App marked as ready for navigation');
    _isAppReady = true;

    // Process pending notification if exists
    if (_pendingNotification != null) {
      print('🎯 [READY] Processing pending notification...');
      Future.delayed(const Duration(milliseconds: 300), () {
        _processNotificationNavigation(_pendingNotification!);
        _pendingNotification = null;
      });
    }
  }

  /// Store pending notification
  static void _storePendingNotification(RemoteMessage message) {
    print('💾 [STORE] Storing pending notification: ${message.data}');
    _pendingNotification = message;
  }

  /// Process pending notification (call this after login/auth check)
  static Future<void> processPendingNotification() async {
    if (_pendingNotification != null) {
      print('🎯 [PENDING] Processing pending notification...');
      await Future.delayed(const Duration(milliseconds: 500));
      _processNotificationNavigation(_pendingNotification!);
      _pendingNotification = null;
    } else {
      print('ℹ️ [PENDING] No pending notification to process');
    }
  }

  /// Check if there's a pending notification
  static bool hasPendingNotification() {
    return _pendingNotification != null;
  }

  /// Request notification permission (iOS)
  static Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print(
      '📱 [PERMISSION] Notification permission: ${settings.authorizationStatus}',
    );
  }

  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('📱 [LOCAL_TAP] Local notification tapped');
        print('📱 [LOCAL_TAP] Payload: ${response.payload}');

        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final payloadData = jsonDecode(response.payload!);
            print('📱 [LOCAL_TAP] Parsed payload: $payloadData');

            final message = RemoteMessage(
              data: Map<String, dynamic>.from(payloadData['data'] ?? {}),
              notification: payloadData['notification'] != null
                  ? RemoteNotification(
                      title: payloadData['notification']['title'],
                      body: payloadData['notification']['body'],
                    )
                  : null,
            );

            print('📱 [LOCAL_TAP] Created RemoteMessage: ${message.data}');

            // Store and process
            _storePendingNotification(message);
            if (_isAppReady) {
              _processNotificationNavigation(message);
            }
          } catch (e) {
            print('❌ [LOCAL_TAP] Error parsing notification payload: $e');
          }
        }
      },
    );

    // Create notification channel untuk Android
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Channel untuk notifikasi penting',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    print('✅ [INIT] Local notifications initialized');
  }

  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    print('📱 [FOREGROUND] Received foreground message: ${message.messageId}');
    print('📱 [FOREGROUND] Message data: ${message.data}');
    print('📱 [FOREGROUND] Notification: ${message.notification?.title}');

    // Show local notification ketika app di foreground
    _showLocalNotification(message);
  }

  /// Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;

    if (notification != null) {
      print('🔨 [LOCAL] Showing local notification: ${notification.title}');

      // Prepare payload with full message data
      final payload = jsonEncode({
        'data': message.data,
        'notification': {
          'title': notification.title,
          'body': notification.body,
        },
      });

      print('🔨 [LOCAL] Payload: $payload');

      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'Channel untuk notifikasi penting',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
            styleInformation: BigTextStyleInformation(
              notification.body ?? '',
              contentTitle: notification.title,
            ),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );

      print('✅ [LOCAL] Local notification shown');
    }
  }

  /// Process notification navigation
  static void _processNotificationNavigation(RemoteMessage message) {
    print('═══════════════════════════════════════');
    print('🎯 [NAV] PROCESSING NOTIFICATION NAVIGATION');
    print('🎯 [NAV] Message data: ${message.data}');

    final data = message.data;
    final type = data['type'] as String?;

    print('🎯 [NAV] Type: $type');
    print('🎯 [NAV] Navigator key available: ${_navigatorKey != null}');
    print(
      '🎯 [NAV] Context available: ${_navigatorKey?.currentContext != null}',
    );

    if (_navigatorKey?.currentContext == null) {
      print('⚠️ [NAV] Context not ready, storing for later');
      _storePendingNotification(message);
      return;
    }

    final context = _navigatorKey!.currentContext!;

    // Navigate based on type
    try {
      switch (type) {
        case 'izin_approved':
        case 'izin_rejected':
          final izinId = int.tryParse(
            data['pengajuan_izin_id']?.toString() ?? '',
          );
          print('🎯 [NAV] Izin ID: $izinId');

          if (izinId != null) {
            print('✅ [NAV] Navigating to detail izin: $izinId');
            Navigator.of(context).pushNamed('/detail-izin', arguments: izinId);
          } else {
            print('⚠️ [NAV] Invalid izin ID, going to notifications');
            Navigator.of(context).pushNamed('/notifications');
          }
          break;

        case 'tukar_shift_approved':
        case 'tukar_shift_rejected':
          print('ℹ️ [NAV] Navigating to notifications (tukar shift)');
          Navigator.of(context).pushNamed('/notifications');
          break;

        default:
          print('ℹ️ [NAV] Default navigation to notifications');
          Navigator.of(context).pushNamed('/notifications');
      }

      print('✅ [NAV] Navigation completed successfully');
      _pendingNotification = null; // Clear after successful navigation
    } catch (e) {
      print('❌ [NAV] Navigation error: $e');
      // Try callback as fallback
      if (_onMessageTapped != null) {
        print('🔄 [NAV] Trying callback fallback');
        _onMessageTapped!(message);
      }
    }

    print('═══════════════════════════════════════');
  }

  /// Get FCM token
  static Future<String?> getToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      print('🔑 [TOKEN] FCM Token: $token');
      return token;
    } catch (e) {
      print('❌ [TOKEN] Error getting FCM token: $e');
      return null;
    }
  }

  /// Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('📢 [TOPIC] Subscribed to topic: $topic');
    } catch (e) {
      print('❌ [TOPIC] Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('📢 [TOPIC] Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ [TOPIC] Error unsubscribing from topic: $e');
    }
  }

  /// Delete FCM token
  static Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _isAppReady = false; // Reset ready flag on logout
      _pendingNotification = null; // Clear pending notification
      print('🗑️ [TOKEN] FCM token deleted');
    } catch (e) {
      print('❌ [TOKEN] Error deleting FCM token: $e');
    }
  }
}
