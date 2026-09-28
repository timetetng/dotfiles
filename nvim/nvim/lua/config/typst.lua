-- ============================================================
-- typst 数学笔记：数学区判定 + 包裹/快捷输入 + 预览快捷键
--   数学区判定用 treesitter（typst parser 已装），带 changedtick 缓存，
--   供 snippets 的 condition/show_condition 与插入模式自动下标使用。
-- ============================================================
local M = {}

-- ─────────────────── 是否在 $ ... $ 里 ───────────────────
local cache = { buf = -1, tick = -1, row = -1, col = -1, math = false }

--- 本行光标之前未闭合的 $ 个数（奇 = 在公式里）
--- 兜住「正在输入、$ 还没闭合」的情况：此时 treesitter 里还没有 math 节点
local function line_in_math()
  local pos = vim.api.nvim_win_get_cursor(0)
  local before = vim.api.nvim_get_current_line():sub(1, pos[2])
  before = before:gsub("\\%$", "") -- 去掉 \$ 转义
  local _, n = before:gsub("%$", "")
  return n % 2 == 1
end

--- 光标是否位于 typst 数学区（行内/行间 $...$）
---@return boolean
function M.in_math()
  local buf = vim.api.nvim_get_current_buf()
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local pos = vim.api.nvim_win_get_cursor(0)
  local row, col = pos[1], pos[2]

  if cache.buf == buf and cache.tick == tick and cache.row == row and cache.col == col then
    return cache.math
  end

  local math = false
  local ok = pcall(function()
    local parser = vim.treesitter.get_parser(buf, "typst", { error = false })
    if not parser then
      return
    end
    local root = parser:parse()[1]:root()
    local node = root:named_descendant_for_range(row - 1, col, row - 1, col)
    while node do
      if node:type() == "math" then
        math = true
        break
      end
      node = node:parent()
    end
  end)

  -- treesitter 说在数学区就信它（能覆盖跨行的行间公式）；
  -- 否则再看本行 $ 是否未闭合（覆盖「刚敲了 $ 还没写收尾」的输入过程）
  if not ok or not math then
    math = line_in_math()
  end

  cache = { buf = buf, tick = tick, row = row, col = col, math = math }
  return math
end

--- 数学区之外（正文）
---@return boolean
function M.in_text()
  return not M.in_math()
end

--- 光标是否在代码块/行内代码里（raw_blck / raw_span / blob）
--- 这里面的 $ 是字面量，不做配对
---@return boolean
function M.in_raw()
  local buf = vim.api.nvim_get_current_buf()
  local pos = vim.api.nvim_win_get_cursor(0)
  local row, col = pos[1] - 1, pos[2]
  local ok, res = pcall(function()
    local parser = vim.treesitter.get_parser(buf, "typst", { error = false })
    if not parser then
      return false
    end
    local node = parser:parse()[1]:root():named_descendant_for_range(row, col, row, col)
    while node do
      local t = node:type()
      if t == "raw_blck" or t == "raw_span" or t == "blob" then
        return true
      end
      node = node:parent()
    end
    return false
  end)
  return ok and res or false
end

-- ─────────── 插入模式：$ 自动配对 / 全角 ￥ 纠正 ───────────
--- 敲下 $（或中文输入法打出的全角 ￥）时该怎么处理：
---   one  ← 代码块里 / 前面是反斜杠转义 / 已经在未闭合的数学区里 → 只插一个 $
---   skip ← 光标右边已经是 $ → 跳过它（括号配对手感）
---   pair ← 正文里 → 补成 $ $ 并把光标放到中间
---@return "one"|"skip"|"pair"
function M.dollar_action()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  if line:sub(col, col) == "\\" or M.in_raw() then
    return "one"
  end
  if line:sub(col + 1, col + 1) == "$" then
    return "skip"
  end
  if M.in_math() then
    return "one"
  end
  return "pair"
end

--- 插入模式映射的执行体：直接改 buffer + 移光标（不依赖 termcode，expr 映射返回键码在这里不可靠）
function M.dollar_insert()
  local action = M.dollar_action()
  local pos = vim.api.nvim_win_get_cursor(0)
  local row, col = pos[1], pos[2]

  if action == "skip" then
    vim.api.nvim_win_set_cursor(0, { row, col + 1 })
    return
  end

  local ul = vim.bo.undolevels
  vim.bo.undolevels = -1 -- 与本次插入合并为一个 undo 块
  vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { action == "pair" and "$$" or "$" })
  vim.api.nvim_win_set_cursor(0, { row, col + 1 })
  vim.bo.undolevels = ul
