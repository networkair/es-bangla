import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/storage/local_storage_service.dart';
import '../domain/mock_test_models.dart';

class MockTestRepository {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Accept': 'application/json',
    },
  ));

  final LocalStorageService _storage = LocalStorageService();

  // In-memory session cache for ultra-fast screen transitions
  final Map<String, dynamic> _memoryCache = {};

  /// Fetch API Manifest
  Future<Map<String, dynamic>?> getManifest() async {
    try {
      final response = await _dio.get(ApiConstants.manifestEndpoint);
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
    } catch (_) {}
    return null;
  }

  /// Fetch Subjects for current semester with stale-while-revalidate
  Future<List<SubjectModel>> getSubjects(int semester, {String? version}) async {
    final cacheKey = 'subjects_sem_$semester';

    // 1. Check memory cache first
    if (_memoryCache.containsKey(cacheKey)) {
      return (_memoryCache[cacheKey] as List)
          .map((s) => SubjectModel.fromJson(s))
          .toList();
    }

    // 2. Check disk cache
    final localJson = _storage.getCachedResponse(cacheKey);
    List<SubjectModel>? diskSubjects;
    if (localJson != null) {
      try {
        final decoded = jsonDecode(localJson);
        final list = (decoded['subjects'] as List? ?? [])
            .map((s) => SubjectModel.fromJson(s))
            .toList();
        diskSubjects = list;
        _memoryCache[cacheKey] = decoded['subjects'];
      } catch (_) {}
    }

    // 3. Network fetch (background or direct)
    try {
      final url = ApiConstants.subjectsUrl(semester, version: version);
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        await _storage.setCachedResponse(cacheKey, jsonEncode(data));
        final list = (data['subjects'] as List? ?? [])
            .map((s) => SubjectModel.fromJson(s))
            .toList();
        _memoryCache[cacheKey] = data['subjects'];
        return list;
      }
    } catch (e) {
      if (diskSubjects != null && diskSubjects.isNotEmpty) return diskSubjects;
      try {
        final manifestStr = await rootBundle.loadString('assets/manifest/content_manifest.json');
        final data = jsonDecode(manifestStr);
        final semNotes = data['semesters']?['$semester']?['notes'] as List? ?? [];
        if (semNotes.isNotEmpty) {
          final fallbackList = semNotes.map((s) => SubjectModel(
            subjectId: s['subject_id'] ?? '',
            name: s['subject_name'] ?? '',
            nameEn: s['subject_name_en'] ?? '',
            order: 1,
            iconUrl: s['icon_asset'] ?? '',
            topicCount: (s['topics'] as List? ?? []).length,
            hasPremium: true,
          )).toList();
          _memoryCache[cacheKey] = fallbackList.map((s) => s.toJson()).toList();
          return fallbackList;
        }
      } catch (_) {}
      if (diskSubjects != null) return diskSubjects;
      rethrow;
    }

    return diskSubjects ?? [];
  }

  /// Fetch Topics & Sets of a subject
  Future<List<TopicModel>> getTopics(int semester, String subjectId, {String? version}) async {
    final cacheKey = 'topics_sem_${semester}_$subjectId';

    if (_memoryCache.containsKey(cacheKey)) {
      return (_memoryCache[cacheKey] as List)
          .map((t) => TopicModel.fromJson(t))
          .toList();
    }

    final localJson = _storage.getCachedResponse(cacheKey);
    List<TopicModel>? diskTopics;
    if (localJson != null) {
      try {
        final decoded = jsonDecode(localJson);
        final list = (decoded['topics'] as List? ?? [])
            .map((t) => TopicModel.fromJson(t))
            .toList();
        diskTopics = list;
        _memoryCache[cacheKey] = decoded['topics'];
      } catch (_) {}
    }

    try {
      final url = ApiConstants.topicsUrl(semester, subjectId, version: version);
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        await _storage.setCachedResponse(cacheKey, jsonEncode(data));
        final list = (data['topics'] as List? ?? [])
            .map((t) => TopicModel.fromJson(t))
            .toList();
        _memoryCache[cacheKey] = data['topics'];
        return list;
      }
    } catch (e) {
      if (diskTopics != null && diskTopics.isNotEmpty) return diskTopics;
      try {
        final manifestStr = await rootBundle.loadString('assets/manifest/content_manifest.json');
        final data = jsonDecode(manifestStr);
        final semNotes = data['semesters']?['$semester']?['notes'] as List? ?? [];
        final matchedSub = semNotes.firstWhere(
          (s) => s['subject_id'] == subjectId,
          orElse: () => null,
        );
        if (matchedSub != null) {
          final tList = matchedSub['topics'] as List? ?? [];
          final fallbackTopics = tList.map((t) => TopicModel(
            topicId: t['topic_id'] ?? '',
            name: t['title'] ?? '',
            order: 1,
            sets: [
              TestSetModel(
                setFile: 'set1',
                title: 'Set 1',
                setNumber: 1,
                questionCount: 10,
                totalMarks: 10,
                isPremium: false,
                hasTimer: false,
                durationMinutes: 10,
                version: '1',
              ),
              TestSetModel(
                setFile: 'set2',
                title: 'Set 2',
                setNumber: 2,
                questionCount: 10,
                totalMarks: 10,
                isPremium: true,
                hasTimer: true,
                durationMinutes: 10,
                version: '1',
              ),
              TestSetModel(
                setFile: 'set3',
                title: 'Set 3',
                setNumber: 3,
                questionCount: 10,
                totalMarks: 10,
                isPremium: true,
                hasTimer: true,
                durationMinutes: 10,
                version: '1',
              ),
              TestSetModel(
                setFile: 'set4',
                title: 'Set 4',
                setNumber: 4,
                questionCount: 10,
                totalMarks: 10,
                isPremium: true,
                hasTimer: true,
                durationMinutes: 10,
                version: '1',
              ),
            ],
          )).toList();
          if (fallbackTopics.isNotEmpty) {
            _memoryCache[cacheKey] = fallbackTopics.map((t) => {
              'topic_id': t.topicId,
              'name': t.name,
              'order': t.order,
              'sets': t.sets.map((s) => s.toJson()).toList(),
            }).toList();
            return fallbackTopics;
          }
        }
      } catch (_) {}
      if (diskTopics != null) return diskTopics;
      rethrow;
    }

    return diskTopics ?? [];
  }

  /// Fetch and parse Test Paper with background isolate parsing
  Future<TestPaperModel> getTestPaper(
    int semester,
    String subjectId,
    String setFile, {
    String? version,
  }) async {
    final cacheKey = 'test_${semester}_${subjectId}_$setFile';

    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey] as TestPaperModel;
    }

    final localJson = _storage.getCachedResponse(cacheKey);
    if (localJson != null) {
      try {
        final paper = await compute(_parseTestPaperJson, localJson);
        _memoryCache[cacheKey] = paper;
        return paper;
      } catch (_) {}
    }

    final url = ApiConstants.testSetUrl(semester, subjectId, setFile, version: version);
    final response = await _dio.get(url);
    if (response.statusCode == 200) {
      final rawString = response.data is String ? response.data : jsonEncode(response.data);
      await _storage.setCachedResponse(cacheKey, rawString);
      final paper = await compute(_parseTestPaperJson, rawString);
      _memoryCache[cacheKey] = paper;
      return paper;
    }

    throw Exception('Failed to load test paper');
  }

  /// Submit Question Report or Feedback (Firebase Realtime DB + Firestore + API Fallback)
  Future<bool> sendReport({
    required String type,
    required String name,
    required String email,
    required String message,
    required String contextSummary,
    Map<String, dynamic>? meta,
  }) async {
    final clientRequestId = const Uuid().v4();
    final jsonPayload = {
      'client_request_id': clientRequestId,
      'type': type,
      'name': name.isEmpty ? 'Student' : name,
      'email': email.isEmpty ? 'student@esbangla.app' : email,
      'message': message,
      'context': contextSummary,
      if (meta != null) 'meta': meta,
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'pending',
    };

    bool delivered = false;

    // 1. Firebase Realtime Database (100% open write & guaranteed real-time delivery to Admin Panel)
    try {
      final rtdbResponse = await _dio.post(
        'https://es-bangla-225f2-default-rtdb.firebaseio.com/question_reports.json',
        data: jsonPayload,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (rtdbResponse.statusCode == 200) {
        delivered = true;
      }
    } catch (_) {}

    // 2. Direct Firestore Submission (to question_reports and users subcollection)
    try {
      final firestorePayload = {
        ...jsonPayload,
        'created_at': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance.collection('question_reports').add(firestorePayload);
      delivered = true;
    } catch (_) {}

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('reports')
            .add({
          ...jsonPayload,
          'created_at': FieldValue.serverTimestamp(),
        });
        delivered = true;
      }
    } catch (_) {}

    // 3. HTTP Endpoint Sync
    try {
      final response = await _dio.post(
        ApiConstants.reportEndpoint,
        data: jsonPayload,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (response.statusCode == 200) delivered = true;
    } catch (_) {}

    return delivered;
  }
}

// Background isolate JSON parser to maintain 60 FPS
TestPaperModel _parseTestPaperJson(dynamic jsonStr) {
  final decoded = jsonDecode(jsonStr as String);
  return TestPaperModel.fromJson(Map<String, dynamic>.from(decoded));
}
