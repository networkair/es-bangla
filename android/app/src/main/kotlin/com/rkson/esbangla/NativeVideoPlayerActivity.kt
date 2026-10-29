package com.rkson.esbangla

import android.annotation.SuppressLint
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
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
    private lateinit var btnPlayerBack: View
    private lateinit var btnPlayerFullscreen: View

    private var customView: View? = null
    private var customViewCallback: WebChromeClient.CustomViewCallback? = null

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_native_video_player)

        // Clean status bar matching white theme
        setupStatusBar()

        val title = intent.getStringExtra("title") ?: "Es Bangla Video Lecture"
        val rawVideoId = intent.getStringExtra("videoId") ?: ""
        val cleanVideoId = extractCleanId(rawVideoId)

        Log.d(TAG, "Starting Safollo-Style Clean Video Player for videoId: $cleanVideoId (title: $title)")

        // Bind layout views
        normalLayout = findViewById(R.id.normalLayout)
        fullscreenContainer = findViewById(R.id.fullscreenContainer)
        videoWebView = findViewById(R.id.videoWebView)
        playerLoading = findViewById(R.id.playerLoading)
        btnPlayerBack = findViewById(R.id.btnPlayerBack)
        btnPlayerFullscreen = findViewById(R.id.btnPlayerFullscreen)

        // Custom bottom-left back button: exits to topic page
        btnPlayerBack.setOnClickListener {
            finish()
        }

        // Custom bottom-right fullscreen button: toggles fullscreen
        btnPlayerFullscreen.setOnClickListener {
            toggleFullscreen()
        }

        if (cleanVideoId.isEmpty()) {
            playerLoading.visibility = View.GONE
            return
        }

        setupWebView(cleanVideoId)
    }

    private fun setupStatusBar() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.statusBarColor = Color.WHITE
            window.insetsController?.setSystemBarsAppearance(
                WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS,
                WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS
            )
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
            window.statusBarColor = Color.WHITE
        }
    }

    private fun toggleFullscreen() {
        if (customView != null) {
            // Currently in fullscreen: exit fullscreen back to portrait
            onBackPressed()
        } else {
            // Trigger HTML5 fullscreen in the embedded video player
            val js = """
                (function() {
                    try {
                        var fsBtn = document.querySelector('.ytp-fullscreen-button');
                        if (fsBtn) {
                            fsBtn.click();
                        } else {
                            var v = document.querySelector('video');
                            if (v) {
                                if (v.requestFullscreen) v.requestFullscreen();
                                else if (v.webkitRequestFullscreen) v.webkitRequestFullscreen();
                            }
                        }
                    } catch(e) {}
                })();
            """.trimIndent()
            videoWebView.evaluateJavascript(js, null)
        }
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

        // Native touch guard overlays:
        // overlayChannelGuard blocks clicks on the channel avatar & title (0-135dp from start)
        // overlayBottomBarGuard blocks clicks anywhere between the back & fullscreen buttons
        val touchGuards = listOf(
            findViewById<View>(R.id.overlayChannelGuard),
            findViewById<View>(R.id.overlayBottomBarGuard)
        )
        touchGuards.forEach { guard ->
            guard?.setOnClickListener { /* Absorb click */ }
            guard?.setOnTouchListener { _, _ -> true /* Absorb touch */ }
        }

        // Android OS Clipboard Guard: Clear any YouTube or embed links if copied
        try {
            val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
            clipboard?.addPrimaryClipChangedListener {
                val clip = clipboard.primaryClip
                if (clip != null && clip.itemCount > 0) {
                    val text = clip.getItemAt(0).text?.toString() ?: ""
                    if (text.contains("youtu") || text.contains("embed") || text.contains("http")) {
                        clipboard.setPrimaryClip(ClipData.newPlainText("", ""))
                        Log.d(TAG, "Cleared video link from clipboard")
                    }
                }
            }
        } catch (e: Exception) {}

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
                setupStatusBar()
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
                // Allow ONLY player embed itself to load
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
                injectPlayerModifications(view)
            }

            override fun onReceivedError(view: WebView?, request: WebResourceRequest?, error: WebResourceError?) {
                super.onReceivedError(view, request, error)
                if (request?.isForMainFrame == true) {
                    playerLoading.visibility = View.GONE
                }
            }
        }

        // Direct loadUrl of YouTube embed with Referer header and iv_load_policy=3 (disable video annotations)
        val embedUrl = "https://www.youtube-nocookie.com/embed/$videoId?autoplay=1&playsinline=1&enablejsapi=1&rel=0&modestbranding=1&fs=1&iv_load_policy=3"
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
            /* 1. COMPLETELY HIDE pause overlay, more videos, related shelf, suggestions, end-screen */
            .ytp-pause-overlay,
            .ytp-pause-overlay-backdrop,
            .ytp-pause-overlay-container,
            .ytp-expand-pause-overlay,
            .ytp-more-videos-view,
            .ytp-suggestions,
            .ytp-suggestion-set,
            .ytp-suggestion-overlay,
            .ytp-cued-thumbnail-overlay,
            .ytp-related-on-error-overlay,
            .ytp-copylink-button,
            .ytp-share-button,
            .ytp-share-panel,
            .ytp-overflow-panel,
            .ytp-contextmenu,
            .ytp-watermark,
            .ytp-watermark-small,
            .ytp-youtube-button,
            .ytp-impression-link,
            .ytp-muted-autoplay-overlay {
                display: none !important;
                visibility: hidden !important;
                pointer-events: none !important;
                opacity: 0 !important;
                width: 0 !important;
                height: 0 !important;
                position: absolute !important;
                top: -9999px !important;
                left: -9999px !important;
                z-index: -999 !important;
            }

            /* 2. Block click and touch interactions on channel avatar, channel name, and top header */
            .ytp-title-link,
            .ytp-title-channel,
            .ytp-title,
            .ytp-title-text,
            .ytp-chrome-top a {
                pointer-events: none !important;
                cursor: default !important;
                user-select: none !important;
            }

            /* 3. Hide the last menuitem ("More / ... আরও বিকল্প") in Settings popup */
            .ytp-panel-menu > .ytp-menuitem:last-child {
                display: none !important;
                visibility: hidden !important;
                pointer-events: none !important;
            }

            /* 4. Ensure Volume/Mute, Play/Pause, Scrubber, Settings gear, and Fullscreen are fully interactive */
            .ytp-chrome-bottom,
            .ytp-chrome-controls,
            .ytp-play-button,
            .ytp-settings-button,
            .ytp-fullscreen-button,
            .ytp-progress-bar-container,
            .ytp-progress-bar,
            .ytp-scrubber-container,
            .ytp-mute-button,
            .ytp-volume-area,
            .ytp-volume-panel {
                pointer-events: auto !important;
            }
        """

        private const val CUSTOM_CLEANER_SCRIPT = """
            (function() {
                function isBlockedTarget(target) {
                    if (!target) return false;

                    // NEVER block sound/mute button or player controls
                    if (target.closest && (
                        target.closest('.ytp-mute-button') ||
                        target.closest('.ytp-volume-area') ||
                        target.closest('.ytp-volume-panel') ||
                        target.closest('.ytp-play-button') ||
                        target.closest('.ytp-progress-bar-container') ||
                        target.closest('.ytp-settings-button') ||
                        target.closest('.ytp-fullscreen-button')
                    )) {
                        return false;
                    }

                    // Check menu items inside settings panel (block More / শেয়ার / লিঙ্ক etc.)
                    var menuItem = target.closest ? target.closest('.ytp-menuitem, [role="menuitem"]') : null;
                    if (menuItem) {
                        var text = (menuItem.innerText || menuItem.textContent || '').trim().toLowerCase();
                        var aria = (menuItem.getAttribute('aria-label') || '').toLowerCase();
                        if (text.indexOf('more') !== -1 ||
                            text.indexOf('বিকল্প') !== -1 ||
                            text.indexOf('option') !== -1 ||
                            text.indexOf('share') !== -1 ||
                            text.indexOf('copy') !== -1 ||
                            text.indexOf('link') !== -1 ||
                            text.indexOf('embed') !== -1 ||
                            text.indexOf('stats') !== -1 ||
                            text.indexOf('feedback') !== -1 ||
                            aria.indexOf('more') !== -1 ||
                            aria.indexOf('বিকল্প') !== -1) {
                            return true;
                        }

                        var parent = menuItem.parentElement;
                        if (parent && (parent.classList?.contains('ytp-panel-menu') || parent.getAttribute('role') === 'menu')) {
                            var items = parent.querySelectorAll('.ytp-menuitem, [role="menuitem"]');
                            if (items.length >= 2 && menuItem === items[items.length - 1]) {
                                return true;
                            }
                        }
                    }

                    // Check sensitive player overlays / recommendations / buttons
                    var sensitive = target.closest ? target.closest(
                        '.ytp-overflow-panel, .ytp-share-panel, .ytp-contextmenu, ' +
                        '.ytp-copylink-button, .ytp-share-button, .ytp-pause-overlay, ' +
                        '.ytp-pause-overlay-container, .ytp-expand-pause-overlay, ' +
                        '.ytp-more-videos-view, .ytp-suggestions, .ytp-suggestion-set, ' +
                        '.ytp-impression-link, .ytp-watermark, .ytp-youtube-button, ' +
                        '.ytp-title-link, .ytp-title-channel, .ytp-title'
                    ) : null;
                    if (sensitive) {
                        return true;
                    }

                    return false;
                }

                function interceptEvent(e) {
                    if (isBlockedTarget(e.target)) {
                        e.preventDefault();
                        e.stopPropagation();
                        e.stopImmediatePropagation();
                        return false;
                    }
                }

                // Intercept all touch, pointer, mouse and click events in capture phase
                var eventTypes = ['touchstart', 'touchend', 'touchcancel', 'pointerdown', 'pointerup', 'mousedown', 'mouseup', 'click'];
                for (var i = 0; i < eventTypes.length; i++) {
                    window.addEventListener(eventTypes[i], interceptEvent, true);
                    document.addEventListener(eventTypes[i], interceptEvent, true);
                }

                // Aggressively remove and sweep DOM
                function sweepDOM() {
                    try {
                        // 1. Remove More Videos & Suggestions from DOM entirely
                        var removeSelectors = [
                            '.ytp-pause-overlay',
                            '.ytp-pause-overlay-backdrop',
                            '.ytp-pause-overlay-container',
                            '.ytp-expand-pause-overlay',
                            '.ytp-more-videos-view',
                            '.ytp-suggestions',
                            '.ytp-suggestion-set',
                            '.ytp-copylink-button',
                            '.ytp-share-button',
                            '.ytp-watermark',
                            '.ytp-youtube-button'
                        ];
                        for (var s = 0; s < removeSelectors.length; s++) {
                            var elements = document.querySelectorAll(removeSelectors[s]);
                            for (var e = 0; e < elements.length; e++) {
                                var el = elements[e];
                                if (el && el.parentNode) {
                                    el.parentNode.removeChild(el);
                                }
                            }
                        }

                        // 2. Neutralize channel links
                        var channelLinks = document.querySelectorAll('.ytp-title-link, .ytp-title-channel, .ytp-chrome-top a, .ytp-title');
                        for (var j = 0; j < channelLinks.length; j++) {
                            channelLinks[j].removeAttribute('href');
                            channelLinks[j].removeAttribute('target');
                            channelLinks[j].style.cursor = 'default';
                            channelLinks[j].style.pointerEvents = 'none';
                        }

                        // 3. Hide blocked settings menu items
                        var menuItems = document.querySelectorAll('.ytp-menuitem, [role="menuitem"]');
                        for (var k = 0; k < menuItems.length; k++) {
                            var mi = menuItems[k];
                            if (isBlockedTarget(mi)) {
                                mi.style.setProperty('display', 'none', 'important');
                                mi.style.setProperty('pointer-events', 'none', 'important');
                            }
                        }

                        // 4. Ensure Volume/Mute button is unblocked
                        var muteBtns = document.querySelectorAll('.ytp-mute-button, .ytp-volume-area');
                        for (var m = 0; m < muteBtns.length; m++) {
                            muteBtns[m].style.setProperty('pointer-events', 'auto', 'important');
                            muteBtns[m].style.setProperty('cursor', 'pointer', 'important');
                        }
                    } catch(e) {}
                }

                // Prevent clipboard writes in JS
                try {
                    if (navigator.clipboard) {
                        navigator.clipboard.writeText = function() { return Promise.resolve(); };
                        navigator.clipboard.write = function() { return Promise.resolve(); };
                    }
                    window.open = function() { return null; };
                    document.addEventListener('copy', function(e) {
                        e.preventDefault();
                        e.stopPropagation();
                        e.stopImmediatePropagation();
                    }, true);
                } catch(e) {}

                if (!window._esyInterceptorActive) {
                    window._esyInterceptorActive = true;
                    var obs = new MutationObserver(sweepDOM);
                    obs.observe(document.body || document.documentElement, { childList: true, subtree: true });
                    setInterval(sweepDOM, 250);
                    sweepDOM();
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
                setupStatusBar()
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
