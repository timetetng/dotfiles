#!/usr/bin/env bash
# Clavis shell 默认启动脚本（niri 登录时调用）
# 依赖：quickshell 运行时、build/qml（native 插件）、key-cli/keytop（~/.local/bin）
set -euo pipefail

# QT_SCALE_FACTOR 不要在 Wayland 下设置：它会把 layershell 表面几何算小，
# 导致壁纸不铺满、overview 显示过小。用 niri 的 scale + 组件内置缩放即可。
export QML_IMPORT_PATH="$HOME/Projects/clavis/build/qml${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}"
# Qt 没有平台主题插件，默认只查 hicolor → 大量图标解析失败（紫红色缺图块）
export QS_ICON_THEME="${QS_ICON_THEME:-$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'" || echo Adwaita)}"
# 从 SSH/终端手动拉起时不会继承 niri 会话变量，keytop 靠它识别 WM
export XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-niri}"
export DESKTOP_SESSION="${DESKTOP_SESSION:-niri}"
export CLAVIS_BIN_HOME="$HOME/.local/bin"
export CLAVIS_KEY="$HOME/.local/bin/key"
export PATH="$HOME/.local/bin:$PATH"

# -p 让 clavis 作为独立配置实例运行；-n 防止重复实例
# prime-run 强制用 NVIDIA 渲染，避免核显渲染时灵动岛歌词态掉到 ~15fps
exec prime-run qs -p "$HOME/Projects/clavis" -n
