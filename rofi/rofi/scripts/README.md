# 壁纸模糊背景

`blur-common.bash` 提供两个函数，让 rofi 启动器自动用当前壁纸（含模糊缓存）做背景。

## 用法

```bash
source "$HOME/.config/rofi/rofi/scripts/blur-common.bash"
rofi_blur -show drun -theme "path/to/theme.rasi"
```

`rofi_blur` 等价于 `rofi` 并自动追加三条 `-theme-str` 覆盖背景。同一主题内其余启动器只需把 `rofi` 替换成 `rofi_blur` 即可。
