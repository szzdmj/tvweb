import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WebShellApp());
}

class WebShellApp extends StatelessWidget {
  const WebShellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SZZDMJ Flutter WebShell',
      debugShowCheckedModeBanner: false,
      initialRoute: '/webshell',
      routes: {
        '/webshell': (_) => const WebShellPage(),
      },
    );
  }
}

class WebShellPage extends StatefulWidget {
  const WebShellPage({super.key});
  @override
  State<WebShellPage> createState() => _WebShellPageState();
}

class _WebShellPageState extends State<WebShellPage> {
  InAppWebViewController? _controller;
  final String _initial = 'file:///android_asset/index.html'; // 仍从原生 assets 加载

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: InAppWebView(
          // 5.x: 使用 Uri.parse
          initialUrlRequest: URLRequest(url: Uri.parse(_initial)),
          // 5.x: 使用 initialOptions + InAppWebViewGroupOptions
          initialOptions: InAppWebViewGroupOptions(
            crossPlatform: InAppWebViewOptions(
              javaScriptEnabled: true,
              javaScriptCanOpenWindowsAutomatically: true, // 允许 window.open/target=_blank
              mediaPlaybackRequiresUserGesture: false,
            ),
            android: AndroidInAppWebViewOptions(
              mixedContentMode:
                  AndroidMixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE,
              useHybridComposition: true,
              supportMultipleWindows: true, // 允许多窗口（我们会在 onCreateWindow 中转到同 WebView）
              allowFileAccessFromFileURLs: true, // 兼容 file:// 下的 XHR/资源请求
              allowUniversalAccessFromFileURLs: true,
            ),
            ios: IOSInAppWebViewOptions(
              allowsInlineMediaPlayback: true,
            ),
          ),
          onWebViewCreated: (controller) {
            _controller = controller;
            // 可按需添加更多 JS handler
            controller.addJavaScriptHandler(
              handlerName: 'getPlaylists',
              callback: (args) {
                return [
                  {
                    'title': '示例 1',
                    'url': 'https://example.com/video1.mp4',
                    'type': 'mp4'
                  }
                ];
              },
            );
          },
          onConsoleMessage: (controller, message) {
            // 调试输出：adb logcat 可见
            // print('[WebView] ${message.message}');
          },

          // 关键点：拦截 target=_blank / window.open
          onCreateWindow: (controller, createWindowRequest) async {
            final uri = createWindowRequest.request.url;
            if (uri != null) {
              // 在当前 WebView 直接加载新 URL，避免“打开新窗口失败然后回到主页”的现象
              await controller.loadUrl(urlRequest: URLRequest(url: uri));
            }
            // 返回 true 表示我们己处理新窗口请求
            return true;
          },

          shouldOverrideUrlLoading: (controller, action) async {
            final uri = action.request.url;
            // 这里可按需拦截外部 scheme（intent:, market: 等），当前统一放行 http/https/file
            // 若要拦截外链到系统浏览器，可在此判断并返回 CANCEL
            return NavigationActionPolicy.ALLOW;
          },

          // 可选增强：记录错误，便于排查
          onLoadError: (controller, url, code, message) async {
            // print('onLoadError: $url [$code] $message');
          },
          onLoadHttpError: (controller, url, statusCode, description) async {
            // print('onLoadHttpError: $url [$statusCode] $description');
          },
        ),
      ),
    );
  }
}
