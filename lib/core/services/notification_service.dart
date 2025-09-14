import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Initialize local notifications
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestSoundPermission: false,
        requestBadgePermission: false,
        requestAlertPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      const androidChannel = AndroidNotificationChannel(
        'expense_tracker_channel',
        'Safar Notifications',
        description: 'Notifications for expense tracking reminders',
        importance: Importance.high,
      );

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(androidChannel);
      }

      _initialized = true;
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    print('Notification tapped: ${response.payload}');
  }

  static Future<bool> requestPermissions() async {
    try {
      // Request notification permission
      PermissionStatus notificationStatus = await Permission.notification.status;

      if (!notificationStatus.isGranted) {
        notificationStatus = await Permission.notification.request();
      }

      // Request Firebase messaging permission
      NotificationSettings messagingSettings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      return notificationStatus.isGranted &&
          messagingSettings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  static Future<bool> areNotificationsEnabled() async {
    try {
      final permission = await Permission.notification.status;
      final messagingSettings = await _firebaseMessaging.getNotificationSettings();

      return permission.isGranted &&
          messagingSettings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      print('Error checking notification status: $e');
      return false;
    }
  }

  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'expense_tracker_channel',
        'Safar Notifications',
        channelDescription: 'Notifications for expense tracking reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  static Future<void> scheduleReminder({
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'expense_tracker_channel',
        'Safar Notifications',
        channelDescription: 'Scheduled reminders for expense tracking',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);

      await _localNotifications.zonedSchedule(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  static Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  static void setupForegroundNotificationHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      try {
        if (message.notification != null) {
          showLocalNotification(
            title: message.notification!.title ?? 'Safar',
            body: message.notification!.body ?? 'You have a new notification',
            payload: message.data.toString(),
          );
        }
      } catch (e) {
        print('Error handling foreground message: $e');
      }
    });
  }

  static Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
    } catch (e) {
      print('Error canceling notifications: $e');
    }
  }

  static Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
    } catch (e) {
      print('Error canceling notification: $e');
    }
  }

  // Helper method to schedule daily expense reminders
  static Future<void> scheduleDailyReminder({
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    try {
      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

      // If the time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await scheduleReminder(
        title: title,
        body: body,
        scheduledTime: scheduledDate,
      );
    } catch (e) {
      print('Error scheduling daily reminder: $e');
    }
  }

  // Check if we have notification permission without requesting
  static Future<bool> hasNotificationPermission() async {
    try {
      final permission = await Permission.notification.status;
      return permission.isGranted;
    } catch (e) {
      print('Error checking permission: $e');
      return false;
    }
  }
}