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
# 注意: 签名通常由 Xcode 的编译设置（Provisioning Profile / Team ID）自动处理
# 你也可以通过 --export-options-plist 参数指定导出配置
flutter build ipa --release

echo -e "\n编译完成！"
echo "IPA 路径: build/ios/archive/Runner.xcarchive"
echo "导出后的 IPA 通常位于 build/ios/ipa/ 目录下。"
