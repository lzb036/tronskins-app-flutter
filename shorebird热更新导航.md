# Shorebird 热更新（Android）集成与测试指南

adb connect 127.0.0.1:7555

本文记录在现有 Flutter 项目中安装 Shorebird CLI、集成热更新（Android 端）以及测试热更新的完整流程。

## 1. 安装 Shorebird CLI

### 1.1 准备

- 需要已安装 `git`
- 需要可用的 Flutter（用于日常开发）

### 1.2 Windows 安装

打开 PowerShell，执行：

```powershell
Set-ExecutionPolicy RemoteSigned -scope CurrentUser; iwr -UseBasicParsing 'https://raw.githubusercontent.com/shorebirdtech/install/main/install.ps1' | iex
```

安装完成后，确认 CLI 可用：

```powershell
shorebird --version
```

### 1.3 登录

```powershell
shorebird login
```

首次使用建议运行诊断：

```powershell
shorebird doctor
```

## 2. 集成热更新（Android）

### 2.1 初始化项目

在 Flutter 项目根目录执行：

```powershell
shorebird init
```

该命令会完成以下工作：

- 生成 `shorebird.yaml`（包含 `app_id`）
- 将 `shorebird.yaml` 添加到 `pubspec.yaml` 的 assets
- 检查 AndroidManifest 网络权限

### 2.2 Android 网络权限

Shorebird 需要联网拉取补丁，确保 `android/app/src/main/AndroidManifest.xml` 中包含：

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### 2.3 pubspec.yaml 资产

确保 `pubspec.yaml` 中包含：

```yaml
flutter:
  assets:
    - shorebird.yaml
```

### 2.4 自动更新策略

默认情况下，`shorebird.yaml` 使用后台自动更新。若希望手动触发更新，可在 `shorebird.yaml` 中启用：

```yaml
auto_update: false
```

然后在代码中使用 `shorebird_code_push` 手动检查并应用补丁（本项目已配置，见下）。

### 2.5 手动检查更新（按钮示例）

若需要手动触发更新，需要：

- `shorebird.yaml` 启用 `auto_update: false`
- 依赖中加入 `shorebird_code_push: ^2.0.5`
- 运行 `flutter pub get`
- 在 UI 中调用 `ShorebirdUpdater` 进行检查与下载

本项目已在 `lib/main.dart` 添加 “Check for update” 按钮，点击后会：

1. 调用 `checkForUpdate()` 判断是否有补丁
2. 有补丁时调用 `update()` 下载
3. 下载完成后提示用户重启 App 生效

## 3. 测试热更新（Android）

> 注意：热更新只能作用于 Dart 代码和资源，原生改动无法通过 patch 生效。

### 3.1 真机准备与连接

1. 手机开启开发者选项，并打开“USB 调试”。
2. 使用数据线连接电脑，弹窗提示时选择“允许 USB 调试”。
3. 确保本机可用 `adb`（Android SDK Platform-Tools 已安装并加入 PATH）。
4. 验证连接：

```powershell
adb devices
```

输出中应包含设备序列号且状态为 `device`。若有多个设备，请使用 `adb -s <device_id>` 指定。

### 3.2 首次发布（Release）

1. 修改 UI（例如 `lib/main.dart` 文本显示为 “Version A”）
2. 执行发布命令：（用于生成一个正式的APK安装包）

```powershell
shorebird release android
```

执行完后会在`build/app/outputs/flutter-apk/app-release.apk`这个目录下生成一个apk文件。

3. 使用输出的 APK 路径安装到设备：（将APK安装包安装到连接的真机上）

```powershell
adb install -r <apk_path>
例如：
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

如果提示 `unauthorized`，请在手机上重新授权 USB 调试后重试。

命令`adb install -r <apk_path>`**等同于“手动安装 APK”（侧载）**。**安装完成后可以拔掉 USB，再进行热更新测试。**

### 3.3 推送热更新（Patch）

1. 再次修改 UI（例如文本改成 “Version B”）
2. 推送补丁：

```powershell
shorebird patch android
```

推送补丁有两种方案：

**方案 1（继续用已发布的 1.0.0+1）**

- 后续热更新继续针对 1.0.0+1：  
  `shorebird patch android --release-version=1.0.0+1`其实就是默认的`shorebird patch android`命令
- 前提：当前代码要和你当初发布 1.0.0+1 时一致，否则 patch 可能不匹配。

**方案 2（发布新版本）**

- 把 pubspec.yaml 里的 version 改成 1.0.0+2 或 1.0.1+2
- 再运行：  
    `shorebird release android --artifact=apk`

### 3.4 验证更新

1. 打开 App，保持联网
2. 等待几秒钟补丁下载完成
3. **彻底退出 App 并重新打开**
4. UI 显示 “Version B” 即说明热更新生效

### 3.5 手动更新测试（按钮）

当 `auto_update: false` 时，使用以下流程：

1. 打开 App，点击 “Check for update” 按钮
2. 按钮提示 “Update downloaded. Restart app.”
3. **彻底退出 App 并重新打开**
4. UI 显示 “Version B” 即说明手动更新生效

## 4. 常见注意事项

- 必须使用 `shorebird release` 安装的 release 包，`flutter run` 的 debug 包不会热更新
- patch 只支持 Dart 代码与资源更新，不能替代原生修改
- Android 端必须有 `INTERNET` 权限
