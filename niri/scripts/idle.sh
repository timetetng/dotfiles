#!/bin/sh
# 空闲 30 分钟（1800s）自动锁屏，仅保留锁屏
# 修改后重启该脚本生效：pkill swayidle && ~/.config/niri/scripts/idle.sh &
exec swayidle -w \
    timeout 1800 'qs -p /home/xingjian/Projects/clavis ipc call lock open'
