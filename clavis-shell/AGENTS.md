# Clavis Shell 开发约定

## Project responsibilities

Clavis 是 CMake/Ninja + QML/Quickshell 项目。`shell.qml` 是入口，`AppShell.qml`
负责顶层装配；`Modules/` 放业务模块，`Services/` 放长期状态和系统交互，`Widgets/`
只放展示控件，`Common/` 放主题、尺寸、路径和纯工具，`core/` 放原生 backend 与 QML
plugin。

三个仓库是独立项目，测试和构建不得跨仓库依赖：

- Clavis 负责 QML UI、Quickshell 生命周期、Niri IPC、窗口/工作区/输出、天气、
  WeatherMapProvider、M3Shapes、MediaPalette、键盘锁状态、实时 Cava、MPRIS 歌词和
  同步时间轴。
- `key-cli` 负责 `key shell`、`key ipc`、录屏、音频文件录制、剪贴板 backend 以及
  对外 machine JSON protocol。
- `keytop` 唯一负责系统指标采集、解析、TUI 和 JSON/JSONL machine protocol；Clavis
  直接消费 `keytop value stream --format jsonl`，不得在 Clavis 重新实现 keytop parser。

Clavis 测试必须在单独 clone 后成立，不能依赖 `../keytop`、`../key-cli` 或它们的构建
产物。不得恢复 `cast`、`key top`、`key sysmon`、Clavis.Sysmon、天气 CLI 中转、Python
歌词脚本、内嵌 C++ key CLI、release manager、rollback、`current` 软链接、`releases/`、
`setup.sh`、`justfile` 或 Makefile。参考仓库只读，不能修改。

## Build

顶层 CMake 统一构建原生 module、测试和 QML 源码安装，不调用 sudo：

```bash
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build build
ctest --test-dir build --output-on-failure
```

开发入口是 `~/.config/quickshell/clavis` 指向当前源码；稳定外部入口使用
`${CLAVIS_KEY:-key}`。开发原生 module 使用：

```bash
QML_IMPORT_PATH="$PWD/build/qml${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}" key shell
```

不能把仓库绝对路径或构建路径写入用户 Niri 配置。IPC 文档和快捷键使用 `key ipc ...`，
不使用裸 `quickshell ipc`。

## QML modules

- `import qs.Common`、`import qs.Services`、`import qs.Modules.Foo` 是 Quickshell
  root-relative shell modules。纯 QML 目录不得新增手写 `qmldir`。
- `import Clavis.Weather`、`import Clavis.WeatherMap`、`import Clavis.Cava`、
  `import Clavis.Lyrics` 等 native imports 由 CMake 的 `qt_add_qml_module()` 管理，
  不添加无意义的版本号。
- Native QML module 的 build-tree 输出统一在 `build/qml/`；`qmldir`、`*.qmltypes`、
  plugin 是 CMake/Qt 生成物，不能手写或编辑。
- 展示组件不得创建 `Process` 或执行系统命令。录屏、录音和剪贴板通过带参数数组的
  `key` 调用，必须校验 machine response 的 `schemaVersion` 和错误。
- FFmpeg、pactl、ffprobe、录音 PID、临时音频文件和 finalizer 属于 `key audio`；歌词
  获取、缓存、LRC 解析和 MPRIS seek 属于 `Clavis.Lyrics`。

## QML tooling

`.qmlls.ini` 是 Quickshell 生成的机器相关文件，已加入 `.gitignore`，不得提交。正确
流程是先 configure/build native modules，再由 `scripts/dev/lint-qml.sh` 通过 Quickshell
生成或刷新 tooling VFS，读取其中的 `buildDir` 和 `importPaths`，最后把真实路径作为
`-I` 传给 `qmllint`。如果 offscreen 环境不能生成有效 VFS，脚本必须失败并报告人工
恢复命令，不得伪造 lint 成功。

```bash
scripts/dev/format-qml.sh
scripts/dev/format-qml.sh --check
scripts/dev/lint-qml.sh
```

`.qmlformat.ini` 使用 4 空格、Unix newline、禁止 tab，并关闭激进 import/order
normalize。普通 format/check 只处理当前改动的 QML，避免 legacy tree 被批量重写；只有
明确要迁移整棵树时才使用 `scripts/dev/format-qml.sh --all`。除非确有语义需要，不要
借格式化顺手重排大范围属性或对象。

## Test Policy

质量检查和 tests 分开。`qmllint`、`qmlformat`、`clang-format`、`bash -n`、
`shellcheck`、Python `compileall`、compiler warnings、build 和 `git diff --check` 是
quality checks，不是 tests。

**Do not add tests automatically just because code was changed.**

**Fixing a bug does not automatically require a regression test.**

新增 test 前必须能够说明：

