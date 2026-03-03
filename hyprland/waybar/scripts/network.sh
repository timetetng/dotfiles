#!/bin/bash

# Function to check internet connectivity
check_internet() {
    # Ping a reliable public DNS server with 1 second timeout
    if ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Check if there's any active connection
ACTIVE_CONN=$(nmcli -t -f TYPE,STATE dev status 2>/dev/null | grep ":connected" | head -1)

# Format output based on connection type
if echo "$ACTIVE_CONN" | grep -q "wifi"; then
    # Get active WiFi connection info
    ACTIVE_WIFI=$(nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi | grep "^是:")

    if [ -n "$ACTIVE_WIFI" ]; then
        SIGNAL=$(echo "$ACTIVE_WIFI" | cut -d: -f3)
        SSID=$(echo "$ACTIVE_WIFI" | cut -d: -f2)

        # Get additional network info
        IP=$(nmcli -t -f IP4.ADDRESS dev show | grep IP4 | head -1 | cut -d: -f2 | cut -d/ -f1)

        # Auto-detect WiFi device
        WIFI_DEV=$(nmcli dev show | grep "GENERAL.DEVICE" | grep -E "wlp|wlan|wl" | head -1 | cut -d: -f2 | tr -d ' ')
        SPEED=$(nmcli dev show "$WIFI_DEV" 2>/dev/null | grep "GENERAL.SPEED" | cut -d: -f2 | tr -d ' ')

        # Check internet connectivity
        if check_internet; then
            # Connected to internet
            CLASS="wifi-connected"
            STATUS="✓ 已联网"
            TOOLTIP="已连接: ${SSID}\\n信号强度: ${SIGNAL}%\\nIP地址: ${IP}\\n状态: ✓ 互联网访问正常"
            TEXT="{\"text\":\" ${SIGNAL}%\", \"class\":\"${CLASS}\", \"tooltip\":\"${TOOLTIP}\"}"
        else
            # Connected to WiFi but no internet
            CLASS="wifi-disconnected"
            STATUS="⚠ 无网络"
            TOOLTIP="已连接: ${SSID}\\n信号强度: ${SIGNAL}%\\nIP地址: ${IP}\\n状态: ⚠ 已连接WiFi但无法访问互联网"
            TEXT="{\"text\":\" ${SIGNAL}%\", \"class\":\"${CLASS}\", \"tooltip\":\"${TOOLTIP}\"}"
        fi

        echo "$TEXT"
    else
        echo "{\"text\":\"\", \"class\":\"wifi\", \"tooltip\":\"WiFi已连接\"}"
    fi
elif echo "$ACTIVE_CONN" | grep -q "ethernet"; then
    IP=$(nmcli -t -f IP4.ADDRESS dev show | grep IP4 | head -1 | cut -d: -f2 | cut -d/ -f1)
    SPEED=$(nmcli dev show | grep "GENERAL.SPEED" | head -1 | cut -d: -f2 | tr -d ' ')

    # Check internet connectivity for ethernet
    if check_internet; then
        TOOLTIP="Ethernet | IP: ${IP} | ✓ 互联网访问正常"
        echo "{\"text\":\"\", \"class\":\"ethernet-connected\", \"tooltip\":\"${TOOLTIP}\"}"
    else
        TOOLTIP="Ethernet | IP: ${IP} | ⚠ 已连接但无法访问互联网"
        echo "{\"text\":\"⚠️ 以太网\", \"class\":\"ethernet-disconnected\", \"tooltip\":\"${TOOLTIP}\"}"
    fi
elif echo "$ACTIVE_CONN" | grep -q "tun" || echo "$ACTIVE_CONN" | grep -q "vpn"; then
    VPN_CONN=$(nmcli -t -f NAME,TYPE con show --active | grep "vpn" | cut -d: -f1)
    TOOLTIP="VPN: ${VPN_CONN}"
    echo "{\"text\":\"🔒\", \"class\":\"vpn\", \"tooltip\":\"${TOOLTIP}\"}"
else
    echo "{\"text\":\"⚠️ 无连接\", \"class\":\"disconnected\", \"tooltip\":\"无网络连接\"}"
fi