end

-- ─────────────────── 视觉选择包裹 ───────────────────
local function visual_marks()
  local s = vim.api.nvim_buf_get_mark(0, "<")
  local e = vim.api.nvim_buf_get_mark(0, ">")
  local sl, sc, el, ee = s[1], s[2], e[1], e[2]
  if sl > el or (sl == el and sc > ee) then
    sl, sc, el, ee = el, ee, sl, sc
  end
  return sl, sc, el, ee
end

--- 把当前视觉选择包起来（left/right 为左右定界符）
---@param left string
---@param right string
---@param block boolean|nil 是否包成多行（用于行间公式）
function M.wrap_selection(left, right, block)
  local sl, sc, el, ee = visual_marks()

  -- 退出 visual，避免插入位置随选区变化
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)

  -- 先插右侧（从后往前，避免前面的插入影响后面偏移）
  if block then
    vim.api.nvim_buf_set_text(0, el - 1, ee + 1, el - 1, ee + 1, { "", right })
    vim.api.nvim_buf_set_text(0, sl - 1, sc, sl - 1, sc, { left, "" })
  else
    vim.api.nvim_buf_set_text(0, el - 1, ee + 1, el - 1, ee + 1, { right })
    vim.api.nvim_buf_set_text(0, sl - 1, sc, sl - 1, sc, { left })
  end
end

-- ─────────────────── 插入模式自动下标：a1 → a_1 ───────────────────
local busy = false

--- 在 line 的 col 处识别「字母+刚输入的数字」，返回 (插入点偏移, 字母, 数字)
--- 兼容两种光标约定：插入模式的光标在插入点之后 / 停在刚输入的字符上
local function match_sub(line, col)
  local cands = {
    { idx = col, digit = line:sub(col, col), letter = line:sub(col - 1, col - 1) },
    { idx = col + 1, digit = line:sub(col + 1, col + 1), letter = line:sub(col, col) },
  }
  for _, c in ipairs(cands) do
    if c.digit:match("%d") and c.letter:match("%a") then
      -- 只在单词边界触发：a2 → a_2，但 ab2 不动；x_12 也不再动
      local before = line:sub(c.idx - 2, c.idx - 2)
      if not before:match("[%a%d_]") then
        return c.idx, c.letter, c.digit
      end
    end
  end
  return nil
end

--- 插入模式下把刚敲的 a2 变成 a_2（仅限 typst 数学区）
function M.auto_subscript()
  if busy or vim.bo.filetype ~= "typst" then
    return
  end
  local pos = vim.api.nvim_win_get_cursor(0)
  local row, col = pos[1], pos[2]
  local idx, letter, digit = match_sub(vim.api.nvim_get_current_line(), col)
  if not idx or not M.in_math() then
    return
  end

  busy = true
  local ul = vim.bo.undolevels
  vim.bo.undolevels = -1 -- 与本次插入合并为一个 undo 块
  vim.api.nvim_buf_set_text(0, row - 1, idx - 2, row - 1, idx, { letter .. "_" .. digit })
  vim.api.nvim_win_set_cursor(0, { row, idx + 1 })
  vim.bo.undolevels = ul
  busy = false
end

vim.api.nvim_create_autocmd("TextChangedI", {
  group = vim.api.nvim_create_augroup("TypstAutoSubscript", { clear = true }),
  desc = "typst 数学区自动下标 a1 → a_1",
  callback = M.auto_subscript,
})

-- ─────────── 数学区连按空格：渐进的真实间隙 ───────────
-- 数学区里敲出来的空格只是「语法分隔」（渲染宽度 0，用来分开 ab 这种多字母 token），
-- 想要真正的空白得写 #h(0.5em) / quad / wide。这里把「连按空格」做成逐级加宽：
--   1 次 → 普通空格   2 次 → #h(0.5em)   3 次 → quad (1em)   4 次 → wide (2em)
--   5 次起 → 又是普通空格（不影响排版，想再来一遍从第 2 级重新升）
-- <BS> 对称：光标紧跟间隙命令时，一次退格把整段删掉并降一级：
--   wide → quad → #h(0.5em) → 删掉（前面那个分隔空格还在）
-- quad / wide 自带一个尾随空格：`a quadb` 会被 typst 当成一个未知变量
-- （`#h(...)` 结尾是括号，不会跟后面的字母粘在一起）。
-- 实测（typst 0.15.1，10pt 正文，用 measure 量宽度）：普通空格 +0pt、
-- #h(0.5em) +0.5em、quad +1em、wide +2em（另有 thin/med/thick = 1/6、2/9、5/18 em）。
local SPACE_CHAIN = { "space", "h", "quad", "wide" }
local SPACE_TEXT = { space = " ", h = "#h(0.5em)", quad = "quad ", wide = "wide " }

