package com.szzdmj.tvweb;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.KeyEvent;
import android.webkit.JavascriptInterface;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

public class MainActivity extends Activity {
    private static final String TAG = "MainActivity";
    private WebView webView;

    private static final String LOCAL_FALLBACK = "file:///android_asset/index.html";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        webView = findViewById(R.id.webview);
        WebSettings ws = webView.getSettings();
        ws.setJavaScriptEnabled(true);
        ws.setDomStorageEnabled(true);
        ws.setAllowFileAccess(true);
        ws.setSaveFormData(false);
        ws.setMediaPlaybackRequiresUserGesture(false);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            ws.setMixedContentMode(WebSettings.MIXED_CONTENT_COMPATIBILITY_MODE);
        }

        webView.setWebChromeClient(new WebChromeClient());
        webView.setWebViewClient(new WebViewClient() {
            @Override
            @Deprecated
            public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
                Log.w(TAG, "WebView error: " + errorCode + " " + description);
                view.loadUrl(LOCAL_FALLBACK);
            }
        });

        webView.addJavascriptInterface(new AndroidBridge(), "AndroidBridge");

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                WebView.setWebContentsDebuggingEnabled(true);
            }
        } catch (Throwable t) {
            // ignore
        }

        webView.loadUrl(LOCAL_FALLBACK);
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (webView != null && (keyCode == KeyEvent.KEYCODE_DPAD_CENTER || keyCode == KeyEvent.KEYCODE_ENTER)) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                    webView.evaluateJavascript(
                        "if(document.activeElement){try{document.activeElement.click();}catch(e){}}", null);
                } else {
                    webView.loadUrl("javascript:(function(){if(document.activeElement){try{document.activeElement.click();}catch(e){}}})();");
                }
            } catch (Throwable t) {
                Log.w(TAG, "Error dispatching click to webview", t);
            }
            return true;
        }
        return super.onKeyDown(keyCode, event);
    }

    private class AndroidBridge {
        AndroidBridge() {}

        @JavascriptInterface
        public String getPlaylists() {
            return "["
                + "{\"title\":\"示例視頻 1\",\"url\":\"https://example.com/video1.mp4\",\"type\":\"mp4\"},"
                + "{\"title\":\"示例視頻 2\",\"url\":\"https://example.com/video2.m3u8\",\"type\":\"hls\"}"
                + "]";
        }

        @JavascriptInterface
        public void openUrl(String url) {
            try {
                Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(intent);
            } catch (Throwable t) {
                Log.w(TAG, "openUrl failed: " + url, t);
            }
        }
    }

    @Override
    protected void onDestroy() {
        if (webView != null) {
            try {
                webView.removeJavascriptInterface("AndroidBridge");
                webView.destroy();
            } catch (Throwable t) {
                // ignore
            }
        }
        super.onDestroy();
    }
}
