package com.rkson.esbangla

import android.content.pm.ActivityInfo
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ScrollView
import android.graphics.Color
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.pierfrancescosoffritti.androidyoutubeplayer.core.player.PlayerConstants
import com.pierfrancescosoffritti.androidyoutubeplayer.core.player.YouTubePlayer
import com.pierfrancescosoffritti.androidyoutubeplayer.core.player.listeners.AbstractYouTubePlayerListener
import com.pierfrancescosoffritti.androidyoutubeplayer.core.player.listeners.FullscreenListener
import com.pierfrancescosoffritti.androidyoutubeplayer.core.player.views.YouTubePlayerView

class NativeVideoPlayerActivity : AppCompatActivity() {

    private val TAG = "NativeVideoPlayer"
    private lateinit var youtubePlayerView: YouTubePlayerView
    private lateinit var normalLayout: LinearLayout
    private lateinit var fullscreenContainer: FrameLayout
    private lateinit var headerLayout: LinearLayout
    private lateinit var contentScrollView: ScrollView

    private var currentFullscreenView: View? = null
    private var currentExitFullscreen: (() -> Unit)? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Note: FLAG_SECURE is omitted so Chromium WebView hardware video acceleration can render YouTube frames cleanly without blackouts
        setContentView(R.layout.activity_native_video_player)

        val title = intent.getStringExtra("title") ?: "Es Bangla Video Lecture"
        val rawVideoId = intent.getStringExtra("videoId") ?: ""
        val cleanVideoId = extractCleanId(rawVideoId)

        Log.d(TAG, "Starting Native Video Player for videoId: $cleanVideoId (title: $title)")

        // Bind layout views
        normalLayout = findViewById(R.id.normalLayout)
        fullscreenContainer = findViewById(R.id.fullscreenContainer)
        headerLayout = findViewById(R.id.headerLayout)
        contentScrollView = findViewById(R.id.contentScrollView)
        youtubePlayerView = findViewById(R.id.youtubePlayerView)

        val tvHeaderTitle: TextView = findViewById(R.id.tvHeaderTitle)
        val tvVideoTitle: TextView = findViewById(R.id.tvVideoTitle)
        val tvPlayerStatus: TextView = findViewById(R.id.tvPlayerStatus)
        val btnBack: View = findViewById(R.id.btnBack)

        tvHeaderTitle.text = title
        tvVideoTitle.text = title

        if (cleanVideoId.isEmpty()) {
            tvPlayerStatus.text = "⚠️ কোনো ভিডিও লিঙ্ক যুক্ত করা হয়নি"
            tvPlayerStatus.setTextColor(Color.parseColor("#F87171"))
        } else {
            tvPlayerStatus.text = "⏳ ভিডিও প্রস্তুত হচ্ছে... (ID: $cleanVideoId)"
            tvPlayerStatus.setTextColor(Color.parseColor("#93C5FD"))
        }

        btnBack.setOnClickListener {
            finish()
        }

        // Register lifecycle observer
        lifecycle.addObserver(youtubePlayerView)

