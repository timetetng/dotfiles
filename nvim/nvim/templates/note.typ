// ============================================================
//  数学笔记 · 引用式模板（`typ init` 默认用这个）
//  · 排版定义在本地包 @local/mathnote:0.1.0：改那一处 → 所有笔记一起变
//  · 标题由 `typ init` 用文件名自动填好（下面的 __TITLE__）
//  · 预览：<Space>tp    速查表：~/notes/typst/00-cheatsheet.typ
//  · 想看写法示例：typ init -t sample
//  · 想要单文件自包含、不引用包：typ init -s <名字>
// ============================================================
#import "@local/mathnote:0.1.0": *

#show: note.with(title: "__TITLE__")

// 想单独调这篇的字间距 / 页边距 / 字号，就写成：
//   #show: note.with(title: "__TITLE__", tracking: 1pt, margin: 2.6cm, size: 12pt)

// ════════════ 正文从这里开始 ════════════
