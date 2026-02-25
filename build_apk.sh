#!/bin/bash
# 一键构建 AI 录音机 APK（请在本机「终端」里执行此脚本）
set -e
cd "$(dirname "$0")"
PROJECT_DIR="$(pwd)/ai_recorder_app"
OUTPUT_DIR="$PROJECT_DIR/build/app/outputs/flutter-apk"

# 尝试加载 Homebrew 到 PATH（Apple Silicon 或 Intel 常见路径）
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# 查找 flutter 命令
FLUTTER=""
if command -v flutter &>/dev/null; then
  FLUTTER="flutter"
else
  # Homebrew Cask 安装的 Flutter 常见路径
  for f in /opt/homebrew/Caskroom/flutter/*/flutter/bin/flutter /usr/local/Caskroom/flutter/*/flutter/bin/flutter; do
    [ -x "$f" ] && FLUTTER="$f" && break
  done
fi

if [ -z "$FLUTTER" ]; then
  echo "错误：未找到 Flutter。请先在终端执行："
  echo "  brew install --cask flutter"
  echo "  flutter --version"
  exit 1
fi

echo "使用 Flutter: $FLUTTER"
cd "$PROJECT_DIR"

echo ">>> 补全 Flutter 工程结构（生成 android/ 等）..."
"$FLUTTER" create . --project-name ai_recorder_app

echo ">>> 安装依赖..."
"$FLUTTER" pub get

echo ">>> 生成 Isar 代码..."
dart run build_runner build --delete-conflicting-outputs

echo ">>> 构建 Debug APK..."
"$FLUTTER" build apk --debug

if [ -f "$OUTPUT_DIR/app-debug.apk" ]; then
  echo ""
  echo "========== 构建成功 =========="
  echo "APK 文件路径："
  echo "  $OUTPUT_DIR/app-debug.apk"
  echo ""
  echo "正在打开所在文件夹..."
  open "$OUTPUT_DIR"
else
  echo "构建可能失败，请检查上方报错。"
  exit 1
fi
