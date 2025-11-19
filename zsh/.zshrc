# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
#plugins=(git)

plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    sudo
    extract
    docker
    autojump
    archlinux
)
source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
source /opt/clash/script/common.sh && source /opt/clash/script/clashctl.sh && watch_proxy
clashctl on
alias kvm="virt-manager &"
export VISUAL=nvim
export EDITOR=nvim
export PATH=/home/xingjian/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl

# nano2vim
nano(){
    echo "是否使用 nvim 代替(y/n)"
    read confirm
    case $confirm in
        [Yy]|[Yy][Ee][Ss])
        command nvim "$@"
        ;;
    *)
        command nano "$@"
        ;;
    esac
}
# wifi
wifi(){
 if [ -n "$1" ];then
     if [ "$1" = "wifi1" ];then
         local arg1="破解不要睡得太死"
 local passwd="3OneFour"
     elif [ "$1" = "wifi2" ];then
         local arg1="窝式嫩蝶_5G"
 local passwd="3OneFour"
     elif [ "$1" = "phone" ];then
         local arg1="TimeXingjian"
 local passwd="123456789"
     else
         echo "未知wifi,请重新输入！"
         return 1 
     fi
     nmcli device wifi list&> /dev/null && nmcli dev wifi connect $arg1
     local wifi_ok=`nmcli device | grep "已连接" | awk '{print $4}'|| echo "error"`
     echo $wifi_ok
     if [ $wifi_ok = $arg1 ];then
        notify-send "成功切换至 [$arg1] !"
     else
         notify-send "切换失败!"
     fi
 else
     nmcli device
 fi   
}
export PATH="$HOME/.local/bin:$PATH"

# yazi
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}
clear

hello(){echo "hello, xingjian!"}
so(){source ~/.zshrc}
alias farm='tail -f '/home/xingjian/.steam/steam/steamapps/compatdata/2060160/pfx/drive_c/users/steamuser/AppData/LocalLow/TheFarmerWasReplaced/TheFarmerWasReplaced/output.txt''
alias ssh='TERM=xterm-256color ssh'
function ww(){
/home/xingjian/Projects/Python/.venv/bin/python3.13 /home/xingjian/Projects/Python/wuwa_manager/wuwa_manager.py $@
}
function tf2(){
    if [ -# = 0 ];then
    /home/xingjian/Projects/sshtf/.venv/bin/python3.12 /home/xingjian/Projects/sshtf/ssh.py $@
elif [ $1 = "-c" ];then
    echo "$PWD"
    cd /home/xingjian/Projects/sshtf
    /home/xingjian/Projects/sshtf/.venv/bin/python3.12 /home/xingjian/Projects/sshtf/main.py
else
    /home/xingjian/Projects/sshtf/.venv/bin/python3.12 /home/xingjian/Projects/sshtf/main.py $@ 
fi
}

# pnpm
export PNPM_HOME="/home/xingjian/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# alias eza -> ls 
alias l='eza -l --icons --git -a'
