package com.rkson.esbangla

import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val SECURE_CHANNEL = "com.rkson.esbangla/security"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        applyCutoutAndFullscreen()
        NotificationAlarmReceiver.scheduleAlarm(this)
    }

    override fun onResume() {
        super.onResume()
        NotificationAlarmReceiver.scheduleAlarm(this)
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            applyCutoutAndFullscreen()
            NotificationAlarmReceiver.scheduleAlarm(this)
        }
    }

    private fun applyCutoutAndFullscreen() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val params = window.attributes
            params.layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
            window.attributes = params
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
        window.statusBarColor = Color.WHITE
        window.navigationBarColor = Color.WHITE
        window.decorView.setBackgroundColor(Color.WHITE)

        @Suppress("DEPRECATION")
        window.decorView.systemUiVisibility = (
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
            or View.SYSTEM_UI_FLAG_FULLSCREEN
            or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
            or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            or View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register Native YouTube PlatformView Factory
        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory(
                "com.rkson.esbangla/youtube_player",
                NativeYouTubePlayerFactory(this, flutterEngine.dartExecutor.binaryMessenger)
            )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableSecureScreen" -> {
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(true)
                }
                "disableSecureScreen" -> {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(true)
                }
                "openUrl" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        try {
                            val intent = android.content.Intent(android.content.Intent.ACTION_VIEW, android.net.Uri.parse(url))
                            intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("INTENT_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_URL", "URL cannot be null", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        val VIDEO_CHANNEL = "com.rkson.esbangla/video"
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VIDEO_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "playVideo" -> {
                    val videoId = call.argument<String>("videoId") ?: ""
                    val title = call.argument<String>("title") ?: ""
                    try {
                        val intent = android.content.Intent(this, NativeVideoPlayerActivity::class.java).apply {
                            putExtra("videoId", videoId)
                            putExtra("title", title)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ACTIVITY_ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        val AUDIO_CHANNEL = "com.rkson.esbangla/audio"
        val audioAttributes = android.media.AudioAttributes.Builder()
            .setUsage(android.media.AudioAttributes.USAGE_GAME)
            .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val soundPool = android.media.SoundPool.Builder()
            .setMaxStreams(4)
            .setAudioAttributes(audioAttributes)
            .build()
        val correctSoundId = soundPool.load(this, R.raw.quiz_correct, 1)
        val wrongSoundId = soundPool.load(this, R.raw.quiz_wrong, 1)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "playCorrect" -> {
                    try {
                        soundPool.play(correctSoundId, 1f, 1f, 1, 0, 1f)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("AUDIO_ERROR", e.message, null)
                    }
                }
                "playWrong" -> {
                    try {
                        soundPool.play(wrongSoundId, 1f, 1f, 1, 0, 1f)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("AUDIO_ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    @Suppress("DEPRECATION")
    override fun onBackPressed() {
        if (NativeYouTubePlatformView.activeExitFullscreen != null) {
            NativeYouTubePlatformView.activeExitFullscreen?.invoke()
            NativeYouTubePlatformView.activeExitFullscreen = null
            return
        }
        super.onBackPressed()
    }
}
