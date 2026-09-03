#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
CONFIG="$HOME/.config"
BACKUP="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
AUR_HELPER="$(command -v yay || command -v paru || true)"

GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

items=(
  "cava           |cava                    |$CONFIG/cava|cava"
  "fastfetch      |fastfetch               |$CONFIG/fastfetch|fastfetch"
  "fcitx5         |fcitx5/fcitx5           |$CONFIG/fcitx5|fcitx5-im fcitx5-chinese-addons"
  "foot           |foot                    |$CONFIG/foot|foot"
  "hypr           |hyprland/hypr           |$CONFIG/hypr|hyprland"
  "hyprpanel      |hyprland/hyprpanel      |$CONFIG/hyprpanel|hyprpanel"
  "waybar         |hyprland/waybar         |$CONFIG/waybar|waybar"
  "kitty          |kitty/kitty             |$CONFIG/kitty|kitty"
  "mpd            |mpd                     |$CONFIG/mpd|mpd"
  "ncmpcpp        |ncmpcpp                 |$CONFIG/ncmpcpp|ncmpcpp"
  "niri           |niri                    |$CONFIG/niri|niri"
  "nvim           |nvim/nvim               |$CONFIG/nvim|neovim"
  "quickshell     |quickshell              |$CONFIG/quickshell|quickshell"
  "rofi           |rofi                    |$CONFIG/rofi|rofi"
  "fontconfig     |theme/fontconfig        |$CONFIG/fontconfig|fontconfig"
  "gtk3           |theme/gtk-3.0           |$CONFIG/gtk-3.0|gtk3"
  "gtk4           |theme/gtk-4.0           |$CONFIG/gtk-4.0|gtk4"
  "nwg-look       |theme/nwg-look          |$CONFIG/nwg-look|nwg-look"
  "xsettingsd     |theme/xsettingsd        |$CONFIG/xsettingsd|xsettingsd"
  "wlogout        |wlogout                 |$CONFIG/wlogout|wlogout"
  "yazi           |yazi/yazi               |$CONFIG/yazi|yazi"
  "zsh            |zsh/.zshrc              |$HOME/.zshrc|zsh"
)

link() {
  local src="$SCRIPT_DIR/$1" dest="$2"
  [ -z "$1" ] && echo -e "${YELLOW}  ⚠ empty source, skip${NC}" && return
  [ -z "$2" ] && echo -e "${YELLOW}  ⚠ empty dest, skip${NC}" && return
  if [ ! -e "$src" ] && [ ! -L "$src" ]; then
    echo -e "${YELLOW}  ⚠ $1 not found, skip${NC}"; return
  fi
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
      echo -e "${GREEN}  ✓ $dest${NC}"; return
    fi
    mkdir -p "$BACKUP"; mv "$dest" "$BACKUP/"
  fi
  ln -s "$src" "$dest"
  echo -e "${GREEN}  ✓${NC} $1"
}

