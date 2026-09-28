-- ============================================================
-- cjk —— 中文/西文混排的文本规则（纯 Lua：输入是字符串或行数组，不碰 buffer）
--
-- 两个入口共用同一套规则：
--   · 实时：lua/config/cjk.lua 的 InsertCharPre（只用「中英之间补空格」那一档）
--   · 保存：conform.nvim 的 Lua formatter（全量规则整篇兜底）
--
-- 规则（2026-09-28 定）：
--   1. 中英、中文与数字之间补一个半角空格（盘古之白）
--   2. 数字与白名单单位之间补空格（10m/s → 10 m/s）；% ° ℃ 紧跟数字（50 % → 50%）
--   3. 标点双向：
--        · 代码/公式/raw 区内：全角标点 → 半角，但仅当该标点两侧都不是汉字
--        · 正文里：紧邻汉字的半角 , . : ; ! ? → 全角
--   4. 括号/引号按内容语言：含汉字的 () "" → （）“”；不含汉字的（）“” → () ""
--   5. 全角标点后残留的半角空格删掉（rime 转全角时留在原地的那个空格）
--   6. 保护区（规则 1/2/4 跳过，规则 3 只在这里生效）：
--        markdown: frontmatter / 围栏代码块 / 行内 code / $公式$ / HTML 标签 / URL / 链接目标
--        typst   : $数学$ / `raw` / // 注释
--        tex     : $数学$ \( \) \[ \] / verbatim 族 / \verb / % 注释 / \url{} 等宏参数
--
-- 约定：一切文本先拆成 UTF-8 字符数组再处理，绝不按字节下标切字符串。
-- ============================================================
local M = {}

-- ─────────────────────── UTF-8 基础 ───────────────────────

