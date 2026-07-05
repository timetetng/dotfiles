#!/usr/bin/env bash
set -uo pipefail

CONFIG="${WALLHAVEN_CONFIG:-$HOME/.config/wallhaven.toml}"

wh_url() {
  local BLACKLIST="真人|写实|男性|実写|写真|写実|photography|realistic|male"
  local atleast=$(grep -oP '^atleast\s*=\s*"\K[^"]*' "$CONFIG" 2>/dev/null || echo "1920x1080")
  local purity=$(grep -oP '^purity\s*=\s*"\K[^"]*' "$CONFIG" 2>/dev/null || echo "100")
  local categories=$(grep -oP '^categories\s*=\s*"\K[^"]*' "$CONFIG" 2>/dev/null || echo "010")

  local tags=()
  while IFS= read -r t; do tags+=("$t"); done < <(tr '\n' ' ' < "$CONFIG" | grep -oP 'tags\s*=\s*\[\K[^\]]*' | tr ',' '\n' | sed -n 's/.*"\(.*\)".*/\1/p')
  [ ${#tags[@]} -eq 0 ] && tags=("anime")

  for ((i = 0; i < ${#tags[@]}; i++)); do
    local idx=$((RANDOM % ${#tags[@]}))
    local tag="${tags[idx]}"
    unset 'tags[idx]'

    local json; json=$(curl -4 -G -s --connect-timeout 5 -H "User-Agent: wallhaven-bash/1.0" \
      "https://wallhaven.cc/api/v1/search" \
      --data-urlencode "q=$tag" \
      --data-urlencode "categories=$categories" \
      --data-urlencode "purity=$purity" \
      --data-urlencode "sorting=random" \
      --data-urlencode "atleast=$atleast") || continue

    local path; path=$(echo "$json" | jq -r '.data[0].path // empty') || continue
    [ -z "$path" ] && continue

    local tag_names; tag_names=$(echo "$json" | jq -r '.data[0].tags // [] | .[].name' 2>/dev/null)
    local bad; bad=$(echo "$tag_names" | grep -i -E "$BLACKLIST" || true)
    [ -n "$bad" ] && continue

    echo "$path"
    return 0
  done

  return 1
}

case "${1:-}" in
  --url)   wh_url ;;
  --set|*)
    local url; url=$(wh_url) || { notify-send "壁纸" "获取失败"; exit 1; }
    curl -s "$url" | awww img - \
      --transition-type "wave" \
      --transition-angle "$((RANDOM % 360))" \
      --transition-duration 3 \
      --transition-fps 60 \
      --transition-bezier .43,1.19,1,.4
    ;;
esac