--- 连按空格 / 整段退格该怎么改文本（纯函数，方便单测）
---@param pre string 光标之前的本行文本
---@param dir? "up"|"down" 默认 "up" = 连按空格加宽；"down" = <BS> 降级
---@param kind? string 上一次是谁插的（只有本功能刚插完、游标没动过才传；nil = 全新一次）
---@return { back: integer, text: string, kind: string }|nil back = 删掉光标前几个字符；nil = 交给默认行为
function M.space_step(pre, dir, kind)
  -- 文本对不上就不认这个 kind：状态可能过期了（undo、别的窗口改了同一个 buffer…）
  if kind ~= nil and pre:sub(-#SPACE_TEXT[kind]) ~= SPACE_TEXT[kind] then
    kind = nil
  end
  local i = 0
  for n, k in ipairs(SPACE_CHAIN) do
    if k == kind then
      i = n
    end
  end

  if dir == "down" then
    if i < 2 then
      return nil -- 光标前没有间隙命令（或只是个普通空格）→ 用内置退格
    end
    local prev = SPACE_CHAIN[i - 1]
    -- 降到「普通空格」那一级 = 把命令整个删掉（前面那个分隔空格留着）
    return { back = #SPACE_TEXT[kind], text = prev == "space" and "" or SPACE_TEXT[prev], kind = prev }
  end

  if i == 0 then
    return { back = 0, text = SPACE_TEXT.space, kind = "space" }
  end
  if i == 1 then
    -- 普通空格后面补上 #h(0.5em)：那个空格留着当分隔，读起来是 `a #h(0.5em)`
    return { back = 0, text = SPACE_TEXT.h, kind = "h" }
  end
  if i == #SPACE_CHAIN then
    return { back = 0, text = " ", kind = "wide" } -- 到顶了：wide 留着，再按只是再插个普通空格
  end
  local next_kind = SPACE_CHAIN[i + 1]
  return { back = #SPACE_TEXT[kind], text = SPACE_TEXT[next_kind], kind = next_kind }
end

-- 只有「上一次按空格就是本功能干的、之后游标没动过」才继续升级：
-- 这样手写的 quad / #h(0.5em) 不会被下一次空格误升级成 wide。
local chain = { buf = -1, row = -1, col = -1, kind = nil }

--- 插入模式映射的执行体：直接改 buffer + 移游标（和上面 $ 配对同一套做法）
---@param dir? "up"|"down"
function M.space_insert(dir)
  local buf = vim.api.nvim_get_current_buf()
  local pos = vim.api.nvim_win_get_cursor(0)
  local row, col = pos[1], pos[2]
  local kind = nil
  if chain.buf == buf and chain.row == row and chain.col == col then
    kind = chain.kind -- 游标还停在上次插入的末尾 → 算「连按」
  end

  local plan = nil
  -- 代码块/行内代码里的 $ 是字面量，别在 raw 里乱插命令
  if vim.bo.filetype == "typst" and M.in_math() and not M.in_raw() then
    plan = M.space_step(vim.api.nvim_get_current_line():sub(1, col), dir, kind)
  end
  chain = { buf = buf, row = row, col = col, kind = nil } -- 默认清掉，下面真改了就重记

  if plan == nil then
    -- 正文里的空格 / 普通退格：交回内置行为（保留自动换行、行首退格并行的语义）
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes(dir == "down" and "<BS>" or "<Space>", true, false, true),
      "n",
      false
    )
    return
  end

  local ul = vim.bo.undolevels
  vim.bo.undolevels = -1 -- 与本次插入合并为一个 undo 块
  local from = col - plan.back
  vim.api.nvim_buf_set_text(0, row - 1, from, row - 1, col, { plan.text })
  local new_col = from + #plan.text
  vim.api.nvim_win_set_cursor(0, { row, new_col })
  vim.bo.undolevels = ul
  chain = { buf = buf, row = row, col = new_col, kind = plan.kind }
end

-- ─────────── 片段文件入口 ───────────
local SNIPPET_FILE = vim.fn.stdpath("config") .. "/lua/snippets/typst.lua"

--- 打开 typst 片段文件（右侧分栏；改完保存即生效）
function M.edit_snippets()
  vim.cmd("vsplit " .. vim.fn.fnameescape(SNIPPET_FILE))
end

vim.api.nvim_create_user_command("TypstSnippets", M.edit_snippets, {
  desc = "编辑 typst snippets（改完保存后自动重载）",
})

-- ─────────── 预览启动反馈 ───────────
-- 原生 `:TypstPreview` 在等待期间**完全静默**：它只在二进制缺失或端口被占时说话，
-- 而 tinymist 自己的 stderr 只有在插件 debug 开关打开时才写进日志文件。
-- 结果就是“慢”和“失败”在界面上长得一模一样。这里包一层，把进度变成可见的通知。
local PREVIEW_LOG = vim.fn.stdpath("data") .. "/typst-preview/log.txt"

-- 日志是只追加的，多开 nvim 时所有会话混写在一起；每次启动前插个分隔标记，
-- <leader>tL 就能只显示「最近一次启动」的那一段。
local PREVIEW_MARK = "===== typst-preview 启动 ====="

local function preview_notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "typst-preview" })
end

