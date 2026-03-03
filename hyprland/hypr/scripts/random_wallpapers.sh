#!/bin/bash

# 壁纸目录
WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"

# 直接获取当前焦点显示器(跟随鼠标焦点)
ACTIVE_MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')

# 随机选择壁纸
WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" \) | shuf -n 1)

# 设置壁纸
swww img "$WALLPAPER" --outputs "$ACTIVE_MONITOR" --transition-type random
