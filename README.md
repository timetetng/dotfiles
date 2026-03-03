# Dotfiles

个人 Linux Dotfiles 配置，管理 Hyprland、Neovim、Zsh、Kitty 等应用的设置。

## 📂 目录结构 (Directory Structure)

- **fastfetch**: 系统信息工具配置。
- **fcitx5**: 输入法框架设置。
- **hyprland**:
  - `hypr`: 核心 Hyprland 配置、脚本和壁纸。
  - `hyprpanel`: HyprPanel 的配置。
  - `waybar`: 状态栏配置。
- **kitty**: 终端模拟器配置和主题。
- **niri**: 可滚动平铺窗口管理器配置。
- **nvim**: Neovim 配置 (基于 LazyVim)。
- **theme**: 全局主题 (GTK, Fontconfig 等)。
- **yazi**: 终端文件管理器配置。
- **zsh**: Zsh Shell 配置和 Oh-My-Zsh 设置。

## 🚀 安装 (Installation)

### 1. 前置条件 (Prerequisites)

请确保您已安装 `git` 以克隆此仓库。

```bash
sudo pacman -S git  # Arch Linux
# sudo apt install git  # Debian/Ubuntu
```

### 2. 克隆仓库 (Clone the Repository)

将此仓库克隆到您的家目录 (或任何您喜欢的路径)：

```bash
git clone https://github.com/timetetng/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 3. 运行安装脚本 (Run the Installation Script)

随附的 `install.sh` 脚本将自动创建从本仓库到系统配置目录 (例如 `~/.config/`) 的符号链接。现有的配置将被备份。

```bash
chmod +x install.sh
./install.sh
```

**脚本功能 (What the script does):**

- 将现有的配置文件备份到 `~/.dotfiles_backup_<timestamp>/`。
- 为所有受管理的配置创建符号链接。
- 设置 `zsh` 和 `.oh-my-zsh` 的链接到 `~/`。

## 📦 软件要求 (Software Requirements)

这些 Dotfiles 专为 **Arch Linux** 定制。

安装核心依赖项：

```bash
sudo pacman -S git zsh neovim hyprland waybar kitty yazi fastfetch fcitx5-im fcitx5-chinese-addons nwg-look eza thefuck autojump npm
```

**详细要求 (Detailed Requirements):**

### 核心 (Core)

- **窗口管理器 (Window Manager)**: [Hyprland](https://hyprland.org/) 或 [Niri](https://github.com/YaLTeR/niri)
- **Shell**: [Zsh](https://www.zsh.org/) (`.oh-my-zsh` 插件已包含在配置中)
- **终端 (Terminal)**: [Kitty](https://sw.kovidgoyal.net/kitty/)
- **编辑器 (Editor)**: [Neovim](https://neovim.io/) (推荐 >= 0.9.0 版本)

### 命令行工具 (CLI Tools)

- **eza**: 现代 `ls` 替代品。
- **thefuck**: 纠正您上一个控制台命令的应用程序。
- **autojump**: 更快地导航文件系统的方式。
- **npm** / **pnpm**: Node 包管理器。
- **Fastfetch**: 系统信息工具。

### 桌面工具 (Desktop Utilities)

- **状态栏 (Bar)**: [Waybar](https://github.com/Alexays/Waybar)
- **启动器 (Launcher)**: `wofi` 或 `rofi` (检查 Hyprland 配置中的绑定)
- **文件管理器 (File Manager)**: [Yazi](https://github.com/sxyazi/yazi)
- **输入法 (Input Method)**: [Fcitx5](https://fcitx-im.org/wiki/Fcitx_5) (带 Rime/Pinyin)
- **主题管理器 (Theme Manager)**: `nwg-look` (用于 GTK 主题)

### 字体 (Fonts)

- [Nerd Fonts](https://www.nerdfonts.com/) (Waybar、Neovim、Yazi 等中的图标需要。推荐：**JetBrainsMono Nerd Font**)

## 🛠️ 手动配置说明 (Manual Notes)

- **壁纸 (Wallpapers)**: `hyprland/hypr/scripts/` 中的壁纸脚本可能依赖于特定的路径。请检查 `hyprland/hypr/hyprland.conf` 中的壁纸处理 (通常使用 `swww` 或 `hyprpaper`)。
- **GTK 主题 (GTK Themes)**: 如果 GTK 设置未自动应用，请使用 `nwg-look` 进行验证。
- **Neovim**: 首次启动时，LazyVim 将自动安装插件。

---

# English Version

# Dotfiles Configuration

User's personal dotfiles configuration for Linux, managing settings for Hyprland, Neovim, Zsh, Kitty, and more.

## 📂 Directory Structure

- **fastfetch**: System information tool configuration.
- **fcitx5**: Input method framework settings.
- **hyprland**:
  - `hypr`: Core Hyprland configuration, scripts, and wallpapers.
  - `hyprpanel`: Configuration for HyprPanel.
  - `waybar`: Status bar configuration.
- **kitty**: Terminal emulator configuration and themes.
- **niri**: Scrollable tiling window manager configuration.
- **nvim**: Neovim configuration (LazyVim based).
- **theme**: System-wide theming (GTK, Fontconfig, etc.).
- **yazi**: Terminal file manager configuration.
- **zsh**: Zsh shell configuration and Oh-My-Zsh setup.

## 🚀 Installation

### 1. Prerequisites

Ensure you have `git` installed to clone this repository.

```bash
sudo pacman -S git  # Arch Linux
# sudo apt install git  # Debian/Ubuntu
```

### 2. Clone the Repository

Clone this repository to your home directory (or any preferred location):

```bash
git clone https://github.com/timetetng/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 3. Run the Installation Script

