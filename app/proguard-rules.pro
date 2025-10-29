# Keep methods used by WebView JavascriptInterface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep MainActivity (used via manifest)
-keep class com.szzdmj.tvweb.MainActivity { *; }
