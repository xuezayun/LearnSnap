#!/bin/bash

# iOS 编译与签名脚本 (需在 macOS 上运行)

# 确保脚本在项目根目录运行
if [ ! -d "ios" ]; then
  echo "错误: 请在项目根目录下运行此脚本。"
  exit 1
fi

echo "正在清理旧的编译产物..."
flutter clean

echo "正在获取依赖..."
flutter pub get

cd ios
echo "正在安装 Pods..."
pod install
cd ..

echo "正在编译 IPA (Release)..."
# Team ID 9QQTRV79MF 已写入 ios/Runner.xcodeproj（Automatic signing）
# Codemagic 构建请使用仓库根目录的 codemagic.yaml
flutter build ipa --release

echo -e "\n编译完成！"
echo "IPA 路径: build/ios/archive/Runner.xcarchive"
echo "导出后的 IPA 通常位于 build/ios/ipa/ 目录下。"
