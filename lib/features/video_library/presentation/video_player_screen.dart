import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/security_manager.dart';
import '../data/youtube_helper.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String title;
  final String youtubeVideoId;

  const VideoPlayerScreen({
    super.key,
    required this.title,
    required this.youtubeVideoId,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final String _cleanVideoId;
  MethodChannel? _channel;
  bool _isPlaying = false;
  String _playerState = 'INITIALIZING';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Enable secure window to prevent screen recording and screenshotting
    SecurityManager.enableSecureScreen();
    _cleanVideoId = YoutubeHelper.extractVideoId(widget.youtubeVideoId);
  }

  @override
  void dispose() {
    SecurityManager.disableSecureScreen();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onPlatformViewCreated(int id) {
    _channel = MethodChannel('com.rkson.esbangla/youtube_player_$id');
    _channel!.setMethodCallHandler(_handleNativeCall);
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onReady':
        if (mounted) {
          setState(() {
            _playerState = 'READY';
            _errorMessage = '';
          });
        }
        break;
      case 'onStateChange':
        final state = call.arguments as String? ?? '';
        if (mounted) {
          setState(() {
            _playerState = state;
            _isPlaying = (state == 'PLAYING');
          });
        }
        break;
      case 'onError':
        final error = call.arguments as String? ?? '';
        debugPrint('YouTube Player Error: $error');
        if (mounted) {
          setState(() {
            _errorMessage = 'প্লেয়ার সতর্কতা: $error';
          });
        }
        break;
      case 'onEnterFullscreen':
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        break;
      case 'onExitFullscreen':
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        break;
    }
  }

  void _triggerPlay() {
    _channel?.invokeMethod('play');
    setState(() => _isPlaying = true);
  }

  void _triggerPause() {
    _channel?.invokeMethod('pause');
    setState(() => _isPlaying = false);
  }

  void _triggerReload() {
    _channel?.invokeMethod('loadVideo', {'videoId': _cleanVideoId});
    setState(() {
      _errorMessage = '';
      _isPlaying = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined, size: 14, color: AppColors.primaryDark),
                          SizedBox(width: 4),
                          Text(
                            'Secure',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 16:9 AspectRatio Native Player
              // NOTE: Direct rendering without any blocking Flutter overlay
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.black,
                  child: AndroidView(
                    viewType: 'com.rkson.esbangla/youtube_player',
                    layoutDirection: TextDirection.ltr,
                    creationParams: <String, dynamic>{
                      'videoId': _cleanVideoId,
                      'autoPlay': true,
                    },
                    creationParamsCodec: const StandardMessageCodec(),
                    onPlatformViewCreated: _onPlatformViewCreated,
                    gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{
                      Factory<OneSequenceGestureRecognizer>(
                        EagerGestureRecognizer.new,
                      ),
                    },
                  ),
                ),
              ),

              // Details & Quick Controls section below player
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Video Title
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Badges
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Es Bangla Video Lecture',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.lock_rounded, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          const Text(
                            'সুরক্ষিত শিক্ষা প্লেয়ার',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Quick Action Bar for Instant Play / Pause / Reload
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Play / Pause Toggle Button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isPlaying ? _triggerPause : _triggerPlay,
                                icon: Icon(
                                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  size: 20,
                                ),
                                label: Text(
                                  _isPlaying ? 'পজ করুন' : 'প্লে করুন',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isPlaying ? Colors.orange.shade700 : AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Reload Button
                            OutlinedButton.icon(
                              onPressed: _triggerReload,
                              icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textPrimary),
                              label: const Text(
                                'রিলোড',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                side: const BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.red.shade700, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage,
                                  style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      // User Tips Box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.primary),
                                SizedBox(width: 6),
                                Text(
                                  'ব্যবহারবিধি ও সুবিধা',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              '• ভিডিও দেখতে সরাসরি উপরের প্লেয়ারে ট্যাপ করুন অথবা "প্লে করুন" বাটনে চাপ দিন।\n'
                              '• পুরো স্ক্রিন জুড়ে বড় করে দেখতে প্লেয়ারের নিচের ডানদিকের ফুলস্ক্রিন আইকনে ট্যাপ করুন।\n'
                              '• ফুলস্ক্রিন থেকে ফিরে আসতে ফোনের সাধারণ ব্যাক বাটন চাপুন।',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
