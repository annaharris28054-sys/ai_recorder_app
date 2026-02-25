# 用 Android Studio 生成 APK

按下面步骤在 Android Studio 里打开项目并打出 APK。

## 1. 安装 Android Studio 和 Flutter

1. 若未安装 [Android Studio](https://developer.android.com/studio)，先下载并安装。
2. 打开 Android Studio → **Plugins**（或 File → Settings → Plugins）→ 搜索 **Flutter** → 安装 **Flutter** 插件（会提示安装 Dart，一起装）。
3. 安装完成后重启 Android Studio。若提示配置 Flutter SDK，选「从网络下载」或指定本机已有路径；若本机没有，用 **Get Flutter SDK** 下载到例如 `~/development/flutter`。

## 2. 打开项目

1. Android Studio 里选 **File → Open**。
2. 选中文件夹：**`/Users/mi/LUYINJI/ai_recorder_app`**（不要选上一级 LUYINJI），点 **Open**。
3. 若提示「未检测到 Android 工程」或缺少 `android` 目录，先做第 3 步再继续。

## 3. 补全工程并安装依赖（在 Android Studio 底部 Terminal 里执行）

在 Android Studio 底部点 **Terminal**，在项目目录下依次执行：

```bash
flutter create . --project-name ai_recorder_app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

若提示 `flutter: command not found`，在 Android Studio 里先配好 Flutter SDK 路径（File → Settings → Languages & Frameworks → Flutter），再重试。

## 4. 用 Android Studio 构建 APK

1. 菜单栏选 **Build → Flutter → Build APK**（或 **Build APK**）。
2. 等构建完成，右下角会提示成功，并给出 APK 路径。

## 5. 找到 APK 文件

APK 在项目目录下的：

```
ai_recorder_app/build/app/outputs/flutter-apk/
```

- **app-debug.apk**：调试版，可直接装手机。
- 若点了 **Build → Flutter → Build APK** 且未配置 release 签名，一般就是 **app-debug.apk**。

在 Finder 中打开该文件夹即可把 APK 拖到手机或通过微信/AirDrop 发送。

---

**若没有「Build → Flutter」菜单**：确认已安装 Flutter 插件且当前打开的是 `ai_recorder_app` 根目录（能看到 `pubspec.yaml`），并已执行过第 3 步的 `flutter create .`。
