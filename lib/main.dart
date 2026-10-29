import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/storage/local_storage_service.dart';
import 'core/network/network_connectivity_service.dart';
import 'core/network/offline_screen.dart';
import 'features/reminder/data/reminder_notification_service.dart';
import 'core/notifications/app_notification_service.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/main_shell_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    final data = message.data;
    final notification = message.notification;
    final title = notification?.title ?? (data['title'] ?? 'নতুন বিজ্ঞপ্তি 📢').toString().trim();
    final body = notification?.body ?? (data['body'] ?? data['message'] ?? '').toString().trim();
    final imageUrl = notification?.android?.imageUrl ?? (data['imageUrl'] ?? data['image'] ?? '').toString().trim();
    final actionUrl = (data['actionUrl'] ?? data['link'] ?? data['redirectUrl'] ?? '').toString().trim();
    final msgId = message.messageId ?? 'notif_${DateTime.now().millisecondsSinceEpoch}';

    // Discard any dummy/test notification
    if ((title.toLowerCase().contains('test') || title.contains('টেস্টিং')) &&
        (body.toLowerCase() == 'test' || body.isEmpty)) {
      return;
    }

    // 1. Save directly into device local storage (SharedPreferences)
    final prefs = await SharedPreferences.getInstance();
    const storageKey = 'user_local_notifications';
    final raw = prefs.getString(storageKey);
    List<Map<String, dynamic>> list = [];
    if (raw != null && raw.isNotEmpty) {
      try {
        final List decoded = jsonDecode(raw);
        list = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) {}
    }

    final notifMap = {
      'id': msgId,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'isRead': false,
    };

    list.removeWhere((item) =>
        (msgId.isNotEmpty && item['id']?.toString() == msgId) ||
        (item['title'] == title && item['body'] == body));
    list.insert(0, notifMap);
    await prefs.setString(storageKey, jsonEncode(list));

    // 2. Display Status Bar Notification
    await AppNotificationService().showSystemNotification(
      id: msgId.hashCode & 0x7FFFFFFF,
      title: title,
      body: body,
      actionUrl: actionUrl,
      imageUrl: imageUrl,
    );
  } catch (e) {
    debugPrint('FCM background handler error: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fullscreen Immersive Mode: hide status bar (clock, battery, notifications)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize Local Storage
  await LocalStorageService().initialize();

  // Initialize Network Connectivity & Health Watcher
  NetworkConnectivityService().initialize();

  // Initialize Firebase (local native config)
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Allows preview even before Firebase credentials setup on emulator
  }

  // Launch UI immediately so the user doesn't face splash screen delays
  runApp(const ProviderScope(child: EsBanglaApp()));

  // Run notification and background messaging services asynchronously
  _initBackgroundServices();
}

void _initBackgroundServices() async {
  // Initialize Local Reminders
  try {
    await ReminderNotificationService().initialize();
  } catch (_) {}

  // Firebase Background messaging & Notification System
  try {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await AppNotificationService().initialize();
    AppNotificationService().startRealtimeListener(LocalStorageService().semester);
  } catch (_) {}
}

class EsBanglaApp extends StatelessWidget {
  const EsBanglaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivityService = NetworkConnectivityService();

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: LocalStorageService().themeModeNotifier,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: connectivityService.isOnlineNotifier,
          builder: (context, isOnline, child) {
            return MaterialApp(
              title: 'Es Bangla',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              home: FirebaseAuth.instance.currentUser != null
                  ? const MainShellScreen()
                  : const LoginScreen(),
              builder: (context, child) {
                // Strict Online-Only Blocker (PRD Section 23):
                // Overlays entire navigator stack with un-dismissible OfflineScreen
                if (!isOnline) {
                  return const OfflineScreen();
                }
                return child ?? const SizedBox.shrink();
              },
            );
          },
        );
      },
    );
  }
}
