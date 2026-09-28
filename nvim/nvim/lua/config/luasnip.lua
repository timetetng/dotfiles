-- LuaSnip：片段引擎（blink.cmp 的 snippets source 通过 preset='luasnip' 读取）
--   · friendly-snippets（VSCode 格式）继续对其它语言生效
--   · typst 自定义片段在 lua/snippets/typst.lua（保存后自动重载，见文件末尾）
--   · 对外提供 snippet_descriptions()：blink 菜单右侧的灰字说明
local ls = require("luasnip")

local M = {}

local SNIP_DIR = vim.fn.stdpath("config") .. "/lua/snippets"

ls.config.set_config({
  history = true,
  -- 让 LuaSnip 在插入模式下也能感知文本变化（片段跳转/恢复必需）
  updateevents = "TextChanged,TextChangedI",
  enable_autosnippets = true,
})

-- 其它语言：沿用 friendly-snippets（与之前 vim.snippet 时的覆盖范围一致）
require("luasnip.loaders.from_vscode").lazy_load()

-- typst 自定义片段
require("luasnip.loaders.from_lua").lazy_load({ paths = { SNIP_DIR } })

-- ─────────────── 使用次数统计（给 `typ snippets --stats` 看） ───────────────
local USAGE_FILE = vim.fn.expand("~/.cache/typ/snippet-usage.json")

local function bump_usage(trigger)
  local data = {}
  local f = io.open(USAGE_FILE, "r")
  if f then
    local content = f:read("*a")
    f:close()
    local ok, decoded = pcall(vim.json.decode, content)
    if ok and type(decoded) == "table" then
      data = decoded
    end
  end
  data[trigger] = (data[trigger] or 0) + 1
  vim.fn.mkdir(vim.fn.fnamemodify(USAGE_FILE, ":h"), "p")
  local out = io.open(USAGE_FILE, "w")
  if out then
    out:write(vim.json.encode(data))
    out:close()
  end
end

-- 包一层 snip_expand：只统计形如 sum / ff / RR 这种简单触发词，
-- 不统计 lsp_expand 生成的整段 body（那种 trigger 里带空格换行）
local orig_snip_expand = ls.snip_expand
ls.snip_expand = function(snip, opts)
  local trig = snip and snip.trigger
  if type(trig) == "string" and trig:match("^%a[%w]*$") then
    pcall(bump_usage, trig)
  end
  return orig_snip_expand(snip, opts)
end

-- ─────────────── 描述（blink 菜单里的灰字） ───────────────
-- blink 的 luasnip provider 构造补全项时**不会**带上 LuaSnip 的 dscr
-- （见 blink.cmp/lua/blink/cmp/sources/snippets/luasnip.lua:98-113 只填了
-- label/insertText/sortText/data），而菜单的 label_description 列读的是
-- item.labelDetails.description（blink.cmp/lua/blink/cmp/completion/windows/render/context.lua:63）。
-- 所以这里给出 id → 描述 的映射，由 blink 的 snippets provider 的
-- transform_items 补到每个 item 上（配置在 lua/plugins/blink-cmp.lua）。
local dscr_cache = nil

--- LuaSnip 片段 id → dscr 描述
---@return table<integer, string>
function M.snippet_descriptions()
  if dscr_cache then
    return dscr_cache
  end
  local map = {}
  pcall(function()
    for _, ft in ipairs(require("luasnip.util.util").get_snippet_filetypes()) do
      for _, snip in ipairs(ls.get_snippets(ft, { type = "snippets" })) do
        local d = snip.dscr
        local text = type(d) == "table" and table.concat(d, " ") or (type(d) == "string" and d or nil)
        if snip.id and text and text ~= "" then
          map[snip.id] = text
        end
      end
    end
  end)
  dscr_cache = map
  return map
end

-- ─────────────── 改完片段文件保存即生效 ───────────────
-- LuaSnip 的 lazy_load 已经给 SNIP_DIR 注册了文件监视器（内置 fs_event /
-- BufWritePost 回退），保存即重载，不用自己写 autocmd。
--
-- 但重载只是把旧片段标记为 invalidated（为性能默认不立刻回收），
-- 而 blink 的补全菜单读的是 get_snippets()，会把失效的旧条目也列出来 →
-- 保存后菜单里会短暂出现重复项。LuasnipSnippetsAdded 事件在每次重载
-- 完成后触发，在这里直接回收一次即可（本 autocmd 注册得比 blink 的缓存
-- 刷新早，所以 blink 拿到的已经是干净的列表）。
vim.api.nvim_create_autocmd("User", {
  group = vim.api.nvim_create_augroup("LuaSnipCleanInvalidated", { clear = true }),
  pattern = "LuasnipSnippetsAdded",
  desc = "片段重载后立刻回收被替换的旧片段（否则补全菜单有重复项）",
  callback = function()
    dscr_cache = nil -- 片段变了，描述缓存作废
    pcall(function()
      require("luasnip.session.snippet_collection").clean_invalidated({})
    end)
  end,
})

return M