        // Configure Fullscreen listener
        youtubePlayerView.addFullscreenListener(object : FullscreenListener {
            override fun onEnterFullscreen(fullscreenView: View, exitFullscreen: () -> Unit) {
                Log.d(TAG, "onEnterFullscreen")
                currentFullscreenView = fullscreenView
                currentExitFullscreen = exitFullscreen

                normalLayout.visibility = View.GONE
                fullscreenContainer.visibility = View.VISIBLE
                fullscreenContainer.removeAllViews()
                fullscreenContainer.addView(
                    fullscreenView,
                    ViewGroup.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.MATCH_PARENT
                    )
                )

                requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
                hideSystemUI()
            }

            override fun onExitFullscreen() {
                Log.d(TAG, "onExitFullscreen")
                fullscreenContainer.removeAllViews()
                fullscreenContainer.visibility = View.GONE
                normalLayout.visibility = View.VISIBLE

                currentFullscreenView = null
                currentExitFullscreen = null

                requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
                showSystemUI()
            }
        })

        // Standard canonical YouTube player listener with cueVideo & status updates
        youtubePlayerView.addYouTubePlayerListener(object : AbstractYouTubePlayerListener() {
            override fun onReady(player: YouTubePlayer) {
                Log.d(TAG, "Native YouTube player onReady! Cueing video: $cleanVideoId")
                if (cleanVideoId.isNotEmpty()) {
                    // Cue video so YouTube thumbnail and red play button show up immediately
                    player.cueVideo(cleanVideoId, 0f)
                    tvPlayerStatus.text = "▶️ ভিডিও প্রস্তুত! প্লে করতে ভিডিওতে ট্যাপ করুন"
                    tvPlayerStatus.setTextColor(Color.parseColor("#4ADE80"))
                }
            }

            override fun onError(player: YouTubePlayer, error: PlayerConstants.PlayerError) {
                Log.e(TAG, "Native YouTube player error: $error")
                when (error) {
                    PlayerConstants.PlayerError.VIDEO_NOT_PLAYABLE_IN_EMBEDDED_PLAYER -> {
                        tvPlayerStatus.text = "⚠️ এই ভিডিওটিতে চ্যানেল মালিক Embedding বন্ধ রেখেছেন (Error 150)। নিজের আনলিস্টেড ভিডিওতে 'Allow embedding' চালু রাখলে তা চলবে।"
                    }
                    PlayerConstants.PlayerError.VIDEO_NOT_FOUND -> {
                        tvPlayerStatus.text = "⚠️ ভিডিওটি ইউটিউবে খুঁজে পাওয়া যায়নি (Invalid ID)"
                    }
                    else -> {
                        tvPlayerStatus.text = "⚠️ ভিডিও লোড হতে সমস্যা: $error"
                    }
                }
                tvPlayerStatus.setTextColor(Color.parseColor("#F87171"))
            }

            override fun onStateChange(player: YouTubePlayer, state: PlayerConstants.PlayerState) {
                Log.d(TAG, "Native YouTube player state: $state")
                when (state) {
                    PlayerConstants.PlayerState.PLAYING -> {
                        tvPlayerStatus.text = "🟢 ভিডিও চলছে"
                        tvPlayerStatus.setTextColor(Color.parseColor("#4ADE80"))
                    }
                    PlayerConstants.PlayerState.PAUSED -> {
                        tvPlayerStatus.text = "⏸️ ভিডিও সাময়িকভাবে বন্ধ আছে"
                        tvPlayerStatus.setTextColor(Color.parseColor("#FCD34D"))
                    }
                    PlayerConstants.PlayerState.BUFFERING -> {
                        tvPlayerStatus.text = "⏳ লোডিং হচ্ছে..."
                        tvPlayerStatus.setTextColor(Color.parseColor("#93C5FD"))
                    }
                    PlayerConstants.PlayerState.VIDEO_CUED -> {
                        tvPlayerStatus.text = "▶️ ভিডিও প্রস্তুত! প্লে করতে ভিডিওতে ট্যাপ করুন"
                        tvPlayerStatus.setTextColor(Color.parseColor("#4ADE80"))
                    }
                    PlayerConstants.PlayerState.ENDED -> {
                        tvPlayerStatus.text = "✅ ভিডিও সমাপ্ত হয়েছে"
                        tvPlayerStatus.setTextColor(Color.parseColor("#94A3B8"))
                    }
                    else -> {}
                }
            }
        })
    }

    private fun hideSystemUI() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.insetsController?.let {
                it.hide(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())
                it.systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_FULLSCREEN
                or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
            )
        }
    }

    private fun showSystemUI() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.insetsController?.show(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_VISIBLE
        }
    }

    @Suppress("DEPRECATION")
    override fun onBackPressed() {
        if (currentExitFullscreen != null) {
            currentExitFullscreen?.invoke()
            currentExitFullscreen = null
            return
        }
        super.onBackPressed()
    }

    private fun extractCleanId(input: String): String {
        val trimmed = input.trim()
        if (trimmed.isEmpty()) return ""
        if (trimmed.matches(Regex("^[a-zA-Z0-9_-]{11}$"))) {
            return trimmed
        }
        val match = Regex(
            "(?:youtu\\.be/|youtube\\.com/(?:embed/|v/|watch\\?v=|watch\\?.+&v=|shorts/|live/))([\\w-]{11})",
            RegexOption.IGNORE_CASE
        ).find(trimmed)
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
}
