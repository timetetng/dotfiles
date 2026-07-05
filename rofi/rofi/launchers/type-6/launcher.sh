#!/usr/bin/env bash

## Rofi   : Launcher (Modi Drun, Run, File Browser, Window)
## style-9

DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$DIR/../../scripts/blur-common.bash"

rofi_blur -show drun -theme "${DIR}/style-9.rasi"
