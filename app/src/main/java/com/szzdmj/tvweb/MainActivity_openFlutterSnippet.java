// 片段示例：在 MainActivity 中新增一个方法
package com.szzdmj.tvweb;

import android.app.Activity;
import android.content.Intent;
import io.flutter.embedding.android.FlutterActivity;

public class MainActivity extends Activity {
    // ... 你的现有代码 ...

    private void openFlutterWebShell() {
        Intent intent = FlutterActivity
            .withNewEngine()
            .initialRoute("/webshell")
            .build(this);
        startActivity(intent);
    }
}
