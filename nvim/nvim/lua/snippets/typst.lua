-- ============================================================
-- typst 数学笔记 snippets（LuaSnip 引擎，blink.cmp 的补全菜单提供）
--
-- 【怎么用】打前缀 → 补全菜单里 Tab 选中/回车确认展开。
--
-- 【怎么改】直接编辑本文件，**保存即生效**（不用重启 nvim）。
--   · 改触发词：每行第一个字符串，如 M("sum", ...) 里的 "sum"
--   · 删掉不用的：整行删掉就行（M(…) / T(…) 都是一行一条，T( 开头的长的也是）
--   · 改展开成什么：第三个参数
--       · 纯文本：t("oo")
--       · 带光标停靠点：fmt("({})/({})", { i(1, "a"), i(2, "b") })
--         —— {} 会被 i(...) 按顺序填；i(1, "a") 里的 1 是 Tab 跳转顺序，"a" 是默认文本
--       · 多行：fmt("$\n  {}\n$", { i(0) })   （\n 是换行）
--   · M(...) = 只在数学区 $...$ 里出现；T(...) = 只在正文里出现
--
-- 【三个例子，照抄改就行】
--   M("ff",   "分式",       fmt("({})/({})", { i(1, "a"), i(2, "b") }))  -- 打 ff → (a)/(b)
--   M("oo",   "无穷",       t("oo"))                                    -- 固定文本，无光标停靠
--   T("thm",  "定理环境",   fmt("#theorem(title: \"{}\")[\n  {}\n]", { i(1), i(2) }))
--
-- 【怎么知道该改哪个】typ snippets --stats   看哪些常用、哪些一次没用过
-- 【打开本文件】nvim 里 <Space>tS，或命令行 typ snippets
--
-- 其它：
--   · 希腊字母不在这里：tinymist 的 LSP 补全已覆盖（打 alp → alpha）
--   · 包裹/快捷输入在 lua/config/typst.lua（gs / gS / a_1 自动下标 / $ 配对）
--   · 数学区的真实空白不在片段里：连按 <Space> 1/2/3/4 次 → 普通空格 / #h(0.5em) / quad(1em) / wide(2em)，<BS> 反向降级
--   · 报错排查：:messages 里会打印重载信息；改完在 .typ 里打触发词看菜单有没有
-- ============================================================
local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt
local typst = require("config.typst")

local snips = {}

local function add(cond, trig, dscr, nodes)
  snips[#snips + 1] = s({ trig = trig, dscr = dscr, condition = cond, show_condition = cond }, nodes)
end

--- 只在数学区里出现
local function M(trig, dscr, nodes)
  add(typst.in_math, trig, dscr, nodes)
end

--- 只在正文里出现（数学区里不出现）
local function T(trig, dscr, nodes)
  add(typst.in_text, trig, dscr, nodes)
end

-- ─────────────────────────── 结构 ───────────────────────────
M("ff", "分式 (a)/(b)", fmt("({})/({})", { i(1, "a"), i(2, "b") }))
M("frac", "分式 (a)/(b)", fmt("({})/({})", { i(1, "a"), i(2, "b") }))
M("sq", "根号", fmt("sqrt({})", { i(1) }))
M("rt", "n 次根", fmt("root({}, {})", { i(1, "3"), i(2) }))
M("lr", "自适应括号", fmt("lr(({}))", { i(1) }))
M("abs", "绝对值", fmt("abs({})", { i(1) }))
M("norm", "范数", fmt("norm({})", { i(1) }))
M("floor", "下取整", fmt("floor({})", { i(1) }))
M("ceil", "上取整", fmt("ceil({})", { i(1) }))
M("round", "四舍五入", fmt("round({})", { i(1) }))
M("binom", "二项式系数", fmt("binom({}, {})", { i(1, "n"), i(2, "k") }))
M("eq", "对齐等号（多行公式用）", t("&= "))

-- ─────────────────────── 求和 / 积分 / 极限 ───────────────────────
M("sum", "求和", fmt("sum_({} = 1)^{} {}", { i(1, "n"), i(2, "oo"), i(0) }))
M("prod", "连乘", fmt("product_({} = 1)^{} {}", { i(1, "n"), i(2, "oo"), i(0) }))
M("int", "定积分", fmt("integral_{}^{} {} dif {}", { i(1, "0"), i(2, "oo"), i(3), i(4, "x") }))
M("iint", "二重积分", fmt("integral.double_{} {} dif {} dif {}", { i(1, "D"), i(2), i(3, "x"), i(4, "y") }))
M(
  "iiint",
  "三重积分",
  fmt("integral.triple_{} {} dif {} dif {} dif {}", { i(1, "V"), i(2), i(3, "x"), i(4, "y"), i(5, "z") })
)
M("oint", "环路积分", fmt("integral.cont_{} {} dif {}", { i(1, "C"), i(2), i(3, "s") }))
M("lim", "极限", fmt("lim_({} -> {}) {}", { i(1, "x"), i(2, "0"), i(0) }))
M("limsup", "上极限", fmt("limsup_({} -> oo) {}", { i(1, "n"), i(0) }))
M("liminf", "下极限", fmt("liminf_({} -> oo) {}", { i(1, "n"), i(0) }))

-- ─────────────────────────── 导数 ───────────────────────────
M("ddx", "d/dx", fmt("(dif {})/(dif {})", { i(1, "f"), i(2, "x") }))
M("pdx", "∂/∂x", fmt("(partial {})/(partial {})", { i(1, "f"), i(2, "x") }))
M("ddt", "d/dt", fmt("(dif {})/(dif t)", { i(1, "f") }))
M("pdt", "∂/∂t", fmt("(partial {})/(partial t)", { i(1, "f") }))

-- ─────────────────────── 矩阵 / 向量 / 分段 ───────────────────────
M(
  "mat",
  "矩阵（圆括号）",
  fmt('mat(delim: "(", {}, {}; {}, {})', { i(1, "1"), i(2, "2"), i(3, "3"), i(4, "4") })
)
M(
  "bmat",
  "矩阵（方括号）",
  fmt('mat(delim: "[", {}, {}; {}, {})', { i(1, "1"), i(2, "2"), i(3, "3"), i(4, "4") })
)
M("dmat", "行列式", fmt('mat(delim: "|", {}, {}; {}, {})', { i(1, "a"), i(2, "b"), i(3, "c"), i(4, "d") }))
M("vec", "列向量", fmt("vec({}, {}, {})", { i(1), i(2), i(3) }))
M("cases", "分段函数", fmt('cases({} & "if" {}, {} & "else")', { i(1), i(2, "x > 0"), i(3, "0") }))

-- ─────────────────────────── 集合 / 逻辑 ───────────────────────────
M("in", "属于", t("in "))
M("notin", "不属于", t("in.not "))
M("sub", "子集", t("subset "))
M("subeq", "子集（可相等）", t("subset.eq "))
M("supset", "超集", t("supset "))
M("inter", "交", t("inter "))
M("union", "并", t("union "))
M("interbig", "大交", fmt("inter.big_({} = 1)^{} {}", { i(1, "i"), i(2, "n"), i(0) }))
M("unionbig", "大并", fmt("union.big_({} = 1)^{} {}", { i(1, "i"), i(2, "n"), i(0) }))
M("empty", "空集", t("emptyset"))
M("forall", "任意", t("forall "))
M("exists", "存在", t("exists "))
M("implies", "推出", t("=> "))
M("iff", "等价", t("<=> "))
M("mapsto", "映射到", t("mapsto "))
M("to", "趋于", t("-> "))
M("RR", "实数集", t("RR"))
M("NN", "自然数集", t("NN"))
M("ZZ", "整数集", t("ZZ"))
M("QQ", "有理数集", t("QQ"))
M("CC", "复数集", t("CC"))
M("aleph0", "可数无穷", t("aleph_0"))

-- ─────────────────────────── 标记 / 字体 ───────────────────────────
M("hat", "帽子", fmt("hat({})", { i(1) }))
M("bar", "上划线（共轭）", fmt("overline({})", { i(1) }))
M("under", "下划线", fmt("underline({})", { i(1) }))
M("dot", "一点", fmt("dot({})", { i(1) }))
M("ddot", "两点", fmt("dot.double({})", { i(1) }))
M("til", "波浪", fmt("tilde({})", { i(1) }))
M("arv", "向量箭头", fmt("arrow({})", { i(1) }))
M("cal", "花体", fmt("cal({})", { i(1, "L") }))
M("bb", "黑板体", fmt("bb({})", { i(1, "R") }))
M("boldv", "粗体向量", fmt("bold({})", { i(1, "v") }))

-- ─────────────────────────── 运算符 / 常量 ───────────────────────────
M("times", "乘号", t("times "))
M("cdot", "点乘", t("dot.op "))
M("pm", "正负号", t("plus.minus "))
M("mp", "负正号", t("minus.plus "))
M("leq", "小于等于", t("<= "))
M("geq", "大于等于", t(">= "))
M("neq", "不等于", t("!= "))
M("approx", "约等于", t("approx "))
M("equiv", "恒等于", t("equiv "))
M("prop", "正比于", t("prop "))
M("oo", "无穷", t("oo"))
M("dif", "微分算子 d", t("dif "))
M("partialop", "偏导算子 ∂", t("partial "))
M("nabla", "梯度算子", t("nabla "))
M("qed", "证毕方块", t("square"))

-- ─────────────────────────── 正文（数学区外） ───────────────────────────
T("mk", "行内公式 $...$", fmt("${}$", { i(0) }))
T("dm", "行间公式 $ ... $", fmt("$\n  {}\n$", { i(0) }))
T(
  "fig",
  "图片 figure",
  fmt('#figure(\n  image("{}"),\n  caption: [{}],\n)<fig:{}>', { i(1, "path.png"), i(2), i(3) })
)
T(
  "tbl",
  "表格 figure",
  fmt(
    "#figure(\n  table(\n    columns: (auto, auto),\n    table.header([{}], [{}]),\n    [{}], [{}],\n  ),\n  caption: [{}],\n)<tab:{}>",
    { i(1), i(2), i(3), i(4), i(5), i(6) }
  )
)
T("thm", "定理环境", fmt('#theorem(title: "{}")[\n  {}\n]', { i(1), i(2) }))
T("lem", "引理环境", fmt('#lemma(title: "{}")[\n  {}\n]', { i(1), i(2) }))
T("cor", "推论环境", fmt("#corollary[\n  {}\n]", { i(1) }))
T("prope", "命题环境", fmt("#proposition[\n  {}\n]", { i(1) }))
T("defn", "定义环境", fmt("#definition[\n  {}\n]", { i(1) }))
T("exm", "例环境", fmt("#example[\n  {}\n]", { i(1) }))
T("rem", "注环境", fmt("#remark[\n  {}\n]", { i(1) }))
T("prf", "证明环境", fmt("#proof[\n  {}\n]", { i(1) }))
T("todo", "待办标记", fmt("#text(fill: red)[TODO: {}]", { i(1) }))

return snips
