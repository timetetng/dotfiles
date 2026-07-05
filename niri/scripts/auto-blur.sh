#!/bin/bash

# ==============================================================================
# 1. 配置区
# ==============================================================================
LAST_CLEAR_FILE="/tmp/niri_last_clear_wallpaper"
PID_FILE="/tmp/niri_auto_blur.pid"
LINK_NAME="cache-niri-auto-blur-bg"

# --- 核心设置 ---
WALLPAPER_BACKEND="auto"
OVERVIEW_FORCE_CLEAR="false"
AUTO_MAINTENANCE="true"
MAINTENANCE_INTERVAL=1800
WALL_DIR="$HOME/.config/wallpaper/"
ORPHAN_CACHE_LIMIT=10
FLOAT_BYPASS_ENABLED="true"
FLOAT_BYPASS_THRESHOLD="1"

# --- 视觉参数 ---
# 如果设为 true，则使用 overview.sh 生成的带有暗色遮罩的模糊缓存
# 如果设为 false，则使用纯模糊缓存
ENABLE_DARK="false"

# 这里的数值用来在缓存丢失时进行兜底生成，保持和 overview.sh 完全一致
BLUR_ARG_PURE="0x4"
BLUR_ARG_DARK="0x4"
DARK_OPACITY="40%"
ANIM_TYPE="fade"
ANIM_DURATION="0.4"
WORK_SWITCH_DELAY="0.1"

# ==============================================================================
# ★★★ 缓存路径统一逻辑 ★★★
# ==============================================================================
if [[ "$ENABLE_DARK" == "true" ]]; then
  CACHE_DIR="$HOME/.cache/wallpaper_overview"
  FILE_PREFIX="overview_"
else
  CACHE_DIR="$HOME/.cache/wallpaper_blur"
  FILE_PREFIX="blurred_"
fi
mkdir -p "$CACHE_DIR"

# ==============================================================================
# 2. 后端检测与初始化
# ==============================================================================
detect_backend() {
  if [[ "$WALLPAPER_BACKEND" == "auto" ]]; then
    if command -v awww &>/dev/null; then
      WALLPAPER_BACKEND="awww"
    elif command -v awww &>/dev/null; then
      WALLPAPER_BACKEND="awww"
    else
      echo "Error: Neither 'awww' nor 'awww' found."
      exit 1
    fi
  fi

  if ! command -v "$WALLPAPER_BACKEND" &>/dev/null; then
    echo "Error: Wallpaper backend '$WALLPAPER_BACKEND' not found."
    exit 1
  fi
}

detect_backend
SET_WALL_CMD="$WALLPAPER_BACKEND img --transition-type $ANIM_TYPE --transition-duration $ANIM_DURATION"
log() { echo -e "[$(date '+%H:%M:%S')] $1"; }

# ==============================================================================
# 3. 防止重复运行检查
# ==============================================================================
if [[ -f "$PID_FILE" ]]; then
  OLD_PID=$(cat "$PID_FILE")
  if kill -0 "$OLD_PID" 2>/dev/null; then
    echo "Script already running (PID: $OLD_PID). Exiting."
    exit 1
  fi
fi
echo $$ >"$PID_FILE"

# ==============================================================================
# 4. 预计算与工具函数
# ==============================================================================
if [[ "$FLOAT_BYPASS_ENABLED" == "true" ]] && ! command -v jq &>/dev/null; then
  FLOAT_BYPASS_ENABLED="false"
fi

fetch_current_wall() {
  local raw_line
  read -r raw_line < <($WALLPAPER_BACKEND query 2>/dev/null)
  if [[ "$raw_line" =~ image:[[:space:]]*([^[:space:]]+) ]]; then
    _RET_WALL="${BASH_REMATCH[1]}"
  else
    _RET_WALL=""
  fi
}

is_blur_filename() {
  # 兼容识别新的统一缓存前缀以及历史前缀
  [[ "$1" == "blurred_"* || "$1" == "overview_"* || "$1" == auto-blur-* ]]
}

