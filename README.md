# app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

创建的文件列表：
•
scripts/build_android.ps1: 适用于 Windows 的 PowerShell 脚本。
•
scripts/build_ios.sh: 适用于 macOS 的 Shell 脚本。
•
android/key.properties.example: Android 签名配置模板。
•
android/app/build.gradle.kts: 已更新，支持自动读取签名配置。

----------------测试和生产环境------------------------------
地址
环境	Host
测试 dev
http://10.0.2.2:8000
生产 prod
https://zhiyainfo.com
孩子端 App
默认 APP_ENV=dev（模拟器连测试）
生产构建：flutter run/build --dart-define=APP_ENV=prod
或：.\scripts\build_android.ps1 -Env prod（脚本默认 prod）
仍可用 --dart-define=API_BASE_URL=... 直接覆盖
小程序
改 miniprogram/utils/config.js 顶部的 APP_ENV：'dev' / 'prod'
prod 时自动关闭 USE_DEV_LOGIN，并设置下载页为官网
发版前记得：小程序把 APP_ENV 设为 'prod'，并在微信后台配置合法域名 zhiyainfo.com。