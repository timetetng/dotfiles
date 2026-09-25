#!/usr/bin/env bash

set -uo pipefail

# 配置
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"
ROFI_THEME="${ROFI_THEME:-$HOME/dotfiles/rofi/wallpaper_2_line.rasi}"
WH_CONF="${WALLHAVEN_CONFIG:-$HOME/.config/wallhaven.toml}"

# 启动 awww 守护进程
if ! pgrep -x "awww-daemon" >/dev/null 2>&1; then
  awww-daemon >/dev/null 2>&1 &
  sleep 0.25
fi

# 收集壁纸
mapfile -t WALLS < <(find -L "$WALLPAPER_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | grep -v "cache-niri-auto-blur-bg/" | sort)

# 构建 rofi 菜单
MENU_ITEMS=""
for wp in "${WALLS[@]}"; do
  name=$(basename "$wp")
  MENU_ITEMS+="$name\0icon\x1f$wp\n"
done
WH_ICON="${WALLS[RANDOM % ${#WALLS[@]}]:-preferences-system}"
MENU_ITEMS="🌐 Wallhaven 随机\0icon\x1f${WH_ICON}\n$MENU_ITEMS"

ROFI_CMD=(rofi -dmenu -p "选择壁纸" -show-icons)
[ -n "$ROFI_THEME" ] && ROFI_CMD+=(-theme "$ROFI_THEME")
if [ "${ROFI_DENIAL_FIX:-0}" = "1" ]; then
  ROFI_CMD+=(-theme-str "window { x-offset: -427px; y-offset: -267px; }")
fi

# 在 Denial 下把壁纸写入 Denial 的壁纸状态文件，shell 会自动应用
denial_set_wallpaper() {
  local img="$1"
  local state="${XDG_STATE_HOME:-$HOME/.local/state}/denial/wallpaper"
  mkdir -p "$(dirname "$state")"
  if [ -f "$state" ] && grep -q '^{' "$state" 2>/dev/null; then
    python3 -c '
import json, sys
p, img = sys.argv[1], sys.argv[2]
try:
    d = json.load(open(p))
except Exception:
    d = {}
d["version"] = 5
d["all"] = "file:" + img
d.setdefault("horizontalAlignment", "center")
d.setdefault("verticalAlignment", "center")
d.setdefault("alignmentX", 0.0)
d.setdefault("alignmentY", 0.0)
d.setdefault("darkness", 0.0)
json.dump(d, open(p, "w"))
' "$state" "$img"
  else
    printf 'file:%s\n' "$img" > "$state"
  fi
}

CHOICE=$(printf '%b' "$MENU_ITEMS" | "${ROFI_CMD[@]}")
[ -z "$CHOICE" ] && exit 0

if [ "$CHOICE" = "🌐 Wallhaven 随机" ]; then
  proxy="${http_proxy:-${https_proxy:-http://127.0.0.1:7890}}"
  BLACKLIST="真人|写实|男性|実写|写真|写実|photography|realistic|male"

  parse_tags() { tr '\n' ' ' < "$WH_CONF" | grep -oP 'tags\s*=\s*\[\K[^\]]*' | tr ',' '\n' | sed -n 's/.*"\(.*\)".*/\1/p'; }

  atleast=$(grep -oP '^atleast\s*=\s*"\K[^"]*' "$WH_CONF" 2>/dev/null || echo "1920x1080")
  purity=$(grep -oP '^purity\s*=\s*"\K[^"]*' "$WH_CONF" 2>/dev/null || echo "100")
  categories=$(grep -oP '^categories\s*=\s*"\K[^"]*' "$WH_CONF" 2>/dev/null || echo "010")

  mapfile -t TAGS < <(parse_tags)
  [ ${#TAGS[@]} -eq 0 ] && TAGS=("anime")

  for ((i = 0; i < ${#TAGS[@]}; i++)); do
    idx=$((RANDOM % ${#TAGS[@]}))
    tag="${TAGS[idx]}"
    unset 'TAGS[idx]'

    json=$(curl -G -s --connect-timeout 5 --proxy "$proxy" -H "User-Agent: wallhaven-bash/1.0" \
      "https://wallhaven.cc/api/v1/search" \
      --data-urlencode "q=$tag" \
      --data-urlencode "categories=$categories" \
      --data-urlencode "purity=$purity" \
      --data-urlencode "sorting=random" \
      --data-urlencode "atleast=$atleast")
    path=$(echo "$json" | jq -r '.data[0].path // empty')
    [ -z "$path" ] && continue

    tag_names=$(echo "$json" | jq -r '.data[0].tags // [] | .[].name' 2>/dev/null)
    bad=$(echo "$tag_names" | grep -i -E "$BLACKLIST" || true)
    [ -n "$bad" ] && continue

    id=$(echo "$json" | jq -r '.data[0].id // empty')
    ext="${path##*.}"
    dest="$HOME/Pictures/wallpapers/wallhaven-$id.$ext"
    mkdir -p "$HOME/Pictures/wallpapers"
    [ ! -f "$dest" ] && curl -sL --proxy "$proxy" -o "$dest" "$path"
    if [ "${ROFI_DENIAL_FIX:-0}" = "1" ]; then
      denial_set_wallpaper "$dest"
    else
      ANGLE=$((RANDOM % 360))
      awww img "$dest" \
        --transition-type "wave" \
        --transition-angle "$ANGLE" \
        --transition-duration 3 \
        --transition-fps 60 \
        --transition-bezier .43,1.19,1,.4
    fi
    notify-send "壁纸已切换" "Wallhaven: $id" -i "$dest"
    [ "${ROFI_DENIAL_FIX:-0}" = "1" ] || bash "$HOME/dotfiles/rofi/overview.sh"
    exit $?
  done

  rofi -e "Wallhaven 无符合要求的壁纸"
  exit 1
fi

# 本地壁纸
SELECTED=""
for wp in "${WALLS[@]}"; do
  if [ "$(basename "$wp")" = "$CHOICE" ]; then
    SELECTED="$wp"
    break
  fi
done
[ -z "$SELECTED" ] && { echo "未找到壁纸" >&2; exit 1; }

if [ "${ROFI_DENIAL_FIX:-0}" = "1" ]; then
  denial_set_wallpaper "$SELECTED"
else
  ANGLE=$((RANDOM % 360))
  awww img "$SELECTED" \
    --transition-type "wave" \
    --transition-angle "$ANGLE" \
    --transition-duration 3 \
    --transition-fps 60 \
    --transition-bezier .43,1.19,1,.4
fi

notify-send "壁纸已切换" "$(basename "$SELECTED")" -i "$SELECTED"
[ "${ROFI_DENIAL_FIX:-0}" = "1" ] || bash "$HOME/dotfiles/rofi/overview.sh"