check_floating_bypass() {
  [[ "$FLOAT_BYPASS_ENABLED" != "true" ]] && return 1
  local workspaces_json=$(niri msg -j workspaces 2>/dev/null)
  local windows_json=$(niri msg -j windows 2>/dev/null)
  [[ -z "$workspaces_json" || -z "$windows_json" ]] && return 1

  local counts=$(jq -n -r --argjson ws "$workspaces_json" --argjson wins "$windows_json" '
        ($ws[] | select(.is_focused == true).id) as $focus_id |
        ($wins | map(select(.workspace_id == $focus_id))) as $my_wins |
        {
            total: ($my_wins | length),
            floating: ($my_wins | map(select(.is_floating == true)) | length),
            tiling: ($my_wins | map(select(.is_floating == false)) | length)
        } | "\(.total) \(.floating) \(.tiling)"
    ')
  read -r total floating tiling <<<"$counts"

  [[ "$total" -eq 0 ]] && return 0
  if [[ "$tiling" -eq 0 && "$floating" -le "$FLOAT_BYPASS_THRESHOLD" ]]; then
    log "Bypass: Only floating windows ($floating) -> Keep Clear"
    return 0
  fi
  return 1
}

# ==============================================================================
# X. [常驻后台] 自动维护守护进程
# ==============================================================================
MAINTENANCE_PID=""

start_maintenance_daemon() {
  [[ "$AUTO_MAINTENANCE" != "true" ]] && return
  log "Maintenance Daemon: 启动..."

  if [[ ! -d "$WALL_DIR" ]]; then return; fi

  (
    sleep 5
    while true; do
      fetch_current_wall
      local loop_current="$_RET_WALL"
      local loop_current_target=""
      [[ -n "$loop_current" ]] && loop_current_target="$CACHE_DIR/${FILE_PREFIX}${loop_current##*/}"

      declare -A active_wallpapers
      active_wallpapers=()

      while IFS= read -r -d '' file; do
        active_wallpapers["${file##*/}"]=1
      done < <(find "$WALL_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' -o -iname '*.webp' \) -print0)

      local orphan_list=$(mktemp)
      local orphan_count=0

      while IFS= read -r -d '' cache_file; do
        local cache_name="${cache_file##*/}"
        local original_name="${cache_name#${FILE_PREFIX}}"

        if [[ -z "${active_wallpapers[$original_name]}" ]]; then
          if [[ "$cache_name" != "${loop_current_target##*/}" ]]; then
            echo "$cache_file" >>"$orphan_list"
            orphan_count=$((orphan_count + 1))
          fi
        fi
      done < <(find "$CACHE_DIR" -maxdepth 1 -name "${FILE_PREFIX}*" -print0)

      if [[ "$orphan_count" -gt "$ORPHAN_CACHE_LIMIT" ]]; then
        local delete_count=$((orphan_count - ORPHAN_CACHE_LIMIT))
        if [[ -s "$orphan_list" ]]; then
          xargs -a "$orphan_list" ls -1tu | tail -n "$delete_count" | while read -r dead_file; do
            rm -f "$dead_file"
          done
        fi
      fi
      rm -f "$orphan_list"

      # 兜底生成逻辑也替换为极速方案
      for img_name in "${!active_wallpapers[@]}"; do
        local img="${WALL_DIR}/${img_name}"
        local target="$CACHE_DIR/${FILE_PREFIX}${img_name}"

        if [[ -f "$target" ]]; then continue; fi

        if [[ -f "$img" ]]; then
          if [[ "$ENABLE_DARK" == "true" ]]; then
            magick "$img" -scale 25% -blur "$BLUR_ARG_DARK" -fill black -colorize "$DARK_OPACITY" -resize 400% "$target"
          else
            magick "$img" -scale 25% -blur "$BLUR_ARG_PURE" -resize 400% "$target"
          fi
        fi
      done

      sleep "$MAINTENANCE_INTERVAL"
    done
  ) &
  MAINTENANCE_PID=$!
}

# ==============================================================================
# 5. 核心状态管理
# ==============================================================================
CURRENT_STATE=-1
IS_OVERVIEW=false
DEBOUNCE_PID=""
_RET_WALL=""

cleanup() {
  rm -f "$PID_FILE"
  [[ -n "$DEBOUNCE_PID" ]] && kill "$DEBOUNCE_PID" 2>/dev/null
  [[ -n "$MAINTENANCE_PID" ]] && kill "$MAINTENANCE_PID" 2>/dev/null

  fetch_current_wall
  local cname="${_RET_WALL##*/}"
  if is_blur_filename "$cname" && [[ -f "$LAST_CLEAR_FILE" ]]; then
    local original=$(<"$LAST_CLEAR_FILE")
    [[ -f "$original" ]] && $WALLPAPER_BACKEND img "$original" --transition-type none
  fi
  exit 0
}
trap cleanup EXIT SIGINT SIGTERM

do_restore_task() {
  [[ ! -f "$LAST_CLEAR_FILE" ]] && return
  local target=$(<"$LAST_CLEAR_FILE")
  [[ ! -f "$target" ]] && return
  fetch_current_wall
  local cname="${_RET_WALL##*/}"
  if is_blur_filename "$cname"; then
    $SET_WALL_CMD "$target"
  fi
}

switch_to_clear() {
  local mode="$1"
  [[ "$CURRENT_STATE" -eq 0 ]] && return
  [[ -n "$DEBOUNCE_PID" ]] && kill "$DEBOUNCE_PID" 2>/dev/null && DEBOUNCE_PID=""

  if [[ "$mode" == "delay" ]]; then
    (
      sleep "$WORK_SWITCH_DELAY"
      do_restore_task
    ) &
    DEBOUNCE_PID=$!
  else
    do_restore_task
  fi
  CURRENT_STATE=0
}

switch_to_blur() {
  [[ -n "$DEBOUNCE_PID" ]] && kill "$DEBOUNCE_PID" 2>/dev/null && DEBOUNCE_PID=""
  if check_floating_bypass; then
    switch_to_clear "noderect"
    return
  fi

  fetch_current_wall
  local current="$_RET_WALL"
  [[ -z "$current" ]] && return
  local current_name="${current##*/}"

  if is_blur_filename "$current_name"; then
    [[ "$CURRENT_STATE" -ne 1 ]] && CURRENT_STATE=1
    return
  fi
  CURRENT_STATE=1

  # 记录当前清晰壁纸
  echo "$current" >"$LAST_CLEAR_FILE"
  local link_path="${current%/*}/$LINK_NAME"
  ln -sfn "$CACHE_DIR" "$link_path" 2>/dev/null

  local source_wall=$(<"$LAST_CLEAR_FILE")
  local target_blur="$CACHE_DIR/${FILE_PREFIX}${source_wall##*/}"

  # ★★★ 极速生成兜底逻辑 ★★★
  # 正常情况下，切换壁纸时 Quickshell 的 overview.sh 已经瞬间生成了这个缓存
  # 所以这里只是为了防患于未然 (比如手动清空了缓存)
  if [[ ! -f "$target_blur" ]]; then
    if [[ "$ENABLE_DARK" == "true" ]]; then
      magick "$source_wall" -scale 25% -blur "$BLUR_ARG_DARK" -fill black -colorize "$DARK_OPACITY" -resize 400% "$target_blur"
    else
      magick "$source_wall" -scale 25% -blur "$BLUR_ARG_PURE" -resize 400% "$target_blur"
    fi
  else
    touch -a "$target_blur"
  fi

  $SET_WALL_CMD "$target_blur" &
}

force_check_state() {
  local niri_out=$(niri msg focused-window 2>&1)
  if [[ "$niri_out" == *"No window"* ]]; then
    [[ "$1" == "true" ]] && switch_to_clear "delay" || switch_to_clear "noderect"
  else
    switch_to_blur
  fi
}

# ==============================================================================
# 6. 主循环
# ==============================================================================
log "Daemon Started (PID: $$) using backend: $WALLPAPER_BACKEND"

# 开机缓存恢复逻辑 (解决重启后卡在旧模糊壁纸的问题)
# 等待 random-wallpaper.sh 的 wave 动画(3s)完成
sleep 6
fetch_current_wall
if [[ -n "$_RET_WALL" ]]; then
  _START_WALL_NAME="${_RET_WALL##*/}"
  if is_blur_filename "$_START_WALL_NAME"; then
    _ORIGINAL_NAME="${_START_WALL_NAME#${FILE_PREFIX}}"
    if [[ -f "$WALL_DIR/$_ORIGINAL_NAME" ]]; then
      echo "$WALL_DIR/$_ORIGINAL_NAME" >"$LAST_CLEAR_FILE"
    fi
  else
    echo "$_RET_WALL" >"$LAST_CLEAR_FILE"
  fi
fi

start_maintenance_daemon
force_check_state "false"

niri msg event-stream | grep --line-buffered -E "^(Window|Workspace|Overview)" | while read -r line; do
  case "$line" in
  *"Window opened"*) switch_to_blur ;;
  *"Window closed"*) force_check_state "false" ;;
  *"Window focus changed: None"*) switch_to_clear "noderect" ;;
  *"Window focus changed: Some"*) switch_to_blur ;;
  *"Workspace focused"*) [[ "$IS_OVERVIEW" == "false" ]] && force_check_state "true" ;;
  *"Overview toggled: true"*)
    IS_OVERVIEW=true
    [[ "$OVERVIEW_FORCE_CLEAR" == "true" ]] && switch_to_clear "noderect"
    ;;
  *"Overview toggled: false"*)
    IS_OVERVIEW=false
    force_check_state "false"
    ;;
  *"active window changed to Some"*) [[ "$IS_OVERVIEW" == "true" && "$OVERVIEW_FORCE_CLEAR" == "false" ]] && switch_to_blur ;;
  *"active window changed to None"*) [[ "$IS_OVERVIEW" == "true" && "$OVERVIEW_FORCE_CLEAR" == "false" ]] && switch_to_clear "noderect" ;;
  esac
done
