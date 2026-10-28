import 'package:flutter/services.dart';

class QuizAudioService {
  static const MethodChannel _channel = MethodChannel('com.rkson.esbangla/audio');

  static Future<void> playCorrectSound() async {
    try {
      await _channel.invokeMethod('playCorrect');
    } catch (_) {}
  }

  static Future<void> playWrongSound() async {
    try {
      await _channel.invokeMethod('playWrong');
    } catch (_) {}
  }
}