1. 测试验证的 stable behavior 或 public contract 是什么；
2. 为什么 lint/build 无法覆盖它；
3. 为什么 unit test 或必要的 integration test 是合适层级；
4. 为什么测试不会锁死当前实现细节。

允许的 Clavis tests 主要是 deterministic C++ unit tests（parser、geometry/math、工作区
拓扑推导、坐标转换、壁纸分析、歌词解析、路径/config resolution、状态变换）、少量
纯 QML/JavaScript state/math QtTest，以及真正验证外部行为的脚本 integration test。
QML UI、Button、Loader、动画、颜色、Item hierarchy、compositor timing 和普通视觉
layout 默认不新增 QtTest。

绝对禁止通过 `grep`、`sed`、`awk`、regex、source text matching 来断言 property、
Loader、id、Item child、函数名、文件布局、当前 object hierarchy 或 feature 的实现
形状。禁止创建 `test_*_architecture.sh`、`test_*_feature.sh`、
`test_*_implementation.sh`，也不要恢复历史 smoke QML。CTest 只能注册真正的 unit 或
必要 integration test，不注册 source audit。

不要追求 coverage %，不要引入 coverage.py/gcov/lcov/codecov/threshold，也不要为了
本任务引入 clang-tidy、`-Werror`、mypy、pyright 或大型 pre-commit 体系。

## Validation

Codex 应优先运行已有质量入口，而不是为当前任务临时发明测试：

```bash
git diff --check
scripts/dev/format-qml.sh --check
scripts/dev/lint-qml.sh
scripts/dev/check.sh
```

`check.sh` 还会运行 first-party C++ clang-format check、shell syntax/shellcheck、
Python compileall、CMake configure/build 和 CTest。它不得 install、sudo、修改系统或
启动持久后台服务。默认不安装、不重启进程、不提交；只有用户明确要求时才执行这些
外部操作。不得编辑 `build/`、用户 Niri 配置、系统 Qt import 根或已安装文件来修复
源码。

## 本机环境（xingjian 的 arch，2026-10-26）

这份仓库在本机是**实跑**的桌面壳，不是只读快照。改动前先读这节，别把下面这些
"看起来像 bug"的东西当 bug 改掉。

### 启动方式
- 启动脚本 `~/.config/niri/scripts/quickshell-clavis.sh`，niri 里 spawn：
  `prime-run qs -p ~/Projects/clavis -n`
- **必须走 prime-run（NVIDIA RTX 3050）**。核显渲染时灵动岛歌词态掉到 ~15fps，
  机主明确不接受，别"优化"成核显。
- 脚本里有一个看门狗循环：qs 退出后 1 秒自动重启；若会话仍锁定
  （`loginctl show-session <id> -p LockedHint`）则补 `qs ipc -p ... call lock open`；
  连崩 10 次放弃，稳定跑过 60 秒计数清零。
- 重载 Clavis：`pkill qs`（看门狗会拉回）。彻底停掉：`pkill -f quickshell-clavis.sh`。

### 锁屏 / suspend（重要）
- 锁屏走 `WlSessionLock`（ext-session-lock）。**niri 一旦锁定，锁屏界面只属于
  当初申请锁的那个客户端**；客户端死了 niri 不会解锁，只会剩一个没有表面的锁定态
  （屏幕上是一整片主题色红，就是 `colLayer0Base`）。
- 历史事故：suspend/resume 后 qs 退出，日志里最后一行是
  `eglSwapBuffers failed with 0x3000` —— prime-run 的 EGL 上下文随 dGPU 掉电被销毁。
  已做的缓解：
  1. `/etc/modprobe.d/nvidia-power-management.conf`：`NVreg_PreserveVideoMemoryAllocations=1`
     ＋ `NVreg_TemporaryFilePath=/var/tmp`（`/tmp` 是 4G tmpfs，放不下 4G VRAM），
     `nvidia-suspend/resume.service` 已 enable。长睡眠有效，短间隔连续挂起仍会丢。
  2. 看门狗自动重启 + 补锁（见上）。
  3. 锁屏期间重启的实例**抓不到桌面快照**，抓到的只会是锁屏画面本身，所以重启时
     `CLAVIS_LOCK_NO_SNAPSHOT=1` 让 `LockWarmup.qml` 直接放弃快照；
     `LockSurface.qml` 背景退回 `WallpaperService.currentWallpaper`。
- 改了 `LockSurface.qml` / `LockWarmup.qml` 的背景逻辑，别再退回"没快照就显示纯色"。

### 未决
- suspend 偶发 6~9 秒自醒（`pm_wakeup_irq=9`，ACPI SCI），怀疑 2.4G 无线接收器；
  记录器 `/usr/lib/systemd/system-sleep/50-log-wake` → `/var/lib/pm-wake/wake.log`
  （记 suspend 前后 GPE/SCI 计数差）。