The included `install.sh` script will automatically create symbolic links from this repository to your system's configuration directories (e.g., `~/.config/`). Existing configurations will be backed up.

```bash
chmod +x install.sh
./install.sh
```

**What the script does:**

- Backs up existing config files to `~/.dotfiles_backup_<timestamp>/`.
- Creates symlinks for all managed configurations.
- Sets up `zsh` and `.oh-my-zsh` links in `~/`.

## 📦 Software Requirements

These dotfiles are tailored for **Arch Linux**.

To install the core dependencies:

```bash
sudo pacman -S git zsh neovim hyprland waybar kitty yazi fastfetch fcitx5-im fcitx5-chinese-addons nwg-look eza thefuck autojump npm
```

**Detailed Requirements:**

### Core

- **Window Manager**: [Hyprland](https://hyprland.org/) or [Niri](https://github.com/YaLTeR/niri)
- **Shell**: [Zsh](https://www.zsh.org/) (Plugins included in `.oh-my-zsh`)
- **Terminal**: [Kitty](https://sw.kovidgoyal.net/kitty/)
- **Editor**: [Neovim](https://neovim.io/) (>= 0.9.0)

### CLI Tools

- **eza**: Modern replacement for `ls`.
- **thefuck**: App corrects your previous console command.
- **autojump**: A faster way to navigate your filesystem.
- **npm** / **pnpm**: Node package managers.
- **Fastfetch**: System information.

### Desktop Utilities

- **Bar**: [Waybar](https://github.com/Alexays/Waybar)
- **Launcher**: `wofi` or `rofi` (check Hyprland config for binding)
- **File Manager**: [Yazi](https://github.com/sxyazi/yazi)
- **Input Method**: [Fcitx5](https://fcitx-im.org/wiki/Fcitx_5) (with Rime/Pinyin)
- **Theme Manager**: `nwg-look` (for GTK theming)

### Fonts

- [Nerd Fonts](https://www.nerdfonts.com/) (Required for icons in Waybar, Neovim, Yazi, etc. Recommended: **JetBrainsMono Nerd Font**)

## 🛠️ Manual Notes

- **Wallpapers**: Wallpaper scripts in `hyprland/hypr/scripts/` may rely on specific paths. Check `hyprland/hypr/hyprland.conf` for wallpaper handling (often uses `swww` or `hyprpaper`)。
- **GTK Themes**: Use `nwg-look` to verify GTK settings if they don't apply automatically.
- **Neovim**: Upon first launch, LazyVim will automatically install plugins.
