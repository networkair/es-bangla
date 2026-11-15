import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../widgets/app_update_dialog.dart';

class AppUpdateInfo {
  final String latestVersion;
  final int latestBuildNumber;
  final String title;
  final String message;
  final String updateUrl;
  final bool isForce;
  final bool enabled;

  const AppUpdateInfo({
    required this.latestVersion,
    this.latestBuildNumber = 0,
    required this.title,
    required this.message,
    required this.updateUrl,
    this.isForce = false,
    this.enabled = true,
  });
}

class AppUpdateService {
  static const String currentVersion = '1.3.63';
  static const int currentBuildNumber = 94;

  static const String _prefDismissedVersionKey = 'last_dismissed_update_version';
  static bool _hasPromptedThisSession = false;

  /// Compares semantic version strings (e.g. "1.3.62" vs "1.3.61").
  /// Returns true if [remote] is strictly newer than [current].
  static bool isVersionNewer(String remote, String current) {
    try {
      final cleanRemote = remote.replaceAll(RegExp(r'[^0-9.]'), '');
      final cleanCurrent = current.replaceAll(RegExp(r'[^0-9.]'), '');

      final rParts = cleanRemote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final cParts = cleanCurrent.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      final maxLen = rParts.length > cParts.length ? rParts.length : cParts.length;
      for (int i = 0; i < maxLen; i++) {
        final r = i < rParts.length ? rParts[i] : 0;
        final c = i < cParts.length ? cParts[i] : 0;
        if (r > c) return true;
        if (r < c) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Checks Firestore `app_config/update` first, falling back to GitHub Releases API.
  static Future<AppUpdateInfo?> fetchUpdateInfo() async {
    // 1. Check Cloud Firestore collection `app_config`, doc `update`
    try {
      final doc = await FirebaseFirestore.instance.collection('app_config').doc('update').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final bool enabled = data['enabled'] ?? true;
        if (!enabled) return null;

        final String remoteVer = (data['latestVersion'] ?? '').toString().trim();
        final int remoteBuild = int.tryParse(data['latestBuildNumber']?.toString() ?? '0') ?? 0;
        final bool isForce = data['isForce'] == true;
        final String title = (data['title'] ?? '').toString().trim();
        final String message = (data['message'] ?? '').toString().trim();
        final String updateUrl = (data['updateUrl'] ?? ApiConstants.githubLatestReleaseUrl).toString().trim();

        final bool hasNewerVer = isVersionNewer(remoteVer, currentVersion);
        final bool hasNewerBuild = remoteBuild > currentBuildNumber;

        if (hasNewerVer || hasNewerBuild) {
          return AppUpdateInfo(
            latestVersion: remoteVer.isNotEmpty ? remoteVer : 'v$remoteBuild',
            latestBuildNumber: remoteBuild,
            title: title.isNotEmpty ? title : 'Exciting Update\nReady For You 🚀 !',
            message: message,
            updateUrl: updateUrl.isNotEmpty ? updateUrl : ApiConstants.githubLatestReleaseUrl,
            isForce: isForce,
            enabled: enabled,
          );
        }
      }
    } catch (e) {
      debugPrint('Firestore update check fallback: $e');
    }

    // 2. Fallback: Query GitHub Releases API directly
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 6),
      ));
      final response = await dio.get(ApiConstants.githubLatestApiEndpoint);
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        final tagName = (data['tag_name'] ?? '').toString().trim();
        final htmlUrl = (data['html_url'] ?? ApiConstants.githubLatestReleaseUrl).toString().trim();

        if (isVersionNewer(tagName, currentVersion)) {
          return AppUpdateInfo(
            latestVersion: tagName.isNotEmpty ? tagName : 'Latest',
            title: 'Exciting Update\nReady For You 🚀 !',
            message: '',
            updateUrl: htmlUrl.isNotEmpty ? htmlUrl : ApiConstants.githubLatestReleaseUrl,
            isForce: false,
            enabled: true,
          );
        }
      }
    } catch (e) {
      debugPrint('GitHub API update check fallback: $e');
    }

    return null;
  }

  /// Automatically called on app launch or manually from ProfileScreen.
  static Future<void> checkForUpdate(
    BuildContext context, {
    bool showToastIfLatest = false,
    bool forcePrompt = false,
  }) async {
    // Avoid spamming user on every tab switch in the same session
    if (!forcePrompt && !showToastIfLatest && _hasPromptedThisSession) {
      return;
    }

    final updateInfo = await fetchUpdateInfo();

    if (!context.mounted) return;

    if (updateInfo != null) {
      final prefs = await SharedPreferences.getInstance();
      final lastDismissed = prefs.getString(_prefDismissedVersionKey) ?? '';

      // If user previously dismissed this exact version and it's not a forced update or manual check, skip
      if (!forcePrompt && !updateInfo.isForce && lastDismissed == updateInfo.latestVersion) {
        return;
      }

      _hasPromptedThisSession = true;

      await AppUpdateDialog.show(
        context,
        title: updateInfo.title,
        message: updateInfo.message,
        version: updateInfo.latestVersion,
        updateUrl: updateInfo.updateUrl,
        isForce: updateInfo.isForce,
      );

      // Save dismissal to avoid re-prompting on every app relaunch
      if (!updateInfo.isForce) {
        await prefs.setString(_prefDismissedVersionKey, updateInfo.latestVersion);
      }
    } else if (showToastIfLatest) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                'You are using the latest version (v$currentVersion) ✨',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
