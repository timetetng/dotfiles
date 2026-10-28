-- Typst 插入行为；使用原生按键完成配对，保留撤销与重做语义。
local M = {}
local context_cache
local function keys(s)
  return vim.api.nvim_replace_termcodes(s, true, false, true)
end

-- 只对当前行的未完成输入兜底，不读取/扫描其他行。
local function line_context(line, col)
  local mode, ticks, depth, previous = nil, nil, 0, nil
  local i = 1
  while i <= col do
    local c, two = line:sub(i, i), line:sub(i, i + 1)
    local step = 1
    if mode == "comment" then
      break
    elseif mode == "block_comment" then
      if two == "/*" then depth, step = depth + 1, 2
      elseif two == "*/" then
        depth, step = depth - 1, 2
        if depth == 0 then mode = previous end
      end
    elseif mode == "raw" then
      if line:sub(i, i + #ticks - 1) == ticks then step, mode = #ticks, nil end
    elseif mode == "string" or mode == "math_string" then
      if c == "\\" then step = 2
      elseif c == '"' then mode = mode == "math_string" and "math" or nil end
    elseif c == "\\" then
      step = 2
    elseif two == "//" then
      mode = "comment"
    elseif two == "/*" then
      previous, mode, depth, step = mode, "block_comment", 1, 2
    elseif c == "`" and mode ~= "math" then
      ticks = line:sub(i):match("^`+")
      mode, step = "raw", #ticks
    elseif c == '"' and (mode == "math" or line:sub(1, i - 1):find("#", 1, true)) then
      mode = mode == "math" and "math_string" or "string"
    elseif c == "$" then
      if mode == "math" then mode = nil else mode = "math" end
    end
    i = i + step
  end
  return { math = mode == "math", protected = mode ~= nil and mode ~= "math" }
end

-- 每次文本变更至多请求一次增量 parse；移动光标只查询已有语法树。
-- 普通输入使用 TS 自带的异步时间片，不能因复杂长段落而同步阻塞按键。
-- 只有显式 Ctrl-L 才允许等待当前公式的完整结束位置。
local tree_cache
function M.context(force)
  local pos = vim.api.nvim_win_get_cursor(0)
  local row, col = pos[1] - 1, pos[2]
  local buf, tick = vim.api.nvim_get_current_buf(), vim.api.nvim_buf_get_changedtick(0)
  if not force and context_cache and context_cache.buf == buf and context_cache.tick == tick
    and context_cache.row == row and context_cache.col == col then
    return context_cache.value
  end
  if force or not tree_cache or tree_cache.buf ~= buf or tree_cache.tick ~= tick then
    local entry = { buf = buf, tick = tick }
    tree_cache = entry
    pcall(function()
      local parser = vim.treesitter.get_parser(buf, "typst", { error = false })
      if not parser then return end
      -- 重解析未完成时沿用 TS 已更新坐标的旧树，避免长公式跨行时丢失数学上下文。
      local existing = parser:trees()
      if existing[1] then entry.root = existing[1]:root() end
      local function ready(err, trees)
        if err or not trees or not trees[1] or tree_cache ~= entry then return end
        if not vim.api.nvim_buf_is_valid(buf) or vim.api.nvim_buf_get_changedtick(buf) ~= tick then return end
        entry.root = trees[1]:root()
        context_cache = nil
      end
      local trees
      if force then trees = parser:parse() else trees = parser:parse(nil, ready) end
      if trees and trees[1] then entry.root = trees[1]:root() end
    end)
  end
  local fallback = line_context(vim.api.nvim_get_current_line(), col)
  local node = tree_cache.root and tree_cache.root:named_descendant_for_range(row, col, row, col)
  -- 行尾注释的插入点可能已不属于 comment 节点；当前行兜底也要参与保护。
  local value = fallback.protected and fallback or nil
  while node and not value do
    local kind = node:type()
    local sr, sc, er, ec = node:range()
    -- TS 的边界节点可能包含结束 $ 后的插入点，必须显式排除末端。
    local inside = (row > sr or (row == sr and col > sc))
      and (row < er or (row == er and col < ec))
    local comment_end = kind == "comment" and row == er and col == ec
      and vim.api.nvim_get_current_line():sub(ec - 1, ec) ~= "*/"
    if (inside or comment_end) and (kind == "string" or kind == "raw_span" or kind == "raw_blck" or kind == "comment") then
      value = { math = false, protected = true }
      break
    elseif inside and kind == "math" then
      value = { math = true, protected = false, finish = { row = er + 1, col = ec } }
      break
    end
    node = node:parent()
  end
  if not value then value = fallback end
  context_cache = { buf = buf, tick = tick, row = row, col = col, value = value }
  return value
end

local function escaped()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local pre = vim.api.nvim_get_current_line():sub(1, col)
  return #(pre:match("\\+$") or "") % 2 == 1
end

local function replace(from, to, text, cursor)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  pcall(vim.cmd, "undojoin")
  vim.api.nvim_buf_set_text(0, row - 1, from, row - 1, to, { text })
  vim.api.nvim_win_set_cursor(0, { row, cursor })
end

local function cjk_end(text)
  local chars = require("cjk").chars(text)
  return chars[#chars] ~= nil and require("cjk").is_cjk(chars[#chars])
end

function M.dollar()
  local ctx = M.context()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local line = vim.api.nvim_get_current_line()
  if ctx.protected or escaped() then
    replace(col, col, "$", col + 1)
  elseif ctx.math and line:sub(col + 1, col + 1) == "$" then
    vim.api.nvim_win_set_cursor(0, { vim.fn.line("."), col + 1 })
  elseif ctx.math then
    replace(col, col, "$", col + 1)
  else
    local prefix = cjk_end(line:sub(1, col)) and " " or ""
    replace(col, col, prefix .. "$$", col + #prefix + 1)
  end
end

function M.leave_or_wrap()
  local ctx = M.context(true)
  if ctx.protected then return end
  if ctx.math then
    -- 未闭合的公式不猜测结束位置。
    if not ctx.finish then return end
    local row, col = ctx.finish.row, ctx.finish.col
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
    if line:sub(col, col) ~= "$" then return end
    pcall(vim.cmd, "undojoin")
    if line:sub(col + 1, col + 1) ~= " " then
      vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { " " })
    end
    vim.api.nvim_win_set_cursor(0, { row, col + 1 })
    return
  end
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local line = vim.api.nvim_get_current_line()
  local letter = line:sub(col, col)
  if not letter:match("[A-Za-z]") then return end
  local prefix = cjk_end(line:sub(1, col - 1)) and " " or ""
  local suffix = line:sub(col + 1, col + 1) == " " and "" or " "
  local text = prefix .. "$" .. letter .. "$" .. suffix
  replace(col - 1, col, text, col - 1 + #text + (suffix == "" and 1 or 0))
end

local pairs = { ["("] = ")", ["["] = "]", ["{"] = "}", ["<"] = ">" }
local fullwidth = { ["【"] = "[", ["】"] = "]", ["（"] = "(", ["）"] = ")", ["《"] = "<", ["》"] = ">" }
function M.pair(char)
  local ctx = M.context()
  local original = char
  if fullwidth[char] then
    if not ctx.math then return char end
    char = fullwidth[char]
  end
  if ctx.protected or escaped() then return original end
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local next_char = vim.api.nvim_get_current_line():sub(col + 1, col + 1)
  if pairs[char] then
    local prefix = not ctx.math and cjk_end(vim.api.nvim_get_current_line():sub(1, col)) and " " or ""
    return prefix .. char .. pairs[char] .. keys("<Left>")
  end
  if next_char == char then return keys("<Right>") end
  return char
end

function M.script(char)
  local ctx = M.context()
  if not ctx.math or escaped() then return char end
  return char .. "()" .. keys("<Left>")
end

function M.backspace()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local line = vim.api.nvim_get_current_line()
  local left, right = line:sub(col, col), line:sub(col + 1, col + 1)
  if not M.context().protected and (pairs[left] == right or (left == "$" and right == "$")) then
    local count = 1
    -- ^(|) / _(|) 一次退格删掉整个自动生成结构。
    if left == "(" and line:sub(col - 1, col - 1):match("[%^_]") then count = 2 end
    return keys(string.rep("<BS>", count) .. "<Del>")
  end
  return keys("<BS>")
end

function M.setup(buf)
  local o = { buffer = buf, silent = true }
  for _, char in ipairs({ "$", "¥", "￥" }) do
    vim.keymap.set("i", char, M.dollar, vim.tbl_extend("force", o, { desc = "公式配对并补中英间距" }))
  end
  vim.keymap.set("i", "<C-l>", M.leave_or_wrap, vim.tbl_extend("force", o, { desc = "包裹前一个字母 / 跳出公式" }))
  local function expr(char, fn)
    vim.keymap.set("i", char, function() return fn(char) end,
      vim.tbl_extend("force", o, { expr = true, replace_keycodes = false }))
  end
  for _, char in ipairs({ "(", ")", "[", "]", "{", "}", "【", "】", "（", "）", "《", "》" }) do expr(char, M.pair) end
  for _, char in ipairs({ "^", "_" }) do expr(char, M.script) end
end

-- InsertCharPre 在字符落盘前处理，因此补全菜单打开时也能即时触发。
-- 直接改 v:char，不在 TextChangedI 里改 buffer，也不清空 undo 历史。
vim.api.nvim_create_autocmd("InsertCharPre", {
  group = vim.api.nvim_create_augroup("TypstInput", { clear = true }),
  callback = function()
    if vim.bo.filetype ~= "typst" then return end
    local digit = vim.v.char:match("^%d$") ~= nil
    local cjk = require("cjk")
    local first = cjk.chars(vim.v.char)[1]
    local chinese = first ~= nil and cjk.is_cjk(first)
    if not digit and not chinese then return end
    local ctx = M.context()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local pre = vim.api.nvim_get_current_line():sub(1, col)
    if digit and ctx.math then
      if pre:match("%f[%a][A-Za-z]$") and not pre:match("[%w_][A-Za-z]$") then
        vim.v.char = "_" .. vim.v.char
      end
    elseif chinese and not ctx.math and not ctx.protected and not escaped()
      and pre:match("[$%)%]%}]$") then
      -- 闭合公式/半角括号与后续中文之间的盘古之白；中文标点保持原样。
      vim.v.char = " " .. vim.v.char
    end
  end,
})

return M