--- 字符串 → UTF-8 字符数组（非法字节按单字节处理，拼接可逆）
---@param s string
---@return string[]
function M.chars(s)
  local out = {}
  local i, n = 1, #s
  while i <= n do
    local b = s:byte(i)
    local len
    if b < 0x80 then
      len = 1
    elseif b < 0xE0 then
      len = 2
    elseif b < 0xF0 then
      len = 3
    else
      len = 4
    end
    out[#out + 1] = s:sub(i, i + len - 1)
    i = i + len
  end
  return out
end

--- 单个字符的码点
local function codepoint(ch)
  local b1, b2, b3, b4 = ch:byte(1, 4)
  if not b2 then
    return b1
  elseif b1 < 0xE0 then
    return (b1 - 0xC0) * 0x40 + (b2 - 0x80)
  elseif b1 < 0xF0 then
    return (b1 - 0xE0) * 0x1000 + (b2 - 0x80) * 0x40 + (b3 - 0x80)
  end
  return (b1 - 0xF0) * 0x40000 + (b2 - 0x80) * 0x1000 + (b3 - 0x80) * 0x40 + (b4 - 0x80)
end

-- CJK「文字侧」区间：汉字、假名、韩文。故意不含全角/CJK 标点（U+3000-303F、FF00-FFEF），
-- 因为标点前后不该再补空格。
local CJK_RANGES = {
  { 0x2E80, 0x2EFF }, -- 康熙部首
  { 0x3005, 0x3007 }, -- 々〆〇
  { 0x3040, 0x30FF }, -- 平假名 / 片假名
  { 0x31F0, 0x31FF }, -- 片假名扩展
  { 0x3400, 0x4DBF }, -- 汉字扩展 A
  { 0x4E00, 0x9FFF }, -- 汉字基本区
  { 0xF900, 0xFAFF }, -- 兼容表意
  { 0xAC00, 0xD7AF }, -- 韩文音节
  { 0x20000, 0x2FA1F }, -- 扩展 B 及以上
}

--- 是否「CJK 侧」字符
---@param ch string|nil
---@return boolean
function M.is_cjk(ch)
  if not ch or ch == "" then
    return false
  end
  local cp = codepoint(ch)
  for _, r in ipairs(CJK_RANGES) do
    if cp >= r[1] and cp <= r[2] then
      return true
    end
  end
  return false
end

--- 是否 ASCII 字母或数字
---@param ch string|nil
---@return boolean
function M.is_word(ch)
  return ch ~= nil and #ch == 1 and ch:match("[A-Za-z0-9]") ~= nil
end

--- 字符串里是否含 CJK 字符
---@param s string
---@return boolean
function M.has_cjk(s)
  for _, ch in ipairs(M.chars(s)) do
    if M.is_cjk(ch) then
      return true
    end
  end
  return false
end

-- ─────────────────────── 保护区扫描 ───────────────────────
-- 每个 stepper：输入「一行的字符数组 + 状态」，输出「该行每个字符是否受保护 + 新状态」。
-- 状态跨行传递，所以实时层可以按行缓存（见 config/cjk.lua）。

local function blank_flags(n)
  local flags = {}
  for i = 1, n do
    flags[i] = false
  end
  return flags
end

--- 从 i 开始找同字符的结束位置（i 不算），用于「反引号 run」配对
local function find_run(chars, i, ch, min_len)
  local n = #chars
  local j = i
  while j <= n do
    if chars[j] == ch then
      local k = j
      while k <= n and chars[k] == ch do
        k = k + 1
      end
      if k - j >= min_len then
        return j, k - 1
      end
      j = k
    else
      j = j + 1
    end
  end
  return nil
end

--- 括号配对：返回与 i 处的 open 匹配的 close 位置（考虑嵌套）
local function match_bracket(chars, i, open, close)
  local depth = 0
  for k = i, #chars do
    if chars[k] == open then
      depth = depth + 1
    elseif chars[k] == close then
      depth = depth - 1
      if depth == 0 then
        return k
      end
    end
  end
  return nil
end

-- ── markdown ──
local function md_fence(chars)
  -- 行首（允许前导空格）3 个以上的 ` 或 ~ → { ch, len }
  local i = 1
  while i <= #chars and chars[i] == " " do
    i = i + 1
  end
  local ch = chars[i]
  if ch ~= "`" and ch ~= "~" then
    return nil
  end
  local j = i
  while j <= #chars and chars[j] == ch do
    j = j + 1
  end
  if j - i < 3 then
    return nil
  end
  return { ch = ch, len = j - i }
end

local function md_fence_close(chars, fence)
  local f = md_fence(chars)
  if not f or f.ch ~= fence.ch or f.len < fence.len then
    return false
  end
  -- 关闭行除围栏外只能是空白
  for k = 1, #chars do
    local ch = chars[k]
    if ch ~= fence.ch and ch ~= " " and ch ~= "\t" then
      return false
    end
  end
  return true
end

local function step_markdown(chars, state)
  local n = #chars
  local flags = blank_flags(n)
  local i = 1

  -- frontmatter：文件开头的 --- … ---
  if state.frontmatter then
    for k = 1, n do
      flags[k] = true
    end
    local text = table.concat(chars)
    if text:match("^%-%-%-%s*$") and state.frontmatter_seen then
      state.frontmatter = false
    end
    state.frontmatter_seen = true
    return flags, state
  end

  -- 围栏代码块
  if state.fence then
    if md_fence_close(chars, state.fence) then
      for k = 1, n do
        flags[k] = true
      end
      state.fence = nil
      return flags, state
    end
    for k = 1, n do
      flags[k] = true
    end
    return flags, state
  end

  local fence = md_fence(chars)
  if fence then
    for k = 1, n do
      flags[k] = true
    end
    state.fence = fence
    return flags, state
  end

  while i <= n do
    local ch = chars[i]
    if ch == "\\" then
      i = i + 2
    elseif ch == "`" then
      local j = i
      while j <= n and chars[j] == "`" do
        j = j + 1
      end
      local run = j - i
      local a, b = find_run(chars, j, "`", run)
      if a then
        for k = i, b do
          flags[k] = true
        end
        i = b + 1
      else
        for k = i, j - 1 do
          flags[k] = true
        end
        i = j
      end
    elseif ch == "$" then
      local double = chars[i + 1] == "$"
      local a = double and i + 1 or i
      local found = nil
      for k = a + 1, n do
        if chars[k] == "$" then
          found = k
          break
        end
      end
      if found then
        for k = i, found do
          flags[k] = true
        end
        i = found + 1
      else
        -- 未闭合：$$ 开块（跨行），单个 $ 当普通字符
        if double then
          flags[i] = true
          flags[i + 1] = true
          state.math = true
          return flags, state
        end
        i = i + 1
      end
    elseif ch == "<" and chars[i + 1] and chars[i + 1]:match("[A-Za-z/!]") then
      local found = nil
      for k = i + 1, n do
        if chars[k] == ">" then
          found = k
          break
        end
      end
      if found then
        for k = i, found do
          flags[k] = true
        end
        i = found + 1
      else
        i = i + 1
      end
    elseif ch == "]" and chars[i + 1] == "(" then
      local found = match_bracket(chars, i + 1, "(", ")")
      if found then
        for k = i + 1, found do
          flags[k] = true
        end
        i = found + 1
      else
        i = i + 1
      end
    elseif ch == "h" or ch == "f" or ch == "w" then
      -- 裸 URL：http(s):// ftp:// www.
      local rest = table.concat(chars, "", i, math.min(n, i + 7))
      if rest:match("^https?://") or rest:match("^ftp://") or rest:match("^www%.") then
        local j = i
        while j <= n and not chars[j]:match("[%s%)%]>\"'`]") do
          j = j + 1
        end
        for k = i, j - 1 do
          flags[k] = true
        end
        i = j
      else
        i = i + 1
      end
    else
      i = i + 1
    end
  end

  -- $$ 块公式跨行：上一行开了没关
  if state.math then
    for k = 1, n do
      flags[k] = true
    end
    local text = table.concat(chars)
    if text:find("%$%$") then
      state.math = false
    end
  end
  return flags, state
end

-- ── typst ──

--- # 之后 typst 代码段的结束位置：允许命令名、链式调用、字符串、括号；
--- 遇 [（内容区）、$（公式）或汉字即停
---@return integer
local function typst_code_end(chars, i)
  local n = #chars
  local j = i + 1
  -- 全角括号也当作代码段（#show: f（x）这种误输入要靠保护区内的全角→半角修回）
  local CODE_PUNCT = ":_.,()=+-*/<>!&|'%#（）"
  while j <= n do
    local ch = chars[j]
    if ch == '"' then
      local k = j + 1
      while k <= n and chars[k] ~= '"' do
        k = k + 1
      end
      if k > n then
        break
      end
      j = k + 1
    elseif ch:match("[%w_]") or ch == " " or ch == "\t" then
      j = j + 1
    elseif CODE_PUNCT:find(ch, 1, true) then
      j = j + 1
    else
      break
    end
  end
  return j - 1
end

local function step_typst(chars, state)
  local n = #chars
  local flags = blank_flags(n)

  if state.math then
    for k = 1, n do
      flags[k] = true
    end
    for k = 1, n do
      if chars[k] == "$" and chars[k - 1] ~= "\\" then
        state.math = false
        break
      end
    end
    return flags, state
  end

  -- 块级 raw：``` … ```（跨行，可带语言标签）
  if state.raw_fence then
    for k = 1, n do
      flags[k] = true
    end
    if md_fence_close(chars, state.raw_fence) then
      state.raw_fence = nil
    end
    return flags, state
  end
  local fence = md_fence(chars)
  if fence then
    for k = 1, n do
      flags[k] = true
    end
    state.raw_fence = fence
    return flags, state
  end

  local i = 1
  while i <= n do
    local ch = chars[i]
    if ch == "#" and chars[i + 1] and chars[i + 1]:match("[%a_]") then
      -- typst 代码段（#show: / #set text(...) / #emph …）：整体保护
      local b = typst_code_end(chars, i)
      for k = i, b do
        flags[k] = true
      end
      i = b + 1
    elseif ch == "/" and chars[i + 1] == "/" then
      for k = i, n do
        flags[k] = true
      end
      break
    elseif ch == "`" then
      local j = i
      while j <= n and chars[j] == "`" do
        j = j + 1
      end
      local run = j - i
      local a, b = find_run(chars, j, "`", run)
      if a then
        for k = i, b do
          flags[k] = true
        end
        i = b + 1
      else
        for k = i, j - 1 do
          flags[k] = true
        end
        i = j
      end
    elseif ch == "$" and chars[i - 1] ~= "\\" then
      -- 同行找配对的 $
      local found = nil
      for k = i + 1, n do
        if chars[k] == "$" and chars[k - 1] ~= "\\" then
          found = k
          break
        end
      end
      if found then
        for k = i, found do
          flags[k] = true
        end
        i = found + 1
      else
        flags[i] = true
        state.math = true
        i = i + 1
      end
    else
      i = i + 1
    end
  end
  return flags, state
end

-- ── tex ──
local TEX_VERBATIM_ENVS = {
  verbatim = true,
  Verbatim = true,
  lstlisting = true,
  minted = true,
  verbatimstar = true,
}

local TEX_ARG_CMDS = {
  url = true,
  href = true,
  cite = true,
  citep = true,
  citet = true,
  ref = true,
  eqref = true,
  autoref = true,
  label = true,
  includegraphics = true,
  input = true,
  include = true,
  bibliography = true,
  verb = true,
  lstinline = true,
  mintinline = true,
}

local function step_tex(chars, state)
  local n = #chars
  local flags = blank_flags(n)

  -- verbatim 环境内部：整行保护，直到 \end{env}
  if state.verbatim_env then
    for k = 1, n do
      flags[k] = true
    end
    local text = table.concat(chars)
    if text:find("\\end{" .. state.verbatim_env .. "}") then
      state.verbatim_env = nil
    end
    return flags, state
  end

  if state.math then
    for k = 1, n do
      flags[k] = true
    end
    for k = 1, n do
      if chars[k] == "$" and chars[k - 1] ~= "\\" then
        state.math = false
      elseif chars[k] == "\\" and (chars[k + 1] == ")" or chars[k + 1] == "]") then
        state.math = false
      end
    end
    return flags, state
  end

  -- 行首 verbatim 环境
  local begin_env = table.concat(chars):match("^%s*\\begin{(%a+%*?)}")
  if begin_env and TEX_VERBATIM_ENVS[begin_env] then
    for k = 1, n do
      flags[k] = true
    end
    state.verbatim_env = begin_env
    return flags, state
  end

  local i = 1
  while i <= n do
    local ch = chars[i]
    if ch == "%" and chars[i - 1] ~= "\\" then
      for k = i, n do
        flags[k] = true
      end
      break
    elseif ch == "\\" then
      -- \verb|...| / \verb{...}
      local name = table.concat(chars, "", i + 1, math.min(n, i + 12)):match("^(%a+)")
      if name == "verb" or name == "lstinline" or name == "mintinline" then
        local d = i + 1 + #name
        -- mintinline 可能带 {lang} 前缀
        if chars[d] == "{" then
          local close = match_bracket(chars, d, "{", "}")
          d = close and close + 1 or d
        end
        while d <= n and chars[d] == " " do
          d = d + 1
        end
        local delim = chars[d]
        if delim then
          local close = nil
          for k = d + 1, n do
            if chars[k] == delim then
              close = k
              break
            end
          end
          flags[i] = true
          for k = i + 1, close or n do
            flags[k] = true
          end
          i = (close or n) + 1
        else
          i = i + 1
        end
      elseif name and TEX_ARG_CMDS[name] then
        local d = i + 1 + #name
        while d <= n and chars[d] == " " do
          d = d + 1
        end
        if chars[d] == "[" then
          local close = match_bracket(chars, d, "[", "]")
          d = close and close + 1 or d
        end
        if chars[d] == "{" then
          local close = match_bracket(chars, d, "{", "}")
          flags[i] = true
          for k = i + 1, close or n do
            flags[k] = true
          end
          i = (close or n) + 1
        else
          i = i + 1
        end
      else
        i = i + 1
      end
    elseif ch == "$" and chars[i - 1] ~= "\\" then
      local found = nil
      for k = i + 1, n do
        if chars[k] == "$" and chars[k - 1] ~= "\\" then
          found = k
          break
        end
      end
      if found then
        for k = i, found do
          flags[k] = true
        end
        i = found + 1
      else
        flags[i] = true
        state.math = true
        i = i + 1
      end
    elseif ch == "\\" and (chars[i + 1] == "(" or chars[i + 1] == "[") then
      local close = chars[i + 1] == "(" and ")" or "]"
      local found = nil
      for k = i + 2, n - 1 do
        if chars[k] == "\\" and chars[k + 1] == close then
          found = k + 1
          break
        end
      end
      if found then
        for k = i, found do
          flags[k] = true
        end
        i = found + 1
      else
        flags[i] = true
        if chars[i + 1] then
          flags[i + 1] = true
        end
        state.math = true
        i = i + 2
      end
    else
      i = i + 1
    end
  end
  return flags, state
end

local STEPPERS = {
  markdown = step_markdown,
  typst = step_typst,
  tex = step_tex,
}

--- filetype → 扫描器类型
---@param ft string
---@return string
function M.kind(ft)
  if ft == "typst" then
    return "typst"
  elseif ft == "tex" or ft == "plaintex" or ft == "latex" or ft == "context" then
    return "tex"
  end
  return "markdown"
end

--- 初始跨行状态
---@param ft string
---@return table
function M.initial_state(ft)
  local kind = M.kind(ft)
  local state = { kind = kind }
  if kind == "markdown" then
    state.frontmatter = false
    state.frontmatter_seen = false
    state.fence = nil
    state.math = false
  elseif kind == "typst" then
    state.math = false
  else
    state.math = false
    state.verbatim_env = nil
  end
  return state
end

--- 推进一行
---@param chars string[]
---@param state table
---@return boolean[] flags, table state
function M.step(chars, state)
  local stepper = STEPPERS[state.kind] or step_markdown
  return stepper(chars, state)
end

--- 整篇扫描（给测试/保存时用）
---@param lines string[]
---@param ft string
---@return boolean[][] 每行、每字符是否受保护
function M.masks(lines, ft)
  local state = M.initial_state(ft)
  local out = {}
  for i, line in ipairs(lines) do
    out[i], state = M.step(M.chars(line), state)
  end
  return out
end

-- ─────────────────────── 规则 1：盘古之白 ───────────────────────

--- 中英、中文与数字之间补一个半角空格（幂等：已有空格不会再补）
---@param text string
---@return string
function M.pangu(text)
  local chars = M.chars(text)
  local out = {}
  local prev = nil
  for _, ch in ipairs(chars) do
    if prev then
      if (M.is_cjk(prev) and M.is_word(ch)) or (M.is_word(prev) and M.is_cjk(ch)) then
        out[#out + 1] = " "
      end
    end
    out[#out + 1] = ch
    prev = ch
  end
  return table.concat(out)
end

-- ─────────────────────── 规则 2：数字与单位 ───────────────────────

-- 白名单（长优先）。故意不含 B/T/F/C：UTF-8B、5T 硬盘、100C 这类误伤比收益大。
local UNITS = {
  "kmol",
  "kcal",
  "kPa",
  "MPa",
  "hPa",
  "kHz",
  "MHz",
  "GHz",
  "kW",
  "kWh",
  "keV",
  "MeV",
  "GeV",
  "TeV",
  "KiB",
  "MiB",
  "GiB",
  "TiB",
  "mA",
  "µA",
  "µL",
  "µg",
  "µs",
  "µm",
  "μL",
  "μg",
  "μm",
  "ns",
  "nm",
  "cm",
  "mm",
  "km",
  "ms",
  "kg",
  "mg",
  "mL",
  "dB",
  "bit",
  "byte",
  "KB",
  "MB",
  "GB",
  "TB",
  "PB",
  "px",
  "pt",
  "em",
  "rem",
  "dpi",
  "ppm",
  "rpm",
  "fps",
  "bar",
  "atm",
  "mol",
  "min",
  "Hz",
  "Pa",
  "kJ",
  "eV",
  "m",
  "g",
  "s",
  "h",
  "A",
  "V",
  "W",
  "J",
  "N",
  "K",
  "L",
}
table.sort(UNITS, function(a, b)
  return #a > #b
end)

--- 从 j 开始匹配一个白名单单位，要求词边界（后面不是字母/数字/µ）
---@return string|nil
local function match_unit(chars, j)
  local n = #chars
  if j > n then
    return nil
  end
  local rest = table.concat(chars, "", j, math.min(n, j + 7))
  for _, u in ipairs(UNITS) do
    if rest:sub(1, #u) == u then
      local after = chars[j + #u]
      if not after or not (M.is_word(after) or after == "µ" or after == "μ" or after == "_") then
        return u
      end
    end
  end
  return nil
end

-- typst/tex 源码里单位紧贴数字是语法（11pt / 2.5em / 1cm），不能拆
local LEN_UNITS = {
  pt = true,
  em = true,
  rem = true,
  px = true,
  cm = true,
  mm = true,
  ["in"] = true,
  ex = true,
  mu = true,
  fr = true,
  deg = true,
  rad = true,
}

local function is_digit(ch)
  return ch ~= nil and #ch == 1 and ch:match("%d") ~= nil
end

--- 数字与白名单单位之间补空格；% ° ℃ 紧跟数字
---@param text string
---@param opts? {skip_len_units?: boolean} typst/tex 源码里长度单位（11pt/2.5em）不拆
---@return string
function M.units(text, opts)
  local chars = M.chars(text)
  local n = #chars
  local out = {}
  local i = 1
  while i <= n do
    if not is_digit(chars[i]) then
      out[#out + 1] = chars[i]
      i = i + 1
    else
      -- 数字串（含小数部分）
      local j = i
      while j <= n and (is_digit(chars[j]) or (chars[j] == "." and is_digit(chars[j + 1]))) do
        j = j + 1
      end
      local number = table.concat(chars, "", i, j - 1)
      local prev = chars[i - 1]
      local standalone = not (prev and (M.is_word(prev) or prev == "_" or prev == "."))

      local k = j
      while k <= n and chars[k] == " " do
        k = k + 1
      end
      local spaced = k > j
      local nextch = chars[k]

      if nextch == "%" or nextch == "℃" or nextch == "°" then
        out[#out + 1] = number
        out[#out + 1] = nextch
        if nextch == "°" and (chars[k + 1] == "C" or chars[k + 1] == "F") then
          out[#out + 1] = chars[k + 1]
          i = k + 2
        else
          i = k + 1
        end
      elseif not spaced then
        local u = standalone and match_unit(chars, j) or nil
        if u and opts and opts.skip_len_units and LEN_UNITS[u] then
          u = nil
        end
        if u then
          out[#out + 1] = number .. " " .. u
          i = j + #M.chars(u)
        else
          out[#out + 1] = number
          i = j
        end
      else
        out[#out + 1] = number
        i = j
      end
    end
  end
  return table.concat(out)
end

-- ─────────────────────── 规则 3：标点 ───────────────────────

local FULL_TO_HALF = {
  ["，"] = ",",
  ["。"] = ".",
  ["："] = ":",
  ["；"] = ";",
  ["！"] = "!",
  ["？"] = "?",
  ["（"] = "(",
  ["）"] = ")",
  ["【"] = "[",
  ["】"] = "]",
  ["“"] = '"',
  ["”"] = '"',
  ["‘"] = "'",
  ["’"] = "'",
  ["、"] = ",",
  ["－"] = "-",
  ["＝"] = "=",
  ["＋"] = "+",
  ["／"] = "/",
  ["＼"] = "\\",
  ["｜"] = "|",
  ["＆"] = "&",
  ["＊"] = "*",
  ["＃"] = "#",
  ["％"] = "%",
  ["＠"] = "@",
  ["～"] = "~",
  ["＄"] = "$",
  ["＜"] = "<",
  ["＞"] = ">",
  ["｛"] = "{",
  ["｝"] = "}",
  ["［"] = "[",
  ["］"] = "]",
  ["　"] = " ",
}

--- 保护区（代码/公式/raw）：全角标点 → 半角，但标点两侧任一侧是汉字就保留
---@param text string
---@return string
function M.punct_full_to_half(text)
  local chars = M.chars(text)
  local out = {}
  for i, ch in ipairs(chars) do
    local half = FULL_TO_HALF[ch]
    if half then
      local adjacent_cjk = M.is_cjk(chars[i - 1]) or M.is_cjk(chars[i + 1])
      out[#out + 1] = adjacent_cjk and ch or half
    else
      out[#out + 1] = ch
    end
  end
  return table.concat(out)
end

local HALF_TO_FULL = {
  [","] = "，",
  ["."] = "。",
  [":"] = "：",
  [";"] = "；",
  ["!"] = "！",
  ["?"] = "？",
}

-- 右邻字符是否禁止转换
local function blocked_after(ch, nextch)
  if not nextch then
    return false
  end
  if ch == "." then
    -- 别把 ... / 文件.txt / 3.14 / 路径 点坏
    return nextch == "." or M.is_word(nextch) or nextch == "/" or nextch == "\\"
  elseif ch == "!" then
    -- markdown 图片 ![alt]
    return nextch == "["
  end
  return false
end

-- 全角标点后该清掉的空格：只用叙述性标点，不含括号/引号（「（中文） x」这类可能是刻意对齐）
local SPACE_AFTER_FULL = {
  ["，"] = true,
  ["。"] = true,
  ["、"] = true,
  ["；"] = true,
  ["："] = true,
  ["！"] = true,
  ["？"] = true,
}

--- 全角标点后紧跟的半角空格删掉（rime 转全角标点时残留的那个）
---@param text string
---@param more_follows? boolean 该段之后本行还有字符（此时段尾的空格也可删）；
---  否则段尾空白保留 —— 那是 markdown 行尾两个空格的硬换行，删了会静默改变语义
---@return string
function M.tidy_fullwidth_space(text, more_follows)
  local chars = M.chars(text)
  local out = {}
  local i = 1
  local n = #chars
  while i <= n do
    local ch = chars[i]
    out[#out + 1] = ch
    local j = i + 1
    if SPACE_AFTER_FULL[ch] then
      while j <= n and chars[j] == " " do
        j = j + 1
      end
    end
    -- j > i + 1 才有空格要处理；空格后还有内容（或后面还有别的段）才删
    if j > i + 1 and (j <= n or more_follows) then
      i = j
    else
      i = i + 1
    end
  end
  return table.concat(out)
end

--- 正文（自由区）：紧邻汉字的半角 , . : ; ! ? → 全角；括号/引号按内容语言
---@param text string
---@param opts? {brackets?: boolean} brackets=false 时跳过括号/引号的按语言转换（typst/tex 源码里 () "" 是语法）
---@return string
function M.punct_half_to_full(text, opts)
  local chars = M.chars(text)
  local n = #chars
  local out = {}
  local i = 1
  local do_brackets = not (opts and opts.brackets == false)
  while i <= n do
    local ch = chars[i]
    -- ── 括号：按内容语言 ──
    if do_brackets and (ch == "(" or ch == "（") then
      local open_pat = ch
      local close_pat = (open_pat == "(") and ")" or "）"
      local close = match_bracket(chars, i, open_pat, close_pat)
      if close then
        local inner = table.concat(chars, "", i + 1, close - 1)
        if M.has_cjk(inner) then
          out[#out + 1] = "（" .. inner .. "）"
        else
          out[#out + 1] = "(" .. inner .. ")"
        end
        i = close + 1
      else
        out[#out + 1] = ch
        i = i + 1
      end
      -- ── 引号：按内容语言 ──
    elseif do_brackets and (ch == '"' or ch == "“" or ch == "”") then
      local open_pat = (ch == "”") and "“" or ch
      local close_pat = (open_pat == '"') and '"' or "”"
      local close = nil
      for k = i + 1, n do
        if chars[k] == close_pat then
          close = k
          break
        end
      end
      if close then
        local inner = table.concat(chars, "", i + 1, close - 1)
        if M.has_cjk(inner) then
          out[#out + 1] = "“" .. inner .. "”"
        else
          out[#out + 1] = '"' .. inner .. '"'
        end
        i = close + 1
      else
        out[#out + 1] = ch
        i = i + 1
      end
    else
      local full = HALF_TO_FULL[ch]
      if full and M.is_cjk(chars[i - 1]) and not blocked_after(ch, chars[i + 1]) then
        out[#out + 1] = full
      else
        out[#out + 1] = ch
      end
      i = i + 1
    end
  end
  return table.concat(out)
end

-- ─────────────────────── 对外：整行 / 整篇 ───────────────────────

--- 单行：按 flags 切段，保护区走 punct_full_to_half，自由区走 pangu → units → 标点
---@param line string
---@param flags boolean[]|nil
---@param opts? {skip_len_units?: boolean}
---@return string
function M.fix_line(line, flags, opts)
  local chars = M.chars(line)
  if not flags then
    local free = M.pangu(line)
    free = M.units(free, opts)
    free = M.punct_half_to_full(free, opts)
    return M.tidy_fullwidth_space(free, false)
  end
  local out = {}
  local i = 1
  while i <= #chars do
    local prot = flags[i] and true or false
    local j = i
    while j <= #chars and (flags[j] and true or false) == prot do
      j = j + 1
    end
    local seg = table.concat(chars, "", i, j - 1)
    if prot then
      out[#out + 1] = M.punct_full_to_half(seg)
    else
      local free = M.pangu(seg)
      free = M.units(free, opts)
      free = M.punct_half_to_full(free, opts)
      out[#out + 1] = M.tidy_fullwidth_space(free, j <= #chars)
    end
    i = j
  end
  return table.concat(out)
end

--- 整篇
---@param lines string[]
---@param ft string
---@return string[]
function M.transform_lines(lines, ft)
  local masks = M.masks(lines, ft)
  -- typst/tex 源码：长度单位紧贴数字（11pt、2.5em）不得拆开
  local opts = {
    skip_len_units = ft == "typst" or ft == "tex" or ft == "plaintex" or ft == "latex",
    -- 括号/引号的「按内容语言」只在 markdown（散文）里做，typst/tex 里是语法
    brackets = ft == "markdown",
  }
  local out = {}
  for i, line in ipairs(lines) do
    out[i] = M.fix_line(line, masks[i], opts)
  end
  return out
end

return M
