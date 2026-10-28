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
import android.webkit.WebResourceResponse
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.ScrollView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import java.io.ByteArrayInputStream
import java.net.HttpURLConnection
import java.net.URL

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

        // Disable long click and context menu (blocks "Copy embed code", "Copy video link")
        videoWebView.isLongClickable = false
        videoWebView.isHapticFeedbackEnabled = false
        videoWebView.setOnLongClickListener { true }

        // Native touch guard overlay to absorb touches on channel link at top-left
        findViewById<View>(R.id.overlayChannelGuard)?.setOnClickListener { /* Consume touch */ }

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
                if (newProgress > 60) {
                    playerLoading.visibility = View.GONE
                    injectPlayerModifications(view)
                }
            }
        }

        videoWebView.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                val url = request?.url?.toString() ?: ""
                Log.d(TAG, "Navigation requested: $url")
                // Allow the player embed itself to load
                if (url.startsWith("https://www.youtube-nocookie.com/embed/") ||
                    url.startsWith("https://www.youtube.com/embed/") ||
                    url.startsWith("about:blank")) {
                    return false
                }
                // BLOCK ALL external links (Channel page, Share link, YouTube app, etc.)
                Log.d(TAG, "Blocked external link navigation: $url")
                return true
            }

            override fun shouldInterceptRequest(view: WebView?, request: WebResourceRequest?): WebResourceResponse? {
                val url = request?.url?.toString() ?: return null

                // 1. Intercept player stylesheet (www-player.css or player_embed*.css)
                if (url.contains("www-player.css") || (url.contains("player") && url.endsWith(".css"))) {
                    try {
                        val connection = URL(url).openConnection() as HttpURLConnection
                        connection.requestMethod = "GET"
                        request.requestHeaders?.forEach { (k, v) ->
                            connection.setRequestProperty(k, v)
                        }
                        if (connection.getRequestProperty("User-Agent") == null) {
                            connection.setRequestProperty("User-Agent", view?.settings?.userAgentString ?: "Mozilla/5.0")
                        }
                        connection.connectTimeout = 8000
                        connection.readTimeout = 8000

                        val originalCss = connection.inputStream.bufferedReader().use { it.readText() }
                        val modifiedCss = originalCss + "\n\n/* Antigravity Cleaner */\n" + CUSTOM_CLEANER_CSS

                        return WebResourceResponse(
                            "text/css",
                            "UTF-8",
                            ByteArrayInputStream(modifiedCss.toByteArray(Charsets.UTF_8))
                        )
                    } catch (e: Exception) {
                        Log.e(TAG, "CSS Interception failed: ${e.message}")
                    }
                }

                // 2. Intercept embed HTML to inject cleaner style tag & script directly into the document
                if (url.startsWith("https://www.youtube-nocookie.com/embed/") || url.startsWith("https://www.youtube.com/embed/")) {
                    try {
                        val connection = URL(url).openConnection() as HttpURLConnection
                        connection.requestMethod = "GET"
                        request.requestHeaders?.forEach { (k, v) ->
                            connection.setRequestProperty(k, v)
                        }
                        if (connection.getRequestProperty("User-Agent") == null) {
                            connection.setRequestProperty("User-Agent", view?.settings?.userAgentString ?: "Mozilla/5.0")
                        }
                        if (connection.getRequestProperty("Referer") == null) {
                            connection.setRequestProperty("Referer", "https://www.youtube-nocookie.com")
                        }
                        connection.connectTimeout = 8000
                        connection.readTimeout = 8000

                        var originalHtml = connection.inputStream.bufferedReader().use { it.readText() }

                        val injectHead = """
                            <style id="esy-native-interceptor-style">
                                $CUSTOM_CLEANER_CSS
                            </style>
                        """.trimIndent()

                        val injectBody = """
                            <script id="esy-native-interceptor-script">
                                $CUSTOM_CLEANER_SCRIPT
                            </script>
                        """.trimIndent()

                        if (originalHtml.contains("</head>")) {
                            originalHtml = originalHtml.replace("</head>", "$injectHead\n</head>")
                        } else {
                            originalHtml = "$injectHead\n$originalHtml"
                        }

                        if (originalHtml.contains("</body>")) {
                            originalHtml = originalHtml.replace("</body>", "$injectBody\n</body>")
                        } else {
                            originalHtml = "$originalHtml\n$injectBody"
                        }

                        return WebResourceResponse(
                            "text/html",
                            "UTF-8",
                            ByteArrayInputStream(originalHtml.toByteArray(Charsets.UTF_8))
                        )
                    } catch (e: Exception) {
                        Log.e(TAG, "HTML Interception failed: ${e.message}")
                    }
                }

                return super.shouldInterceptRequest(view, request)
            }

            override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) {
                super.onPageStarted(view, url, favicon)
                playerLoading.visibility = View.VISIBLE
            }

            override fun onPageFinished(view: WebView?, url: String?) {
                super.onPageFinished(view, url)
                playerLoading.visibility = View.GONE
                tvPlayerStatus.text = "🟢 সুরক্ষিত শিক্ষা ভিডিও চলছে"
                tvPlayerStatus.setTextColor(Color.parseColor("#4ADE80"))

                injectPlayerModifications(view)
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

        // Direct loadUrl of YouTube embed with Referer header - eliminates iframe barrier
        val embedUrl = "https://www.youtube-nocookie.com/embed/$videoId?autoplay=1&playsinline=1&enablejsapi=1&rel=0&modestbranding=1&fs=1"
        val extraHeaders = HashMap<String, String>()
        extraHeaders["Referer"] = "https://www.youtube-nocookie.com"
        videoWebView.loadUrl(embedUrl, extraHeaders)
    }

    private fun injectPlayerModifications(view: WebView?) {
        val js = """
            (function() {
                try {
                    var cssId = 'esy-player-clean-style';
                    if (!document.getElementById(cssId)) {
                        var head = document.head || document.getElementsByTagName('head')[0] || document.documentElement;
                        var style = document.createElement('style');
                        style.id = cssId;
                        style.type = 'text/css';
                        style.appendChild(document.createTextNode(`$CUSTOM_CLEANER_CSS`));
                        head.appendChild(style);
                    }
                    $CUSTOM_CLEANER_SCRIPT
                } catch(e) {}
            })();
        """.trimIndent()
        view?.evaluateJavascript(js, null)
    }

    companion object {
        private const val CUSTOM_CLEANER_CSS = """
            /* 1. Hide Copy Link button at bottom-left completely */
            .ytp-overlay-bottom-left,
            .ytp-copylink-button,
            .ytp-copylink-button-visible,
            .ytp-copylink-icon,
            .ytp-copylink-title,
            .ytp-show-copylink-title,
            .ytp-share-button,
            .ytp-show-share-title,

            /* 2. Hide "More videos" / related videos shelf & thumbnails at bottom-center */
            .ytp-pause-overlay,
            .ytp-pause-overlay-container,
            .ytp-pause-overlay-backdrop,
            .ytp-pause-overlay-controls-hidden,
            .ytp-expand-pause-overlay,
            .ytp-more-videos-view,
            .ytp-more-videos-view-container,
            .ytp-more-videos-button,
            .ytp-more-videos-button-thumbnail,
            .ytp-more-videos-button-title,
            .ytp-suggestions,
            .ytp-suggestion-link,
            .ytp-suggestion-image,
            .ytp-suggestion-title,
            .ytp-suggestion-author,
            .ytp-suggestion-overlay,
            .ytp-autonav-endscreen-more-videos,
            .ytp-watch-again-on-youtube-endscreen-more-videos-container,

            /* 3. Hide YouTube logo and watermark at bottom-right */
            .ytp-impression-link,
            .ytp-impression-link-content,
            .ytp-impression-link-logo,
            .ytp-impression-link-text,
            .ytp-music-impression-link,
            .ytp-watermark,
            .ytp-watermark-small,
            .ytp-youtube-button,

            /* 4. Hide "More options" popup panel & share panels completely */
            .ytp-overflow-panel,
            .ytp-overflow-panel-action-buttons,
            .ytp-overflow-panel-close,
            .ytp-overflow-panel-content,
            .ytp-share-panel,
            .ytp-share-panel-close,
            .ytp-share-panel-inner-content,
            .ytp-share-panel-service-button,
            .ytp-share-panel-service-buttons,
            .ytp-contextmenu,
            .ytp-cards-button,
            .ytp-overflow-button,

            /* 5. In main settings drawer, hide the last item ("... More options") */
            .ytp-settings-menu .ytp-panel-menu > .ytp-menuitem:last-child {
                display: none !important;
                visibility: hidden !important;
                opacity: 0 !important;
                pointer-events: none !important;
                width: 0 !important;
                height: 0 !important;
                min-height: 0 !important;
                max-height: 0 !important;
                margin: 0 !important;
                padding: 0 !important;
                overflow: hidden !important;
            }

            /* 6. Ensure channel name & avatar at top-left stay visible */
            .ytp-chrome-top,
            .ytp-title,
            .ytp-title-link,
            .ytp-title-channel,
            .ytp-title-expanded-title,
            .ytp-overlay-top-left {
                display: flex !important;
                visibility: visible !important;
                opacity: 1 !important;
            }

            /* 7. Ensure fullscreen button at bottom-right stays visible */
            .ytp-fullscreen-button {
                display: inline-block !important;
                visibility: visible !important;
                opacity: 1 !important;
                pointer-events: auto !important;
            }
        """

        private const val CUSTOM_CLEANER_SCRIPT = """
            (function() {
                function cleanMenu() {
                    try {
                        var items = document.querySelectorAll('.ytp-menuitem');
                        for (var i = 0; i < items.length; i++) {
                            var it = items[i];
                            var txt = (it.innerText || it.textContent || '').trim().toLowerCase();
                            if (txt.indexOf('more') !== -1 || txt.indexOf('বিকল্প') !== -1 || txt.indexOf('share') !== -1 || txt.indexOf('copy') !== -1) {
                                it.style.setProperty('display', 'none', 'important');
                                it.style.setProperty('visibility', 'hidden', 'important');
                                it.style.setProperty('pointer-events', 'none', 'important');
                                it.style.setProperty('height', '0px', 'important');
                            }
                        }
                        var channelLinks = document.querySelectorAll('.ytp-title-link, .ytp-title-channel, .ytp-chrome-top a');
                        for (var j = 0; j < channelLinks.length; j++) {
                            channelLinks[j].removeAttribute('href');
                            channelLinks[j].removeAttribute('target');
                            channelLinks[j].style.cursor = 'default';
                        }
                    } catch(e) {}
                }

                document.addEventListener('click', function(e) {
                    var t = e.target;
                    if (!t) return;
                    var m = t.closest ? t.closest('.ytp-menuitem') : null;
                    if (m) {
                        var txt = (m.innerText || m.textContent || '').trim().toLowerCase();
                        if (txt.indexOf('more') !== -1 || txt.indexOf('বিকল্প') !== -1 || txt.indexOf('share') !== -1 || txt.indexOf('copy') !== -1) {
                            e.preventDefault();
                            e.stopPropagation();
                            e.stopImmediatePropagation();
                            return false;
                        }
                    }
                    var blk = t.closest ? t.closest('.ytp-copylink-button, .ytp-share-button, .ytp-impression-link, .ytp-watermark, .ytp-pause-overlay, .ytp-overflow-panel') : null;
                    if (blk) {
                        e.preventDefault();
                        e.stopPropagation();
                        e.stopImmediatePropagation();
                        return false;
                    }
                    setTimeout(cleanMenu, 25);
                    setTimeout(cleanMenu, 100);
                    setTimeout(cleanMenu, 300);
                }, true);

                cleanMenu();
                if (!window._esyObsAttached) {
                    window._esyObsAttached = true;
                    var obs = new MutationObserver(cleanMenu);
                    obs.observe(document.body || document.documentElement, { childList: true, subtree: true });
                    setInterval(cleanMenu, 400);
                }
            })();
        """
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
