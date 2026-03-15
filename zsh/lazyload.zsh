# ================= TheFuck 懒加载 =================
# 原来的 eval $(thefuck --alias) 每次打开终端都会执行，非常耗时
# 现在的做法：只有在你第一次输入 fuck 时，才初始化并执行
fuck() {
    unfunction fuck
    eval $(thefuck --alias)
    fuck "$@"
}

# ================= Conda 懒加载 =================
conda() {
    unfunction conda
    local conda_path="/home/xingjian/miniconda3"
    
    __conda_setup="$('$conda_path/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "$conda_path/etc/profile.d/conda.sh" ]; then
            . "$conda_path/etc/profile.d/conda.sh"
        else
            export PATH="$conda_path/bin:$PATH"
        fi
    fi
    unset __conda_setup
    
    conda "$@"
}
