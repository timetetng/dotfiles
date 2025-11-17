#!/bin/bash

# Script to cycle system stats state on click
# Changes state: 0 (RAM) -> 1 (CPU) -> 2 (GPU) -> 0 (RAM)
# Also handles power mode switching via scroll events

LOCK=/tmp/system_stats.lock
POWER_LOCK=/tmp/system_power.lock

# Check if power mode argument is provided
if [ "$1" = "power" ]; then
    # Switch power mode
    if [ ! -f "$POWER_LOCK" ]; then
        echo "0" > "$POWER_LOCK"
        exit 0
    fi

    power_state=$(cat "$POWER_LOCK")
    next_power_state=$(( (power_state + 1) % 3 ))

    echo "$next_power_state" > "$POWER_LOCK"

    # Apply power profile
    case "$next_power_state" in
        0)
            if command -v powerprofiles-cli &> /dev/null; then
                powerprofiles-cli set power-saver
            fi
            ;;
        1)
            if command -v powerprofiles-cli &> /dev/null; then
                powerprofiles-cli set balanced
            fi
            ;;
        2)
            if command -v powerprofiles-cli &> /dev/null; then
                powerprofiles-cli set performance
            fi
            ;;
    esac

    exit 0
fi

# Cycle system stats (default behavior for on-click)
if [ ! -f "$LOCK" ]; then
    echo "0" > "$LOCK"
    exit 0
fi

state=$(cat "$LOCK")
next_state=$(( (state + 1) % 3 ))

echo "$next_state" > "$LOCK"
