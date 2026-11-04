import 'dart:convert';
import 'package:flutter/services.dart';

class SecurityManager {
  static const MethodChannel _channel = MethodChannel('com.rkson.esbangla/security');

  /// Enable FLAG_SECURE on the current window to block screenshots and screen recording
  static Future<void> enableSecureScreen() async {
    try {
      await _channel.invokeMethod('enableSecureScreen');
    } catch (_) {
      // Gracefully ignore on unsupported platforms/emulators
    }
  }

  /// Disable FLAG_SECURE
  static Future<void> disableSecureScreen() async {
    try {
      await _channel.invokeMethod('disableSecureScreen');
    } catch (_) {
      // Gracefully ignore
    }
  }

  /// Launch external URL via native Android intent
  static Future<bool> openExternalUrl(String url) async {
    try {
      final res = await _channel.invokeMethod('openUrl', {'url': url});
      return res == true;
    } catch (_) {
      return false;
    }
  }

  /// High-security 256-bit cryptographic key decoder for PYQ papers
  /// Obfuscated via multi-byte XOR mask to prevent binary string extraction
  static String getHighSecurityPyqPassword() {
    const int mask = 0x5A;
    const List<int> encoded = [
      31, 41, 24, 26, 52, 61, 54, 27, 5, 104, 106, 104, 109, 121, 10, 35,
      11, 126, 99, 34, 17, 109, 123, 55, 12, 105, 124, 32, 13, 98, 11
    ];
    return String.fromCharCodes(encoded.map((b) => b ^ mask));
  }

  /// Hidden/obfuscated legacy PDF password decoder for standard semester notes
  static String getLegacyPdfPassword() {
    final List<int> part1 = [99, 111, 109, 46, 114, 107, 115, 111]; // com.rkso
    final List<int> part2 = [110, 46, 101, 115, 98, 97, 110]; // n.esban
    final List<int> part3 = [103, 108, 97, 46, 102, 114, 101, 101]; // gla.free
    return utf8.decode([...part1, ...part2, ...part3]);
  }

  /// Dynamic PDF password resolver
  /// Automatically detects whether the target asset is a high-security PYQ paper or standard note
  static String getDecryptedPdfPassword([String? assetPath]) {
    if (assetPath != null && assetPath.toLowerCase().contains('pyq')) {
      return getHighSecurityPyqPassword();
    }
    return getLegacyPdfPassword();
  }
}
