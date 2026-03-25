# ================= 常用函数 =================
hello() { echo "hello, xingjian!" }
so() { source ~/.zshrc; echo "Zsh config reloaded." }

# ================= 代理切换开关 =================
# 优化建议：不要默认全局 export 代理，而是用命令按需开启/关闭
proxy_on() {
    export https_proxy=http://127.0.0.1:7890
    export http_proxy=http://127.0.0.1:7890
    export all_proxy=socks5://127.0.0.1:7890
    echo -e "终端代理已开启。"
}

proxy_off() {
    unset http_proxy https_proxy all_proxy
    echo -e "终端代理已关闭。"
}

# ================= Yazi 增强 =================
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

# ================= Nano 拦截 =================
nano() {
    echo "是否使用 nvim 代替(y/n)?"
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

# ================= Wifi 助手 =================
wifi() {
    if [ -n "$1" ]; then
        local arg1=""
        local passwd=""
        if [ "$1" = "wifi1" ]; then
            arg1="破解不要睡得太死"
            passwd="3OneFour"
        elif [ "$1" = "wifi2" ]; then
            arg1="窝式嫩蝶_5G"
            passwd="3OneFour"
        elif [ "$1" = "phone" ]; then
            arg1="TimeXingjian"
            passwd="123456789"
        else
            echo "未知wifi,请重新输入！"
            return 1 
        fi
        # 优化：添加密码参数以防尚未保存的网络连接失败
        nmcli device wifi list &> /dev/null && nmcli dev wifi connect "$arg1" password "$passwd"
        local wifi_ok=$(nmcli device | grep "已连接" | awk '{print $4}' || echo "error")
        echo "$wifi_ok"
        if [ "$wifi_ok" = "$arg1" ]; then
            notify-send "成功切换至 [$arg1] !"
        else
            notify-send "切换失败!"
        fi
    else
        nmcli device
    fi   
}


# 定义完整的插件初始化后置钩子函数，确保在插件完全加载后强制覆盖
function zvm_after_init() {
    # 强制开启自定义光标支持
    export ZVM_CURSOR_STYLE_ENABLED=true
    
    # 强制将各模式光标变量设为闪烁状态
    export ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BEAM
    export ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BLOCK
    export ZVM_VISUAL_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BLOCK
    export ZVM_VISUAL_LINE_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BLOCK
    export ZVM_OPPEND_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BLOCK
    
    # 移除失效的内部函数调用，改为直接向 foot 终端发送转义序列
    # \e[5 q 代表闪烁竖线，确保终端刚打开时处于 Insert 模式且光标闪烁
    echo -ne '\e[5 q'
}

# 下载 X (Twitter) 视频的快捷函数
xdl() {
    # 检查是否传入了参数
    if [[ -z "$1" ]]; then
        echo "错误：请提供至少一个 X (Twitter) 视频链接。"
        echo "用法: dlx <推文链接> [更多链接...]"
        return 1
    fi

    # 确保目标文件夹存在，防止 yt-dlp 因目录缺失报错
    mkdir -p "/home/xingjian/Videos/Twitter"

    # 执行下载，使用 "$@" 允许你一次性粘贴多个链接进行批量下载
    yt-dlp --cookies-from-browser firefox \
           -o "/home/xingjian/Videos/Twitter/%(uploader)s_%(id)s.%(ext)s" \
           "$@"
}
