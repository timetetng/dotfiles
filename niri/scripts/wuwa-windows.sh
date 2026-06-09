#!/bin/bash

# Niri 鸣潮遮罩窗口自动清理守护进程

# 监听 Niri 事件流，只过滤窗口打开或焦点变化事件，作为低功耗触发器
niri msg event-stream | grep --line-buffered -E "Window opened|Window focus" | while read -r line; do

  # 获取当前窗口 JSON，并使用 jq 筛选出符合遮罩特征的窗口 ID
  # 遮罩特征提取自你的日志：app_id 属于 steam_proton，标题为空 ("")，且为悬浮窗口 (is_floating == true)
  MASK_IDS=$(niri msg -j windows 2>/dev/null | jq -r '.[] | select(.app_id == "steam_proton" and .title == "" and .is_floating == true) | .id')

  for id in $MASK_IDS; do
    if [[ -n "$id" ]]; then
      # Niri 执行 close-window 默认作用于当前焦点窗口，因此通过指定 --id 先聚焦再关闭
      niri msg action focus-window --id "$id"
      niri msg action close-window

      # 遮罩被关掉后焦点可能会落在背景或其他窗口，这里主动把焦点还给鸣潮本体
      GAME_ID=$(niri msg -j windows 2>/dev/null | jq -r '.[] | select(.app_id == "steam_proton" and (.title | test("^鸣潮"))) | .id' | head -n 1)

      if [[ -n "$GAME_ID" ]]; then
        niri msg action focus-window --id "$GAME_ID"
      fi
    fi
  done

done
