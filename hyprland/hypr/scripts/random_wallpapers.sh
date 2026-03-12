#!/bin/bash

# 壁纸目录
WALLPAPER_DIR="$HOME/.config/wallpaper"

# 1. 自动识别环境并获取当前焦点显示器
if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ]; then
  ACTIVE_MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')
elif [ "$XDG_CURRENT_DESKTOP" = "niri" ]; then
  # 逻辑：
  # 1. grep 找到包含 "(focused)" 的行
  # 2. awk -F'[()]' '{print $(NF-1)}'
  #    意思是：以 '(' 或 ')' 为分隔符，取出倒数第二个字段（即括号内的内容）
  ACTIVE_MONITOR=$(niri msg outputs | grep "(focused)" | awk -F'[()]' '{print $(NF-1)}')
else
  echo "未知的桌面环境: $XDG_CURRENT_DESKTOP"
  exit 1
fi

# 检查是否成功获取
if [ -z "$ACTIVE_MONITOR" ]; then
  echo "错误：无法获取焦点显示器名称"
  exit 1
fi

# 2. 随机选择壁纸
WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" \) | shuf -n 1)

if [ -z "$WALLPAPER" ]; then
  echo "错误：未找到壁纸文件"
  exit 1
fi

# 3. 设置壁纸
swww img "$WALLPAPER" --outputs "$ACTIVE_MONITOR" --transition-type random
