import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart';
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
  Timer? _rtdbPollTimer;
  final Set<String> _seenDocIds = {};
  bool _isFirestoreFirstSyncDone = false;
  bool _isRtdbFirstSyncDone = false;
  bool _isPolling = false;
  DateTime _serviceStartTime = DateTime.now();

  /// Real-time count of unread announcements for the top-bar bell badge
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  Future<void> initialize() async {
    if (_initialized) return;

    _serviceStartTime = DateTime.now();

    // Hydrate in-memory seen set from persistent storage immediately
    try {
      final persisted = _storage.getSeenNotificationIds();
      _seenDocIds.addAll(persisted);
    } catch (_) {}

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
      fcm.subscribeToTopic('all').catchError((e) => debugPrint('FCM topic all error: $e'));
      fcm.subscribeToTopic('c12_sem$sem').catchError((e) => debugPrint('FCM topic sem error: $e'));

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        final data = message.data;
        final title = (notification?.title ?? (data['title'] ?? 'নতুন বিজ্ঞপ্তি 📢')).toString().trim();
        final body = (notification?.body ?? (data['body'] ?? data['message'] ?? '')).toString().trim();
        final actionUrl = (data['actionUrl'] ?? data['link'] ?? '').toString().trim();
        final imageUrl = (notification?.android?.imageUrl ?? data['imageUrl'] ?? '').toString().trim();

        // Discard any dummy/test notification
        if ((title.toLowerCase().contains('test') || title.contains('টেস্টিং')) &&
            (body.toLowerCase() == 'test' || body.isEmpty)) {
          return;
        }

        final msgKey = message.messageId ?? '${title}_${body}';

        // 1. Save directly into device local storage
        _storage.saveLocalNotification({
          'id': msgKey,
          'title': title,
          'body': body,
          'actionUrl': actionUrl,
          'imageUrl': imageUrl,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        _updateUnreadCount();

        if (_seenDocIds.contains(msgKey)) return;
        _seenDocIds.add(msgKey);
        _storage.addSeenNotificationId(msgKey);

        showSystemNotification(
          id: (message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch) & 0x7FFFFFFF,
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

    _updateUnreadCount();
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

  /// Starts listening to real-time Firestore & RTDB notifications targeted for the user's semester
  void startRealtimeListener(int semester) {
    _firestoreSubscription?.cancel();
    _rtdbPollTimer?.cancel();
    _isFirestoreFirstSyncDone = false;
    _isRtdbFirstSyncDone = false;

    // Refresh memory cache from storage
    try {
      _seenDocIds.addAll(_storage.getSeenNotificationIds());
    } catch (_) {}

    final semKey1 = 'c12_sem$semester';
    final semKey2 = 'sem$semester';
    final semKey3 = semester.toString();
    final installTime = _storage.installTimestamp;

    // 1. Primary Firestore Snapshot Stream
    _firestoreSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .snapshots()
        .listen(
      (snapshot) {
        if (!_isFirestoreFirstSyncDone) {
          // FIRST LOAD: Mark all existing documents as seen so historical notices NEVER trigger phone alerts
          for (final doc in snapshot.docs) {
            _seenDocIds.add(doc.id);
            _storage.addSeenNotificationId(doc.id);

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
            final createdAt = createdAtStamp?.toDate();
            final createdAtMs = createdAt?.millisecondsSinceEpoch ?? 0;

            // Only show in inbox if created AFTER app installation and within 7 days
            final bool isPostInstall = createdAtMs >= installTime;
            final bool isWithinSevenDays = createdAt != null &&
                DateTime.now().difference(createdAt).inDays <= 7;

            final title = (data['title'] ?? '').toString().trim();
            final body = (data['body'] ?? data['message'] ?? '').toString().trim();
            final isTest = (title.toLowerCase().contains('test') || title.contains('টেস্টিং')) &&
                (body.toLowerCase() == 'test' || body.isEmpty);

            if (isPostInstall && isWithinSevenDays && !isTest) {
              _storage.saveLocalNotification({
                'id': doc.id,
                'title': title,
                'body': body,
                'actionUrl': (data['actionUrl'] ?? data['link'] ?? data['redirectUrl'] ?? '').toString().trim(),
                'imageUrl': (data['imageUrl'] ?? data['image'] ?? '').toString().trim(),
                'timestamp': createdAtMs,
              });
            }
          }

          _isFirestoreFirstSyncDone = true;
          _updateUnreadCount();
          return;
        }

        // SUBSEQUENT EVENTS: A new document was added in Firestore while the user is actively inside the app
        for (final change in snapshot.docChanges) {
          if (change.type != DocumentChangeType.added) continue;

          final doc = change.doc;
          final docId = doc.id;
          if (_seenDocIds.contains(docId)) continue;
          _seenDocIds.add(docId);
          _storage.addSeenNotificationId(docId);

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
          final createdAt = createdAtStamp?.toDate();
          if (createdAt == null) continue;

          final title = (data['title'] ?? 'নতুন বিজ্ঞপ্তি 📢').toString().trim();
          final body = (data['body'] ?? data['message'] ?? '').toString().trim();
          final isTest = (title.toLowerCase().contains('test') || title.contains('টেস্টিং')) &&
              (body.toLowerCase() == 'test' || body.isEmpty);
          if (isTest) continue;

          final actionUrl = (data['actionUrl'] ?? data['link'] ?? data['redirectUrl'] ?? '').toString().trim();
          final imageUrl = (data['imageUrl'] ?? data['image'] ?? '').toString().trim();

          _storage.saveLocalNotification({
            'id': docId,
            'title': title,
            'body': body,
            'actionUrl': actionUrl,
            'imageUrl': imageUrl,
            'timestamp': createdAt.millisecondsSinceEpoch,
          });

          // Strictly real-time: created AFTER current app session started and within 90 seconds
          final bool isRealtime = createdAt.isAfter(_serviceStartTime) &&
              DateTime.now().difference(createdAt).inSeconds.abs() <= 90;

          if (isRealtime) {
            showSystemNotification(
              id: (docId.hashCode & 0x7FFFFFFF),
              title: title,
              body: body,
              actionUrl: actionUrl,
              imageUrl: imageUrl,
            );
          }
        }

        _updateUnreadCount();
      },
      onError: (err) {
        debugPrint('AppNotificationService real-time listener error: $err');
      },
    );

    // 2. Dual-Sync Realtime Database Polling (every 30 seconds)
    _pollRtdbNotifications(semester);
    _rtdbPollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _pollRtdbNotifications(semester);
    });
  }

  Future<void> _pollRtdbNotifications(int semester) async {
    if (_isPolling) return;
    _isPolling = true;

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      final res = await dio.get('https://es-bangla-225f2-default-rtdb.firebaseio.com/notifications.json');
      if (res.data is Map) {
        final Map<String, dynamic> dataMap = Map<String, dynamic>.from(res.data);
        final semKey1 = 'c12_sem$semester';
        final semKey2 = 'sem$semester';
        final semKey3 = semester.toString();
        final installTime = _storage.installTimestamp;

        if (!_isRtdbFirstSyncDone) {
          // FIRST RTDB LOAD: Mark all existing keys as seen so historical notices NEVER trigger phone alerts
          dataMap.forEach((key, val) {
            _seenDocIds.add(key);
            _storage.addSeenNotificationId(key);

            if (val is Map) {
              final map = Map<String, dynamic>.from(val);
              final bool isActive = map['isActive'] ?? true;
              if (!isActive) return;

              final audience = (map['audience'] ?? 'all').toString().trim().toLowerCase();
              final bool isTarget = audience == 'all' ||
                  audience == semKey1 ||
                  audience == semKey2 ||
                  audience == semKey3 ||
                  audience == '0';
              if (!isTarget) return;

              final createdAtRaw = map['createdAt'];
              DateTime? createdAt;
              if (createdAtRaw is num) {
                createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtRaw.toInt());
              } else if (createdAtRaw is String) {
                createdAt = DateTime.tryParse(createdAtRaw);
              }
              final createdAtMs = createdAt?.millisecondsSinceEpoch ?? 0;

              // Only show in inbox if created AFTER app installation and within 7 days
              final bool isPostInstall = createdAtMs >= installTime;
              final bool isWithinSevenDays = createdAt != null &&
                  DateTime.now().difference(createdAt).inDays <= 7;

              final title = (map['title'] ?? '').toString().trim();
              final body = (map['body'] ?? map['message'] ?? '').toString().trim();
              final isTest = (title.toLowerCase().contains('test') || title.contains('টেস্টিং')) &&
                  (body.toLowerCase() == 'test' || body.isEmpty);

              if (isPostInstall && isWithinSevenDays && !isTest) {
                _storage.saveLocalNotification({
                  'id': key,
                  'title': title,
                  'body': body,
                  'actionUrl': (map['actionUrl'] ?? map['link'] ?? map['redirectUrl'] ?? '').toString().trim(),
                  'imageUrl': (map['imageUrl'] ?? map['image'] ?? '').toString().trim(),
                  'timestamp': createdAtMs,
                });
              }
            }
          });

          _isRtdbFirstSyncDone = true;
          _updateUnreadCount();
          return;
        }

        // SUBSEQUENT RTDB POLLS: Only trigger if newly added during current app session
        dataMap.forEach((key, val) {
          if (_seenDocIds.contains(key)) return;
          _seenDocIds.add(key);
          _storage.addSeenNotificationId(key);

          if (val is Map) {
            final map = Map<String, dynamic>.from(val);
            final bool isActive = map['isActive'] ?? true;
            if (!isActive) return;

            final audience = (map['audience'] ?? 'all').toString().trim().toLowerCase();
            final bool isTarget = audience == 'all' ||
                audience == semKey1 ||
                audience == semKey2 ||
                audience == semKey3 ||
                audience == '0';
            if (!isTarget) return;

            final createdAtRaw = map['createdAt'];
            DateTime? createdAt;
            if (createdAtRaw is num) {
              createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtRaw.toInt());
            } else if (createdAtRaw is String) {
              createdAt = DateTime.tryParse(createdAtRaw);
            }
            if (createdAt == null) return;

            final title = (map['title'] ?? 'নতুন বিজ্ঞপ্তি 📢').toString().trim();
            final body = (map['body'] ?? map['message'] ?? '').toString().trim();
            final isTest = (title.toLowerCase().contains('test') || title.contains('টেস্টিং')) &&
                (body.toLowerCase() == 'test' || body.isEmpty);
            if (isTest) return;

            final actionUrl = (map['actionUrl'] ?? map['link'] ?? map['redirectUrl'] ?? '').toString().trim();
            final imageUrl = (map['imageUrl'] ?? map['image'] ?? '').toString().trim();

            _storage.saveLocalNotification({
              'id': key,
              'title': title,
              'body': body,
              'actionUrl': actionUrl,
              'imageUrl': imageUrl,
              'timestamp': createdAt.millisecondsSinceEpoch,
            });

            final bool isRealtime = createdAt.isAfter(_serviceStartTime) &&
                DateTime.now().difference(createdAt).inSeconds.abs() <= 90;

            if (isRealtime) {
              showSystemNotification(
                id: (key.hashCode & 0x7FFFFFFF),
                title: title,
                body: body,
                actionUrl: actionUrl,
                imageUrl: imageUrl,
              );
            }
          }
        });

        _updateUnreadCount();
      }
    } catch (_) {
    } finally {
      _isPolling = false;
    }
  }

  void _updateUnreadCount() {
    final lastReadMs = _storage.lastReadNotificationTimestamp;
    final list = _storage.getLocalNotifications();
    int unread = 0;
    for (final item in list) {
      final ts = (item['timestamp'] as num?)?.toInt() ?? 0;
      if (ts > lastReadMs) {
        unread++;
      }
    }
    unreadCountNotifier.value = unread;
  }

  /// Displays an immediate high-priority Heads-up Notification on the user's phone with BigPicture image preview
  Future<void> showSystemNotification({
    required int id,
    required String title,
    required String body,
    String? actionUrl,
    String? imageUrl,
  }) async {
    await initialize();

    ByteArrayAndroidBitmap? bigPictureBitmap;
    final cleanImageUrl = imageUrl?.trim() ?? '';

    // If notification has an image, download bytes to display in Android notification drawer
    if (cleanImageUrl.isNotEmpty && (cleanImageUrl.startsWith('http://') || cleanImageUrl.startsWith('https://'))) {
      try {
        final dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 5),
        ));
        final response = await dio.get<List<int>>(
          cleanImageUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        if (response.data != null && response.data!.isNotEmpty) {
          bigPictureBitmap = ByteArrayAndroidBitmap(Uint8List.fromList(response.data!));
        }
      } catch (e) {
        debugPrint('Notification image preview download note: $e');
      }
    }

    final StyleInformation styleInformation = bigPictureBitmap != null
        ? BigPictureStyleInformation(
            bigPictureBitmap,
            contentTitle: title,
            summaryText: body,
            largeIcon: bigPictureBitmap,
            hideExpandedLargeIcon: false,
          )
        : BigTextStyleInformation(
            body,
            contentTitle: title,
            summaryText: 'Es Bangla Update',
          );

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'es_bangla_announcements',
      'বিজ্ঞপ্তি ও গুরুত্বপূর্ণ আপডেট (Announcements)',
      channelDescription: 'নোটিশ, রুটিন এবং স্টাডি সংক্রান্ত সমস্ত আপডেট',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      largeIcon: bigPictureBitmap,
      styleInformation: styleInformation,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    final safeId = id & 0x7FFFFFFF;
    await _notificationsPlugin.show(
      safeId,
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
    _rtdbPollTimer?.cancel();
  }
}
