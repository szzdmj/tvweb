# Android TV WebView app

## 功能
- 最低支援 Android 4.4 (minSdk 19)。
- 內建 WebView 載入 `app/src/main/assets/index.html`（請自行加入內容）。
- `AndroidBridge.getPlaylists()` 傳回 JSON 字串；`AndroidBridge.openUrl(url)` 透過 Intent 開啟外部播放器或瀏覽器。
- 遙控器 DPAD/ENTER 會觸發目前聚焦元素點擊。

## 建置
1. 安裝 JDK 11。
2. 執行 `./gradlew assembleDebug` 或 `./gradlew assembleRelease`。
3. 首次執行 `gradlew` 會自動下載 Gradle 7.5.1 wrapper。

## CI
`.github/workflows/android.yml` 會在 push / PR 觸發 `./gradlew assembleRelease`，並上傳 unsigned APK (`tvwebapp` artifact)。
