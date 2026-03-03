#!/bin/bash

# 城市配置文件
CITY_FILE="$HOME/.config/waybar/scripts/weather_city.txt"

# 读取城市设置，如果没有则使用默认
if [[ -f "$CITY_FILE" ]]; then
    CITY=$(cat "$CITY_FILE" | tr -d '\n')
else
    CITY=""  # 留空表示自动检测
fi

# 构建API URL - 获取更详细的信息
if [[ -n "$CITY" ]]; then
    URL="wttr.in/${CITY}?format=%C+%t+%h+%w"
else
    URL="wttr.in?format=%C+%t+%h+%w"
fi

# 获取天气数据
weather=$(curl -s "$URL" 2>/dev/null | head -n 1 | tr -d '\n')

if [ -z "$weather" ]; then
    echo "{\"text\":\"🌤️ 无数据\", \"tooltip\":\"无法获取天气数据\"}"
    exit
fi

# 解析数据：天气状况 温度 湿度 风速
read -r condition temp humidity wind <<< "$weather"

# 确定显示图标和中文描述
case "$condition" in
    *"Clear"*)
        icon="☀️"
        condition_cn="晴"
        ;;
    *"Cloud"*)
        icon="☁️"
        condition_cn="多云"
        ;;
    *"Rain"*)
        icon="🌧️"
        condition_cn="雨"
        ;;
    *"Snow"*)
        icon="❄️"
        condition_cn="雪"
        ;;
    *"Overcast"*)
        icon="🌥️"
        condition_cn="阴"
        ;;
    *)
        icon="🌤️"
        condition_cn="$condition"
        ;;
esac

# 确定显示的城市名
DISPLAY_CITY="${CITY:-自动定位}"
if [ -z "$CITY" ]; then
    # 尝试从wttr.in获取当前位置名称
    LOCATION=$(curl -s "wttr.in?format=%l" 2>/dev/null | tr -d '\n')
    if [ -n "$LOCATION" ]; then
        DISPLAY_CITY="$LOCATION"
    fi
fi

# 格式化输出
TOOLTIP="城市: ${DISPLAY_CITY}\\n天气: ${condition_cn} ${temp}\\n湿度: ${humidity}\\n风速: ${wind}"

echo "{\"text\":\"${icon} ${temp}\", \"tooltip\":\"${TOOLTIP}\"}"
