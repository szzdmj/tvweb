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
  final String _initial = 'file:///android_asset/index.html';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: Uri.parse(_initial)),
          initialOptions: InAppWebViewGroupOptions(
            crossPlatform: InAppWebViewOptions(
              javaScriptEnabled: true,
              javaScriptCanOpenWindowsAutomatically: true, // 允许 window.open / target=_blank
              mediaPlaybackRequiresUserGesture: false,
            ),
            android: AndroidInAppWebViewOptions(
              mixedContentMode:
                  AndroidMixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE,
              useHybridComposition: true,
              supportMultipleWindows: true, // 需要配合 onCreateWindow
            ),
            ios: IOSInAppWebViewOptions(
              allowsInlineMediaPlayback: true,
            ),
          ),

          onWebViewCreated: (controller) async {
            _controller = controller;
            // 可根据需要添加 JS-bridge
          },

          // 关键：处理 target=_blank 和 window.open
          onCreateWindow: (controller, createWindowRequest) async {
            final uri = createWindowRequest.request.url;
            if (uri != null && uri.toString().isNotEmpty && uri.toString() != 'about:blank') {
              await controller.loadUrl(urlRequest: URLRequest(url: uri));
              return true; // 我们已处理
            }

            // 常见模式：about:blank -> 新窗口里再赋值 URL
            // 这里注入一个钩子，把新窗口的后续导航重定向到当前窗口
            // 对部分站点有效，作为降级兜底。
            try {
              await controller.evaluateJavascript(source: """
                (function(){
                  try {
                    // 覆盖 window.open，让其在当前窗口跳转
                    window.open = function(u){ if(u){ location.href = u; } };
                    // 把所有 a[target=_blank] 改为 _self
                    document.querySelectorAll('a[target="_blank"]').forEach(function(a){
                      a.setAttribute('target','_self');
                    });
                  }catch(e){}
                })();
              """);
            } catch (e) {
              // 忽略注入失败
            }
            return false; // 交还默认流程（已注入降级 JS）
          },

          // 统一约束导航，防止“无效链接/相对路径”把页面带回首页
          shouldOverrideUrlLoading: (controller, action) async {
            final uri = action.request.url;
            if (uri == null) return NavigationActionPolicy.ALLOW;

            final urlStr = uri.toString();

            // 允许的协议
            if (uri.scheme == 'http' || uri.scheme == 'https' || uri.scheme == 'file') {
              return NavigationActionPolicy.ALLOW;
            }

            // 锚点或空链接：留在当前页
            if (urlStr.startsWith('#') || urlStr.isEmpty) {
              return NavigationActionPolicy.CANCEL;
            }

            // 明显的“相对路径”（没有 scheme），避免导航到 file:///android_asset/xxx 造成“回主页/404”
            if ((uri.scheme.isEmpty || uri.scheme == '') && !urlStr.startsWith('about:')) {
              // 可以在这里加日志/JS 提示
              return NavigationActionPolicy.CANCEL;
            }

            // 其它自定义 scheme（tel:, mailto:, intent: 等），如需外部处理可在此分流；
            // 当前一律取消，避免异常回退到首页。
            return NavigationActionPolicy.CANCEL;
          },

          onLoadStop: (controller, url) async {
            // 再注入一次降级逻辑，确保 window.open/_blank 在所有页面都按“当前页打开”
            try {
              await controller.evaluateJavascript(source: """
                (function(){
                  try {
                    window.open = function(u){ if(u){ location.href = u; } };
                    document.querySelectorAll('a[target="_blank"]').forEach(function(a){
                      a.setAttribute('target','_self');
                    });
                  }catch(e){}
                })();
              """);
            } catch (_) {}
          },

          onLoadError: (controller, url, code, message) async {
            // 可加日志/上报
          },
          onLoadHttpError: (controller, url, statusCode, description) async {
            // 可加日志/上报
          },
        ),
      ),
    );
  }
}
