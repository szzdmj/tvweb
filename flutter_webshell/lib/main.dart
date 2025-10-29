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
  final String _initial = 'file:///android_asset/index.html'; // 仍然从原生 assets 加载

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(_initial)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            mediaPlaybackRequiresUserGesture: false,
            mixedContentMode: MixedContentMode.COMPATIBILITY_MODE,
            useOnDownloadStart: true,
            useShouldOverrideUrlLoading: true,
          ),
          onWebViewCreated: (controller) {
            _controller = controller;
            controller.addJavaScriptHandler(
              handlerName: 'getPlaylists',
              callback: (args) {
                return [
                  {'title': '示例 1', 'url': 'https://example.com/video1.mp4', 'type': 'mp4'}
                ];
              },
            );
          },
          onConsoleMessage: (controller, message) {
            // 调试输出：adb logcat 可见
            // print('[WebView] ${message.message}');
          },
          shouldOverrideUrlLoading: (controller, action) async {
            return NavigationActionPolicy.ALLOW;
          },
        ),
      ),
    );
  }
}
