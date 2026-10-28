import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../storage/local_storage_service.dart';
import '../utils/security_manager.dart';

class AppNotificationService {
  static final AppNotificationService _instance = AppNotificationService._internal();
  factory AppNotificationService() => _instance;
  AppNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final LocalStorageService _storage = LocalStorageService();

  bool _initialized = false;
  StreamSubscription<QuerySnapshot>? _firestoreSubscription;
  final Set<String> _seenDocIds = {};
  DateTime _serviceStartTime = DateTime.now();

  /// Real-time count of unread announcements for the top-bar bell badge
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  Future<void> initialize() async {
    if (_initialized) return;

    _serviceStartTime = DateTime.now();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload?.trim() ?? '';
        if (payload.isNotEmpty && (payload.startsWith('http://') || payload.startsWith('https://'))) {
          SecurityManager.openExternalUrl(payload);
        }
      },
    );

    // Create high-priority Notification Channel for Android
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'es_bangla_announcements',
        'বিজ্ঞপ্তি ও গুরুত্বপূর্ণ আপডেট (Announcements)',
        description: 'নোটিশ, রুটিন এবং স্টাডি সংক্রান্ত সমস্ত আপডেট',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await androidImplementation.createNotificationChannel(channel);
      await requestPermissions();
    }

    // Initialize Firebase Cloud Messaging (FCM) & Topics
    try {
      final fcm = FirebaseMessaging.instance;
      await fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final sem = _storage.semester;
      await fcm.subscribeToTopic('all');
      await fcm.subscribeToTopic('c12_sem$sem');

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        final data = message.data;
        final title = notification?.title ?? (data['title'] ?? 'নতুন বিজ্ঞপ্তি 📢');
        final body = notification?.body ?? (data['body'] ?? data['message'] ?? '');
        final actionUrl = data['actionUrl'] ?? data['link'] ?? '';
        final imageUrl = notification?.android?.imageUrl ?? data['imageUrl'] ?? '';

        showSystemNotification(
          id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
          title: title,
          body: body,
          actionUrl: actionUrl,
          imageUrl: imageUrl,
        );
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        final actionUrl = message.data['actionUrl'] ?? message.data['link'] ?? '';
        if (actionUrl.isNotEmpty && (actionUrl.startsWith('http://') || actionUrl.startsWith('https://'))) {
          SecurityManager.openExternalUrl(actionUrl);
        }
      });
    } catch (e) {
      debugPrint('FCM init note: $e');
    }

    _initialized = true;
  }

  /// Request runtime permissions on Android 13+ (POST_NOTIFICATIONS)
  Future<bool> requestPermissions() async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final granted = await androidImplementation.requestNotificationsPermission();
      return granted ?? true;
    }
    return true;
  }

  /// Starts listening to real-time Firestore notifications targeted for the user's semester
  void startRealtimeListener(int semester) {
    _firestoreSubscription?.cancel();

    final semKey1 = 'c12_sem$semester';
    final semKey2 = 'sem$semester';
    final semKey3 = semester.toString();

    _firestoreSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .snapshots()
        .listen(
      (snapshot) {
        final lastReadMs = _storage.lastReadNotificationTimestamp;
        int unreadCount = 0;

        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final bool isActive = data['isActive'] ?? true;
          if (!isActive) continue;

          final audience = (data['audience'] ?? 'all').toString().trim().toLowerCase();
          final bool isTarget = audience == 'all' ||
              audience == semKey1 ||
              audience == semKey2 ||
              audience == semKey3 ||
              audience == '0';

          if (!isTarget) continue;

          final createdAtStamp = data['createdAt'] as Timestamp?;
          final createdAt = createdAtStamp?.toDate() ?? DateTime.now();

          // Calculate unread badge count
          if (createdAt.millisecondsSinceEpoch > lastReadMs) {
            unreadCount++;
          }

          // Trigger heads-up system notification on user phone if new notification created after app opened
          final docId = doc.id;
          final isRecentlyCreated = createdAt.isAfter(_serviceStartTime.subtract(const Duration(seconds: 15)));

          if (isRecentlyCreated && !_seenDocIds.contains(docId)) {
            _seenDocIds.add(docId);

            final title = (data['title'] ?? 'নতুন বিজ্ঞপ্তি 📢').toString().trim();
            final body = (data['body'] ?? data['message'] ?? '').toString().trim();
            final actionUrl = (data['actionUrl'] ?? data['link'] ?? data['redirectUrl'] ?? '').toString().trim();
            final imageUrl = (data['imageUrl'] ?? data['image'] ?? '').toString().trim();

            showSystemNotification(
              id: docId.hashCode,
              title: title,
              body: body,
              actionUrl: actionUrl,
              imageUrl: imageUrl,
            );
          } else {
            _seenDocIds.add(docId);
          }
        }

        unreadCountNotifier.value = unreadCount;
      },
      onError: (err) {
        debugPrint('AppNotificationService real-time listener error: $err');
      },
    );
  }

  /// Displays an immediate high-priority Heads-up Notification on the user's phone
  Future<void> showSystemNotification({
    required int id,
    required String title,
    required String body,
    String? actionUrl,
    String? imageUrl,
  }) async {
    await initialize();

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'es_bangla_announcements',
      'বিজ্ঞপ্তি ও গুরুত্বপূর্ণ আপডেট (Announcements)',
      channelDescription: 'নোটিশ, রুটিন এবং স্টাডি সংক্রান্ত সমস্ত আপডেট',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Es Bangla Update',
      ),
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: actionUrl ?? '',
    );
  }

  /// Marks all current announcements as read and clears the unread badge
  Future<void> markAllAsRead() async {
    await _storage.setLastReadNotificationTimestamp(DateTime.now().millisecondsSinceEpoch);
    unreadCountNotifier.value = 0;
  }

  void dispose() {
    _firestoreSubscription?.cancel();
  }
}
