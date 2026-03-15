#!/bin/bash

# 1. 严格获取路径
WALLPAPER="${1:-$(swww query | head -n1 | grep -oP 'image: \K.*')}"

if [ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ]; then
  echo "$(date) - ERROR: Invalid wallpaper path" >>/tmp/wp_debug.log
  exit 1
fi

CACHE_DIR="$HOME/.cache/wallpaper_blur"
CACHE_DIR_OVERVIEW="$HOME/.cache/wallpaper_overview"
CACHE_ROFI="$HOME/.cache/wallpaper_rofi"
mkdir -p "$CACHE_DIR" "$CACHE_DIR_OVERVIEW" "$CACHE_ROFI"

FILENAME=$(basename "$WALLPAPER")
BLURRED_WALLPAPER_OVERVIEW="$CACHE_DIR_OVERVIEW/overview_$FILENAME"
BLURRED_WALLPAPER="$CACHE_DIR/blurred_$FILENAME"

# 2. 并行生成并等待结束
if [ ! -f "$BLURRED_WALLPAPER" ] || [ ! -f "$BLURRED_WALLPAPER_OVERVIEW" ]; then
  echo "Generating backgrounds..." >>/tmp/wp_debug.log
  # 使用 & 后台运行，然后用 wait 等待，确保两个都完成
  magick "$WALLPAPER" -resize 25% -blur 0x4 -fill black -colorize 40% "$BLURRED_WALLPAPER_OVERVIEW" &
  magick "$WALLPAPER" -resize 25% -blur 0x4 "$BLURRED_WALLPAPER" &
  wait # <--- 关键：确保上面两个 magick 进程彻底退出
fi

# 3. 再次确认文件真的存在（防止 magick 崩溃导致 cp 报错）
if [ ! -f "$BLURRED_WALLPAPER" ]; then
  echo "$(date) - ERROR: Magick failed to output file" >>/tmp/wp_debug.log
  exit 1
fi

# 4. 执行切换
swww img -n overview "$BLURRED_WALLPAPER_OVERVIEW" --transition-type fade --transition-duration 0.5

# 5. 确保复制操作在文件完全可用后执行
cp -f "$WALLPAPER" "$CACHE_ROFI/current"
cp -f "$BLURRED_WALLPAPER" "$CACHE_ROFI/blurred" && echo "Saved blurred" >>/tmp/wp_debug.log

echo "$(date) - Done" >>/tmp/wp_debug.log
