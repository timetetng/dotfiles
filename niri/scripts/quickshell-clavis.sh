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

# ---- 锁屏看门狗 ----
# niri 用 ext-session-lock：一旦锁定，锁屏界面只属于当初申请锁的那个客户端。
# Clavis 在锁定期间退出（suspend 恢复后常见）→ niri 仍保持锁定但没有锁屏表面 → 全屏红。
# 这里在 qs 退出后查 LockedHint：仍锁定就重启 Clavis 并重新申请锁屏。
session_locked() {
    local sid="${XDG_SESSION_ID:-}"
    if [ -z "$sid" ]; then
        sid=$(loginctl list-sessions --no-legend 2>/dev/null | awk -v u="$(id -un)" '$3==u {print $1; exit}')
    fi
    [ -n "$sid" ] || return 1
    loginctl show-session "$sid" -p LockedHint 2>/dev/null | grep -q 'LockedHint=yes'
}

relock() {
    for _ in $(seq 1 100); do
        if qs ipc -p "$HOME/Projects/clavis" call lock open >/dev/null 2>&1; then
            return 0
        fi
        sleep 0.2
    done
    echo "[clavis] relock failed" >&2
    return 1
}

restarts=0
while :; do
    started=$(date +%s)
    prime-run qs -p "$HOME/Projects/clavis" -n &
    qs_pid=$!
    session_locked && relock
    wait "$qs_pid" || true

    # 活过 60 秒算稳定，重启计数清零
    if [ $(( $(date +%s) - started )) -ge 60 ]; then
        restarts=0
    fi
    restarts=$((restarts + 1))
    if [ "$restarts" -ge 10 ]; then
        echo "[clavis] too many restarts, giving up" >&2
        break
    fi

    # 锁屏期间挂掉：重启后抓不到桌面快照，让它退回壁纸背景
    if session_locked; then
        export CLAVIS_LOCK_NO_SNAPSHOT=1
        echo "[clavis] shell exited while locked, restart #$restarts" >&2
    else
        unset CLAVIS_LOCK_NO_SNAPSHOT
        echo "[clavis] shell exited, restart #$restarts" >&2
    fi
    sleep 1
done
