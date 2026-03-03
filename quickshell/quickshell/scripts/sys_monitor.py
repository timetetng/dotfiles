#!/usr/bin/env python3
import json
import psutil
import time
import sys


def get_cpu_temp():
    try:
        temps = psutil.sensors_temperatures()
        if not temps:
            return 0

        # 1. 优先寻找常见的 CPU 温度标签
        # 'coretemp' 是 Intel CPU 的标准名
        # 'k10temp' 是 AMD CPU 的标准名
        for name in ["coretemp", "k10temp", "zenpower"]:
            if name in temps:
                for entry in temps[name]:
                    # 通常 'Package id 0' 或 'Tctl' 是 CPU 总温度
                    if "Package" in entry.label or "Tctl" in entry.label:
                        return entry.current
                # 如果没找到 Package，就返回该组的第一个温度（通常是 Core 0）
                return temps[name][0].current

        # 2. 如果没找到知名 CPU，就遍历所有传感器，返回最高的那个
        # (通常 CPU 是系统里最热的组件之一)
        max_temp = 0
        for name, entries in temps.items():
            for entry in entries:
                if entry.current > max_temp:
                    max_temp = entry.current
        return max_temp
    except:
        return 0


def get_sys_info():
    # 1. CPU 使用率 (阻塞 0.1 秒来采样)
    cpu_percent = psutil.cpu_percent(interval=0.1)

    # 2. 内存使用
    mem = psutil.virtual_memory()
    # 转换为 GB，保留一位小数
    ram_used_gb = round((mem.total - mem.available) / (1024**3), 1)

    # 3. CPU 温度
    temp = round(get_cpu_temp())

    # 4. 构建 JSON
    data = {
        "cpu": f"{int(cpu_percent)}%",
        "ram": f"{ram_used_gb}G",
        "temp": f"{temp}°C",
    }

    print(json.dumps(data))


if __name__ == "__main__":
    get_sys_info()
