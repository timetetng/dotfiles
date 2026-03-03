#!/bin/bash

# 1. 优先使用传入的参数
if [ -n "$1" ]; then
  WALLPAPER="$1"
else
  # 只有没传参数时，才去问 swww (兜底逻辑)
  sleep 0.5
  WALLPAPER=$(swww query | head -n1 | grep -oP 'image: \K.*')
fi

# 检查一下到底有没有拿到路径
if [ -z "$WALLPAPER" ]; then
  echo "$(date) - ERROR: No wallpaper path found!" >>/tmp/wp_debug.log
  exit 1
fi

CACHE_DIR="$HOME/.cache/wallpaper_blur"
CACHE_DIR_OVERVIEW="$HOME/.cache/wallpaper_overview"
mkdir -p "$CACHE_DIR" "$CACHE_DIR_OVERVIEW"

# 获取文件名并定义输出路径
FILENAME=$(basename "$WALLPAPER")
BLURRED_WALLPAPER_OVERVIEW="$CACHE_DIR_OVERVIEW/overview_$FILENAME"
BLURRED_WALLPAPER="$CACHE_DIR/blurred_$FILENAME"

# ============================================================
# 2. 极速模糊逻辑 (核心优化点)
# ============================================================
# 先缩小 25% -> 进行小半径模糊 -> 再放大 400%。视觉效果几乎一致，但速度快 10 倍以上。
if [ ! -f "$BLURRED_WALLPAPER" ] || [ ! -f "$BLURRED_WALLPAPER_OVERVIEW" ]; then
  magick "$WALLPAPER" -scale 25% -blur 0x4 -fill black -colorize 40% -resize 400% "$BLURRED_WALLPAPER_OVERVIEW"
  magick "$WALLPAPER" -scale 25% -blur 0x8 -resize 400% "$BLURRED_WALLPAPER"
fi

# ============================================================
# 3. 设置壁纸
# ============================================================
swww img -n overview "$BLURRED_WALLPAPER_OVERVIEW" \
  --transition-type fade \
  --transition-duration 0.5

# ============================================================
# 4. 核心保存逻辑 (改用软链接优化 I/O)
# ============================================================
CACHE_ROFI="$HOME/.cache/wallpaper_rofi"
mkdir -p "$CACHE_ROFI"

# 放弃缓慢的 cp 物理复制，改用 ln -sf 创建软链接。瞬间完成且不浪费磁盘空间！
ln -sf "$WALLPAPER" "$CACHE_ROFI/current" && echo "Linked current" >>/tmp/wp_debug.log || echo "Failed to link current" >>/tmp/wp_debug.log
ln -sf "$BLURRED_WALLPAPER" "$CACHE_ROFI/blurred" && echo "Linked blurred" >>/tmp/wp_debug.log || echo "Failed to link blurred" >>/tmp/wp_debug.log

echo "$(date) - Done" >>/tmp/wp_debug.log
