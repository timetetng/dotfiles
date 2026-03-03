#!/bin/bash

# Dotfiles Installation Script
# Author: Gemini (Modified)
# Description: Modular installer with interactive menu.

set -e # Exit on error

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
CONFIG_DIR="$HOME/.config"

# Colors for pretty printing
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}       Dotfiles Installer v2.0          ${NC}"
echo -e "${BLUE}========================================${NC}"
echo "Source: $DOTFILES_DIR"
echo "Target: $HOME"
echo "Backup: $BACKUP_DIR"
echo -e "${BLUE}========================================${NC}"

# Ensure Config Directory exists
mkdir -p "$CONFIG_DIR"

# --- Utility Functions ---

# Usage: link_config <source_rel_path> <dest_abs_path>
link_config() {
  local src="$DOTFILES_DIR/$1"
  local dest="$2"
  local dest_dir="$(dirname "$dest")"

  # Check if source exists
  if [ ! -e "$src" ]; then
    echo -e "${YELLOW}⚠️  Warning: Source '$1' does not exist. Skipping...${NC}"
    return
  fi

  # Create destination parent directory if it doesn't exist
  if [ ! -d "$dest_dir" ]; then
    echo "📂 Creating directory: $dest_dir"
    mkdir -p "$dest_dir"
  fi

  # Handle existing destination
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    local current_link
    if [ -L "$dest" ]; then
      current_link="$(readlink "$dest")"
      if [ "$current_link" == "$src" ]; then
        echo -e "${GREEN}✅ Already linked: $dest${NC}"
        return
      fi
    fi

    echo "📦 Backing up existing $dest..."
    mkdir -p "$BACKUP_DIR"
    local backup_path="$BACKUP_DIR/$(basename "$dest")_$(date +%s)"
    mv "$dest" "$backup_path"
  fi

  # Create symlink
  echo "🔗 Linking $src -> $dest"
  ln -s "$src" "$dest"
}

# --- Module Functions ---

install_shell() {
  echo -e "\n${BLUE}👉 Installing Shell & Terminal Configs (Zsh, Kitty, Fastfetch)...${NC}"
  link_config "fastfetch" "$CONFIG_DIR/fastfetch"
  link_config "kitty/kitty" "$CONFIG_DIR/kitty"
  link_config "zsh/.zshrc" "$HOME/.zshrc"
  # Optional: check if oh-my-zsh exists before linking custom folder
  if [ -d "$HOME/.oh-my-zsh" ]; then
    link_config "zsh/.oh-my-zsh" "$HOME/.oh-my-zsh"
  else
    echo -e "${YELLOW}⚠️  Oh-My-Zsh not found in $HOME, skipping .oh-my-zsh link.${NC}"
  fi
}

install_wm() {
  echo -e "\n${BLUE}👉 Installing Window Manager (Hyprland, Waybar, Niri)...${NC}"
  link_config "hyprland/hypr" "$CONFIG_DIR/hypr"
  link_config "hyprland/hyprpanel" "$CONFIG_DIR/hyprpanel"
  link_config "hyprland/waybar" "$CONFIG_DIR/waybar"
  link_config "niri" "$CONFIG_DIR/niri"

  echo "🔒 Setting executable permissions for WM scripts..."
  chmod +x "$CONFIG_DIR/hypr/scripts/"* 2>/dev/null || true
  chmod +x "$CONFIG_DIR/waybar/scripts/"* 2>/dev/null || true
  chmod +x "$CONFIG_DIR/waybar/tools/"* 2>/dev/null || true
}

install_tools() {
  echo -e "\n${BLUE}👉 Installing Tools (Nvim, Yazi, Fcitx5)...${NC}"
  link_config "nvim/nvim" "$CONFIG_DIR/nvim"
  link_config "yazi/yazi" "$CONFIG_DIR/yazi"
  link_config "fcitx5/fcitx5" "$CONFIG_DIR/fcitx5"
}

install_theme() {
  echo -e "\n${BLUE}👉 Installing Themes (GTK, Fonts, etc)...${NC}"
  link_config "theme/fontconfig" "$CONFIG_DIR/fontconfig"
  link_config "theme/gtk-3.0" "$CONFIG_DIR/gtk-3.0"
  link_config "theme/gtk-4.0" "$CONFIG_DIR/gtk-4.0"
  link_config "theme/nwg-look" "$CONFIG_DIR/nwg-look"
  link_config "theme/xsettingsd" "$CONFIG_DIR/xsettingsd"
}

install_all() {
  install_shell
  install_wm
  install_tools
  install_theme
}

# --- Main Logic ---

usage() {
  echo -e "${BLUE}Please select an installation option:${NC}"
  echo "1) 🚀 Install EVERYTHING (Recommended)"
  echo "2) 🐚 Shell Only (Zsh, Kitty, Fastfetch)"
  echo "3) 🖼️  Window Manager Only (Hyprland, Waybar...)"
  echo "4) 🛠️  Tools Only (Nvim, Yazi, Fcitx5)"
  echo "5) 🎨 Theme Only (GTK, Fontconfig)"
  echo "q) ❌ Quit"
}

# Allow -y or --yes flag for non-interactive full install
if [[ "$1" == "-y" || "$1" == "--yes" ]]; then
  install_all
  exit 0
fi

while true; do
  usage
  read -p "Select option [1-5/q]: " choice
  case $choice in
  1)
    install_all
    break
    ;;
  2)
    install_shell
    break
    ;;
  3)
    install_wm
    break
    ;;
  4)
    install_tools
    break
    ;;
  5)
    install_theme
    break
    ;;
  q | Q)
    echo "Exiting..."
    exit 0
    ;;
  *) echo -e "${YELLOW}Invalid option, please try again.${NC}" ;;
  esac
done

echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}✅ Installation process finished!${NC}"
if [ -d "$BACKUP_DIR" ]; then
  # Check if backup directory is empty
  if [ -z "$(ls -A "$BACKUP_DIR")" ]; then
    rmdir "$BACKUP_DIR"
  else
    echo -e "📦 Backups saved to: ${YELLOW}$BACKUP_DIR${NC}"
  fi
fi
echo -e "${YELLOW}⚠️  Note: Restart shell or logout/login for changes to take effect.${NC}"
echo -e "${BLUE}========================================${NC}"
