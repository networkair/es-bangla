package com.rkson.esbangla

import android.app.Activity
import android.content.Context
import android.content.pm.ActivityInfo
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.ViewGroup
import androidx.lifecycle.LifecycleOwner
import com.pierfrancescosoffritti.androidyoutubeplayer.core.player.PlayerConstants
import com.pierfrancescosoffritti.androidyoutubeplayer.core.player.YouTubePlayer
import com.pierfrancescosoffritti.androidyoutubeplayer.core.player.listeners.AbstractYouTubePlayerListener
import com.pierfrancescosoffritti.androidyoutubeplayer.core.player.listeners.FullscreenListener
import com.pierfrancescosoffritti.androidyoutubeplayer.core.player.options.IFramePlayerOptions
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

    private val mainHandler = Handler(Looper.getMainLooper())
    private val youTubePlayerView: YouTubePlayerView = YouTubePlayerView(context)
    private var youTubePlayer: YouTubePlayer? = null
    private val channel: MethodChannel = MethodChannel(messenger, "com.rkson.esbangla/youtube_player_$id")

    private var currentFullscreenView: View? = null
    private var currentExitFullscreen: (() -> Unit)? = null

    init {
        channel.setMethodCallHandler(this)

        val videoId = creationParams?.get("videoId") as? String ?: ""
        val autoPlay = creationParams?.get("autoPlay") as? Boolean ?: true

        // Register lifecycle observer if activity is LifecycleOwner
        (activity as? LifecycleOwner)?.lifecycle?.addObserver(youTubePlayerView)

        // Disable automatic initialization to configure options
        youTubePlayerView.enableAutomaticInitialization = false

        val options = IFramePlayerOptions.Builder()
            .controls(1)
            .fullscreen(1)
            .rel(0)
            .ivLoadPolicy(3)
            .ccLoadPolicy(0)
            .build()

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

        youTubePlayerView.initialize(object : AbstractYouTubePlayerListener() {
            override fun onReady(player: YouTubePlayer) {
                youTubePlayer = player
                if (videoId.isNotEmpty()) {
                    if (autoPlay) {
                        player.loadVideo(videoId, 0f)
                    } else {
                        player.cueVideo(videoId, 0f)
                    }
                }
                mainHandler.post {
                    channel.invokeMethod("onReady", null)
                }
            }

            override fun onStateChange(player: YouTubePlayer, state: PlayerConstants.PlayerState) {
                mainHandler.post {
                    channel.invokeMethod("onStateChange", state.name)
                }
            }

            override fun onError(player: YouTubePlayer, error: PlayerConstants.PlayerError) {
                mainHandler.post {
                    channel.invokeMethod("onError", error.name)
                }
            }
        }, options)
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
            "loadVideo" -> {
                val vid = call.argument<String>("videoId") ?: ""
                youTubePlayer?.loadVideo(vid, 0f)
                result.success(null)
            }
            "cueVideo" -> {
                val vid = call.argument<String>("videoId") ?: ""
                youTubePlayer?.cueVideo(vid, 0f)
                result.success(null)
            }
            "play" -> {
                youTubePlayer?.play()
                result.success(null)
            }
            "pause" -> {
                youTubePlayer?.pause()
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
