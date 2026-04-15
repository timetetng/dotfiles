# # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi
#
# ================= 1. 核心框架配置 =================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# 官方文档标准写法：将插入模式下的退出键设置为 jk
# 必须放在 plugins 加载之前
ZVM_VI_INSERT_ESCAPE_BINDKEY=jk

plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    sudo
    zsh-vi-mode
)

# 直接加载 Arch Linux 系统目录下的 fzf 脚本
if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
    source /usr/share/fzf/key-bindings.zsh
    source /usr/share/fzf/completion.zsh
fi

# zsh-vi-mode 专用配置函数
function zvm_after_init() {
  zvm_bindkey viins '^R' fzf-history-widget
  zvm_bindkey vicmd '^R' fzf-history-widget
  zvm_bindkey viins '^F' autosuggest-accept
}

source $ZSH/oh-my-zsh.sh

# ================= 2. 模块化加载 =================
ZSH_CONFIG_DIR="$HOME/.config/zsh"
mkdir -p "$ZSH_CONFIG_DIR" # 确保目录存在

# 依次加载拆分出来的配置模块
for config_file in env.zsh aliases.zsh functions.zsh lazyload.zsh; do
    if [[ -f "$ZSH_CONFIG_DIR/$config_file" ]]; then
        source "$ZSH_CONFIG_DIR/$config_file"
    fi
done

# ================= 3. 收尾工作 =================
# zoxide 的 init 是使用 Rust 编写的，速度极快，通常不需要懒加载
eval "$(zoxide init zsh --cmd j)"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# md - copy last command to clipboard
MD_CMD_NAME="md"
source "$HOME/.md/md.sh"





# clashctl START
# 加载 clashctl 命令
. /home/xingjian/clashctl/scripts/cmd/clashctl.sh
# 自动开启代理环境
watch_proxy
clashtun on > /dev/null 2>&1 
# clashctl END

fpath+=~/.zfunc; autoload -Uz compinit; compinit

zstyle ':completion:*' menu select

export UV_DEFAULT_INDEX="https://pypi.tuna.tsinghua.edu.cn/simple"
#sudo sshfs xingjian@家里云:/home/xingjian /home/xingjian/share/EQ14
TOSU_OSU_PATH=/usr/bin/osu-lazer

STATIC_FOLDER_PATH=/home/xingjian/.config/tosu/.static

# opencode
export PATH=/home/xingjian/.opencode/bin:$PATH
