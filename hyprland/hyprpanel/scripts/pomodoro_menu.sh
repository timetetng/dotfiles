#!/bin/bash

# 定义选项
OPTIONS="开始/暂停\n重置\n设定: 工作25分钟\n设定: 工作45分钟\n设定: 休息5分钟\n设定: 休息15分钟\n+5分钟\n-5分钟"

# 打开 Rofi 菜单
SELECTED=$(echo -e "$OPTIONS" | rofi -dmenu -p "🍅 番茄钟控制")

# 你的 Python 脚本路径
SCRIPT="python3 ~/.config/hyprpanel/scripts/pomodoro.py"

case "$SELECTED" in
"开始/暂停")
  $SCRIPT toggle
  ;;
"重置")
  $SCRIPT reset
  ;;
"设定: 工作25分钟")
  $SCRIPT set 25 work
  $SCRIPT toggle
  ;;
"设定: 工作45分钟")
  $SCRIPT set 45 work
  $SCRIPT toggle
  ;;
"设定: 休息5分钟")
  $SCRIPT set 5 break
  $SCRIPT toggle
  ;;
"设定: 休息15分钟")
  $SCRIPT set 15 break
  $SCRIPT toggle
  ;;
"+5分钟")
  $SCRIPT change 300
  ;;
"-5分钟")
  $SCRIPT change -300
  ;;
esac
