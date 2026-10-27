import 'dart:convert';
import 'package:flutter/services.dart';

class NoteTopic {
  final String topicId;
  final String title;
  final String filePath;

  NoteTopic({required this.topicId, required this.title, required this.filePath});

  factory NoteTopic.fromJson(Map<String, dynamic> json) => NoteTopic(
        topicId: json['topic_id'] ?? '',
        title: json['title'] ?? '',
        filePath: json['file_path'] ?? '',
      );
}

class NoteSubject {
  final String subjectId;
  final String subjectName;
  final String subjectNameEn;
  final List<NoteTopic> topics;

  NoteSubject({
    required this.subjectId,
    required this.subjectName,
    required this.subjectNameEn,
    required this.topics,
  });

  factory NoteSubject.fromJson(Map<String, dynamic> json) {
    final list = (json['topics'] as List? ?? [])
        .map((t) => NoteTopic.fromJson(Map<String, dynamic>.from(t)))
        .toList();
    return NoteSubject(
      subjectId: json['subject_id'] ?? '',
      subjectName: json['subject_name'] ?? '',
      subjectNameEn: json['subject_name_en'] ?? '',
      topics: list,
    );
  }
}

class PyqPaper {
  final String year;
  final String title;
  final String filePath;

  PyqPaper({required this.year, required this.title, required this.filePath});

  factory PyqPaper.fromJson(Map<String, dynamic> json) => PyqPaper(
        year: json['year'] ?? '',
        title: json['title'] ?? '',
        filePath: json['file_path'] ?? '',
      );
}

class PyqSubject {
  final String subjectId;
  final String subjectName;
  final List<PyqPaper> papers;

  PyqSubject({required this.subjectId, required this.subjectName, required this.papers});

  factory PyqSubject.fromJson(Map<String, dynamic> json) {
    final list = (json['papers'] as List? ?? [])
        .map((p) => PyqPaper.fromJson(Map<String, dynamic>.from(p)))
        .toList();
    return PyqSubject(
      subjectId: json['subject_id'] ?? '',
      subjectName: json['subject_name'] ?? '',
      papers: list,
    );
  }
}

class ContentManifestRepository {
  Map<String, dynamic>? _cachedManifest;

  Future<Map<String, dynamic>> _loadManifest() async {
    if (_cachedManifest != null) return _cachedManifest!;
    final str = await rootBundle.loadString('assets/manifest/content_manifest.json');
    _cachedManifest = jsonDecode(str);
    return _cachedManifest!;
  }

  Future<List<NoteSubject>> getNotesForSemester(int semester) async {
    final manifest = await _loadManifest();
    final semData = manifest['semesters']?['$semester'];
    if (semData == null || semData['notes'] == null) return [];
    return (semData['notes'] as List)
        .map((s) => NoteSubject.fromJson(Map<String, dynamic>.from(s)))
        .toList();
  }

  Future<List<PyqSubject>> getPyqForSemester(int semester) async {
    final manifest = await _loadManifest();
    final semData = manifest['semesters']?['$semester'];
    if (semData == null || semData['pyq'] == null) return [];
    return (semData['pyq'] as List)
        .map((s) => PyqSubject.fromJson(Map<String, dynamic>.from(s)))
        .toList();
  }
}
