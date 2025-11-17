#!/bin/bash

# Script for temperature display with cycling functionality
# Cycles through different temperature sensors on click
# Uses lock file for state management

LOCK=/tmp/temperature.lock

get_cpu_temp() {
    if command -v sensors &> /dev/null; then
        # Try multiple methods to get CPU temperature
        local temp=$(sensors 2>/dev/null | grep -E "^(Tctl|edge|Package|id|Core 0)" | head -1 | awk -F'[+°]' '{print $2}' | tr -d ' ' | cut -d'.' -f1)
        if [ -n "$temp" ]; then
            echo "$temp"
        else
            # Fallback: read from thermal zone
            local thermal_zone=$(ls /sys/class/thermal/thermal_zone* 2>/dev/null | head -1)
            if [ -n "$thermal_zone" ]; then
                local temp_raw=$(cat "$thermal_zone/temp" 2>/dev/null)
                if [ -n "$temp_raw" ]; then
                    echo $((temp_raw / 1000))
                else
                    echo "N/A"
                fi
            else
                echo "N/A"
            fi
        fi
    else
        echo "N/A"
    fi
}

get_gpu_temp() {
    if command -v nvidia-smi &> /dev/null; then
        local gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | awk '{print $1}')
        if [ -n "$gpu_temp" ]; then
            echo "$gpu_temp"
        else
            echo "N/A"
        fi
    elif [ -d /sys/class/drm/card0 ]; then
        # Try AMD GPU
        if [ -f /sys/class/drm/card0/device/hwmon/hwmon*/temp1_input ]; then
            local amd_temp=$(cat /sys/class/drm/card0/device/hwmon/hwmon*/temp1_input 2>/dev/null | head -1)
            if [ -n "$amd_temp" ]; then
                echo $((amd_temp / 1000))
            else
                echo "N/A"
            fi
        else
            echo "N/A"
        fi
    else
        echo "N/A"
    fi
}

get_nvme_temp() {
    # Try nvme command first if available
    if command -v nvme &> /dev/null; then
        for device in /dev/nvme*; do
            if [ -e "$device" ]; then
                local temp=$(nvme smart-log "$device" 2>/dev/null | grep "temperature" | awk '{print $3}' | head -1)
                if [ -n "$temp" ] && [ "$temp" != "0" ]; then
                    echo "$temp"
                    return
                fi
            fi
        done
    fi

    # Try smartctl if available
    if command -v smartctl &> /dev/null; then
        for device in /dev/nvme*; do
            if [ -b "$device" ]; then
                local temp=$(smartctl -a "$device" 2>/dev/null | grep "Temperature:" | awk '{print $2}' | head -1)
                if [ -n "$temp" ]; then
                    echo "$temp"
                    return
                fi
            fi
        done
    fi

    # Try reading from sysfs (modern kernels expose NVMe temp via hwmon)
    for hwmon in /sys/class/hwmon/hwmon*/temp*_input; do
        if [ -e "$hwmon" ]; then
            local name=$(dirname "$hwmon")/name
            if [ -e "$name" ]; then
                local driver=$(cat "$name" 2>/dev/null)
                if [[ "$driver" == *"nvme"* ]] || [[ "$driver" == *"nvme"* ]]; then
                    local temp=$(cat "$hwmon" 2>/dev/null | head -1)
                    if [ -n "$temp" ] && [ "$temp" != "0" ]; then
                        echo $((temp / 1000))
                        return
                    fi
                fi
            fi
        fi
    done

    echo "N/A"
}

get_all_temps() {
    local cpu=$(get_cpu_temp)
    local gpu=$(get_gpu_temp)
    local nvme=$(get_nvme_temp)

    echo "  CPU: $cpu°C"
    echo "  GPU: $gpu°C"
    echo "  NVMe: $nvme°C"
}

# Initialize lock file
if [ ! -f "$LOCK" ]; then
    echo "0" > "$LOCK"
fi

# Read current state
state=$(cat "$LOCK")

# Get temperatures
cpu_temp=$(get_cpu_temp)
gpu_temp=$(get_gpu_temp)
nvme_temp=$(get_nvme_temp)

# Get icon based on temperature
get_temp_icon() {
    local temp=$1
    if [ "$temp" = "N/A" ]; then
        echo ""
    elif [ "$temp" -lt 50 ]; then
        echo ""
    elif [ "$temp" -lt 80 ]; then
        echo ""
    else
        echo ""
    fi
}

cpu_icon=$(get_temp_icon "$cpu_temp")
gpu_icon=$(get_temp_icon "$gpu_temp")
nvme_icon=$(get_temp_icon "$nvme_temp")

# Output based on current state
case "$state" in
    0)
        # Show CPU temperature
        printf '{"text": "CPU: %s°C %s", "tooltip": "All Temps:\\nCPU: %s°C\\nGPU: %s°C\\nNVMe: %s°C\\n\\nClick: Cycle sensors\\nHover: Details", "class": "state-cpu-temp"}\n' \
            "$cpu_temp" "$cpu_icon" "$cpu_temp" "$gpu_temp" "$nvme_temp"
        ;;
    1)
        # Show GPU temperature
        printf '{"text": "GPU: %s°C %s", "tooltip": "All Temps:\\nCPU: %s°C\\nGPU: %s°C\\nNVMe: %s°C\\n\\nClick: Cycle sensors\\nHover: Details", "class": "state-gpu-temp"}\n' \
            "$gpu_temp" "$gpu_icon" "$cpu_temp" "$gpu_temp" "$nvme_temp"
        ;;
    2)
        # Show NVMe temperature
        printf '{"text": "NVMe: %s°C %s", "tooltip": "All Temps:\\nCPU: %s°C\\nGPU: %s°C\\nNVMe: %s°C\\n\\nClick: Cycle sensors\\nHover: Details", "class": "state-nvme-temp"}\n' \
            "$nvme_temp" "$nvme_icon" "$cpu_temp" "$gpu_temp" "$nvme_temp"
        ;;
esac
