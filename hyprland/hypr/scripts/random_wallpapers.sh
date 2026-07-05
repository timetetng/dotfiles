#!/bin/bash

WALLPAPER_DIR="$HOME/.config/wallpaper"
WH_CONF="${WALLHAVEN_CONFIG:-$HOME/.config/wallhaven.toml}"

if [ "${1:-}" = "--wallhaven" ]; then
  tag=$(tr '\n' ' ' < "$WH_CONF" | grep -oP 'tags\s*=\s*\[\K[^\]]*' | tr ',' '\n' | sed -n 's/.*"\(.*\)".*/\1/p' | shuf -n 1)
  tag="${tag:-nature}"
  atleast=$(grep -oP '^atleast\s*=\s*"\K[^"]*' "$WH_CONF" 2>/dev/null || echo "1920x1080")
  purity=$(grep -oP '^purity\s*=\s*"\K[^"]*' "$WH_CONF" 2>/dev/null || echo "100")
  categories=$(grep -oP '^categories\s*=\s*"\K[^"]*' "$WH_CONF" 2>/dev/null || echo "111")
  json=$(curl -4 -G -s --connect-timeout 5 -H "User-Agent: wallhaven-bash/1.0" \
    "https://wallhaven.cc/api/v1/search" \
    --data-urlencode "q=$tag" \
    --data-urlencode "categories=$categories" \
    --data-urlencode "purity=$purity" \
    --data-urlencode "sorting=random" \
    --data-urlencode "atleast=$atleast")
  path=$(echo "$json" | jq -r '.data[0].path // empty')
  [ -n "$path" ] && curl -s "$path" | awww img - --transition-type random
  exit 0
fi

if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ]; then
  ACTIVE_MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')
elif [ "$XDG_CURRENT_DESKTOP" = "niri" ]; then
  ACTIVE_MONITOR=$(niri msg outputs | grep "(focused)" | awk -F'[()]' '{print $(NF-1)}')
else
  echo "未知桌面: $XDG_CURRENT_DESKTOP" >&2; exit 1
fi
[ -z "$ACTIVE_MONITOR" ] && { echo "无法获取焦点显示器" >&2; exit 1; }

WALLPAPER=$(find -L "$WALLPAPER_DIR" -path "*/cache-niri-auto-blur-bg" -prune -o -type f \( -iname "*.jpg" -o -iname "*.png" \) -print | shuf -n 1)
[ -z "$WALLPAPER" ] && { echo "未找到壁纸" >&2; exit 1; }

awww img "$WALLPAPER" --outputs "$ACTIVE_MONITOR" --transition-type random
