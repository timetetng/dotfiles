# dotfiles

个人 Linux 桌面配置。覆盖 Hyprland / Niri 双窗口管理器、QuickShell QML 面板、Neovim、Zsh、Kitty 等。

## 配置清单

| 条目 | 路径 | 说明 |
|------|------|------|
| cava | `~/.config/cava` | 音频可视化 |
| fastfetch | `~/.config/fastfetch` | 系统信息 |
| fcitx5 | `~/.config/fcitx5` | 输入法框架（Rime） |
| foot | `~/.config/foot` | 轻量终端 |
| hypr | `~/.config/hypr` | Hyprland 窗口管理器核心 |
| hyprpanel | `~/.config/hyprpanel` | HyprPanel 面板 |
| waybar | `~/.config/waybar` | Waybar 状态栏 |
| kitty | `~/.config/kitty` | 终端模拟器 |
| mpd | `~/.config/mpd` | 音乐播放守护 |
| ncmpcpp | `~/.config/ncmpcpp` | MPD 客户端 |
| niri | `~/.config/niri` | Niri 滚动平铺 WM |
| nvim | `~/.config/nvim` | Neovim（LazyVim） |
| quickshell | `~/.config/quickshell` | QML 面板/组件系统 |
| rofi | `~/.config/rofi` | 应用启动器 |
| theme/fontconfig | `~/.config/fontconfig` | 字体配置 |
| theme/gtk-3.0 | `~/.config/gtk-3.0` | GTK3 主题 |
| theme/gtk-4.0 | `~/.config/gtk-4.0` | GTK4 主题 |
| theme/nwg-look | `~/.config/nwg-look` | nwg-look 配置 |
| theme/xsettingsd | `~/.config/xsettingsd` | X 设置守护 |
| wlogout | `~/.config/wlogout` | 注销/关机界面 |
| yazi | `~/.config/yazi` | 终端文件管理器 |
| zsh | `~/.zshrc` | Zsh 配置 |

## 安装

```bash
git clone https://github.com/timetetng/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

安装脚本支持：
- **交互式多选** — 逐个勾选要安装的配置项
- `./install.sh -y` — 安装全部
- `./install.sh -c "1,3,5"` — 指定编号安装
- `./install.sh -d -c 1,3,5` — 安装指定配置并自动补齐系统依赖
- `./install.sh -d -y` — 安装全部配置及依赖

## 依赖

脚本 `-d` 参数会自动安装缺失的包（通过 pacman 或 yay/paru）。
也可手动安装：

```bash
sudo pacman -S git zsh neovim kitty yazi fastfetch fcitx5-im fcitx5-chinese-addons nwg-look
```

AUR 包（hyprpanel、wlogout）需通过 yay/paru 安装。
