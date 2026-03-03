#!/bin/bash
echo "开始更新Hyprland..."
sudo pacman -Syu Hyprland
hyprpm purge-cache
hyprpm update
hyprpm add https://github.com/hyprwm/hyprland-plugins
hyprpm enable hyprscrolling
hyprpm enable hyprexpo
