import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  late SharedPreferences _prefs;
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);
  final ValueNotifier<String> userAvatarNotifier = ValueNotifier<String>('');

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    themeModeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    localNotificationsNotifier.value = getLocalNotifications();
    userAvatarNotifier.value = userAvatar;
  }

  // User Profile & Academic Info
  static const String _keyDarkMode = 'is_dark_mode';
  static const String _keySemester = 'user_semester';
  static const String _keyClass = 'user_class';
  static const String _keyUserName = 'user_name';
  static const String _keyUserAvatar = 'user_avatar_path';

  bool get isDarkMode => _prefs.getBool(_keyDarkMode) ?? false;
  set isDarkMode(bool value) {
    _prefs.setBool(_keyDarkMode, value);
    themeModeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
  }
  static const String _keyUserEmail = 'user_email';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keySavedQuestions = 'saved_questions';
  static const String _keyAttemptHistory = 'attempt_history';
  static const String _keyStudyReminders = 'study_reminders';
  static const String _keyApiManifest = 'api_manifest_cache';
  static const String _keyEntitlements = 'user_entitlements';

  int get semester => _prefs.getInt(_keySemester) ?? 3;
  set semester(int value) => _prefs.setInt(_keySemester, value);

  String get userClass => _prefs.getString(_keyClass) ?? '12';
  set userClass(String value) => _prefs.setString(_keyClass, value);

  String get userName => _prefs.getString(_keyUserName) ?? 'Student';
  set userName(String value) => _prefs.setString(_keyUserName, value);

  String get userAvatar => _prefs.getString(_keyUserAvatar) ?? '';
  set userAvatar(String value) {
    _prefs.setString(_keyUserAvatar, value);
    userAvatarNotifier.value = value;
  }

  String get userEmail => _prefs.getString(_keyUserEmail) ?? '';
  set userEmail(String value) => _prefs.setString(_keyUserEmail, value);

  bool get notificationsEnabled => _prefs.getBool(_keyNotificationsEnabled) ?? true;
  set notificationsEnabled(bool value) => _prefs.setBool(_keyNotificationsEnabled, value);

  // Saved Questions (Bookmarks)
  List<Map<String, dynamic>> getSavedQuestions() {
    final raw = _prefs.getString(_keySavedQuestions);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> toggleSaveQuestion(Map<String, dynamic> questionData) async {
    final current = getSavedQuestions();
    final qId = questionData['q_id'];
    final testId = questionData['test_id'];

    final index = current.indexWhere((q) => q['q_id'] == qId && q['test_id'] == testId);
    if (index >= 0) {
      current.removeAt(index);
    } else {
      current.insert(0, questionData);
    }
    await _prefs.setString(_keySavedQuestions, jsonEncode(current));
  }

  bool isQuestionSaved(String testId, String qId) {
    final current = getSavedQuestions();
    return current.any((q) => q['q_id'] == qId && q['test_id'] == testId);
  }

  // Attempt History for Analytics
  List<Map<String, dynamic>> getAttemptHistory() {
    final raw = _prefs.getString(_keyAttemptHistory);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> recordAttempt(Map<String, dynamic> attempt) async {
    final history = getAttemptHistory();
    history.insert(0, attempt);
    await _prefs.setString(_keyAttemptHistory, jsonEncode(history));
  }

  // Study Reminders
  List<Map<String, dynamic>> getStudyReminders() {
    final raw = _prefs.getString(_keyStudyReminders);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveStudyReminders(List<Map<String, dynamic>> reminders) async {
    await _prefs.setString(_keyStudyReminders, jsonEncode(reminders));
  }

  // Cached API Data with stale-while-revalidate
  String? getCachedResponse(String key) => _prefs.getString('api_cache_$key');

  Future<void> setCachedResponse(String key, String data) async {
    await _prefs.setString('api_cache_$key', data);
  }

  // Entitlements
  List<String> getEntitlements() {
    final list = _prefs.getStringList(_keyEntitlements);
    return list ?? [];
  }

  Future<void> setEntitlements(List<String> list) async {
    await _prefs.setStringList(_keyEntitlements, list);
  }

  // Notifications read tracking
  static const String _keyLastReadNotif = 'last_read_notif_time';
  int get lastReadNotificationTimestamp => _prefs.getInt(_keyLastReadNotif) ?? 0;
  Future<void> setLastReadNotificationTimestamp(int timestampMs) =>
      _prefs.setInt(_keyLastReadNotif, timestampMs);

  static const String _keySeenNotifIds = 'seen_notif_ids_set';
  Set<String> getSeenNotificationIds() {
    final list = _prefs.getStringList(_keySeenNotifIds);
    return list?.toSet() ?? {};
  }

  Future<void> addSeenNotificationId(String id) async {
    final set = getSeenNotificationIds();
    set.add(id);
    await _prefs.setStringList(_keySeenNotifIds, set.toList());
  }

  Future<void> addAllSeenNotificationIds(Iterable<String> ids) async {
    final set = getSeenNotificationIds();
    set.addAll(ids);
    await _prefs.setStringList(_keySeenNotifIds, set.toList());
  }

  // Device-Only Local Notification Storage (PRD Section Update)
  static const String _keyLocalNotifications = 'user_local_notifications';
  final ValueNotifier<List<Map<String, dynamic>>> localNotificationsNotifier =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  List<Map<String, dynamic>> getLocalNotifications() {
    final raw = _prefs.getString(_keyLocalNotifications);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveLocalNotification(Map<String, dynamic> notification) async {
    final current = getLocalNotifications();
    final id = notification['id']?.toString() ?? '';
    final title = notification['title']?.toString() ?? '';
    final body = notification['body']?.toString() ?? '';

    // Deduplicate by ID or identical title+body
    current.removeWhere((item) =>
        (id.isNotEmpty && item['id']?.toString() == id) ||
        (item['title'] == title && item['body'] == body));

    current.insert(0, notification);
    await _prefs.setString(_keyLocalNotifications, jsonEncode(current));
    localNotificationsNotifier.value = List<Map<String, dynamic>>.from(current);
  }

  Future<void> deleteLocalNotification(String id) async {
    final current = getLocalNotifications();
    current.removeWhere((item) => item['id']?.toString() == id);
    await _prefs.setString(_keyLocalNotifications, jsonEncode(current));
    localNotificationsNotifier.value = List<Map<String, dynamic>>.from(current);
  }

  Future<void> clearAllLocalNotifications() async {
    await _prefs.remove(_keyLocalNotifications);
    localNotificationsNotifier.value = [];
  }
}
