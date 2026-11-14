import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/storage/local_storage_service.dart';
import '../domain/mock_test_models.dart';
import 'mock_bundle_service.dart';

class MockTestRepository {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Accept': 'application/json',
    },
  ));

  final LocalStorageService _storage = LocalStorageService();
  final MockBundleService _bundleService = MockBundleService();

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

  /// Fetch Subjects for current semester with instant 0ms offline-first loading and background sync
  Future<List<SubjectModel>> getSubjects(int semester, {String? version}) async {
    final cacheKey = 'subjects_sem_$semester';

    // 1. Check memory cache first (0ms)
    if (_memoryCache.containsKey(cacheKey)) {
      return (_memoryCache[cacheKey] as List)
          .map((s) => SubjectModel.fromJson(s))
          .toList();
    }

    // 2. Check disk cache (0ms)
    final localJson = _storage.getCachedResponse(cacheKey);
    List<SubjectModel>? localSubjects;
    if (localJson != null) {
      try {
        final decoded = jsonDecode(localJson);
        final list = (decoded['subjects'] as List? ?? [])
            .map((s) => SubjectModel.fromJson(s))
            .toList();
        if (list.isNotEmpty) {
          localSubjects = list;
          _memoryCache[cacheKey] = decoded['subjects'];
        }
      } catch (_) {}
    }

    // 3. Check bundled pre-packaged offline assets (0ms, 100% reliable)
    if (localSubjects == null || localSubjects.isEmpty) {
      final bundled = await _bundleService.getBundledSubjects(semester);
      if (bundled != null && bundled.isNotEmpty) {
        localSubjects = bundled;
        _memoryCache[cacheKey] = bundled.map((s) => s.toJson()).toList();
      }
    }

    // If we have local or bundled subjects, return immediately in 0ms and trigger silent background sync!
    if (localSubjects != null && localSubjects.isNotEmpty) {
      _silentSyncSubjects(semester, cacheKey, version: version);
      return localSubjects;
    }

    // 4. Fallback network fetch if no local or bundled data was found
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
      // 5. Final fallback to content manifest
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
      rethrow;
    }

    return [];
  }

  void _silentSyncSubjects(int semester, String cacheKey, {String? version}) {
    Future.microtask(() async {
      try {
        final url = ApiConstants.subjectsUrl(semester, version: version);
        final response = await _dio.get(
          url,
          options: Options(receiveTimeout: const Duration(seconds: 6)),
        );
        if (response.statusCode == 200) {
          final data = response.data is String ? jsonDecode(response.data) : response.data;
          await _storage.setCachedResponse(cacheKey, jsonEncode(data));
          _memoryCache[cacheKey] = data['subjects'];
        }
      } catch (_) {}
    });
  }

  /// Fetch Topics & Sets of a subject with instant 0ms offline-first loading and background sync
  Future<List<TopicModel>> getTopics(int semester, String subjectId, {String? version}) async {
    final cacheKey = 'topics_sem_${semester}_$subjectId';

    // 1. Check memory cache first (0ms)
    if (_memoryCache.containsKey(cacheKey)) {
      return (_memoryCache[cacheKey] as List)
          .map((t) => TopicModel.fromJson(t))
          .toList();
    }

    // 2. Check disk cache (0ms)
    final localJson = _storage.getCachedResponse(cacheKey);
    List<TopicModel>? localTopics;
    if (localJson != null) {
      try {
        final decoded = jsonDecode(localJson);
        final list = (decoded['topics'] as List? ?? [])
            .map((t) => TopicModel.fromJson(t))
            .toList();
        if (list.isNotEmpty) {
          localTopics = list;
          _memoryCache[cacheKey] = decoded['topics'];
        }
      } catch (_) {}
    }

    // 3. Check bundled pre-packaged offline assets (0ms, 100% reliable)
    if (localTopics == null || localTopics.isEmpty) {
      final bundled = await _bundleService.getBundledTopics(semester, subjectId);
      if (bundled != null && bundled.isNotEmpty) {
        localTopics = bundled;
        _memoryCache[cacheKey] = bundled.map((t) => {
          'topic_id': t.topicId,
          'name': t.name,
          'order': t.order,
          'sets': t.sets.map((s) => s.toJson()).toList(),
        }).toList();
      }
    }

    // If we have local or bundled topics, return immediately in 0ms and trigger silent background sync!
    if (localTopics != null && localTopics.isNotEmpty) {
      _silentSyncTopics(semester, subjectId, cacheKey, version: version);
      return localTopics;
    }

    // 4. Fallback network fetch
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
      // 5. Final fallback to content manifest
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
      rethrow;
    }

    return [];
  }

  void _silentSyncTopics(int semester, String subjectId, String cacheKey, {String? version}) {
    Future.microtask(() async {
      try {
        final url = ApiConstants.topicsUrl(semester, subjectId, version: version);
        final response = await _dio.get(
          url,
          options: Options(receiveTimeout: const Duration(seconds: 6)),
        );
        if (response.statusCode == 200) {
          final data = response.data is String ? jsonDecode(response.data) : response.data;
          await _storage.setCachedResponse(cacheKey, jsonEncode(data));
          _memoryCache[cacheKey] = data['topics'];
        }
      } catch (_) {}
    });
  }

  /// Fetch and parse Test Paper with instant 0ms offline-first loading and background sync
  Future<TestPaperModel> getTestPaper(
    int semester,
    String subjectId,
    String setFile, {
    String? version,
  }) async {
    final cacheKey = 'test_${semester}_${subjectId}_$setFile';

    // 1. Check in-memory session cache (0ms instant)
    if (_memoryCache.containsKey(cacheKey)) {
      final cached = _memoryCache[cacheKey];
      if (cached is TestPaperModel) {
        _silentSyncTestPaper(semester, subjectId, setFile, cacheKey, currentVersion: cached.metadata.version, version: version);
        return cached;
      }
    }

    // 2. Check disk cache (previously synced or cached update)
    final localJson = _storage.getCachedResponse(cacheKey);
    if (localJson != null) {
      try {
        final paper = await compute(_parseTestPaperJson, localJson);
        _memoryCache[cacheKey] = paper;
        _silentSyncTestPaper(semester, subjectId, setFile, cacheKey, currentVersion: paper.metadata.version, version: version);
        return paper;
      } catch (_) {}
    }

    // 3. Check bundled pre-packaged encrypted offline bundle (0ms instant, works 100% offline!)
    try {
      final bundledMap = await _bundleService.getBundledTestPaper(semester, subjectId, setFile);
      if (bundledMap != null) {
        final paper = await compute(_parseTestPaperJson, bundledMap);
        _memoryCache[cacheKey] = paper;
        _silentSyncTestPaper(semester, subjectId, setFile, cacheKey, currentVersion: paper.metadata.version, version: version);
        return paper;
      }
    } catch (_) {}

    // 4. Fallback network fetch if set was not found locally (e.g. brand new set added to cloud after app release)
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

  void _silentSyncTestPaper(
    int semester,
    String subjectId,
    String setFile,
    String cacheKey, {
    String? currentVersion,
    String? version,
  }) {
    // Run in background without awaiting or blocking the UI
    Future.microtask(() async {
      try {
        // If version hash matches current version, no need to re-download!
        if (version != null && currentVersion != null && version == currentVersion) {
          return;
        }
        final url = ApiConstants.testSetUrl(semester, subjectId, setFile, version: version);
        final response = await _dio.get(
          url,
          options: Options(
            receiveTimeout: const Duration(seconds: 6),
            sendTimeout: const Duration(seconds: 4),
          ),
        );
        if (response.statusCode == 200) {
          final rawString = response.data is String ? response.data : jsonEncode(response.data);
          final updatedPaper = await compute(_parseTestPaperJson, rawString);
          if (currentVersion == null || updatedPaper.metadata.version != currentVersion) {
            await _storage.setCachedResponse(cacheKey, rawString);
            _memoryCache[cacheKey] = updatedPaper;
          }
        }
      } catch (_) {
        // Background sync failure is completely silent to the user
      }
    });
  }

  /// Submit Question Report or Feedback directly to dedicated Report API
  /// (Delivers directly to Telegram Admin Channel via Cloudflare Pages Function)
  Future<bool> sendReport({
    required String type,
    required String name,
    required String email,
    required String message,
    required String contextSummary,
    Map<String, dynamic>? meta,
  }) async {
    final clientRequestId = const Uuid().v4();
    final currentUser = FirebaseAuth.instance.currentUser;
    final uid = meta?['uid'] ?? currentUser?.uid ?? 'guest_student';

    final jsonPayload = {
      'client_request_id': clientRequestId,
      'type': type,
      'name': name.trim().isEmpty ? 'Student' : name.trim(),
      'email': email.trim().isEmpty ? 'student@esbangla.app' : email.trim(),
      'uid': uid,
      'message': message,
      'context': contextSummary,
      if (meta != null) 'meta': meta,
      'timestamp': DateTime.now().toIso8601String(),
    };

    String? idToken;
    try {
      if (currentUser != null) {
        idToken = await currentUser.getIdToken();
      }
    } catch (_) {}

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (idToken != null && idToken.isNotEmpty) 'Authorization': 'Bearer $idToken',
    };

    // 1. Primary: Direct Cloudflare Edge Function -> Telegram
    try {
      final response = await _dio.post(
        ApiConstants.reportEndpoint,
        data: jsonPayload,
        options: Options(
          headers: headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        if (data is Map && (data['status'] == 'success' || data['duplicate'] == true)) {
          return true;
        }
      }
    } catch (e) {
      if (kDebugMode) print('Primary Report API error: $e');
    }

    // 2. Fallback: Legacy endpoint if primary endpoint fails
    try {
      final response = await _dio.post(
        ApiConstants.legacyReportEndpoint,
        data: jsonPayload,
        options: Options(
          headers: headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        if (data is Map && (data['status'] == 'success' || data['duplicate'] == true)) {
          return true;
        }
      }
    } catch (e) {
      if (kDebugMode) print('Legacy Report API error: $e');
    }

    return false;
  }
}

// Background isolate JSON parser to maintain 60/120 FPS
TestPaperModel _parseTestPaperJson(dynamic jsonSource) {
  if (jsonSource is Map) {
    return TestPaperModel.fromJson(Map<String, dynamic>.from(jsonSource));
  }
  final decoded = jsonDecode(jsonSource as String);
  return TestPaperModel.fromJson(Map<String, dynamic>.from(decoded));
}
