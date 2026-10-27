package com.rkson.esbangla

import android.annotation.SuppressLint
import android.content.pm.ActivityInfo
import android.graphics.Bitmap
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.ScrollView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

class NativeVideoPlayerActivity : AppCompatActivity() {

    private val TAG = "NativeVideoPlayer"
    private lateinit var videoWebView: WebView
    private lateinit var playerLoading: ProgressBar
    private lateinit var normalLayout: LinearLayout
    private lateinit var fullscreenContainer: FrameLayout
    private lateinit var headerLayout: LinearLayout
    private lateinit var contentScrollView: ScrollView
    private lateinit var tvPlayerStatus: TextView

    private var customView: View? = null
    private var customViewCallback: WebChromeClient.CustomViewCallback? = null

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_native_video_player)

        val title = intent.getStringExtra("title") ?: "Es Bangla Video Lecture"
        val rawVideoId = intent.getStringExtra("videoId") ?: ""
        val cleanVideoId = extractCleanId(rawVideoId)

        Log.d(TAG, "Starting Direct Native Video Player for videoId: $cleanVideoId (title: $title)")

        // Bind layout views
        normalLayout = findViewById(R.id.normalLayout)
        fullscreenContainer = findViewById(R.id.fullscreenContainer)
        headerLayout = findViewById(R.id.headerLayout)
        contentScrollView = findViewById(R.id.contentScrollView)
        videoWebView = findViewById(R.id.videoWebView)
        playerLoading = findViewById(R.id.playerLoading)

        val tvHeaderTitle: TextView = findViewById(R.id.tvHeaderTitle)
        val tvVideoTitle: TextView = findViewById(R.id.tvVideoTitle)
        tvPlayerStatus = findViewById(R.id.tvPlayerStatus)
        val btnBack: View = findViewById(R.id.btnBack)

        tvHeaderTitle.text = title
        tvVideoTitle.text = title

        btnBack.setOnClickListener {
            finish()
        }

        if (cleanVideoId.isEmpty()) {
            playerLoading.visibility = View.GONE
            tvPlayerStatus.text = "⚠️ কোনো ভিডিও লিঙ্ক যুক্ত করা হয়নি"
            tvPlayerStatus.setTextColor(Color.parseColor("#F87171"))
            return
        }

        tvPlayerStatus.text = "⏳ ভিডিও লোড হচ্ছে..."
        tvPlayerStatus.setTextColor(Color.parseColor("#93C5FD"))

        setupWebView(cleanVideoId)
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun setupWebView(videoId: String) {
        // Hardware acceleration for ultra-smooth video playback
        videoWebView.setLayerType(View.LAYER_TYPE_HARDWARE, null)
        videoWebView.setBackgroundColor(Color.BLACK)

        val settings = videoWebView.settings
        settings.javaScriptEnabled = true
        settings.domStorageEnabled = true
        settings.databaseEnabled = true
        settings.mediaPlaybackRequiresUserGesture = false
        settings.cacheMode = WebSettings.LOAD_DEFAULT
        settings.allowFileAccess = true
        settings.allowContentAccess = true
        settings.loadWithOverviewMode = true
        settings.useWideViewPort = true
        settings.userAgentString = "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"

        videoWebView.webChromeClient = object : WebChromeClient() {
            override fun onShowCustomView(view: View?, callback: CustomViewCallback?) {
                if (customView != null) {
                    callback?.onCustomViewHidden()
                    return
                }
                customView = view
                customViewCallback = callback

                normalLayout.visibility = View.GONE
                fullscreenContainer.visibility = View.VISIBLE
                fullscreenContainer.removeAllViews()
                fullscreenContainer.addView(
                    view,
                    ViewGroup.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.MATCH_PARENT
                    )
                )

                requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
                hideSystemUI()
            }

            override fun onHideCustomView() {
                if (customView == null) return

                fullscreenContainer.removeAllViews()
                fullscreenContainer.visibility = View.GONE
                normalLayout.visibility = View.VISIBLE

                customView = null
                customViewCallback?.onCustomViewHidden()
                customViewCallback = null

                requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
                showSystemUI()
            }

            override fun onProgressChanged(view: WebView?, newProgress: Int) {
                if (newProgress > 70) {
                    playerLoading.visibility = View.GONE
                }
            }
        }

        videoWebView.webViewClient = object : WebViewClient() {
            override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) {
                super.onPageStarted(view, url, favicon)
                playerLoading.visibility = View.VISIBLE
            }

            override fun onPageFinished(view: WebView?, url: String?) {
                super.onPageFinished(view, url)
                playerLoading.visibility = View.GONE
                tvPlayerStatus.text = "🟢 ভিডিও প্রস্তুত ও লোড হয়েছে"
                tvPlayerStatus.setTextColor(Color.parseColor("#4ADE80"))
            }

            override fun onReceivedError(view: WebView?, request: WebResourceRequest?, error: WebResourceError?) {
                super.onReceivedError(view, request, error)
                if (request?.isForMainFrame == true) {
                    playerLoading.visibility = View.GONE
                    tvPlayerStatus.text = "⚠️ ভিডিও লোড হতে ব্যর্থ হয়েছে। ইন্টারনেট সংযোগ পরীক্ষা করুন।"
                    tvPlayerStatus.setTextColor(Color.parseColor("#F87171"))
                }
            }
        }

        // Standard, high-performance HTML5 YouTube embed wrapper
        val htmlData = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
                <style>
                    * { margin: 0; padding: 0; box-sizing: border-box; }
                    html, body {
                        width: 100%;
                        height: 100%;
                        background-color: #000000;
                        overflow: hidden;
                    }
                    .video-wrapper {
                        position: relative;
                        width: 100%;
                        height: 100%;
                    }
                    iframe {
                        position: absolute;
                        top: 0;
                        left: 0;
                        width: 100%;
                        height: 100%;
                        border: 0;
                    }
                </style>
            </head>
            <body>
                <div class="video-wrapper">
                    <iframe
                        src="https://www.youtube-nocookie.com/embed/$videoId?autoplay=1&playsinline=1&enablejsapi=1&rel=0&modestbranding=1&fs=1"
                        title="YouTube Video Player"
                        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share; fullscreen"
                        allowfullscreen>
                    </iframe>
                </div>
            </body>
            </html>
        """.trimIndent()

        videoWebView.loadDataWithBaseURL("https://www.youtube-nocookie.com", htmlData, "text/html", "UTF-8", null)
    }

    override fun onPause() {
        super.onPause()
        videoWebView.onPause()
    }

    override fun onResume() {
        super.onResume()
        videoWebView.onResume()
    }

    override fun onDestroy() {
        if (customView != null) {
            customViewCallback?.onCustomViewHidden()
        }
        videoWebView.stopLoading()
        videoWebView.loadUrl("about:blank")
        videoWebView.destroy()
        super.onDestroy()
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
        if (customView != null) {
            // Exit fullscreen if currently in fullscreen view
            if (customViewCallback != null) {
                videoWebView.webChromeClient?.onHideCustomView()
            } else {
                fullscreenContainer.removeAllViews()
                fullscreenContainer.visibility = View.GONE
                normalLayout.visibility = View.VISIBLE
                customView = null
                requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
                showSystemUI()
            }
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