local function preview_servers()
  local ok, servers = pcall(require, "typst-preview.servers")
  return ok and servers or nil
end

--- 启动预览，并在 nvim 里给出可见的进度/失败反馈
---@param mode? "document"|"slide"
function M.preview_with_feedback(mode)
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    preview_notify("这个 buffer 还没存成文件，没法预览", vim.log.levels.ERROR)
    return
  end
  local servers = preview_servers()
  local already = servers ~= nil and servers.get(path) ~= nil

  -- 日志是 debug 模式下只追加的，攒太大就清掉重来
  if vim.fn.getfsize(PREVIEW_LOG) > 1024 * 1024 then
    vim.fn.delete(PREVIEW_LOG)
  end
  pcall(function()
    local f = io.open(PREVIEW_LOG, "a")
    if f ~= nil then
      f:write(string.format("\n%s %s  %s\n", PREVIEW_MARK, os.date("%Y-%m-%d %H:%M:%S"), path))
      f:close()
    end
  end)

  preview_notify(already and "预览服务已在运行，正在打开浏览器窗口…" or "正在启动 preview 服务（tinymist）…")
  vim.cmd("TypstPreview" .. (mode and (" " .. mode) or ""))
  if already or servers == nil then
    return -- 服务本来就在跑（只是重开一个前端窗口），没什么可等的
  end

  local t0 = vim.uv.hrtime()
  local timer = vim.uv.new_timer()
  local warned = false
  timer:start(150, 150, vim.schedule_wrap(function()
    local elapsed = (vim.uv.hrtime() - t0) / 1e9
    local sers = servers.get(path)
    local link
    if sers ~= nil then
      for _, s in pairs(sers) do
        if s.link ~= nil then
          link = s.link
        end
      end
    end
    if link ~= nil then
      timer:stop()
      timer:close()
      preview_notify(string.format("预览服务就绪（%.1fs）→ http://%s\n剩下的是浏览器那边加载页面", elapsed, link))
      -- 通知会消失，把地址也写进日志，事后 <leader>tL 还能找到（浏览器没弹出来时可以手动打开）
      pcall(function()
        local f = io.open(PREVIEW_LOG, "a")
        if f ~= nil then
          f:write(string.format("[typst-preview] 就绪 %.1fs → http://%s\n", elapsed, link))
          f:close()
        end
      end)
    elseif elapsed > 30 then
      timer:stop()
      timer:close()
      preview_notify("30 秒还没起来，多半是失败了 —— 按 <leader>tL 看日志尾部", vim.log.levels.ERROR)
    elseif not warned and elapsed > 6 then
      warned = true
      preview_notify(
        string.format("%.0f 秒了服务还没就绪，可能卡住了（<leader>tL 看日志）", elapsed),
        vim.log.levels.WARN
      )
    end
  end))
end

