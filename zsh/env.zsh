# ================= 编辑器与全局变量 =================
export VISUAL=nvim
export EDITOR=nvim
export KAGGLE_API_TOKEN="KGAT_4e505ab0417060ce24769055c39b5137"

# ================= 开发环境配置 =================
export GOPATH="$HOME/go"
export JAVA_HOME="/usr/lib/jvm/java-21-openjdk"
export PNPM_HOME="$HOME/.local/share/pnpm"

# ================= PATH 统一管理 =================
# 建议按照优先级把所有自定义 PATH 放在这里统一组合，避免重复 export
typeset -U PATH # 保证 PATH 中的路径不重复
export PATH="\
$HOME/bin:\
$HOME/.local/bin:\
$PNPM_HOME:\
$HOME/.npm-global/bin:\
$HOME/.cargo/bin:\
$JAVA_HOME/bin:\
$GOPATH/bin:\
/usr/local/sbin:\
/usr/local/bin:\
/usr/bin:\
/usr/bin/site_perl:\
/usr/bin/vendor_perl:\
/usr/bin/core_perl:\
$PATH"
