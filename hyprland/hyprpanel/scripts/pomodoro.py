#!/usr/bin/env python3
import time
import json
import os
import argparse

STATE_FILE = "/tmp/hyprpanel_pomodoro.json"

# 默认配置 (秒)
DEFAULT_WORK = 35 * 60
DEFAULT_BREAK = 10 * 60


def load_state():
    if not os.path.exists(STATE_FILE):
        return {
            "state": "stopped",
            "mode": "work",
            "remaining": DEFAULT_WORK,
            "last_tick": time.time(),
        }
    try:
        with open(STATE_FILE, "r") as f:
            return json.load(f)
    except:
        return {
            "state": "stopped",
            "mode": "work",
            "remaining": DEFAULT_WORK,
            "last_tick": time.time(),
        }


def save_state(data):
    with open(STATE_FILE, "w") as f:
        json.dump(data, f)


def format_time(seconds):
    # 确保传入的是数字，并向下取整显示
    seconds = int(max(0, seconds))
    m, s = divmod(seconds, 60)
    return f"{m:02d}:{s:02d}"


def update():
    data = load_state()
    current_time = time.time()

    # 临时变量，用于本次显示，不一定是文件中的值
    display_remaining = data["remaining"]

    if data["state"] == "running":
        elapsed = current_time - data["last_tick"]

        # 核心修改：实时计算剩余时间用于显示，解决卡顿问题
        # 即使文件没更新，这里也会根据流逝的时间显示最新的数值
        display_remaining = data["remaining"] - elapsed

        # 逻辑判断：只有经过了足够长的时间（比如1秒）或者倒计时结束，才更新文件状态
        if elapsed >= 1 or display_remaining <= 0:
            data["remaining"] = display_remaining
            data["last_tick"] = current_time

            if data["remaining"] <= 0:
                # 自动切换模式并发送通知
                if data["mode"] == "work":
                    os.system(
                        'notify-send -u critical "番茄钟" "工作结束，休息一下吧！☕"'
                    )
                    data["mode"] = "break"
                    data["remaining"] = DEFAULT_BREAK
                    data["state"] = "running"
                else:
                    os.system(
                        'notify-send -u critical "番茄钟" "休息结束，开始工作吧！🍅"'
                    )
                    data["mode"] = "work"
                    data["remaining"] = DEFAULT_WORK
                    data["state"] = "stopped"

                # 状态切换后，更新一下 display_remaining 以便本次输出正确
                display_remaining = data["remaining"]

            save_state(data)

    # 图标逻辑
    icon = "🍅" if data["mode"] == "work" else "☕"
    if data["state"] == "paused":
        icon = "⏸️"

    # 状态文本
    mode_text = "工作" if data["mode"] == "work" else "休息"
    status_text = "运行中" if data["state"] == "running" else "已停止"
    if data["state"] == "paused":
        status_text = "已暂停"

    output = {
        "text": format_time(display_remaining),
        "alt": data["mode"] if data["state"] != "paused" else "paused",
        "tooltip": f"模式: {mode_text}\n状态: {status_text}\n剩余: {format_time(display_remaining)}",
        "class": data["mode"],
    }
    print(json.dumps(output))


def toggle():
    data = load_state()
    if data["state"] == "running":
        # 暂停时，需要把这段时间流逝的秒数结算一下，防止暂停后时间倒退
        elapsed = time.time() - data["last_tick"]
        data["remaining"] -= elapsed
        data["state"] = "paused"
    else:
        data["state"] = "running"
        data["last_tick"] = time.time()
    save_state(data)


def change_time(seconds):
    """增加或减少剩余时间"""
    data = load_state()
    data["remaining"] += int(seconds)
    if data["remaining"] < 0:
        data["remaining"] = 0
    save_state(data)


def set_time(minutes, mode=None):
    """直接设置时间和模式"""
    data = load_state()
    data["state"] = "stopped"  # 设置时间时先停止
    data["remaining"] = int(minutes) * 60
    if mode:
        data["mode"] = mode
    save_state(data)


def reset():
    data = load_state()
    data["state"] = "stopped"
    data["remaining"] = DEFAULT_WORK if data["mode"] == "work" else DEFAULT_BREAK
    save_state(data)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "command",
        choices=["status", "toggle", "reset", "change", "set"],
        default="status",
        nargs="?",
    )
    parser.add_argument("value", nargs="?", help="Arguments for change or set")
    parser.add_argument("mode", nargs="?", help="Optional mode for set (work/break)")
    args = parser.parse_args()

    if args.command == "status":
        update()
    elif args.command == "toggle":
        toggle()
        update()
    elif args.command == "reset":
        reset()
        update()
    elif args.command == "change":
        if args.value:
            change_time(args.value)
            update()
    elif args.command == "set":
        if args.value:
            set_time(args.value, args.mode)
            update()


if __name__ == "__main__":
    main()
