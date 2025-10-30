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
              mediaPlaybackRequiresUserGesture: false,
            ),
            android: AndroidInAppWebViewOptions(
              // 允许混合内容（根据页面需要）
              mixedContentMode:
                  AndroidMixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE,
              // useShouldOverrideUrlLoading 在 5.8.0 中已移除/不再需要，删除即可
              useOnDownloadStart: true,
              useHybridComposition: true,
            ),
            ios: IOSInAppWebViewOptions(
              allowsInlineMediaPlayback: true,
            ),
          ),
          onWebViewCreated: (controller) {
            _controller = controller;
            // JS handler 示例（按需扩展）
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
          shouldOverrideUrlLoading: (controller, action) async {
            // 按需拦截或放行
            return NavigationActionPolicy.ALLOW;
          },
        ),
      ),
    );
  }
}
