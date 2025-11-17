#!/bin/bash

# Ensure RAPL is readable on every run (in case permissions reset)
RAPL_ENERGY="/sys/class/powercap/intel-rapl/intel-rapl:0/energy_uj"
if [ -f "$RAPL_ENERGY" ] && [ ! -r "$RAPL_ENERGY" ]; then
    sudo chmod +r "$RAPL_ENERGY" 2>/dev/null || true
fi

# Script for system stats display with cycling functionality
# Cycles through RAM -> CPU -> GPU -> RAM on each click
# Cycles through power modes on scroll
# Uses its own lock file for state management

LOCK=/tmp/system_stats.lock
POWER_LOCK=/tmp/system_power.lock

get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//' | awk '{printf "%.0f", $1}'
}

get_gpu_usage() {
    if command -v nvidia-smi &> /dev/null; then
        nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | awk '{print $1}'
    else
        echo "N/A"
    fi
}

get_gpu_temp() {
    if command -v nvidia-smi &> /dev/null; then
        nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits | awk '{print $1}'
    else
        echo "N/A"
    fi
}

get_gpu_fan() {
    if command -v nvidia-smi &> /dev/null; then
        local fan=$(nvidia-smi --query-gpu=fan.speed --format=csv,noheader,nounits 2>/dev/null | awk '{print $1}')
        if [ -n "$fan" ] && [ "$fan" != "[N/A]" ] && [ "$fan" != "N/A" ]; then
            echo "$fan"
        else
            echo "Auto"
        fi
    else
        echo "N/A"
    fi
}

get_cpu_temp() {
    sensors | grep "Core 0" | awk '{print $3}' | sed 's/+//' | sed 's/°C//'
}

get_ram_usage() {
    free | grep -E "内存：" | awk '{printf "%.0f", ($3/$2) * 100.0}'
}

get_ram_detail() {
    free -h | grep -E "内存：" | awk '{print $3 "/" $2}'
}

get_power_profile() {
    if command -v powerprofiles-cli &> /dev/null; then
        powerprofiles-cli list | grep "active" | awk '{print $2}'
    else
        echo "balanced"
    fi
}

get_cpu_freq() {
    local freq=$(lscpu | grep "CPU(s):" | awk '{print $2}')
    if [ -n "$freq" ]; then
        echo "$freq"
    else
        # Fallback: read from /proc/cpuinfo
        freq=$(grep "cpu MHz" /proc/cpuinfo 2>/dev/null | head -1 | awk '{print int($4)}')
        if [ -n "$freq" ]; then
            echo "$freq"
        else
            echo "N/A"
        fi
    fi
}

