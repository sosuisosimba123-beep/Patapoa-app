import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();

  bool get _isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> initialize() async {
    if (!_isSupported) return;

    try {
      // 1. Request Permission
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission');
      }

      // 2. Initialize Local Notifications
      const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
      const InitializationSettings initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

      await _localNotifications.initialize(initSettings);

      // 3. Listen to Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Received foreground message: ${message.notification?.title}');
        _showLocalNotification(message);
      });

      // 4. Handle notification clicks
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Notification clicked: ${message.data}');
      });

      // 5. Background Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 6. Fetch and Sync Token
      String? token = await getToken();
      if (token != null) {
        await syncTokenWithBackend(token);
      }

      // 7. Refresh listener
      _fcm.onTokenRefresh.listen(syncTokenWithBackend);

      // 8. Subscribe to common topics
      await _fcm.subscribeToTopic('all_users');
    } catch (e) {
      debugPrint("Error initializing FCM: $e");
    }
  }

  Future<void> syncTokenWithBackend(String token) async {
    try {
      final isAuthenticated = await _apiService.isAuthenticated();
      if (isAuthenticated) {
        await _apiService.post('/update-fcm-token', {'fcm_token': token});
        debugPrint('FCM Token synced with backend');
      }
    } catch (e) {
      debugPrint('Error syncing FCM token: $e');
    }
  }

  Future<void> subscribeToRole(String role) async {
    if (!_isSupported) return;
    try {
      await _fcm.subscribeToTopic('${role}s');
    } catch (_) {}
  }

  Future<void> unsubscribeFromRole(String role) async {
    if (!_isSupported) return;
    try {
      await _fcm.unsubscribeFromTopic('${role}s');
    } catch (_) {}
  }

  Future<String?> getToken() async {
    if (!_isSupported) return null;
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint("Could not get FCM token: $e");
      return null;
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'patapoa_channel',
      'General Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      details,
      payload: message.data.toString(),
    );
  }
}

// Global top-level background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling background message: ${message.messageId}");
}
