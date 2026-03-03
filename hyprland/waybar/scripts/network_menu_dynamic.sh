#!/bin/bash

# Dynamic network menu for waybar with Rofi

# Function to show notification
show_notify() {
    local title="$1"
    local message="$2"
    notify-send -t 2000 -u low "$title" "$message" 2>/dev/null &
}

# Get active connection
ACTIVE=$(nmcli -t -f TYPE,STATE dev status | grep ":connected" | head -1 | cut -d: -f1)

# Build menu options dynamically with connection info
if [ -n "$ACTIVE" ]; then
    case "$ACTIVE" in
        wifi)
            # Get WiFi details
            SSID=$(nmcli -t -f ACTIVE,SSID dev wifi | grep "^是:" | cut -d: -f2)
            SIGNAL=$(nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi | grep "^是:" | cut -d: -f3)
            IP=$(nmcli -t -f IP4.ADDRESS dev show | grep IP4 | head -1 | cut -d: -f2 | cut -d/ -f1)
            GATEWAY=$(nmcli -t -f IP4.GATEWAY dev show | grep IP4 | head -1 | cut -d: -f2)

            # Build header with WiFi info
            HEADER="📶 WiFi: $SSID"
            HEADER="$HEADER\n   信号: ${SIGNAL}%"
            HEADER="$HEADER\n   IP: $IP"
            HEADER="$HEADER\n   网关: $GATEWAY"

            MENU="$HEADER
---
断开WiFi
WiFi: 扫描网络
WiFi: 切换网络
连接设置
启用/禁用WiFi"
            ;;
        ethernet)
            # Get Ethernet details
            IP=$(nmcli -t -f IP4.ADDRESS dev show | grep IP4 | head -1 | cut -d: -f2 | cut -d/ -f1)
            GATEWAY=$(nmcli -t -f IP4.GATEWAY dev show | grep IP4 | head -1 | cut -d: -f2)

            # Build header with Ethernet info
            HEADER="🔌 有线连接"
            HEADER="$HEADER\n   IP: $IP"
            HEADER="$HEADER\n   网关: $GATEWAY"

            MENU="$HEADER
---
断开有线
有线: 连接详情
WiFi: 扫描网络
连接设置
启用/禁用WiFi"
            ;;
        *)
            MENU="无连接
---
WiFi: 扫描网络
连接设置
启用/禁用WiFi"
            ;;
    esac
else
    MENU="无连接
---
WiFi: 扫描网络
连接设置
启用/禁用WiFi"
fi

# Add common options
MENU="$MENU
---
刷新"

# Show rofi menu
CHOICE=$(echo -e "$MENU" | rofi -dmenu -p "🌐 网络管理" -width 30 -lines 12)

case "$CHOICE" in
    "断开WiFi")
        nmcli con down
        show_notify "WiFi" "已断开连接"
        ;;
    "断开有线")
        nmcli con down
        show_notify "有线" "已断开连接"
        ;;
    "WiFi: 扫描网络"|"WiFi: 切换网络")
        # Get current connected WiFi SSID
        CURRENT_SSID=$(nmcli -t -f ACTIVE,SSID dev wifi | grep "^是:" | cut -d: -f2)

        # Show available WiFi networks with current connection highlighted
        WIFI_LIST=$(nmcli -f SSID,SIGNAL dev wifi list | grep -v "^--" | grep -v "^SSID" | awk '{
            ssid=$1
            signal=$2
            # Mark current connection with ✓ symbol
            if (ssid == "'"$CURRENT_SSID"'") {
                print "✓ " ssid " (" signal "%)"
            } else {
                print "  " ssid " (" signal "%)"
            }
        }' | rofi -dmenu -p "选择WiFi (当前: ${CURRENT_SSID:-未连接})" -width 35 -lines 15)

        if [ -n "$WIFI_LIST" ]; then
            # Remove the ✓ and extra spaces from the beginning
            SSID=$(echo "$WIFI_LIST" | sed 's/^✓ *//' | awk '{print $1}')
            nmcli dev wifi connect "$SSID" 2>&1 | while read line; do
                show_notify "WiFi" "$line"
            done
            show_notify "WiFi" "正在连接: $SSID"
        fi
        ;;
    "查看连接信息")
        if [ "$ACTIVE" = "wifi" ]; then
            SSID=$(nmcli -t -f ACTIVE,SSID dev wifi | grep "^是:" | cut -d: -f2)
            SIGNAL=$(nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi | grep "^是:" | cut -d: -f3)
            IP=$(nmcli -t -f IP4.ADDRESS dev show | grep IP4 | head -1 | cut -d: -f2 | cut -d/ -f1)

            show_notify "WiFi信息" "SSID: $SSID\n信号: $SIGNAL%\nIP: $IP"
        elif [ "$ACTIVE" = "ethernet" ]; then
            IP=$(nmcli -t -f IP4.ADDRESS dev show | grep IP4 | head -1 | cut -d: -f2 | cut -d/ -f1)
            show_notify "有线信息" "IP: $IP"
        fi
        ;;
    "有线: 连接详情")
        IP=$(nmcli -t -f IP4.ADDRESS dev show | grep IP4 | head -1 | cut -d: -f2 | cut -d/ -f1)
        GATEWAY=$(nmcli -t -f IP4.GATEWAY dev show | grep IP4 | head -1 | cut -d: -f2)
        show_notify "有线信息" "IP: $IP\\n网关: $GATEWAY"
        ;;
    "连接设置")
        nm-connection-editor &
        show_notify "网络" "正在打开连接编辑器"
        ;;
    "启用/禁用WiFi")
        nmcli radio wifi toggle
        sleep 1
        ;;
    "刷新")
        killall -SIGUSR1 waybar 2>/dev/null
        show_notify "刷新" "Waybar已刷新"
        ;;
esac