get_cpu_power() {
    # 改进的RAPL功耗计算 - 正确处理累积计数器
    local rapl_device="/sys/class/powercap/intel-rapl/intel-rapl:0/energy_uj"
    local cache_file="/tmp/cpu_power_baseline"
    local current_time=$(date +%s)

    # 读取当前能耗
    if [ -f "$rapl_device" ] && [ -r "$rapl_device" ]; then
        local current_energy=$(cat "$rapl_device" 2>/dev/null)
        if [ -n "$current_energy" ] && [ "$current_energy" -ge 0 ]; then
            # 检查是否已建立基准点
            if [ -f "$cache_file" ]; then
                local baseline_energy=$(grep "^energy=" "$cache_file" 2>/dev/null | cut -d'=' -f2)
                local baseline_time=$(grep "^time=" "$cache_file" 2>/dev/null | cut -d'=' -f2)

                if [ -n "$baseline_energy" ] && [ -n "$baseline_time" ]; then
                    # 计算自基准点以来的增量
                    local time_diff=$((current_time - baseline_time))
                    local energy_diff=$((current_energy - baseline_energy))

                    # 检测计数器是否重置（当前值小于基准值）
                    if [ "$current_energy" -lt "$baseline_energy" ]; then
                        # 计数器重置，重新建立基准点
                        echo "energy=$current_energy" > "$cache_file"
                        echo "time=$current_time" >> "$cache_file"
                        echo "0.0"
                        return
                    fi

                    # 计算功耗 - 调整时间窗口为>=3秒，增加灵活性
                    if [ "$time_diff" -ge 3 ] && [ "$energy_diff" -ge 0 ]; then
                        # 计算平均功耗 (微焦耳转瓦特)
                        local power_w=$(echo "scale=1; $energy_diff / ($time_diff * 1000000)" | bc -l 2>/dev/null)

                        # 验证功耗在合理范围 (0-500W)
                        if [ -n "$power_w" ]; then
                            local power_num=$(echo "$power_w" | cut -d'.' -f1)
                            if [ "$power_num" -ge 0 ] && [ "$power_num" -le 500 ]; then
                                echo "$power_w"
                                return
                            fi
                        fi
                    elif [ "$time_diff" -ge 1 ]; then
                        # 对于短时间间隔，也尝试计算（可能功耗较低）
                        local power_w=$(echo "scale=1; $energy_diff / ($time_diff * 1000000)" | bc -l 2>/dev/null)
                        if [ -n "$power_w" ]; then
                            local power_num=$(echo "$power_w" | cut -d'.' -f1)
                            if [ "$power_num" -ge 0 ] && [ "$power_num" -le 500 ] && [ "$power_num" -ge 0 ]; then
                                echo "$power_w"
                                return
                            fi
                        fi
                    fi

                    # 如果时间差太小，更新基准点以等待下次计算
                    if [ "$time_diff" -ge 10 ]; then
                        # 长时间没有更新，重新建立基准点
                        echo "energy=$current_energy" > "$cache_file"
                        echo "time=$current_time" >> "$cache_file"
                    fi
                else
                    # 缓存文件格式错误，重新建立
                    echo "energy=$current_energy" > "$cache_file"
                    echo "time=$current_time" >> "$cache_file"
                    echo "0.0"
                    return
                fi
            else
                # 首次运行，建立基准点
                echo "energy=$current_energy" > "$cache_file"
                echo "time=$current_time" >> "$cache_file"
                echo "0.0"
                return
            fi
        fi
    fi

    echo "N/A"
}

get_gpu_power() {
    if command -v nvidia-smi &> /dev/null; then
        local power=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits 2>/dev/null | awk '{print $1}')
        if [ -n "$power" ] && [ "$power" != "N/A" ] && [ "$power" != "0.00" ]; then
            printf "%.1f" "$power"
        else
            echo "0.0"
        fi
    else
        echo "N/A"
    fi
}

get_total_power() {
    local cpu_p=$1
    local gpu_p=$2

    # If either is N/A, show N/A
    if [ "$cpu_p" = "N/A" ] || [ "$gpu_p" = "N/A" ]; then
        # But if GPU has power, show GPU power as total
        if [ "$gpu_p" != "N/A" ] && [ "$gpu_p" != "0.0" ]; then
            echo "$gpu_p"
        else
            echo "N/A"
        fi
    else
        # Calculate total
        local total=$(echo "$cpu_p + $gpu_p" | bc -l 2>/dev/null)
        if [ -n "$total" ]; then
            printf "%.1f" "$total"
        else
            echo "$cpu_p"
        fi
    fi
}

# Initialize lock files
if [ ! -f "$LOCK" ]; then
    echo "0" > "$LOCK"
fi

if [ ! -f "$POWER_LOCK" ]; then
    echo "0" > "$POWER_LOCK"
fi

# Read current states
state=$(cat "$LOCK")
power_state=$(cat "$POWER_LOCK")

# Get all metrics
cpu=$(get_cpu_usage)
gpu=$(get_gpu_usage)
gpu_temp=$(get_gpu_temp)
gpu_fan=$(get_gpu_fan)
cpu_temp=$(get_cpu_temp)
ram=$(get_ram_usage)
ram_detail=$(get_ram_detail)
power_profile=$(get_power_profile)
cpu_freq=$(get_cpu_freq)
cpu_power=$(get_cpu_power)
gpu_power=$(get_gpu_power)

