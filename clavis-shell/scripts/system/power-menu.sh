#!/usr/bin/env bash

set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
shell_dir=$(cd -- "$script_dir/../.." && pwd)
# shellcheck source=scripts/lib/clavis-paths.sh
source "$shell_dir/scripts/lib/clavis-paths.sh"
clavis_paths_init
asset_dir="$shell_dir/assets/wlogout"
color_file="$CLAVIS_GENERATED_HOME/clavis/colors.json"
personalization_file="$CLAVIS_CONFIG_HOME/config.json"
style=${1:-grid}

if ! command -v wlogout >/dev/null 2>&1; then
    printf 'Clavis power menu: wlogout is not installed.\n' >&2
    exit 127
fi

read_color() {
    local key=$1
    local fallback=$2
    local value=""

    if [[ -r "$color_file" ]]; then
        value=$(sed -n \
            "s/.*\"${key}\"[[:space:]]*:[[:space:]]*\"\\(#[0-9A-Fa-f]\\{6\\}\\)\".*/\\1/p" \
            "$color_file" | head -n 1)
    fi

    printf '%s' "${value:-$fallback}"
}

read_opacity() {
    local value=""

    if [[ -r "$personalization_file" ]]; then
        value=$(sed -n \
            's/.*"shellBackgroundOpacity"[[:space:]]*:[[:space:]]*\([0-9][0-9.]*\).*/\1/p' \
            "$personalization_file" | head -n 1)
    fi

    if [[ ! "$value" =~ ^(0([.][0-9]+)?|1([.]0+)?)$ ]]; then
        value=0.82
    fi
    printf '%s' "$value"
}

logical_size=$(niri msg focused-output 2>/dev/null \
    | sed -n 's/^[[:space:]]*Logical size: \([0-9][0-9]*\)x\([0-9][0-9]*\)$/\1 \2/p' \
    | head -n 1)
read -r screen_width screen_height <<< "${logical_size:-1920 1080}"

# Keep optional layout values defined so Bash's nounset mode does not fail
# while rendering the template for the other layout.
margin=0
marginX=0
marginY=0
hoverMargin=0
hoverX=0
hoverY=0

case "$style" in
    row)
        layout="$asset_dir/layout_1"
        template="$asset_dir/style_1.css"
        columns=5
        export margin=$((screen_height * 40 / 100))
        export hoverMargin=$((screen_height * 37 / 100))
        ;;
    *)
        layout="$asset_dir/layout_2"
        template="$asset_dir/style_2.css"
        columns=2
        export marginX=$((screen_width * 35 / 100))
        export marginY=$((screen_height * 25 / 100))
        export hoverX=$((screen_width * 32 / 100))
        export hoverY=$((screen_height * 20 / 100))
        ;;
esac

export fntSize=$((screen_height * 2 / 100))
export activeRad=50
export buttonRad=80
export assetDir="$asset_dir"
export Surface
export OnSurface
export PrimaryContainer
export OnPrimaryContainer
export LockContainer
export OnLockContainer
export ButtonOpacity
Surface=$(read_color surface_container_lowest '#090f0e')
OnSurface=$(read_color on_surface '#dee4e0')
PrimaryContainer=$(read_color primary_container '#005144')
OnPrimaryContainer=$(read_color on_primary_container '#a0f2de')
LockContainer=$(read_color tertiary_container '#2a4a5f')
OnLockContainer=$(read_color on_tertiary_container '#c8e6ff')
ButtonOpacity=$(read_opacity)

case "$(read_color background '#0e1513')" in
    '#f'*|'#e'*|'#d'*|'#c'*|'#b'*|'#a'*|'#F'*|'#E'*|'#D'*|'#C'*|'#B'*|'#A'*)
        export iconTone=black
        ;;
    *)
        export iconTone=white
        ;;
esac

mkdir -p "$CLAVIS_RUNTIME_HOME/temporary"
generated_css=$(mktemp "$CLAVIS_RUNTIME_HOME/temporary/wlogout.XXXXXX.css")
trap 'rm -f -- "$generated_css"' EXIT

template_text=$(<"$template")
template_text=${template_text//\$\{fntSize\}/$fntSize}
template_text=${template_text//\$\{OnSurface\}/$OnSurface}
template_text=${template_text//\$\{Surface\}/$Surface}
template_text=${template_text//\$\{ButtonOpacity\}/$ButtonOpacity}
template_text=${template_text//\$\{OnPrimaryContainer\}/$OnPrimaryContainer}
template_text=${template_text//\$\{PrimaryContainer\}/$PrimaryContainer}
template_text=${template_text//\$\{OnLockContainer\}/$OnLockContainer}
template_text=${template_text//\$\{LockContainer\}/$LockContainer}
template_text=${template_text//\$\{activeRad\}/$activeRad}
template_text=${template_text//\$\{buttonRad\}/$buttonRad}
template_text=${template_text//\$\{assetDir\}/$asset_dir}
template_text=${template_text//\$\{iconTone\}/$iconTone}
template_text=${template_text//\$\{marginX\}/$marginX}
template_text=${template_text//\$\{marginY\}/$marginY}
template_text=${template_text//\$\{hoverX\}/$hoverX}
template_text=${template_text//\$\{hoverY\}/$hoverY}
template_text=${template_text//\$\{margin\}/$margin}
template_text=${template_text//\$\{hoverMargin\}/$hoverMargin}
printf '%s\n' "$template_text" > "$generated_css"
wlogout \
    --buttons-per-row "$columns" \
    --column-spacing 0 \
    --row-spacing 0 \
    --margin 0 \
    --layout "$layout" \
    --css "$generated_css" \
    --protocol layer-shell
