#!/bin/bash
direction=$1

if [ "$direction" = "next" ]; then
    hyprctl dispatch workspace m+1
elif [ "$direction" = "prev" ]; then
    hyprctl dispatch workspace m-1
fi