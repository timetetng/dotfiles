// ============================================================
//  数学笔记 · 自包含模板（`typ init -s` 用这个）
//  · 排版定义整段就在这个文件里，不 import 本地包 —— 单文件自包含、能直接发给别人
//  · 标题由 `typ init` 用文件名自动填好（下面的 __TITLE__）
//  · 预览：<Space>tp    速查表：~/notes/typst/00-cheatsheet.typ
//  · 想「改一处、所有笔记同步」：用默认模板（引用 @local/mathnote:0.1.0）
// ============================================================

// ── 页面与字体 ──────────────────────────────────────────
#set page(
  paper: "a4",
  margin: (x: 2.4cm, y: 2.2cm),
  numbering: "1",
)
#set text(
  font: ("New Computer Modern", "Noto Serif CJK SC"),
  size: 11pt,
  lang: "zh",
  region: "cn",
  tracking: 0.5pt, // 正文字间距（实测行宽 +4.4%；想更松就调大这个数）
)
#show math.equation: set text(font: "New Computer Modern Math") // 公式间距由 math 自己管，不受 tracking 影响
#show raw: set text(tracking: 0pt) // 等宽代码不跟随字间距（否则代码行会变宽、容易折行）
#set par(justify: true, leading: 0.75em)
#set heading(numbering: "1.1")
#show raw.where(block: true): set block(
  inset: 8pt,
  radius: 3pt,
  fill: luma(248),
)

// 行间公式编号
#set math.equation(numbering: "(1)")
#show math.equation.where(block: true): set block(above: 0.9em, below: 0.9em)

// ── 定理类环境 ──
// 编号 = 章号.本章序号（第 2 章第一个定理 → 2.1）；没用一级标题时退化成 1、2、3…
#let _num(ctr) = {
  let chap = counter(heading).get()
  let n = ctr.get().at(0)
  if chap.len() > 0 and chap.at(0) > 0 {
    numbering("1.1", chap.at(0), n)
  } else { numbering("1", n) }
}

#let _env(name, body, title: none, color: rgb("#2f6f4f"), ctr: none) = {
  if ctr != none { ctr.step() } // 先自增再显示 → 第一个是 1 而不是 0
  block(
    width: 100%,
    inset: (x: 9pt, y: 7pt),
    radius: 3pt,
    stroke: (left: 2.2pt + color),
    fill: luma(247),
    above: 0.9em,
    below: 0.9em,
    breakable: true,
  )[
    #text(weight: "bold", fill: color)[
      #name#(if ctr != none [ #context _num(ctr)])
      #(if title != none [ (#title)])
    ]
    #h(0.5em)
    #body
  ]
}

#let thm-ctr = counter("theorem")
#let lem-ctr = counter("lemma")
#let cor-ctr = counter("corollary")
#let prop-ctr = counter("proposition")
#let def-ctr = counter("definition")
#let exm-ctr = counter("example")

#let theorem(body, title: none) = _env("定理", body, title: title, ctr: thm-ctr)
#let lemma(body, title: none) = _env(
  "引理",
  body,
  title: title,
  ctr: lem-ctr,
  color: rgb("#3f5f9f"),
)
#let corollary(body, title: none) = _env(
  "推论",
  body,
  title: title,
  ctr: cor-ctr,
  color: rgb("#3f5f9f"),
)
#let proposition(body, title: none) = _env(
  "命题",
  body,
  title: title,
  ctr: prop-ctr,
  color: rgb("#3f5f9f"),
)
#let definition(body, title: none) = _env(
  "定义",
  body,
  title: title,
  ctr: def-ctr,
  color: rgb("#8a5a00"),
)
#let example(body, title: none) = _env(
  "例",
  body,
  title: title,
  ctr: exm-ctr,
  color: rgb("#8a5a00"),
)
#let remark(body, title: none) = _env(
  "注",
  body,
  title: title,
  color: luma(120),
)

// 每进入新的一章，各计数器归零（y 在每章都从 1 开始）
#show heading.where(level: 1): it => {
  for c in (thm-ctr, lem-ctr, cor-ctr, prop-ctr, def-ctr, exm-ctr) {
    c.update(0)
  }
  it
}

#let proof(body, title: none) = block(
  width: 100%,
  above: 0.6em,
  below: 0.9em,
  breakable: true,
)[
  #text(style: "italic")[_证明#(if title != none [ (#title)])_]#h(0.4em)
  #body
  #h(1fr)
  #box[$square$]
]

// ── 标题 ──
#align(center)[
  #text(size: 17pt, weight: "bold", tracking: 2pt)[__TITLE__]
  #v(2pt)
  #text(size: 10pt, fill: luma(110))[#(
    datetime.today().display("[year]-[month]-[day]")
  )]
]

// ════════════ 正文从这里开始 ════════════
