# ============================================================
#  fish config (移植自容器 xingjian 的那套, 2026-10-25)
# ============================================================

# ---------- 环境变量 ----------
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx GOPATH $HOME/go
set -gx JAVA_HOME /usr/lib/jvm/java-21-openjdk
set -gx PNPM_HOME $HOME/.local/share/pnpm

# ---------- PATH ----------
fish_add_path -g $HOME/bin $HOME/.local/bin $PNPM_HOME $HOME/.npm-global/bin $HOME/.cargo/bin $JAVA_HOME/bin $GOPATH/bin

# ============================================================
#  交互式
# ============================================================
if status is-interactive
    set -g fish_greeting ""

    # ---- 恢复 clashctl 终端代理状态（上次 clashon/clashoff 的结果） ----
    if test -f $HOME/.cache/clashctl/proxy.fish
        source $HOME/.cache/clashctl/proxy.fish
    end

    # ---- zoxide ----
    if command -q zoxide
        zoxide init fish --cmd j | source
    end

    # ---- 终端代理：mihomo 在监听就自动启用（相当于开机 clashctl on）----
    if command -q ss
        if ss -ltn 2>/dev/null | string match -q '*127.0.0.1:7890*'
            set -gx http_proxy http://127.0.0.1:7890
            set -gx https_proxy http://127.0.0.1:7890
            set -gx all_proxy socks5h://127.0.0.1:7890
        end
    end

    # ---- fzf ----
    if command -q fzf
        fzf --fish 2>/dev/null | source
    end

    # ---- 别名 ----
    if command -q eza
        alias l  'eza -l --icons --git -a'
        alias ls 'eza --icons --group-directories-first'
        alias ll 'eza -l --icons --group-directories-first --git'
        alias la 'eza -la --icons --group-directories-first --git'
        alias lt 'eza --tree --level=2 --icons'
    end
    abbr --add :q 'exit'
    if command -q xdg-open
        alias open 'xdg-open'
    end
    function ssh
        TERM=xterm-256color command ssh $argv
    end
    if command -q nvim
        alias nv   nvim
        alias nivm nvim
        alias vim  nvim
    end
    if command -q bat
        alias cat 'bat --style=grid,header'
    end
    function cp
        command cp --reflink=auto $argv
    end
    if command -q wl-copy
        alias wly 'wl-copy'
    end
    if command -q wl-paste
        alias wlp 'wl-paste'
    end
    if command -q ncmpcpp
        alias mu 'ncmpcpp'
    end
    alias ..   'cd ..'
    alias ...  'cd ../..'
    alias df   'df -h'
    alias free 'free -h'
end

# ============================================================
#  常用函数
# ============================================================
function hello
    echo "hello, xingjian!"
end

function so
    source ~/.config/fish/config.fish
    echo "Fish config reloaded."
end

# ---- 代理开关 ----
function proxy_on
    set -gx https_proxy http://127.0.0.1:7890
    set -gx http_proxy  http://127.0.0.1:7890
    set -gx all_proxy   socks5://127.0.0.1:7890
    echo "终端代理已开启。"
end

function proxy_off
    set -e https_proxy http_proxy all_proxy
    echo "终端代理已关闭。"
end

# ---- Yazi 增强 (退出时 cd 到其目录) ----
function y
    if not command -q yazi
        echo "yazi 未安装" >&2
        return 1
    end
    set -l tmp (mktemp -t yazi-cwd.XXXXXX)
    yazi $argv --cwd-file="$tmp"
    if read -z cwd < "$tmp"
        if test -n "$cwd"; and test "$cwd" != "$PWD"
            builtin cd -- "$cwd"
        end
    end
    rm -f -- "$tmp"
end

# ---- Nano 拦截 ----
function nano
    if command -q nvim
        echo "是否使用 nvim 代替(y/n)?"
        read -l confirm
        switch $confirm
            case Y y Yes yes
                command nvim $argv
            case '*'
                command nano $argv
        end
    else
        command nano $argv
    end
end

# ---- TheFuck 懒加载 ----
function fuck
    functions -e fuck
    if command -q thefuck
        thefuck --alias | source
        fuck $argv
    else
        echo "thefuck 未安装" >&2
        return 1
    end
end

# ---- Conda 懒加载 ----
function conda
    functions -e conda
    set -l cpath $HOME/miniconda3
    if test -x $cpath/bin/conda
        eval $cpath/bin/conda "shell.fish" "hook" $argv | source
    else
        echo "conda 未安装" >&2
        return 1
    end
end

# ---- 下载 X(Twitter) 视频 ----
function xdl
    if test (count $argv) -eq 0
        echo "错误：请提供至少一个 X (Twitter) 视频链接。"
        return 1
    end
    if not command -q yt-dlp
        echo "yt-dlp 未安装" >&2
        return 1
    end
    mkdir -p $HOME/Videos/Twitter
    yt-dlp -o "$HOME/Videos/Twitter/%(uploader)s_%(id)s.%(ext)s" $argv
end

# ---- Wifi 助手 ----
function wifi
    if not command -q nmcli
        echo "nmcli 在当前环境不可用" >&2
        return 1
    end
    nmcli device
end

# ---- tmux 弹窗别名 ----
if set -q TMUX
    function __kdwithtmuxpopup
        tmux display-popup "kd $argv"
    end
    alias kd __kdwithtmuxpopup
end

# fastfetch 手动触发
if command -q fastfetch
    alias ff fastfetch
end
