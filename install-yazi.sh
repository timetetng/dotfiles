#!/bin/bash
set -e

YAZI_VERSION="26.1.22"
REPO_URL="http://10.0.0.2:3333/timetetng/dotfiles.git"
CONFIG_DIR="$HOME/.config/yazi"
DOTFILES_DIR="/tmp/dotfiles-yazi-$$"

echo "==> Installing yazi binary..."
curl -LsSf "https://github.com/sxyazi/yazi/releases/download/v${YAZI_VERSION}/yazi-x86_64-unknown-linux-musl.zip" -o /tmp/yazi.zip
unzip -o /tmp/yazi.zip -d /tmp/yazi_bin
mv /tmp/yazi_bin/yazi-x86_64-unknown-linux-musl/yazi /usr/local/bin/
mv /tmp/yazi_bin/yazi-x86_64-unknown-linux-musl/ya /usr/local/bin/
chmod +x /usr/local/bin/yazi /usr/local/bin/ya
rm -rf /tmp/yazi.zip /tmp/yazi_bin

echo "==> Cloning dotfiles (no_proxy)..."
no_proxy="*" git clone --depth=1 "$REPO_URL" "$DOTFILES_DIR"

echo "==> Copying yazi config..."
mkdir -p "$CONFIG_DIR"
cp -r "$DOTFILES_DIR/yazi/"* "$CONFIG_DIR/"

echo "==> Installing plugins..."
no_proxy="*" ya pkg install

echo "==> Cleaning up..."
rm -rf "$DOTFILES_DIR"

echo "==> Done! Run 'yazi' to start."
