import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'storage_service.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> initialize() async {
    // Request permission
    await _requestPermission();
    
    // Initialize local notifications
    await _initializeLocalNotifications();
    
    // Get and save FCM token
    await _saveToken();
    
    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  static Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
    
    print('Notification permission status: ${settings.authorizationStatus}');
  }

  static Future<void> _initializeLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const settings = InitializationSettings(android: android, iOS: ios);
    await _localNotifications.initialize(settings);
  }

  static Future<void> _saveToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken();
    if (token != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Check if notifications are enabled
    final settings = await StorageService.getSettings();
    final notificationsEnabled = settings['notificationsEnabled'] ?? true;
    
    if (!notificationsEnabled) return;

    // Show local notification
    const androidDetails = AndroidNotificationDetails(
      'comments',
      'Comment Notifications',
      channelDescription: 'Notifications for new comments on your posts',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? '새 댓글',
      message.notification?.body ?? '게시글에 새 댓글이 달렸습니다.',
      details,
    );
  }

  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    // Handle notification tap - navigate to post
    print('Notification tapped: ${message.data}');
    // TODO: Navigate to specific post when tapped
  }

  static Future<bool> areNotificationsEnabled() async {
    final settings = await StorageService.getSettings();
    return settings['notificationsEnabled'] ?? true;
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    final settings = await StorageService.getSettings();
    await StorageService.saveSettings({
      ...settings,
      'notificationsEnabled': enabled,
    });

    // Update FCM token based on setting
    if (enabled) {
      await _saveToken();
    } else {
      await _clearToken();
    }
  }

  static Future<void> _clearToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'fcmToken': FieldValue.delete(),
    });
  }
}