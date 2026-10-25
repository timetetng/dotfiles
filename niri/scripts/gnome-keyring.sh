#!/bin/sh
# niri 会话没有 PAM 集成，用空密码解锁 login keyring，
# 让 Secret Service (org.freedesktop.secrets) 可用（Clavis 存 API key 靠它）
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
eval "$(echo -n '' | gnome-keyring-daemon --unlock --components=secrets 2>/dev/null)"
