import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    print('Notification service initialized');
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    print('Notification tapped: ${notificationResponse.payload}');
    // Handle notification tap - you can navigate to specific screens here
  }

  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android 13+ requires POST_NOTIFICATIONS permission
      final status = await Permission.notification.request();
      return status == PermissionStatus.granted;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS permissions
      final status = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return status ?? false;
    }
    return true;
  }

  Future<bool> areNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled =
          prefs.getBool('notifications_enabled') ?? true;

      if (!notificationsEnabled) return false;

      // Check system permissions
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.notification.status;
        return status == PermissionStatus.granted;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final settings = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.checkPermissions();
        return settings?.isEnabled ?? false;
      }
      return true;
    } catch (e) {
      print('Error checking notification permissions: $e');
      return false;
    }
  }

  Future<void> showMealNotification({
    required String elderlyName,
    required DateTime timestamp,
  }) async {
    if (!await areNotificationsEnabled()) return;

    // Check user preferences
    final prefs = await SharedPreferences.getInstance();
    final soundEnabled = prefs.getBool('sound_enabled') ?? true;
    final vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'meal_channel',
          '식사 알림',
          channelDescription: '부모님의 새로운 식사 알림',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          showWhen: true,
          playSound: soundEnabled,
          enableVibration: vibrationEnabled,
          vibrationPattern: vibrationEnabled ? Int64List.fromList([0, 250, 250, 250]) : null,
        );

    final DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: soundEnabled,
        );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    await _flutterLocalNotificationsPlugin.show(
      1,
      '$elderlyName님이 식사하셨어요',
      '오늘 $timeStr에 식사했습니다',
      platformChannelSpecifics,
      payload: 'meal',
    );
  }

  Future<void> showEmergencyNotification({
    required String elderlyName,
    required int daysSinceLastRecord,
  }) async {
    if (!await areNotificationsEnabled()) return;

    // Check user preferences
    final prefs = await SharedPreferences.getInstance();
    final soundEnabled = prefs.getBool('sound_enabled') ?? true;
    final vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'emergency_channel',
          '비상 알림',
          channelDescription: '부모님 식사 비상 알림',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          color: Color(0xFFE74C3C),
          ledColor: Color(0xFFE74C3C),
          ledOnMs: 1000,
          ledOffMs: 500,
          playSound: soundEnabled,
          enableVibration: vibrationEnabled,
          vibrationPattern: vibrationEnabled ? Int64List.fromList([0, 500, 250, 500]) : null,
        );

    final DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: soundEnabled,
          interruptionLevel: InterruptionLevel.critical,
        );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      2,
      '$daysSinceLastRecord일째 식사 기록이 없어요',
      '$elderlyName님께 안부를 확인해 주세요',
      platformChannelSpecifics,
      payload: 'emergency',
    );
  }

  Future<void> showSurvivalAlertNotification({
    required String elderlyName,
    required int hoursSinceActivity,
  }) async {
    if (!await areNotificationsEnabled()) return;

    // Check user preferences
    final prefs = await SharedPreferences.getInstance();
    final soundEnabled = prefs.getBool('sound_enabled') ?? true;
    final vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'survival_channel',
          '생존 신호 알림',
          channelDescription: '부모님 생존 신호 알림',
          importance: Importance.max,
          priority: Priority.max,
          showWhen: true,
          color: Color(0xFFE74C3C),
          ledColor: Color(0xFFE74C3C),
          ledOnMs: 1000,
          ledOffMs: 500,
          playSound: soundEnabled,
          enableVibration: vibrationEnabled,
          vibrationPattern: vibrationEnabled ? Int64List.fromList([0, 1000, 500, 1000]) : null,
          fullScreenIntent: true,
        );

    final DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: soundEnabled,
          interruptionLevel: InterruptionLevel.critical,
        );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      3,
      '🚨 $hoursSinceActivity시간째 활동이 없어요',
      '$elderlyName님의 안전을 확인해 주세요',
      platformChannelSpecifics,
      payload: 'survival_alert',
    );
  }

  Future<void> testNotification() async {
    if (!await areNotificationsEnabled()) {
      print('Notifications are disabled');
      return;
    }

    // Check user preferences
    final prefs = await SharedPreferences.getInstance();
    final soundEnabled = prefs.getBool('sound_enabled') ?? true;
    final vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;

    // Simple vibration test - works best in profile/release mode
    if (vibrationEnabled) {
      try {
        await HapticFeedback.heavyImpact();
        print('Vibration triggered');
      } catch (e) {
        print('Vibration test failed: $e');
      }
    }

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'test_channel',
          '테스트 알림',
          channelDescription: '알림 테스트',
          importance: Importance.max,
          priority: Priority.max,
          playSound: soundEnabled,
          enableVibration: vibrationEnabled,
          vibrationPattern: vibrationEnabled ? Int64List.fromList([0, 500, 200, 500, 200, 500]) : null,
          ticker: '테스트 알림',
          autoCancel: false,
          ongoing: false,
        );

    final DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: soundEnabled,
        );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      '🔔 알림 테스트',
      '진동: ${vibrationEnabled ? "ON" : "OFF"} | 소리: ${soundEnabled ? "ON" : "OFF"}',
      platformChannelSpecifics,
      payload: 'test',
    );
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