install_deps() {
  local pkgs=($1)
  [ ${#pkgs[@]} -eq 0 ] && return
  local missing=()
  for pkg in "${pkgs[@]}"; do
    pacman -Qi "$pkg" &>/dev/null || missing+=("$pkg")
  done
  [ ${#missing[@]} -eq 0 ] && return
  echo -e "  ${CYAN}installing: ${missing[*]}${NC}"
  if [ -n "$AUR_HELPER" ]; then
    "$AUR_HELPER" -S --needed --noconfirm "${missing[@]}"
  else
    sudo pacman -S --needed --noconfirm "${missing[@]}"
  fi
}

install_one() {
  local raw="${1// /}"
  local idx=$(( raw - 1 ))
  if [ -z "$raw" ] || [ "$raw" -lt 1 ] || [ "$raw" -gt "${#items[@]}" ]; then
    echo -e "${YELLOW}  ⚠ invalid number: $1, skip${NC}"; return
  fi
  IFS='|' read -r name src dst deps <<< "${items[$idx]}"
  name="${name// /}"; src="${src// /}"; dst="${dst// /}"
  deps="${deps%"${deps##*[! ]}"}"
  [ -z "$name" ] && echo -e "${YELLOW}  ⚠ empty item at #$raw, skip${NC}" && return
  [ "$INSTALL_DEPS" = "1" ] && install_deps "$deps"
  echo -e "\n${CYAN}[$raw] ${name}${NC}"
  link "$src" "$dst"

  case "$name" in
    hypr)   chmod +x "$CONFIG/hypr/scripts/"* 2>/dev/null || true ;;
    waybar) chmod +x "$CONFIG/waybar/scripts/"* "$CONFIG/waybar/tools/"* 2>/dev/null || true ;;
    zsh)
      for f in aliases.zsh env.zsh functions.zsh lazyload.zsh; do
        [ -f "$SCRIPT_DIR/zsh/$f" ] && link "zsh/$f" "$HOME/$f"
      done
      ;;
  esac
}

list() {
  echo -e "${BLUE}Available configs:${NC}"
  for i in "${!items[@]}"; do
    IFS='|' read -r name _ _ <<< "${items[$i]}"
    name="${name// /}"
    printf "  %2d) %s\n" $((i+1)) "$name"
  done
  echo "  a) all"
}

interactive() {
  if [ ! -t 0 ]; then
    echo -e "${YELLOW}Warning: stdin is not a TTY. Installing all configs.${NC}"
    for i in "${!items[@]}"; do install_one $((i+1)); done
    return
  fi
  list
  echo -e "${BLUE}Enter numbers (space/comma/hyphen like 1-5), 'a'll, or 'q':${NC}"
  read -r input || true
  [ "$input" = "q" ] && exit 0
  if [ "$input" = "a" ]; then
    for i in "${!items[@]}"; do install_one $((i+1)); done; return
  fi
  local nums=()
  IFS=' ,' read -ra parts <<< "$input"
  for part in "${parts[@]}"; do
    if [[ "$part" =~ ^([0-9]+)-([0-9]+)$ ]]; then
      for ((j=${BASH_REMATCH[1]}; j<=${BASH_REMATCH[2]}; j++)); do nums+=("$j"); done
    elif [[ "$part" =~ ^[0-9]+$ ]]; then nums+=("$part"); fi
  done
  if [ "${#nums[@]}" -eq 0 ]; then
    echo -e "${YELLOW}No valid numbers entered, nothing to install.${NC}"; return
  fi
  local seen=()
  for n in "${nums[@]}"; do
    local skip=0
    for s in "${seen[@]}"; do [ "$s" = "$n" ] && skip=1 && break; done
    [ "$skip" -eq 1 ] && continue
    seen+=("$n")
    install_one "$n"
  done
}

echo -e "${BLUE}════════════════════════════════════${NC}"
echo -e "${BLUE}  dotfiles installer${NC}"
echo -e "${BLUE}  from: $SCRIPT_DIR${NC}"
echo -e "${BLUE}  backup: $BACKUP${NC}"
echo -e "${BLUE}════════════════════════════════════${NC}"
mkdir -p "$CONFIG"

INSTALL_DEPS=0
opts=()
for arg in "$@"; do
  case "$arg" in
    -d|--deps) INSTALL_DEPS=1 ;;
    *) opts+=("$arg") ;;
  esac
done
set -- "${opts[@]}"

case "${1:-}" in
  -y|--yes)     for i in "${!items[@]}"; do install_one $((i+1)); done ;;
  -l|--list)    list; exit 0 ;;
  -c|--configs) shift; IFS=',' read -ra nums <<< "$1"
                for n in "${nums[@]}"; do install_one "$n"; done ;;
  -h|--help)    echo "Usage: $0 [-d] [-y] [-l] [-c N,N]"; list; exit 0 ;;
  "")           [ "$INSTALL_DEPS" = "1" ] && for i in "${!items[@]}"; do install_one $((i+1)); done
                [ "$INSTALL_DEPS" = "0" ] && interactive ;;
  *)            echo -e "${YELLOW}Unknown: $1${NC}"; exit 1 ;;
esac

if [ -d "$BACKUP" ]; then
  if [ -z "$(ls -A "$BACKUP")" ]; then rmdir "$BACKUP"
  else echo -e "\n${YELLOW}Backups: $BACKUP${NC}"
  fi
fi
echo -e "${GREEN}Done.${NC}"
