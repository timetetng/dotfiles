-- ============================================================
-- 中文/西文混排的 nvim 集成：实时补空格 + 保存时整篇兜底
-- 规则本体在 lua/cjk/init.lua（纯函数，可单测）
--
-- · 实时：InsertCharPre —— 插入的字符与光标前一字符属于「一边汉字、一边拉丁字母/数字」时，
--   自动在该字符前补一个空格。只在 md/typ/tex，且插入点不在保护区（代码块/公式/raw）时。
--   你手动删掉的空格不会被补回来（只在「插入字符那一刻」触发）。
-- · 保存：conform.nvim 的 Lua formatter（见 lua/plugins/formatter.lua）调用 M.format_buffer，
--   整篇跑全量规则（中英空格 + 数字单位 + 标点双向 + 括号引号）。
-- · 手动：:CJKFix 整篇来一次；vim.g.cjk_auto_space = false 可关掉实时补空格。
-- ============================================================
local M = {}

local cjk = require("cjk")

local FTS = {
  markdown = true,
  typst = true,
  tex = true,
  plaintex = true,
  latex = true,
}

--- 清空跨行状态缓存（切换 filetype / 写测试时用）
function M._clear_cache()
  state_cache = {}
end

--- 该 buffer 是否启用
---@param bufnr integer
---@return boolean
function M.enabled(bufnr)
  return FTS[vim.bo[bufnr].filetype] == true
end

-- ─────────────── 跨行状态缓存（实时层用） ───────────────
-- 值 = { lnum, text, state, ft }：表示「处理完第 lnum 行之后」的扫描状态。
-- 状态只在被引用的那一行文本没变时有效（当前行在打字，但缓存的是它前面那行）。
local state_cache = {}

local function get_line(bufnr, lnum)
  return vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
end

--- 算出第 lnum 行每字符的保护区标记（人物：从缓存点继续往后扫）
---@param bufnr integer
---@param lnum integer
---@param chars string[]
---@return boolean[]
local function line_flags(bufnr, lnum, chars)
  local ft = vim.bo[bufnr].filetype
  local cache = state_cache[bufnr]
  if cache and cache.ft ~= ft then
    cache = nil
  end

  local start, state
  if cache and cache.lnum <= lnum - 1 and cache.text == get_line(bufnr, cache.lnum) then
    start = cache.lnum + 1
    state = vim.deepcopy(cache.state)
  else
    start = 1
    state = cjk.initial_state(ft)
  end

  local flags
  local before_last = nil
  for l = start, lnum do
    local line = get_line(bufnr, l)
    flags, state = cjk.step(l == lnum and chars or cjk.chars(line), state)
    if l == lnum - 1 then
      -- 缓存「处理完第 lnum-1 行之后」的状态，下次同一行打字命中
      before_last = vim.deepcopy(state)
    end
  end

  if before_last and lnum > 1 then
    state_cache[bufnr] = {
      lnum = lnum - 1,
      text = get_line(bufnr, lnum - 1),
      state = before_last,
      ft = ft,
    }
  end
  return flags
end

--- 插入点（字节列 col，1-based）是否落在保护区里
---@param bufnr integer
---@param lnum integer
---@param col integer
---@return boolean
local function in_protected(bufnr, lnum, col)
  local line = get_line(bufnr, lnum)
  local chars = cjk.chars(line)
  local before = cjk.chars(line:sub(1, col - 1))
  local idx = #before + 1
  local flags = line_flags(bufnr, lnum, chars)
  if flags[idx] ~= nil then
    return flags[idx] == true
  end
  -- 行尾插入（插入点之后没有字符）：沿用左邻字符的保护状态
  return flags[idx - 1] == true
end

-- ─────────────── 实时：InsertCharPre ───────────────

--- 是否需要在 ch 前补一个空格（纯逻辑，便于单测）
---@param prev string|nil 光标前一字符
---@param ch string 即将插入的字符（可多字符）
---@return boolean
function M.want_space(prev, ch)
  if not prev or not ch or ch == "" then
    return false
  end
  local first = cjk.chars(ch)[1]
  if not first then
    return false
  end
  return (cjk.is_cjk(prev) and cjk.is_word(first)) or (cjk.is_word(prev) and cjk.is_cjk(first))
end

--- 插入点（字节列 col，1-based；lnum 从 1 起）是否落在保护区里（供测试/手工调用）
---@param bufnr integer
---@param lnum integer
---@param col integer
---@return boolean
function M.in_protected_at(bufnr, lnum, col)
  return in_protected(bufnr, lnum, col)
end

--- 只做「中英之间补空格」这一档；标点交给输入法（rime），避免两边打架
local function on_insert_char()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.g.cjk_auto_space == false or not M.enabled(bufnr) then
    return
  end

  local ch = vim.v.char
  if not ch or ch == "" then
    return
  end

  if cjk.chars(ch)[1] == nil then
    return
  end

  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local col = vim.fn.col(".")
  local line = get_line(bufnr, lnum)
  local before = cjk.chars(line:sub(1, col - 1))
  local prev = before[#before]
  if not M.want_space(prev, ch) then
    return
  end
  if in_protected(bufnr, lnum, col) then
    return
  end

  vim.v.char = " " .. ch
end

-- ─────────────── 保存时：整篇兜底 ───────────────

--- 纯计算：返回新行数组；无变化时返回 nil
---@param lines string[]
---@param ft string
---@return string[]|nil
function M.transform(lines, ft)
  local out = cjk.transform_lines(lines, ft)
  for i = 1, #lines do
    if lines[i] ~= out[i] then
      return out
    end
  end
  return nil
end

--- conform.nvim 的 Lua formatter 入口
---@param ctx conform.Context
---@param lines string[]
---@param callback fun(err: nil|string, new_lines: nil|string[])
function M.conform_format(ctx, lines, callback)
  local ft = vim.bo[ctx.buf].filetype
  local ok, out = pcall(M.transform, lines, ft)
  if not ok then
    callback(tostring(out))
    return
  end
  callback(nil, out)
end

--- 手动整篇（:CJKFix）
---@return integer 被改动的行数
function M.fix_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local out = M.transform(lines, vim.bo[bufnr].filetype)
  if not out then
    return 0
  end
  local n = 0
  for i = 1, #lines do
    if lines[i] ~= out[i] then
      n = n + 1
    end
  end
  local view = vim.fn.winsaveview()
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, out)
  vim.fn.winrestview(view)
  return n
end

-- ─────────────── 挂载 ───────────────

vim.api.nvim_create_autocmd("InsertCharPre", {
  group = vim.api.nvim_create_augroup("CJKInsertSpace", { clear = true }),
  desc = "中英/中文与数字之间自动补空格（只在 md/typ/tex，避开代码/公式区）",
  callback = on_insert_char,
})

vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
  group = vim.api.nvim_create_augroup("CJKCacheClean", { clear = true }),
  desc = "清理跨行状态缓存",
  callback = function(args)
    state_cache[args.buf] = nil
  end,
})

vim.api.nvim_create_user_command("CJKFix", function()
  if not M.enabled(0) then
    vim.notify("cjk: 该 filetype 不在处理范围（markdown/typst/tex）", vim.log.levels.WARN)
    return
  end
  local n = M.fix_buffer()
  vim.notify(n == 0 and "cjk: 无需改动" or ("cjk: 已调整 " .. n .. " 行"), vim.log.levels.INFO)
end, { desc = "整篇应用中文排版规则（空格/标点/单位）" })

return M
