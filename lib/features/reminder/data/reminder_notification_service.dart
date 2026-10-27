import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ReminderNotificationService {
  static final ReminderNotificationService _instance = ReminderNotificationService._internal();
  factory ReminderNotificationService() => _instance;
  ReminderNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
      final Duration offset = DateTime.now().timeZoneOffset;
      for (final entry in tz.timeZoneDatabase.locations.entries) {
        if (entry.value.currentTimeZone.offset == offset.inMilliseconds) {
          tz.setLocalLocation(entry.value);
          break;
        }
      }
    } catch (e) {
      debugPrint('Timezone initialization note: $e');
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Tapping notification opens app
      },
    );

    // Create Notification Channel for Android
    final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'study_reminders_channel',
        'Study Reminders',
        description: 'Notifications for study tasks and reminders',
        importance: Importance.max,
        playSound: false, // Heads-up banner notification without alarm sound
        enableVibration: true,
        showBadge: true,
      );

      await androidImplementation.createNotificationChannel(channel);
    }

    _initialized = true;
  }

  /// Request runtime permissions on Android 13+ and Exact Alarms on Android 12+
  Future<bool> requestPermissions() async {
    final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final notifGranted = await androidImplementation.requestNotificationsPermission();
      try {
        await androidImplementation.requestExactAlarmsPermission();
      } catch (_) {}
      return notifGranted ?? true;
    }
    return true;
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await initialize();

    final now = tz.TZDateTime.now(tz.local);
    var tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    if (!tzDate.isAfter(now)) {
      tzDate = now.add(const Duration(seconds: 5));
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'study_reminders_channel',
      'Study Reminders',
      channelDescription: 'Notifications for study tasks and reminders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Exact alarm failed, falling back to inexact schedule: $e');
      try {
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tzDate,
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.inexact,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (err) {
        debugPrint('Failed to schedule reminder notification: $err');
      }
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (_) {}
  }
}
