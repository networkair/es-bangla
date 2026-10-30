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
  /// Syncs all user entitlements from Cloud Firestore database into LocalStorage.
  /// Checks users/{uid} document, users/{uid}/entitlements subcollection,
  /// and access_keys redeemed by the user's email or UID.
  static Future<List<String>> syncUserEntitlements() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return LocalStorageService().getEntitlements();
    }

    final userUid = user.uid;

    try {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(userUid);
      final userDoc = await userDocRef.get();

      // 1. Authoritative check on users/{uid} document
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null && data.containsKey('entitlements')) {
          final List<dynamic> rawList = data['entitlements'] as List? ?? [];
          final List<String> activeGrants = rawList
              .where((e) => e != null && e.toString().trim().isNotEmpty)
              .map((e) => e.toString().trim())
              .toList();

          // Authoritative sync: overwrite local cache with server state!
          await LocalStorageService().setEntitlements(activeGrants);
          debugPrint('Entitlements synced from user doc (Authoritative): $activeGrants');
          return activeGrants;
        }
      }

      // 2. If userDoc doesn't have the field yet, check active keys in access_keys
      final Set<String> activeGrants = {};

      if (userUid.isNotEmpty) {
        final keysByUidSnap = await FirebaseFirestore.instance
            .collection('access_keys')
            .where('redeemedByUid', isEqualTo: userUid)
            .get();

        for (final doc in keysByUidSnap.docs) {
          final data = doc.data();
          final status = data['status'] ?? 'active';
          if (status != 'cancelled' && status != 'revoked' && data['grants'] is List) {
            for (final g in data['grants']) {
              if (g != null && g.toString().isNotEmpty) activeGrants.add(g.toString());
            }
          }
        }
      }

      final resultList = activeGrants.toList();
      await LocalStorageService().setEntitlements(resultList);
      await userDocRef.set({
        'entitlements': resultList,
        'lastEntitlementSyncAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('Entitlements synced from access_keys: $resultList');
      return resultList;
    } catch (e) {
      debugPrint('Entitlement sync error: $e');
      return LocalStorageService().getEntitlements();
    }
  }

  /// Robust Invite Code / Key Redemption & Self-Restoration logic
  static Future<RedeemResult> redeemOrRestoreKey({
    required String inputCode,
    required int semester,
    List<String>? fallbackGrants,
  }) async {
    final code = inputCode.trim().toUpperCase();
    if (code.isEmpty) {
      throw Exception('দয়া করে ইনভাইট কোডটি লিখুন');
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('অ্যাক্টিভেশন কোড রিডিম করতে প্রথমে লগইন করুন।');
    }

    final userUid = user.uid;
    final userEmail = (user.email ?? LocalStorageService().userEmail).trim().toLowerCase();

    final keyDocRef = FirebaseFirestore.instance.collection('access_keys').doc(code);
    final userRef = FirebaseFirestore.instance.collection('users').doc(userUid);

    return await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(keyDocRef);
      if (!snapshot.exists) {
        throw Exception('ইনভাইট কোডটি সঠিক নয় বা খুঁজে পাওয়া যায়নি।');
      }

      final data = snapshot.data()!;
      final status = data['status'] ?? 'active';
      final boundEmail = data['boundEmail']?.toString().trim().toLowerCase();
      final boundUid = data['boundUid']?.toString().trim();
      final redeemedByUid = data['redeemedByUid']?.toString().trim();
      final redeemedByEmail = data['redeemedByEmail']?.toString().trim().toLowerCase();
      final redeemedBy = data['redeemedBy']?.toString().trim().toLowerCase();

      final List<String> defaultGrants = fallbackGrants ?? ['video_library_sem$semester'];
      final List<String> grants = data['grants'] != null
          ? List<String>.from(data['grants'])
          : defaultGrants;

      final int durationDays = data['durationDays'] is num
          ? (data['durationDays'] as num).toInt()
          : 365;

      // Handle Already-Used keys:
      // If used BY THIS SAME USER, restore it seamlessly!
      if (status == 'used') {
        final isOwnedByCurrentUser =
            (redeemedByUid != null && redeemedByUid.isNotEmpty && redeemedByUid == userUid) ||
            (redeemedByEmail != null && redeemedByEmail.isNotEmpty && redeemedByEmail == userEmail) ||
            (redeemedBy != null && redeemedBy.isNotEmpty && redeemedBy == userEmail) ||
            (boundUid != null && boundUid.isNotEmpty && boundUid == userUid) ||
            (boundEmail != null && boundEmail.isNotEmpty && boundEmail == userEmail);

        if (isOwnedByCurrentUser) {
          // Restore entitlement to user subcollection
          final entitlementRef = userRef.collection('entitlements').doc(code);
          transaction.set(entitlementRef, {
            'grants': grants,
            'startsAt': data['redeemedAt'] ?? FieldValue.serverTimestamp(),
            'durationDays': durationDays,
            'sourceCode': code,
            'semester': semester,
            'status': 'active',
            'restoredAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          // Restore array on user doc
          transaction.set(userRef, {
            'entitlements': FieldValue.arrayUnion(grants),
            'lastEntitlementRestoreAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          // Save locally
          final currentEntitlements = LocalStorageService().getEntitlements();
          for (final g in grants) {
            if (!currentEntitlements.contains(g)) currentEntitlements.add(g);
          }
          await LocalStorageService().setEntitlements(currentEntitlements);

          return RedeemResult(
            success: true,
            wasRestored: true,
            message: 'আপনার এই কোডটি পূর্বেই সক্রিয় ছিল। সাবস্ক্রিপশন সফলভাবে পুনরুদ্ধার করা হয়েছে!',
            grants: grants,
          );
        } else {
          throw Exception('এই ইনভাইট কোডটি ইতিমধ্যে অন্য অ্যাকাউন্টে ব্যবহার করা হয়ে গেছে।');
        }
      }

      // Check account binding restrictions
      if (boundEmail != null && boundEmail.isNotEmpty && boundEmail != userEmail) {
        throw Exception('এই কোডটি অন্য একটি ইমেইল অ্যাকাউন্টের ($boundEmail) জন্য বরাদ্দ করা।');
      }

      if (boundUid != null && boundUid.isNotEmpty && boundUid != userUid) {
        throw Exception('এই কোডটি অন্য একটি অ্যাকাউন্টের জন্য নির্ধারিত।');
      }

      // Redeem new key
      transaction.update(keyDocRef, {
        'status': 'used',
        'redeemedByEmail': userEmail,
        'redeemedByUid': userUid,
        'redeemedBy': userEmail,
        'redeemedAt': FieldValue.serverTimestamp(),
      });

      // Save entitlement subcollection
      final entitlementRef = userRef.collection('entitlements').doc(code);
      transaction.set(entitlementRef, {
        'grants': grants,
        'startsAt': FieldValue.serverTimestamp(),
        'durationDays': durationDays,
        'sourceCode': code,
        'semester': semester,
        'status': 'active',
      });

      // Update user doc array
      transaction.set(userRef, {
        'entitlements': FieldValue.arrayUnion(grants),
        'lastEntitlementUpdateAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Save locally
      final currentEntitlements = LocalStorageService().getEntitlements();
      for (final g in grants) {
        if (!currentEntitlements.contains(g)) {
          currentEntitlements.add(g);
        }
      }
      await LocalStorageService().setEntitlements(currentEntitlements);

      return RedeemResult(
        success: true,
        wasRestored: false,
        message: 'অভিনন্দন! আপনার সাবস্ক্রিপশন সফলভাবে সক্রিয় হয়েছে।',
        grants: grants,
      );
    });
  }
}
