import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../storage/local_storage_service.dart';

class RedeemResult {
  final bool success;
  final bool wasRestored;
  final String message;
  final List<String> grants;

  const RedeemResult({
    required this.success,
    required this.wasRestored,
    required this.message,
    this.grants = const [],
  });
}

class EntitlementService {
  // In-memory runtime state, strictly kept in sync with Cloud Firestore
  static List<String> _activeEntitlements = [];
  static final ValueNotifier<List<String>> entitlementsNotifier =
      ValueNotifier<List<String>>([]);

  /// Unmodifiable view of currently active user entitlements
  static List<String> get currentEntitlements => List.unmodifiable(_activeEntitlements);

  /// Helper to check if current user has access to Video Library
  static bool hasVideoAccess(int semester, {String? subjectId, String? subjectName}) {
    if (_activeEntitlements.isEmpty) return false;
    if (_activeEntitlements.contains('video_library_all')) return true;
    if (_activeEntitlements.contains('video_library_sem$semester')) return true;
    if (_activeEntitlements.contains('combo_all')) return true;
    if (_activeEntitlements.contains('combo_sem$semester')) return true;
    if (subjectId != null && _activeEntitlements.contains('subject_$subjectId')) return true;
    if (subjectName != null && _activeEntitlements.contains('subject_$subjectName')) return true;
    return false;
  }

  /// Helper to check if current user has access to Mock Tests
  static bool hasMockAccess(int semester) {
    if (_activeEntitlements.isEmpty) return false;
    if (_activeEntitlements.contains('premium_mock_all')) return true;
    if (_activeEntitlements.contains('premium_mock_sem$semester')) return true;
    if (_activeEntitlements.contains('combo_all')) return true;
    if (_activeEntitlements.contains('combo_sem$semester')) return true;
    return false;
  }

