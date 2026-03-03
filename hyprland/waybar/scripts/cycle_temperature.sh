#!/bin/bash

# Script to cycle temperature sensor state on click
# Changes state: 0 (CPU) -> 1 (GPU) -> 2 (NVMe) -> 0 (CPU)

LOCK=/tmp/temperature.lock

# Initialize lock file
if [ ! -f "$LOCK" ]; then
    echo "0" > "$LOCK"
    exit 0
fi

# Read current state
state=$(cat "$LOCK")

# Calculate next state (0 -> 1 -> 2 -> 0)
next_state=$(( (state + 1) % 3 ))

# Write next state
echo "$next_state" > "$LOCK"
