// ============================================================
//  数学笔记模板 · 示例（typst 0.15）
//  排版定义在本地包 @local/mathnote:0.1.0（改那一处 → 所有笔记一起变）
//  用法：typ init -t sample   |   预览 <Space>tp，停止 <Space>ts
//  速查表：~/notes/typst/00-cheatsheet.typ
// ============================================================
#import "@local/mathnote:0.1.0": *

#show: note.with(title: "标题：数学笔记")

// ── 常用记号（可选：给常写的集合起短名；注意别覆盖内置函数名）──
#let RRx = $bb(R)$ // 直接写 $RR$ 也一样，这里只是演示自定义短名

= 第一节：示例

== 行内与行间公式

行内公式写成 $f(x) = x^2 + 2x + 1$，括号自适应用 $lr((a+b)/c)$。
下标、上标、希腊字母：$a_1$, $x^(n+1)$, $alpha, beta, gamma, theta, lambda, mu, sigma, omega$。

行间公式（`dm` 片段）：

$
  integral_0^oo e^(-x^2) dif x = sqrt(pi)/2
$

多行对齐（`&=` 对齐，行尾 `\` 换行）：

$
  (a + b)^2 & = a^2 + 2 a b + b^2 \
            & = a^2 + b^2 + 2 a b
$

== 求和、连乘、极限、导数

$
  sum_(n=1)^oo 1/n^2 = pi^2/6, quad product_(k=1)^n k = n!, quad lim_(x -> 0) (sin x)/x = 1
$

$
  (dif f)/(dif x), quad (partial f)/(partial x), quad nabla f, quad integral.double_D f(x, y) dif x dif y
$

== 矩阵、向量、分段函数

$
  A = mat(delim: "[", 1, 2; 3, 4), quad bold(v) = vec(1, 2, 3), quad abs(x) = cases(x & "if" x >= 0, -x & "else")
$

== 集合与逻辑

$
  forall epsilon > 0, exists delta > 0: quad 0 < abs(x - a) < delta => abs(f(x) - L) < epsilon
$

$
  A subset.eq B, quad A union B, quad A inter B, quad x in.not A, quad RR subset CC
$

== 定理环境

#definition(title: "连续")[
  设 $f: RR -> RR$。若对任意 $epsilon > 0$ 存在 $delta > 0$，使得
  $abs(x - x_0) < delta$ 时 $abs(f(x) - f(x_0)) < epsilon$，则称 $f$ 在 $x_0$ 处连续。
]

#theorem(title: "介值定理")[
  若 $f$ 在 $[a, b]$ 上连续，且 $f(a) < c < f(b)$，则存在 $xi in (a, b)$ 使 $f(xi) = c$。
]

#proof[
  令 $S = {x in [a, b] : f(x) <= c}$，取 $xi = sup S$，由连续性得 $f(xi) = c$。
]

#example[
  用 `thm` 片段插入定理、`defn` 定义、`exm` 例、`prf` 证明。
]

#remark[模板里的环境定义都在文件头部，按需改颜色/编号即可。]

== 表格与图

#figure(
  table(
    columns: (auto, auto, auto),
    table.header([记号], [含义], [写法]),
    [$RR$], [实数集], [`RR`],
    [$in$], [属于], [`in`],
    [$sum$], [求和], [`sum`],
  ),
  caption: [常用记号示例],
)<tab:symbols>

引用见 @tab:symbols。

#figure(
  // 有图时把下面换成 image("图.png")
  rect(width: 60%, height: 2.5cm, radius: 3pt, stroke: (
    paint: luma(180),
    thickness: 0.8pt,
  ))[
    #align(center + horizon)[图占位：`image("path.png")`]
  ],
  caption: [图示例],
)<fig:demo>

引用见 @fig:demo。

== 代码

```python
def fixed_point(g, x0, tol=1e-10, n=100):
    for _ in range(n):
        x1 = g(x0)
        if abs(x1 - x0) < tol:
            return x1
        x0 = x1
    return x0
```

= 速查

- 希腊字母：直接打字母名 + Tab 补全（`alp` → `alpha`，tinymist 提供）
- 自动下标：数学区里 `a1` 自动变 `a_1`
- 包裹：可视模式选中后 `gs` 包 `$...$`、`gS` 包行间公式、`ga` 包自适应括号
- 片段触发词表：见 `~/notes/typst/00-cheatsheet.typ`
