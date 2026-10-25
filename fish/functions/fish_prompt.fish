# ============================================================
#  fish_prompt —— 仿 powerlevel10k 的双行 powerline 提示符
#  配色: 墨绿底 + 浅绿字 (深->浅墨绿渐层, 高对比, 干净)
#  源自容器 /etc/fish/functions/fish_prompt.fish
# ============================================================
function fish_prompt
    set -l st $status
    set -l sep \ue0b0

    # ---- 墨绿色板 (深绿底 / 浅绿字) ----
    set -l bg_os 081C15 ; set -l fg_os 95D5B2
    set -l bg_u  1B4332 ; set -l fg_u  B7E4C7
    set -l bg_d  2D6A4F ; set -l fg_d  D8F3DC
    set -l bg_g  40916C ; set -l fg_g  D8F3DC
    set -l bg_t  1B4332 ; set -l fg_t  B7E4C7

    # ---- 1) OS 图标（自动识别：Termux→Android，其它→Arch）----
    set_color -b $bg_os $fg_os
    if test -d /data/data/com.termux/files/usr
        printf ' \uf17b '
    else
        printf ' \uf303 '
    end

    # ---- 2) user@host ----
    set_color -b $bg_u $bg_os
    printf '%s' $sep
    set -l u (whoami)
    set -l h (uname -n)
    if test -d /data/data/com.termux/files/usr
        set h termux
    end
    set_color -b $bg_u $fg_u
    printf ' %s@%s ' $u $h

    # ---- 3) 目录 ----
    set_color -b $bg_d $bg_u
    printf '%s' $sep
    set_color -b $bg_d $fg_d
    printf ' \uf07b %s ' (prompt_pwd)

    set -l prev $bg_d

    # ---- 4) git ----
    if command -q git
        set -l g (command git -C . rev-parse --abbrev-ref HEAD 2>/dev/null)
        if test -n "$g"
            set_color -b $bg_g $prev
            printf '%s' $sep
            set -l dirty ''
            if test -n (command git -C . status --porcelain 2>/dev/null)
                set dirty '*'
            end
            set_color -b $bg_g $fg_g
            printf ' \ue0a0 %s%s ' $g $dirty
            set prev $bg_g
        end
    end

    # ---- 5) 时间 ----
    set_color -b $bg_t $prev
    printf '%s' $sep
    set_color -b $bg_t $fg_t
    printf ' \uf017 %s ' (date '+%H:%M')

    # ---- 收尾 ----
    set_color $bg_t
    printf '%s' $sep
    set_color normal
    printf '\n'

    # ---- 提示符 ----
    if test $st -eq 0
        set_color 74C69D
    else
        set_color F87171
    end
    printf '\uf054 '
    set_color normal
end
