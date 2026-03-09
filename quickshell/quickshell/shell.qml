//@ pragma UseQApplication
// ^^^ 必须放在这里，所有 import 之前！

import Quickshell
import Quickshell.Wayland
import qs.Modules.Bar
import "Widget" // 引入 Widget 目录
ShellRoot {
  Bar {}
  BiliBarrageWidget {}
}

