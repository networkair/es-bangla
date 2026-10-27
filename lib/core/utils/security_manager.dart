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

  /// Hidden/obfuscated PDF password decoder
  /// Avoids plain text in string tables or decompiled code
  static String getDecryptedPdfPassword() {
    // Obfuscated master password for all PDFs: com.rkson.esbangla.free
    final List<int> part1 = [99, 111, 109, 46, 114, 107, 115, 111]; // com.rkso
    final List<int> part2 = [110, 46, 101, 115, 98, 97, 110]; // n.esban
    final List<int> part3 = [103, 108, 97, 46, 102, 114, 101, 101]; // gla.free
    return utf8.decode([...part1, ...part2, ...part3]);
  }
}
