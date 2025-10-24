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
  debugPrint('🔔 Background message received: ${message.messageId}');
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

    debugPrint('🔥 Initializing Firebase Messaging...');

    // Request permission untuk iOS
    await _requestPermission();

    // Setup local notifications
    await _initializeLocalNotifications();

    // Setup background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // ✅ Handle notification tapped (app opened from background)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('🔔 App opened from background notification');
      debugPrint('📦 Message data: ${message.data}');
      _storePendingNotification(message);

      // Process immediately if app is ready
      if (_isAppReady) {
        _processNotificationNavigation(message);
      } else {
        debugPrint('⏳ App not ready yet, storing notification');
      }
    });

    // ✅ Check if app was opened from a terminated state
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🔔 App opened from terminated state');
      debugPrint('📦 Initial message data: ${initialMessage.data}');
      _storePendingNotification(initialMessage);
    }

    debugPrint('✅ Firebase Messaging initialized');
  }

  /// Mark app as ready to handle navigation
  static void markAppReady() {
    debugPrint('✅ App marked as ready');
    _isAppReady = true;

    // Process pending notification if exists
    if (_pendingNotification != null) {
      debugPrint('🔄 Processing pending notification...');
      Future.delayed(const Duration(milliseconds: 500), () {
        _processNotificationNavigation(_pendingNotification!);
        _pendingNotification = null;
      });
    } else {
      debugPrint('ℹ️ No pending notifications');
    }
  }

  /// Store pending notification
  static void _storePendingNotification(RemoteMessage message) {
    debugPrint('💾 Storing pending notification');
    debugPrint('📦 Type: ${message.data['type']}');
    _pendingNotification = message;
  }

  /// Process pending notification (call this after login/auth check)
  static Future<void> processPendingNotification() async {
    if (_pendingNotification != null) {
      await Future.delayed(const Duration(milliseconds: 500));
      _processNotificationNavigation(_pendingNotification!);
      _pendingNotification = null;
    }
  }

  /// Check if there's a pending notification
  static bool hasPendingNotification() {
    return _pendingNotification != null;
  }

  /// Request notification permission (iOS)
  static Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('📱 Notification permission: ${settings.authorizationStatus}');
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
        debugPrint('🔔 Local notification tapped!');
        debugPrint('📦 Payload: ${response.payload}');

        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final payloadData = jsonDecode(response.payload!);

            final message = RemoteMessage(
              data: Map<String, dynamic>.from(payloadData['data'] ?? {}),
              notification: payloadData['notification'] != null
                  ? RemoteNotification(
                      title: payloadData['notification']['title'],
                      body: payloadData['notification']['body'],
                    )
                  : null,
            );

            debugPrint('🔄 Processing tapped notification...');

            // Store and process
            _storePendingNotification(message);
            if (_isAppReady) {
              _processNotificationNavigation(message);
            } else {
              debugPrint('⏳ App not ready, notification stored');
            }
          } catch (e) {
            debugPrint('❌ Error parsing notification payload: $e');
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
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    debugPrint('✅ Local notifications initialized');
  }

  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 Foreground message received');
    debugPrint('📦 Data: ${message.data}');
    debugPrint('📬 Notification: ${message.notification?.title}');

    // Show local notification ketika app di foreground
    _showLocalNotification(message);
  }

  /// Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;

    if (notification != null) {
      // Prepare payload with full message data
      final payload = jsonEncode({
        'data': message.data,
        'notification': {
          'title': notification.title,
          'body': notification.body,
        },
      });

      debugPrint('📤 Showing local notification: ${notification.title}');

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

      debugPrint('✅ Local notification shown');
    }
  }

  /// Process notification navigation based on type
  static void _processNotificationNavigation(RemoteMessage message) {
    debugPrint('🎯 Processing notification navigation');
    debugPrint('🎯 Message data: ${message.data}');

    final data = message.data;
    final type = data['type'] as String?;

    debugPrint('🎯 Notification type: $type');

    if (_navigatorKey?.currentContext == null) {
      debugPrint('⚠️ Context not ready, storing for later');
      _storePendingNotification(message);
      return;
    }

    final context = _navigatorKey!.currentContext!;

    try {
      switch (type) {
        // ========================================
        // PENGAJUAN IZIN (MOBILE) ✅
        // ========================================
        case 'izin_approved':
        case 'izin_rejected':
          final izinId = int.tryParse(
            data['pengajuan_izin_id']?.toString() ?? '',
          );
          debugPrint('🎯 [IZIN] Navigating to detail izin: $izinId');

          if (izinId != null) {
            Navigator.of(context).pushNamed('/detail-izin', arguments: izinId);
          } else {
            Navigator.of(context).pushNamed('/notifications');
          }
          break;

        // ========================================
        // PENGAJUAN LEMBUR (MOBILE) ✅
        // ========================================
        case 'lembur_approved':
        case 'lembur_rejected':
          final lemburId = int.tryParse(
            data['pengajuan_lembur_id']?.toString() ?? '',
          );
          debugPrint('🎯 [LEMBUR] Navigating to detail lembur: $lemburId');

          if (lemburId != null) {
            Navigator.of(
              context,
            ).pushNamed('/detail-lembur', arguments: lemburId);
          } else {
            Navigator.of(context).pushNamed('/notifications');
          }
          break;

        // ========================================
        // LEMBUR CONFIRMATION (MOBILE) ✅
        // ========================================
        case 'lembur_confirmed':
        case 'lembur_rejected_by_admin':
        case 'lembur_dikonfirmasi':
        case 'lembur_ditolak':
          final lemburId = int.tryParse(
            data['pengajuan_lembur_id']?.toString() ?? '',
          );
          debugPrint(
            '🎯 [LEMBUR KONFIRMASI] Navigating to detail lembur: $lemburId',
          );

          if (lemburId != null) {
            Navigator.of(
              context,
            ).pushNamed('/detail-lembur', arguments: lemburId);
          } else {
            Navigator.of(context).pushNamed('/history-absensi');
          }
          break;

        // ========================================
        // TUKAR SHIFT (MOBILE PENGAJU) ✅
        // ========================================
        case 'tukar_shift_request': // Permintaan masuk
        case 'tukar_shift_approved': // Disetujui
        case 'tukar_shift_rejected': // Ditolak
          final tukarShiftId = int.tryParse(
            data['tukar_shift_id']?.toString() ?? '',
          );
          debugPrint('🎯 [TUKAR SHIFT] ID: $tukarShiftId');

          // Navigate to jadwal page to see the updated schedule
          Navigator.of(context).pushNamed('/jadwal');
          break;

        // ========================================
        // PRESENSI - ALPA (MOBILE) ✅
        // ========================================
        case 'presensi_alpa':
          debugPrint('🎯 [ALPA] Navigating to history absensi');
          Navigator.of(context).pushNamed('/history-absensi');
          break;

        // ========================================
        // PRESENSI - UPDATE ADMIN (MOBILE) ✅
        // ========================================
        case 'presensi_updated':
        case 'presensi_status_changed':
        case 'presensi_diupdate':
        case 'presensi_tidak_pulang':
          debugPrint('🎯 [PRESENSI UPDATE] Navigating to history absensi');
          Navigator.of(context).pushNamed('/history-absensi');
          break;

        // ========================================
        // JADWAL BARU/UPDATE (MOBILE) ✅
        // ========================================
        case 'jadwal_created':
        case 'jadwal_updated':
        case 'jadwal_baru':
        case 'jadwal_diupdate':
        case 'new_schedule':
          debugPrint('🎯 [JADWAL] Navigating to jadwal page');
          Navigator.of(context).pushNamed('/jadwal');
          break;

        // ========================================
        // PUSH NOTIFICATIONS - PRESENSI
        // ========================================

        // Presensi dimulai (dengan waktu toleransi) ✅
        case 'presensi_buka':
        case 'reminder_presensi_masuk':
          debugPrint('🎯 [PUSH] Presensi dimulai - navigating to absensi');
          Navigator.of(context).pushNamed('/absensi');
          break;

        // Shift dimulai (tanpa waktu toleransi) ✅
        case 'shift_dimulai':
        case 'shift_started':
          debugPrint('🎯 [PUSH] Shift dimulai - navigating to absensi');
          Navigator.of(context).pushNamed('/absensi');
          break;

        // H+30 menit setelah shift dimulai (belum presensi) ✅
        case 'reminder_belum_presensi':
        case 'late_attendance_warning':
          debugPrint(
            '🎯 [PUSH] Reminder belum presensi - navigating to absensi',
          );
          Navigator.of(context).pushNamed('/absensi');
          break;

        // Shift berakhir - saatnya presensi pulang ✅
        case 'shift_berakhir':
        case 'reminder_presensi_pulang':
          debugPrint('🎯 [PUSH] Shift berakhir - navigating to absensi');
          Navigator.of(context).pushNamed('/absensi');
          break;

        // H+10 menit shift berakhir ✅
        case 'reminder_pulang_10_menit':
        case 'overtime_warning':
          debugPrint(
            '🎯 [PUSH] 10 menit setelah shift - navigating to absensi',
          );
          Navigator.of(context).pushNamed('/absensi');
          break;

        // ========================================
        // DEFAULT - Notifikasi Umum
        // ========================================
        default:
          debugPrint('🎯 [DEFAULT] Unknown type - navigating to notifications');
          Navigator.of(context).pushNamed('/notifications');
      }

      debugPrint('✅ Navigation completed successfully');
      _pendingNotification = null; // Clear after successful navigation
    } catch (e) {
      debugPrint('❌ Navigation error: $e');
      // Try callback as fallback
      if (_onMessageTapped != null) {
        _onMessageTapped!(message);
      } else {
        // Last resort: navigate to notifications
        try {
          Navigator.of(context).pushNamed('/notifications');
        } catch (navError) {
          debugPrint('❌ Fallback navigation also failed: $navError');
        }
      }
    }
  }

  /// Get FCM token
  static Future<String?> getToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      debugPrint('🔑 FCM Token: ${token?.substring(0, 20)}...');
      return token;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('📢 Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('📢 Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic: $e');
    }
  }

  /// Delete FCM token
  static Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _isAppReady = false; // Reset ready flag on logout
      _pendingNotification = null; // Clear pending notification
      debugPrint('🗑️ FCM token deleted');
    } catch (e) {
      debugPrint('❌ Error deleting FCM token: $e');
    }
  }
}
