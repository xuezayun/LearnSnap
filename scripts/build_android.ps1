# Android 编译与签名脚本

# 1. 检查 key.properties 是否存在
$keyPropsPath = "android/key.properties"
if (-not (Test-Path $keyPropsPath)) {
    Write-Host "错误: 未找到 android/key.properties 文件。" -ForegroundColor Red
    Write-Host "请参考 android/key.properties.example 创建它并配置您的 Keystore 信息。"
    exit 1
}

Write-Host "正在清理旧的编译产物..." -ForegroundColor Cyan
flutter clean

Write-Host "正在获取依赖..." -ForegroundColor Cyan
flutter pub get

Write-Host "正在编译并签名 APK (Release)..." -ForegroundColor Cyan
flutter build apk --release

Write-Host "正在编译并签名 App Bundle (Release)..." -ForegroundColor Cyan
flutter build appbundle --release

Write-Host "`n编译完成！" -ForegroundColor Green
Write-Host "APK 路径: build/app/outputs/flutter-apk/app-release.apk"
Write-Host "AAB 路径: build/app/outputs/bundle/release/app-release.aab"