# Format icon based on power mode
case "$power_state" in
    0)
        power_icon=""
        power_mode="节能模式"
        ;;
    1)
        power_icon=""
        power_mode="普通模式"
        ;;
    2)
        power_icon=""
        power_mode="性能模式"
        ;;
esac

# Get power profile status
if command -v powerprofiles-cli &> /dev/null; then
    profile_icon=""
    case "$power_profile" in
        "power-saver")
            profile_icon=""
            ;;
        "balanced")
            profile_icon=""
            ;;
        "performance")
            profile_icon=""
            ;;
        *)
            profile_icon="?"
            ;;
    esac
    profile_text=" ($profile_icon $power_profile)"
fi

# Output based on current state
case "$state" in
    0)
        # Show RAM
        printf '{"text": "RAM: %s%%  %s", "tooltip": "🖥️ 硬件信息:\\n  CPU: %s%% (频率: %s MHz)\\n  GPU: %s%% (温度: %s°C)\\n  RAM: %s%%\\n\\n⚡ 功耗信息:\\n  CPU: %s W\\n  GPU: %s W\\n  总功耗: %s W\\n\\n⚙️ 当前模式: %s %s\\n  系统电源模式: %s%s\\n\\n🖱️ 点击: 循环显示 RAM/CPU/GPU\\n🖱️ 滚轮: 切换电源模式", "class": "state-ram"}\n' \
            "$ram" "$power_icon" "$cpu" "$cpu_freq" "$gpu" "$gpu_temp" "$ram" "$cpu_power" "$gpu_power" "$(get_total_power "$cpu_power" "$gpu_power")" "$power_mode" "$power_icon" "$power_profile" "$profile_text"
        ;;
    1)
        # Show CPU
        printf '{"text": "CPU: %s%%  %s", "tooltip": "🖥️ 硬件信息:\\n  CPU: %s%% (频率: %s MHz)\\n  GPU: %s%% (温度: %s°C)\\n  RAM: %s%%\\n\\n⚡ 功耗信息:\\n  CPU: %s W\\n  GPU: %s W\\n  总功耗: %s W\\n\\n⚙️ 当前模式: %s %s\\n  系统电源模式: %s%s\\n\\n🖱️ 点击: 循环显示 RAM/CPU/GPU\\n🖱️ 滚轮: 切换电源模式", "class": "state-cpu"}\n' \
            "$cpu" "$power_icon" "$cpu" "$cpu_freq" "$gpu" "$gpu_temp" "$ram" "$cpu_power" "$gpu_power" "$(get_total_power "$cpu_power" "$gpu_power")" "$power_mode" "$power_icon" "$power_profile" "$profile_text"
        ;;
    2)
        # Show GPU
        printf '{"text": "GPU: %s%% 󰻠 %s", "tooltip": "🖥️ 硬件信息:\\n  CPU: %s%% (频率: %s MHz)\\n  GPU: %s%% (温度: %s°C)\\n  RAM: %s%%\\n\\n⚡ 功耗信息:\\n  CPU: %s W\\n  GPU: %s W\\n  总功耗: %s W\\n\\n⚙️ 当前模式: %s %s\\n  系统电源模式: %s%s\\n\\n🖱️ 点击: 循环显示 RAM/CPU/GPU\\n🖱️ 滚轮: 切换电源模式", "class": "state-gpu"}\n' \
            "$gpu" "$power_icon" "$cpu" "$cpu_freq" "$gpu" "$gpu_temp" "$ram" "$cpu_power" "$gpu_power" "$(get_total_power "$cpu_power" "$gpu_power")" "$power_mode" "$power_icon" "$power_profile" "$profile_text"
        ;;
esac
