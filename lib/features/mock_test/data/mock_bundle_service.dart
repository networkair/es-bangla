import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../domain/mock_test_models.dart';

/// Top-level isolate worker for decrypting and uncompressing encrypted mock test bundles.
/// Ensures the main UI thread never experiences frame drops or jank during parsing.
Map<String, dynamic> _decryptAndParseBundleWorker(Uint8List encryptedBytes) {
  const magic = [0x45, 0x53, 0x4D, 0x42, 0x01]; // ESMB\x01
  final key = utf8.encode('EsBangla_MockTest_SecretSalt_2026_SecureKey_99');

  if (encryptedBytes.length < 5) {
    throw Exception('Invalid mock bundle: file too short');
  }

  for (int i = 0; i < 5; i++) {
    if (encryptedBytes[i] != magic[i]) {
      throw Exception('Invalid mock bundle header');
    }
  }

  final kLen = key.length;
  final payloadLen = encryptedBytes.length - 5;
  final decryptedBytes = Uint8List(payloadLen);

  for (int i = 0; i < payloadLen; i++) {
    decryptedBytes[i] = encryptedBytes[i + 5] ^ key[i % kLen] ^ ((i * 31) & 0xFF);
  }

  final decompressed = gzip.decode(decryptedBytes);
  final jsonStr = utf8.decode(decompressed);
  return jsonDecode(jsonStr) as Map<String, dynamic>;
}

/// Service responsible for securely loading, decrypting, and serving
/// pre-bundled offline Mock Test sets, subjects, and topics from disguised system binary assets.
class MockBundleService {
  static final MockBundleService _instance = MockBundleService._internal();
  factory MockBundleService() => _instance;
  MockBundleService._internal();

  // Internal disguised subject code mapping (prevents exposing subject names in asset paths)
  static const Map<String, String> _subjectCodeMap = {
    'bengali': '01',
    'english': '02',
    'political_science': '03',
    'polscience': '03',
    'education': '04',
    'history': '05',
    'philosophy': '06',
    'sanskrit': '07',
    'geography': '08',
    'computer_application': '09',
    'computer': '09',
  };

  // In-memory cache of decrypted subject bundles: { "sem3_bengali": { "adorini_set_1": { ... } } }
  final Map<String, Map<String, dynamic>> _loadedSubjectBundles = {};

  /// Read bundled subjects list from encrypted system binary assets (instant 0ms offline)
  Future<List<SubjectModel>?> getBundledSubjects(int semester) async {
    final assetPath = 'assets/data/sys_core/sys_s${semester}_cfg.dat';
    try {
      final ByteData byteData = await rootBundle.load(assetPath);
      final Uint8List encryptedBytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
      final decoded = await compute(_decryptAndParseBundleWorker, encryptedBytes);
      final list = (decoded['subjects'] as List? ?? [])
          .map((s) => SubjectModel.fromJson(s))
          .toList();
      return list;
    } catch (_) {
      return null;
    }
  }

  /// Read bundled topics and sets list from encrypted system binary assets (instant 0ms offline)
  Future<List<TopicModel>?> getBundledTopics(int semester, String subjectId) async {
    final code = _subjectCodeMap[subjectId.toLowerCase().trim()];
    if (code == null) return null;

    final assetPath = 'assets/data/sys_core/sys_s${semester}_${code}_idx.dat';
    try {
      final ByteData byteData = await rootBundle.load(assetPath);
      final Uint8List encryptedBytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
      final decoded = await compute(_decryptAndParseBundleWorker, encryptedBytes);
      final list = (decoded['topics'] as List? ?? [])
          .map((t) => TopicModel.fromJson(t))
          .toList();
      return list;
    } catch (_) {
      return null;
    }
  }

  /// Load, decrypt and return a single test paper JSON object from the encrypted system binary bundle
  Future<Map<String, dynamic>?> getBundledTestPaper(
    int semester,
    String subjectId,
    String setFile,
  ) async {
    final bundleKey = 'sem${semester}_$subjectId';

    // 1. Check in-memory cache of already-decrypted subject bundles
    if (_loadedSubjectBundles.containsKey(bundleKey)) {
      final subjectMap = _loadedSubjectBundles[bundleKey]!;
      if (subjectMap.containsKey(setFile)) {
        return subjectMap[setFile] as Map<String, dynamic>?;
      }
      return null;
    }

    final code = _subjectCodeMap[subjectId.toLowerCase().trim()];
    if (code == null) return null;

    // 2. Load from disguised encrypted system binary bundle
    final assetPath = 'assets/data/sys_core/sys_s${semester}_$code.dat';
    try {
      final ByteData byteData = await rootBundle.load(assetPath);
      final Uint8List encryptedBytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );

      // Decrypt and decompress in background isolate so UI stays 100% smooth
      final subjectMap = await compute(_decryptAndParseBundleWorker, encryptedBytes);
      _loadedSubjectBundles[bundleKey] = subjectMap;

      if (subjectMap.containsKey(setFile)) {
        return subjectMap[setFile] as Map<String, dynamic>?;
      }
    } catch (e) {
      if (kDebugMode) {
        print('MockBundleService: Could not load disguised bundle $assetPath: $e');
      }
    }
    return null;
  }

  /// Clear bundle memory cache if needed
  void clearMemoryCache() {
    _loadedSubjectBundles.clear();
  }
}
