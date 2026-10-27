import 'package:flutter/services.dart';
import '../data/youtube_helper.dart';

class NativeVideoHelper {
  static const MethodChannel _channel = MethodChannel('com.rkson.esbangla/video');

  /// Directly launches the 100% Native Android Video Player Activity.
  /// Bypasses Flutter platform view rendering issues, Impeller GPU bugs,
  /// and FLAG_SECURE black screens.
  static Future<void> playVideo({
    required String title,
    required String videoId,
  }) async {
    final cleanId = YoutubeHelper.extractVideoId(videoId);
    if (cleanId.isEmpty) return;

    try {
      await _channel.invokeMethod('playVideo', {
        'title': title,
        'videoId': cleanId,
      });
    } on PlatformException catch (e) {
      // Ignored or logged
    }
  }
}
