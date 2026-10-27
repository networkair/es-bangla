import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

  /// Submit Question Report or Feedback to Telegram API v1/v2
  Future<bool> sendReport({
    required String type,
    required String name,
    required String email,
    required String message,
    required String contextSummary,
    Map<String, dynamic>? meta,
  }) async {
    try {
      final payload = {
        'client_request_id': const Uuid().v4(),
        'type': type,
        'name': name.isEmpty ? 'Student' : name,
        'email': email.isEmpty ? 'student@esbangla.app' : email,
        'message': message,
        'context': contextSummary,
        if (meta != null) 'meta': meta,
      };

      final response = await _dio.post(
        ApiConstants.reportEndpoint,
        data: payload,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

// Background isolate JSON parser to maintain 60 FPS
TestPaperModel _parseTestPaperJson(String jsonStr) {
  final decoded = jsonDecode(jsonStr);
  return TestPaperModel.fromJson(Map<String, dynamic>.from(decoded));
}
