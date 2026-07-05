#!/usr/bin/env bash
# 壁纸模糊背景 - 被其他 rofi 启动器 source

_get_blurred() {
  local wallpaper
  wallpaper="$(awww query 2>/dev/null | head -n1 | grep -oP 'image: \K.*')"
  if [ -z "$wallpaper" ] || [ ! -f "$wallpaper" ]; then
    wallpaper="$HOME/.config/rofi/images/bga.png"
  fi
  blurred="$HOME/.config/cache-niri-auto-blur-bg/blurred_$(basename "$wallpaper")"
  [ ! -f "$blurred" ] && blurred="$wallpaper"
}

rofi_blur() {
  _get_blurred
  rofi "$@" \
    -theme-str "window { background-image: url(\"$blurred\", width); }" \
    -theme-str "imagebox { background-image: none; }" \
    -theme-str "mainbox { background-color: rgba(0, 0, 0, 0.2); }"
}