--- 打开预览日志（最近一次启动那一截；tinymist 的警告/报错都在里面）
function M.show_preview_log()
  local lines = {}
  if vim.fn.filereadable(PREVIEW_LOG) == 1 then
    lines = vim.fn.readfile(PREVIEW_LOG)
    -- 从最后一次「启动」标记开始看，免得读到别的 nvim 会话混写进来的内容
    local from = nil
    for i = #lines, 1, -1 do
      if lines[i]:find(PREVIEW_MARK, 1, true) then
        from = i
        break
      end
    end
    if from ~= nil then
      lines = vim.list_slice(lines, from)
      if #lines <= 1 then
        -- 插件是缓冲写日志的（utils.lua 里 file:write 不 flush），tinymist 的输出要等
        -- 缓冲满或进程退出才落盘，所以这里可能只有标记行。
        vim.list_extend(lines, {
          "",
          "（日志目前只有标记行：typst-preview 是缓冲写日志的，tinymist 的输出要等缓冲满、",
          "  或者服务停掉之后才落盘。想看某次失败的完整过程：先 <leader>ts 停掉，再 <leader>tL。）",
        })
      end
    end
    -- 再长也只看尾部
    if #lines > 300 then
      lines = vim.list_slice(lines, #lines - 299)
    end
  end
  if #lines == 0 then
    lines = {
      "还没有日志：" .. PREVIEW_LOG,
      "（日志由 typst-preview 的 debug 开关产生，已在 lua/plugins/typst.lua 里打开）",
    }
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  vim.cmd("botright 18split")
  vim.api.nvim_win_set_buf(0, buf)
  vim.cmd("normal! G")
end

vim.api.nvim_create_user_command("TypstPreviewLog", M.show_preview_log, {
  desc = "查看 typst-preview 日志尾部（诊断预览起不来的问题）",
})

-- ─────────────────── 快捷键 ───────────────────
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("TypstKeymaps", { clear = true }),
  pattern = "typst",
  desc = "typst 笔记快捷键",
  callback = function(ev)
    local o = { buffer = ev.buf, silent = true }
    -- 选中后包公式
    vim.keymap.set("x", "gs", function()
      M.wrap_selection("$", "$", false)
    end, vim.tbl_extend("force", o, { desc = "包成行内公式 $...$" }))
    vim.keymap.set("x", "gS", function()
      M.wrap_selection("$", "$", true)
    end, vim.tbl_extend("force", o, { desc = "包成行间公式" }))
    vim.keymap.set("x", "ga", function()
      M.wrap_selection("lr((", "))", false)
    end, vim.tbl_extend("force", o, { desc = "包成自适应括号" }))
    -- 插入模式：$ 自动配对成 $…$（光标进中间）；全角 ￥ 当 $ 用（忘了切输入法时）
    vim.keymap.set("i", "$", M.dollar_insert, vim.tbl_extend("force", o, { desc = "$ 自动配对，光标进中间" }))
    vim.keymap.set("i", "¥", M.dollar_insert, vim.tbl_extend("force", o, { desc = "全角 ￥ 当 $ 用" }))
    vim.keymap.set("i", "￥", M.dollar_insert, vim.tbl_extend("force", o, { desc = "全角 ￥ 当 $ 用" }))
    -- 插入模式：数学区连按空格 → 真实间隙；<BS> 对称地把整段间隙降一级
    vim.keymap.set("i", "<Space>", function()
      M.space_insert("up")
    end, vim.tbl_extend("force", o, { desc = "连按空格：普通空格 → #h(0.5em) → quad → wide" }))
    vim.keymap.set("i", "<BS>", function()
      M.space_insert("down")
    end, vim.tbl_extend("force", o, { desc = "整段退掉间隙命令（wide→quad→#h(0.5em)→删掉）" }))
    -- 片段文件快捷入口（改完保存即生效）
    vim.keymap.set("n", "<leader>tS", M.edit_snippets, vim.tbl_extend("force", o, { desc = "编辑 typst snippets" }))
    -- 预览（手动；带启动进度反馈，见上面 M.preview_with_feedback）
    vim.keymap.set("n", "<leader>tp", function()
      M.preview_with_feedback()
    end, vim.tbl_extend("force", o, { desc = "打开 typst 预览（浏览器，带进度提示）" }))
    vim.keymap.set(
      "n",
      "<leader>tP",
      "<cmd>TypstPreviewToggle<cr>",
      vim.tbl_extend("force", o, { desc = "切换预览" })
    )
    vim.keymap.set("n", "<leader>ts", "<cmd>TypstPreviewStop<cr>", vim.tbl_extend("force", o, { desc = "停止预览" }))
    vim.keymap.set("n", "<leader>tc", "<cmd>TypstPreviewSyncCursor<cr>", vim.tbl_extend("force", o, { desc = "预览同步到光标" }))
    vim.keymap.set("n", "<leader>tL", M.show_preview_log, vim.tbl_extend("force", o, { desc = "查看预览日志（诊断）" }))
  end,
})

return M
