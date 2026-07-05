#!/usr/bin/env bash
set -euo pipefail

sleep 2

WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/.config/wallpaper}"
WH_CONF="${WALLHAVEN_CONFIG:-$HOME/.config/wallhaven.toml}"

if [ "${1:-}" = "--wallhaven" ]; then
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

    curl -s "$path" | awww img - \
      --transition-type "wave" \
      --transition-angle "$((RANDOM % 360))" \
      --transition-duration 3 \
      --transition-fps 60 \
      --transition-bezier .43,1.19,1,.4
    exit 0
  done

  notify-send "壁纸" "Wallhaven 无符合要求的壁纸"
  exit 1
fi

mapfile -t WALLS < <(find -L "$WALLPAPER_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort)
[ ${#WALLS[@]} -eq 0 ] && exit 1
SELECTED="${WALLS[RANDOM % ${#WALLS[@]}]}"

ANGLE=$((RANDOM % 360))
awww img "$SELECTED" \
  --transition-type "wave" \
  --transition-angle "$ANGLE" \
  --transition-duration 3 \
  --transition-fps 60 \
  --transition-bezier .43,1.19,1,.4

CACHE_DIR_OVERVIEW="$HOME/.cache/wallpaper_overview"
CACHE_ROFI="$HOME/.cache/wallpaper_rofi"
mkdir -p "$CACHE_DIR_OVERVIEW" "$CACHE_ROFI"
FILENAME=$(basename "$SELECTED")
BLURRED_OVERVIEW="$CACHE_DIR_OVERVIEW/overview_$FILENAME"
BLURRED="$HOME/.cache/wallpaper_blur/blurred_$FILENAME"
[ ! -f "$BLURRED_OVERVIEW" ] && magick "$SELECTED" -resize 25% -blur 0x4 -fill black -colorize 40% "$BLURRED_OVERVIEW"
[ ! -f "$BLURRED" ] && magick "$SELECTED" -resize 25% -blur 0x4 "$BLURRED"
awww img -n overview "$BLURRED_OVERVIEW" --transition-type fade --transition-duration 0.5
cp -f "$SELECTED" "$CACHE_ROFI/current"
cp -f "$BLURRED" "$CACHE_ROFI/blurred"
