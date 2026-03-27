# Flutter打包、Shorebird热更指南

# 一. 打包+热更

## 1. 安装 Shorebird CLI

### 1.1 准备

- 需要已安装 git
- 需要已安装 Flutter 环境
- https://console.shorebird.dev/
- 去上面这个链接的平台上注册一个Shorebird的号，用于管理应用版本、安装包、热更包：

![image-20260327143411423](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20260327143411423.png)

### 1.2 安装

打开 PowerShell，执行：

```powershell
Set-ExecutionPolicy RemoteSigned -scope CurrentUser; iwr -UseBasicParsing 'https://raw.githubusercontent.com/shorebirdtech/install/main/install.ps1' | iex
```

安装完成后，确认 CLI 可用：

```powershell
shorebird --version
```

### 1.3 登录

使用之前注册的账号进行登录。

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

### 2.4 官方自动更新策略（不灵活）

默认情况下，`shorebird.yaml` 使用后台自动更新。若希望手动触发更新，可在 `shorebird.yaml` 中启用：

```yaml
auto_update: false
```

然后在代码中使用 `shorebird_code_push` 手动检查并应用补丁（本项目已配置，见下）。

### 2.5 自定义更新策略（较为灵活）

若需要手动触发更新，需要：

- `shorebird.yaml` 启用 `auto_update: false`
- 依赖中加入 `shorebird_code_push: ^2.0.5`
- 运行 `flutter pub get`
- 在 UI 中调用 `ShorebirdUpdater` 进行检查与下载
- 加载成功后会自动进行应用的重启，假如重启失败的话会提示用户进行手动重启

## 3. 应用打包（Release）

1. 修改 UI（例如 `lib/main.dart` 文本显示为 “Version A”）
2. 执行发布命令：（用于生成一个正式的APK安装包）

```powershell
shorebird release android 或 shorebird release android --artifact apk
```

**注意：**第一个命令打出来的包是.aab模型，更适合用来上架商城的。假如只是想打一个普通的apk包，就直接使用第二个命令。

执行完后会在`build/app/outputs/flutter-apk/app-release.apk`这个目录下生成一个apk文件。

3. 将这个apk安装到真机或者模拟器上。



## 4. 推送热更包（Patch）

将热更新包推送到shorebird云端上。

```powershell
shorebird patch android
```

**热更注意事项：**

- 假如后续热更新继续针对 1.0.0+1：  
  `shorebird patch android --release-version=1.0.0+1`其实就是默认的`shorebird patch android`命令
  
- 前提：当前代码要和你当初发布 1.0.0+1 时一致，否则 patch 可能不匹配（也就是热更包整个版本必须和现在的应用版本是一样的，不然热更就无法生效）。

- 版本号设置需按一下规则：（`pubspec.yaml`）

  <img src="C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20260327115254087.png" alt="image-20260327115254087" style="zoom:50%;" />

## 5. 常见注意事项

- 必须使用 `shorebird release` 安装的 release 包，`flutter run` 的 debug 包不会热更新。
- patch 只支持 Dart 代码与资源更新，不能替代原生修改。
- Android 端必须有 `INTERNET` 权限。