  /// Real-time stream listening directly to the authenticated user's Firestore document.
  /// If the admin deletes or revokes the entitlement in the cloud, this stream immediately emits
  /// the updated (empty) list, causing screens to lock in real time.
  static Stream<List<String>> liveUserEntitlementsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _activeEntitlements = [];
      entitlementsNotifier.value = [];
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        _activeEntitlements = [];
        entitlementsNotifier.value = [];
        return [];
      }

      final data = snapshot.data()!;

      // Check if VIP is explicitly deactivated
      if (data['isVipActive'] == false) {
        _activeEntitlements = [];
        entitlementsNotifier.value = [];
        return [];
      }

      // Check expiry date if specified
      final expiresRaw = data['subscriptionExpiresAt'];
      if (expiresRaw != null) {
        DateTime? expiryDate;
        if (expiresRaw is Timestamp) {
          expiryDate = expiresRaw.toDate();
        } else if (expiresRaw is String) {
          expiryDate = DateTime.tryParse(expiresRaw);
        }
        if (expiryDate != null && DateTime.now().isAfter(expiryDate)) {
          _activeEntitlements = [];
          entitlementsNotifier.value = [];
          return [];
        }
      }

      final List<dynamic> rawList = data['entitlements'] as List? ?? [];
      final List<String> activeGrants = rawList
          .where((e) => e != null && e.toString().trim().isNotEmpty)
          .map((e) => e.toString().trim())
          .toList();

      _activeEntitlements = activeGrants;
      entitlementsNotifier.value = activeGrants;
      return activeGrants;
    });
  }

  /// Authoritative single-fetch sync directly from Firestore users/{uid}.
  /// Always tries Source.server first, falling back to cache if offline.
  /// Never persists to local storage. If user is guest or field is absent, returns empty list.
  static Future<List<String>> syncUserEntitlements() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _activeEntitlements = [];
      entitlementsNotifier.value = [];
      return [];
    }

    try {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      DocumentSnapshot<Map<String, dynamic>> userDoc;
      try {
        userDoc = await userDocRef.get(const GetOptions(source: Source.server));
      } catch (_) {
        userDoc = await userDocRef.get(const GetOptions(source: Source.cache));
      }

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;

        // Check if VIP is explicitly deactivated
        if (data['isVipActive'] == false) {
          _activeEntitlements = [];
          entitlementsNotifier.value = [];
          return [];
        }

        // Check expiry date if specified
        final expiresRaw = data['subscriptionExpiresAt'];
        if (expiresRaw != null) {
          DateTime? expiryDate;
          if (expiresRaw is Timestamp) {
            expiryDate = expiresRaw.toDate();
          } else if (expiresRaw is String) {
            expiryDate = DateTime.tryParse(expiresRaw);
          }
          if (expiryDate != null && DateTime.now().isAfter(expiryDate)) {
            _activeEntitlements = [];
            entitlementsNotifier.value = [];
            return [];
          }
        }

        final List<dynamic> rawList = data['entitlements'] as List? ?? [];
        final List<String> activeGrants = rawList
            .where((e) => e != null && e.toString().trim().isNotEmpty)
            .map((e) => e.toString().trim())
            .toList();

        _activeEntitlements = activeGrants;
        entitlementsNotifier.value = activeGrants;
        debugPrint('Entitlements synced from server: $activeGrants');
        return activeGrants;
      }

      _activeEntitlements = [];
      entitlementsNotifier.value = [];
      return [];
    } catch (e) {
      debugPrint('Entitlement sync error: $e');
      return _activeEntitlements;
    }
  }

  /// Key Redemption with strict category isolation.
  /// [expectedCategory] MUST be either 'video_library' or 'mock_test'.
  /// Any mismatched key (e.g., trying to redeem a mock test key in video library) is strictly rejected.
  static Future<RedeemResult> redeemOrRestoreKey({
    required String inputCode,
    required int semester,
    required String expectedCategory, // 'video_library' or 'mock_test'
    List<String>? fallbackGrants,
  }) async {
    final code = inputCode.trim().toUpperCase();
    if (code.isEmpty) {
      throw Exception('দয়া করে অ্যাক্টিভেশন কোডটি লিখুন');
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('অ্যাক্টিভেশন কোড রিডিম করতে প্রথমে অ্যাপে লগইন করুন।');
    }

    final userUid = user.uid;
    final userEmail = (user.email ?? LocalStorageService().userEmail).trim().toLowerCase();
    if (userEmail.isEmpty) {
      throw Exception('অ্যাক্টিভেশন কোড রিডিম করতে একটি বৈধ ইমেইল অ্যাকাউন্ট দিয়ে লগইন করা আবশ্যক।');
    }

    final keyDocRef = FirebaseFirestore.instance.collection('access_keys').doc(code);
    final userRef = FirebaseFirestore.instance.collection('users').doc(userUid);

    return await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(keyDocRef);
      if (!snapshot.exists) {
        throw Exception('অ্যাক্টিভেশন কোডটি সঠিক নয় বা খুঁজে পাওয়া যায়নি।');
      }

      final data = snapshot.data()!;
      final status = (data['status'] ?? 'active').toString().toLowerCase();
      final boundEmail = data['boundEmail']?.toString().trim().toLowerCase();
      final boundUid = data['boundUid']?.toString().trim();
      final redeemedByUid = data['redeemedByUid']?.toString().trim();
      final redeemedByEmail = data['redeemedByEmail']?.toString().trim().toLowerCase();

      final List<String> defaultGrants = fallbackGrants ??
          (expectedCategory == 'video_library'
              ? ['video_library_sem$semester']
              : ['premium_mock_sem$semester']);

      final List<String> rawGrants = data['grants'] != null
          ? List<String>.from(data['grants'])
          : defaultGrants;

      final List<String> grants = rawGrants
          .where((g) => g.trim().isNotEmpty)
          .map((g) => g.trim())
          .toList();

      if (grants.isEmpty) {
        throw Exception('এই কোডটির সাথে কোনো বৈধ সাবস্ক্রিপশন যুক্ত নেই।');
      }

      // ==========================================
      // 1. STRICT CATEGORY ISOLATION VALIDATION
      // ==========================================
      final isVideoCategory = expectedCategory == 'video_library';
      final isMockCategory = expectedCategory == 'mock_test';

      final hasMockGrant = grants.any((g) => g.startsWith('premium_mock_'));
      final hasVideoGrant = grants.any((g) => g.startsWith('video_library_') || g.startsWith('subject_'));
      final isCombo = grants.any((g) => g.startsWith('combo_'));

      if (isVideoCategory) {
        // Trying to redeem in Video Library
        if (hasMockGrant && !hasVideoGrant && !isCombo) {
          throw Exception('এই অ্যাক্টিভেশন কোডটি "মক টেস্টের" জন্য নির্ধারিত, ভিডিও লাইব্রেরির জন্য প্রযোজ্য নয়।');
        }
        // Verify semester match if applicable
        final semMatch = grants.any((g) =>
            g == 'video_library_sem$semester' ||
            g == 'video_library_all' ||
            g == 'combo_sem$semester' ||
            g == 'combo_all' ||
            g.startsWith('subject_'));
        if (!semMatch) {
          throw Exception('এই কোডটি সেমিস্টার $semester-এর ভিডিও লাইব্রেরির জন্য প্রযোজ্য নয়।');
        }
      } else if (isMockCategory) {
        // Trying to redeem in Mock Test
        if (hasVideoGrant && !hasMockGrant && !isCombo) {
          throw Exception('এই অ্যাক্টিভেশন কোডটি "ভিডিও লাইব্রেরির" জন্য নির্ধারিত, মক টেস্টের জন্য প্রযোজ্য নয়।');
        }
        // Verify semester match if applicable
        final semMatch = grants.any((g) =>
            g == 'premium_mock_sem$semester' ||
            g == 'premium_mock_all' ||
            g == 'combo_sem$semester' ||
            g == 'combo_all');
        if (!semMatch) {
          throw Exception('এই কোডটি সেমিস্টার $semester-এর মক টেস্টের জন্য প্রযোজ্য নয়।');
        }
      }

      final int durationDays = data['durationDays'] is num
          ? (data['durationDays'] as num).toInt()
          : 365;

      // ==========================================
      // 2. CHECK KEY REVOCATION / CANCELLATION
      // ==========================================
      if (status == 'cancelled' || status == 'revoked') {
        throw Exception('এই অ্যাক্টিভেশন কোডটি অ্যাডমিন কর্তৃক বাতিল বা স্থগিত করা হয়েছে।');
      }

      // ==========================================
      // 3. HANDLE ALREADY-USED KEYS (Self-Restore vs Other User Block)
      // ==========================================
      if (status == 'used') {
        final isOwnedByCurrentUser =
            (boundUid != null && boundUid.isNotEmpty && boundUid == userUid) ||
            (boundEmail != null && boundEmail.isNotEmpty && boundEmail == userEmail) ||
            (redeemedByUid != null && redeemedByUid.isNotEmpty && redeemedByUid == userUid) ||
            (redeemedByEmail != null && redeemedByEmail.isNotEmpty && redeemedByEmail == userEmail);

        if (isOwnedByCurrentUser) {
          // Self-restore to user document
          transaction.set(userRef, {
            'email': userEmail,
            if (user.displayName != null && user.displayName!.isNotEmpty)
              'name': user.displayName,
            'entitlements': FieldValue.arrayUnion(grants),
            'lastEntitlementRestoreAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          final updatedSet = Set<String>.from(_activeEntitlements)..addAll(grants);
          _activeEntitlements = updatedSet.toList();
          entitlementsNotifier.value = _activeEntitlements;

          return RedeemResult(
            success: true,
            wasRestored: true,
            message: 'আপনার এই কোডটি পূর্বেই আপনার অ্যাকাউন্টে সক্রিয় ছিল। সাবস্ক্রিপশন সফলভাবে পুনরুদ্ধার করা হয়েছে!',
            grants: grants,
          );
        } else {
          final target = boundEmail ?? redeemedByEmail ?? 'অন্য শিক্ষার্থী';
          final masked = target.contains('@')
              ? '${target.substring(0, 2)}***@${target.split('@').last}'
              : target;
          throw Exception('এই অ্যাক্টিভেশন কোডটি ইতিমধ্যে $masked অ্যাকাউন্টে একবার ব্যবহার হয়ে গেছে। একটি কোড কেবল একবারই প্রথম ব্যবহারকারীর ইমেইলে স্থায়ীভাবে লক হয়ে যায়।');
        }
      }

      // ==========================================
      // 4. CHECK PRE-BOUND RESTRICTIONS (If pre-set by Admin)
      // ==========================================
      if (boundEmail != null && boundEmail.isNotEmpty && boundEmail != userEmail) {
        throw Exception('এই কোডটি পূর্বেই অন্য একটি নির্দিষ্ট অ্যাকাউন্টের ($boundEmail) জন্য বরাদ্দ করা হয়েছিল।');
      }

      if (boundUid != null && boundUid.isNotEmpty && boundUid != userUid) {
        throw Exception('এই কোডটি অন্য একটি অ্যাকাউন্টের জন্য নির্ধারিত।');
      }

      // ==========================================
      // 5. FIRST-USE PERMANENT EMAIL & UID BINDING
      // ==========================================
      transaction.update(keyDocRef, {
        'status': 'used',
        'boundEmail': userEmail, // Permanently bound to the first user's email!
        'boundUid': userUid,     // Permanently bound to the first user's UID!
        'redeemedByEmail': userEmail,
        'redeemedByUid': userUid,
        'redeemedByName': user.displayName ?? '',
        'redeemedAt': FieldValue.serverTimestamp(),
        'firstUsedAt': FieldValue.serverTimestamp(),
        'category': expectedCategory,
      });

      // Save to user root document (Authoritative Cloud DB)
      transaction.set(userRef, {
        'email': userEmail,
        if (user.displayName != null && user.displayName!.isNotEmpty)
          'name': user.displayName,
        'entitlements': FieldValue.arrayUnion(grants),
        'lastEntitlementUpdateAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Save subcollection record
      final entitlementRef = userRef.collection('entitlements').doc(code);
      transaction.set(entitlementRef, {
        'grants': grants,
        'startsAt': FieldValue.serverTimestamp(),
        'durationDays': durationDays,
        'sourceCode': code,
        'semester': semester,
        'category': expectedCategory,
        'boundEmail': userEmail,
        'boundUid': userUid,
        'status': 'active',
      });

      // Update in-memory state
      final updatedSet = Set<String>.from(_activeEntitlements)..addAll(grants);
      _activeEntitlements = updatedSet.toList();
      entitlementsNotifier.value = _activeEntitlements;

      return RedeemResult(
        success: true,
        wasRestored: false,
        message: 'অভিনন্দন! আপনার সাবস্ক্রিপশন সফলভাবে সক্রিয় হয়েছে।',
        grants: grants,
      );
    });
  }
}
