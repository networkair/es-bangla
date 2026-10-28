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
                    // 1. Inject CSS rules to hide unwanted options and keep channel title & fullscreen button
                    var cssId = 'esy-player-clean-style';
                    if (!document.getElementById(cssId)) {
                        var css = `
                            .ytp-overlay-bottom-left,
                            .ytp-copylink-button,
                            .ytp-share-button,
                            .ytp-pause-overlay,
                            .ytp-pause-overlay-container,
                            .ytp-pause-overlay-backdrop,
                            .ytp-expand-pause-overlay,
                            .ytp-more-videos-view,
                            .ytp-suggestions,
                            .ytp-suggestion-link,
                            .ytp-suggestion-image,
                            .ytp-suggestion-title,
                            .ytp-suggestion-author,
                            .ytp-suggestion-overlay,
                            .ytp-impression-link,
                            .ytp-impression-link-content,
                            .ytp-impression-link-logo,
                            .ytp-impression-link-text,
                            .ytp-watermark,
                            .ytp-watermark-small,
                            .ytp-youtube-button,
                            .ytp-contextmenu,
                            .ytp-cards-button,
                            .ytp-overflow-button {
                                display: none !important;
                                visibility: hidden !important;
                                opacity: 0 !important;
                                pointer-events: none !important;
                                width: 0 !important;
                                height: 0 !important;
                                max-width: 0 !important;
                                max-height: 0 !important;
                            }
                            /* Preserve channel avatar & name visible at top-left */
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
                            /* Keep fullscreen button visible & accessible */
                            .ytp-fullscreen-button {
                                display: inline-block !important;
                                visibility: visible !important;
                                opacity: 1 !important;
                                pointer-events: auto !important;
                            }
                        `;
                        var head = document.head || document.getElementsByTagName('head')[0] || document.documentElement;
                        var style = document.createElement('style');
                        style.id = cssId;
                        style.type = 'text/css';
                        style.appendChild(document.createTextNode(css));
                        head.appendChild(style);
                    }

                    // 2. Disable clipboard write
                    if (navigator.clipboard) {
                        navigator.clipboard.writeText = function() { return Promise.reject(new Error("Disabled")); };
                        navigator.clipboard.write = function() { return Promise.reject(new Error("Disabled")); };
                    }

                    // 3. Purge sensitive / unwanted items from settings menu (e.g. More options, Copy link, Share)
                    function cleanSettingsMenu() {
                        var items = document.querySelectorAll('.ytp-menuitem');
                        for (var i = 0; i < items.length; i++) {
                            var item = items[i];
                            var text = (item.innerText || item.textContent || '').trim().toLowerCase();
                            
                            var isQuality = text.indexOf('quality') !== -1 || text.indexOf('গুণমান') !== -1 || text.indexOf('কোয়ালিটি') !== -1;
                            var isSpeed = text.indexOf('speed') !== -1 || text.indexOf('গতি') !== -1 || text.indexOf('playback') !== -1;
                            var isSubtitles = text.indexOf('subtitle') !== -1 || text.indexOf('caption') !== -1 || text.indexOf('সাবটাইটেল') !== -1 || text.indexOf('cc') !== -1;
                            var isResolutionOrRate = /\d{3,4}p/.test(text) || text.indexOf('auto') !== -1 || text.indexOf('normal') !== -1 || text.indexOf('স্বাভাবিক') !== -1 || /\d(\.\d+)?x/.test(text);

                            var isForbidden = text.indexOf('more') !== -1 || 
                                              text.indexOf('বিকল্প') !== -1 || 
                                              text.indexOf('share') !== -1 || 
                                              text.indexOf('শেয়ার') !== -1 || 
                                              text.indexOf('copy') !== -1 || 
                                              text.indexOf('কপি') !== -1 || 
                                              text.indexOf('link') !== -1 || 
                                              text.indexOf('লিঙ্ক') !== -1 || 
                                              text.indexOf('embed') !== -1 || 
                                              text.indexOf('stats') !== -1 || 
                                              text.indexOf('report') !== -1;

                            if (isForbidden || (!isQuality && !isSpeed && !isSubtitles && !isResolutionOrRate && text.length > 0)) {
                                item.style.setProperty('display', 'none', 'important');
                                item.style.setProperty('visibility', 'hidden', 'important');
                                item.style.setProperty('pointer-events', 'none', 'important');
                                item.style.setProperty('height', '0px', 'important');
                                item.style.setProperty('min-height', '0px', 'important');
                                item.style.setProperty('margin', '0px', 'important');
                                item.style.setProperty('padding', '0px', 'important');
                            }
                        }
                    }

                    // 4. Secure channel title links so clicking them doesn't navigate
                    function secureChannelLinks() {
                        var titleLinks = document.querySelectorAll('.ytp-title-link, .ytp-title-channel, .ytp-chrome-top a');
                        for (var i = 0; i < titleLinks.length; i++) {
                            var a = titleLinks[i];
                            a.removeAttribute('href');
                            a.removeAttribute('target');
                            a.style.cursor = 'default';
                        }
                    }

                    // 5. Global capture click listener to block any forbidden actions immediately
                    if (!window._esyClickGuardsAttached) {
                        window._esyClickGuardsAttached = true;
                        document.addEventListener('click', function(e) {
                            var target = e.target;
                            if (!target) return;
                            
                            // Check if clicking inside a forbidden menuitem in Settings
                            var menuItem = target.closest('.ytp-menuitem');
                            if (menuItem) {
                                var text = (menuItem.innerText || menuItem.textContent || '').trim().toLowerCase();
                                if (text.indexOf('more') !== -1 || text.indexOf('বিকল্প') !== -1 || 
                                    text.indexOf('share') !== -1 || text.indexOf('শেয়ার') !== -1 || 
                                    text.indexOf('copy') !== -1 || text.indexOf('কপি') !== -1 || 
                                    text.indexOf('link') !== -1 || text.indexOf('লিঙ্ক') !== -1 || 
                                    text.indexOf('embed') !== -1 || text.indexOf('stats') !== -1) {
                                    e.preventDefault();
                                    e.stopPropagation();
                                    e.stopImmediatePropagation();
                                    return false;
                                }
                            }

                            // Check if clicking copy button, watermark, or pause overlay
                            var blocked = target.closest('.ytp-copylink-button, .ytp-share-button, .ytp-impression-link, .ytp-watermark, .ytp-pause-overlay');
                            if (blocked) {
                                e.preventDefault();
                                e.stopPropagation();
                                e.stopImmediatePropagation();
                                return false;
                            }

                            setTimeout(cleanSettingsMenu, 25);
                            setTimeout(cleanSettingsMenu, 100);
                            setTimeout(cleanSettingsMenu, 250);
                        }, true);

                        // Block copy commands
                        document.addEventListener('copy', function(e) {
                            e.preventDefault();
                            e.stopPropagation();
                            e.stopImmediatePropagation();
                        }, true);
                    }

                    // Run immediately and observe DOM changes
                    cleanSettingsMenu();
                    secureChannelLinks();

                    if (!window._esyObserverAttached) {
                        window._esyObserverAttached = true;
                        var observer = new MutationObserver(function() {
                            cleanSettingsMenu();
                            secureChannelLinks();
                        });
                        observer.observe(document.body || document.documentElement, {
                            childList: true,
                            subtree: true
                        });
                        setInterval(function() {
                            cleanSettingsMenu();
                            secureChannelLinks();
                        }, 500);
                    }
                } catch(e) {}
            })();
        """.trimIndent()
        view?.evaluateJavascript(js, null)
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
