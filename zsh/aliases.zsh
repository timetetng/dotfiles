# ================= 快捷命令 =================
alias l='eza -l --icons --git -a'
alias :q='exit'
alias open='xdg-open'
alias ssh='TERM=xterm-256color ssh'

# ================= 剪贴板工具 =================
alias wly='wl-copy <'
alias wlp='wl-paste'

# ================= 应用与脚本 =================
alias kvm="virt-manager &"
# 修复了原有 &; 的语法错误，改为 & 即可
alias obs-start='docker start unibarrage && startlive & dmnotifier; echo ROOM_ID:7394063'
alias music='ncmpcpp'
alias mdl='$HOME/dotfiles/scripts/python/.venv/bin/python3 $HOME/dotfiles/scripts/python/mdl.py'
