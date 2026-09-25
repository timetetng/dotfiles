#!/usr/bin/env bash
# Clavis shell 默认启动脚本（niri 登录时调用）
# 依赖：quickshell 运行时、build/qml（native 插件）、key-cli/keytop（~/.local/bin）
set -euo pipefail

# QT_SCALE_FACTOR 不要在 Wayland 下设置：它会把 layershell 表面几何算小，
# 导致壁纸不铺满、overview 显示过小。用 niri 的 scale + 组件内置缩放即可。
export QML_IMPORT_PATH="$HOME/Projects/clavis/build/qml${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}"
export CLAVIS_BIN_HOME="$HOME/.local/bin"
export CLAVIS_KEY="$HOME/.local/bin/key"
export PATH="$HOME/.local/bin:$PATH"

# -p 让 clavis 作为独立配置实例运行；-n 防止重复实例
exec qs -p "$HOME/Projects/clavis" -n
