import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    await Firebase.initializeApp();
  } catch (_) {}
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Storage
  await LocalStorageService().initialize();

  // Initialize Network Connectivity & Health Watcher
  NetworkConnectivityService().initialize();

  // Initialize Local Reminders
  try {
    await ReminderNotificationService().initialize();
  } catch (_) {}

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (_) {
    // Allows preview even before Firebase credentials setup on emulator
  }

  // Initialize App Announcements & Notification System
  try {
    await AppNotificationService().initialize();
    AppNotificationService().startRealtimeListener(LocalStorageService().semester);
  } catch (_) {}

  runApp(const ProviderScope(child: EsBanglaApp()));
}

class EsBanglaApp extends StatelessWidget {
  const EsBanglaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivityService = NetworkConnectivityService();

    return ValueListenableBuilder<bool>(
      valueListenable: connectivityService.isOnlineNotifier,
      builder: (context, isOnline, child) {
        return MaterialApp(
          title: 'Es Bangla',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
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
  }
}
