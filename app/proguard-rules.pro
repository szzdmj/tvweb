# 你现有的规则（保留）
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keep class com.szzdmj.tvweb.MainActivity { *; }

# Flutter / 插件保留
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
# 视需要添加其它第三方插件包名的 keep 规则
