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

  /// Hidden/obfuscated PDF password decoder
  /// Avoids plain text in string tables or decompiled code
  static String getDecryptedPdfPassword() {
    // Encoded parts assembled at runtime
    final List<int> part1 = [69, 115, 66];
    final List<int> part2 = [97, 110, 103];
    final List<int> part3 = [108, 97, 50, 48, 50, 54];
    return utf8.decode([...part1, ...part2, ...part3]);
  }
}
