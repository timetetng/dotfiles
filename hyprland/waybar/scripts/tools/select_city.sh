#!/bin/bash

# 城市配置文件
CITY_FILE="$HOME/.config/hypr/scripts/tools/weather_city.txt"

# 预设常用城市列表
CITIES=$(cat <<'EOF'
北京
上海
广州
深圳
杭州
南京
苏州
成都
重庆
西安
武汉
天津
青岛
大连
厦门
长沙
郑州
济南
合肥
福州
自定义...
EOF
)

# 使用wofi显示选择菜单
SELECTED=$(echo "$CITIES" | wofi --dmenu -p "选择城市:" -lines 15 -width 400)

# 如果用户选择"自定义..."
if [[ "$SELECTED" == "自定义..." ]]; then
    # 弹出输入框让用户输入城市
    INPUT=$(echo "" | wofi --dmenu -p "输入城市名或坐标:" -width 400)

    if [[ -n "$INPUT" ]]; then
        echo "$INPUT" > "$CITY_FILE"
        notify-send "🌤️ 天气" "城市已设置为: $INPUT"
    fi
elif [[ -n "$SELECTED" ]]; then
    # 保存选中的城市
    echo "$SELECTED" > "$CITY_FILE"
    notify-send "🌤️ 天气" "城市已设置为: $SELECTED"
fi
