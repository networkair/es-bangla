package com.rkson.esbangla

import android.app.Activity
import android.content.Context
import android.content.pm.ActivityInfo
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import android.view.ViewGroup
import androidx.lifecycle.LifecycleOwner
import com.pierfrancescosoffritti.androidyoutubeplayer.core.player.PlayerConstants
import com.pierfrancescosoffritti.androidyoutubeplayer.core.player.YouTubePlayer
import com.pierfrancescosoffritti.androidyoutubeplayer.core.player.listeners.AbstractYouTubePlayerListener
import com.pierfrancescosoffritti.androidyoutubeplayer.core.player.listeners.FullscreenListener
import com.pierfrancescosoffritti.androidyoutubeplayer.core.player.views.YouTubePlayerView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class NativeYouTubePlatformView(
    context: Context,
    private val activity: Activity?,
    id: Int,
    creationParams: Map<String?, Any?>?,
    messenger: BinaryMessenger
) : PlatformView, MethodChannel.MethodCallHandler {

    companion object {
        var activeExitFullscreen: (() -> Unit)? = null
    }

    private val TAG = "NativeYouTube"
    private val mainHandler = Handler(Looper.getMainLooper())
    private val youTubePlayerView: YouTubePlayerView = YouTubePlayerView(context)
    private var youTubePlayer: YouTubePlayer? = null
    private val channel: MethodChannel = MethodChannel(messenger, "com.rkson.esbangla/youtube_player_$id")

    private var currentFullscreenView: View? = null
    private var currentExitFullscreen: (() -> Unit)? = null
    private var cleanVideoId: String = ""

    init {
        channel.setMethodCallHandler(this)

        val rawVideoId = creationParams?.get("videoId") as? String ?: ""
        cleanVideoId = extractCleanId(rawVideoId)
        val autoPlay = creationParams?.get("autoPlay") as? Boolean ?: true

        Log.d(TAG, "Initializing Native YouTube Player with ID: $cleanVideoId (raw: $rawVideoId)")

        // Register lifecycle observer
        (activity as? LifecycleOwner)?.lifecycle?.addObserver(youTubePlayerView)

        // Fullscreen listener
        youTubePlayerView.addFullscreenListener(object : FullscreenListener {
            override fun onEnterFullscreen(fullscreenView: View, exitFullscreen: () -> Unit) {
                val act = activity ?: return
                val decorView = act.window.decorView as? ViewGroup ?: return

                currentFullscreenView = fullscreenView
                currentExitFullscreen = exitFullscreen
                activeExitFullscreen = exitFullscreen

                decorView.addView(
                    fullscreenView,
                    ViewGroup.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.MATCH_PARENT
                    )
                )

                act.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
                mainHandler.post {
                    channel.invokeMethod("onEnterFullscreen", null)
                }
            }

            override fun onExitFullscreen() {
                val act = activity ?: return
                val decorView = act.window.decorView as? ViewGroup

                currentFullscreenView?.let {
                    decorView?.removeView(it)
                }
                currentFullscreenView = null
                currentExitFullscreen = null
                activeExitFullscreen = null

                act.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
                mainHandler.post {
                    channel.invokeMethod("onExitFullscreen", null)
                }
            }
        })

        // Standard canonical listener initialization without custom options conflict
        youTubePlayerView.addYouTubePlayerListener(object : AbstractYouTubePlayerListener() {
            override fun onReady(player: YouTubePlayer) {
                youTubePlayer = player
                Log.d(TAG, "YouTube Player is READY! Loading video: $cleanVideoId")
                if (cleanVideoId.isNotEmpty()) {
                    if (autoPlay) {
                        player.loadVideo(cleanVideoId, 0f)
                    } else {
                        player.cueVideo(cleanVideoId, 0f)
                    }
                }
                mainHandler.post {
                    channel.invokeMethod("onReady", null)
                }
            }

            override fun onStateChange(player: YouTubePlayer, state: PlayerConstants.PlayerState) {
                Log.d(TAG, "Player state change: ${state.name}")
                mainHandler.post {
                    channel.invokeMethod("onStateChange", state.name)
                }
            }

            override fun onError(player: YouTubePlayer, error: PlayerConstants.PlayerError) {
                Log.e(TAG, "Player error: ${error.name}")
                mainHandler.post {
                    channel.invokeMethod("onError", error.name)
                }
            }
        })
    }

    private fun extractCleanId(input: String): String {
        val trimmed = input.trim()
        if (trimmed.isEmpty()) return ""
        if (trimmed.matches(Regex("^[a-zA-Z0-9_-]{11}$"))) {
            return trimmed
        }
        val match = Regex("(?:youtu\\.be/|youtube\\.com/(?:embed/|v/|watch\\?v=|watch\\?.+&v=|shorts/|live/))([\\w-]{11})", RegexOption.IGNORE_CASE).find(trimmed)
        if (match != null && match.groupValues.size > 1) {
            return match.groupValues[1]
        }
        val vMatch = Regex("[?&]v=([a-zA-Z0-9_-]{11})").find(trimmed)
        if (vMatch != null && vMatch.groupValues.size > 1) {
            return vMatch.groupValues[1]
        }
        val any11 = Regex("([a-zA-Z0-9_-]{11})").find(trimmed)
        if (any11 != null && any11.groupValues.size > 1) {
            return any11.groupValues[1]
        }
        return trimmed
    }

    override fun getView(): View {
        return youTubePlayerView
    }

    override fun dispose() {
        channel.setMethodCallHandler(null)

        if (activeExitFullscreen == currentExitFullscreen) {
            activeExitFullscreen = null
        }
        currentExitFullscreen?.invoke()

        val decorView = activity?.window?.decorView as? ViewGroup
        currentFullscreenView?.let {
            decorView?.removeView(it)
        }
        currentFullscreenView = null
        currentExitFullscreen = null

        (activity as? LifecycleOwner)?.lifecycle?.removeObserver(youTubePlayerView)
        youTubePlayerView.release()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "play" -> {
                Log.d(TAG, "MethodChannel: play")
                youTubePlayer?.play()
                result.success(null)
            }
            "pause" -> {
                Log.d(TAG, "MethodChannel: pause")
                youTubePlayer?.pause()
                result.success(null)
            }
            "loadVideo" -> {
                val vid = call.argument<String>("videoId")?.let { extractCleanId(it) } ?: cleanVideoId
                Log.d(TAG, "MethodChannel: loadVideo $vid")
                cleanVideoId = vid
                youTubePlayer?.loadVideo(vid, 0f)
                result.success(null)
            }
            "cueVideo" -> {
                val vid = call.argument<String>("videoId")?.let { extractCleanId(it) } ?: cleanVideoId
                Log.d(TAG, "MethodChannel: cueVideo $vid")
                cleanVideoId = vid
                youTubePlayer?.cueVideo(vid, 0f)
                result.success(null)
            }
            "seekTo" -> {
                val seconds = (call.argument<Double>("seconds") ?: 0.0).toFloat()
                youTubePlayer?.seekTo(seconds)
                result.success(null)
            }
            "exitFullscreen" -> {
                currentExitFullscreen?.invoke()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}

class NativeYouTubePlayerFactory(
    private val activity: Activity?,
    private val messenger: BinaryMessenger
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as? Map<String?, Any?>
        return NativeYouTubePlatformView(context, activity, viewId, creationParams, messenger)
    }
}
