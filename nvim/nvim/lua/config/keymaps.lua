-- lua/keymaps.lua

-- ===============================
-- 快捷键辅助函数优化
-- ===============================
-- 修改了 map 函数，让它默认接受一个 desc（描述）参数
-- 这样绑定的同时就能告诉 which-key 这个键是干嘛的，一劳永逸
local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, desc = desc })
end

-- leader 键
vim.g.mapleader = " " -- 空格为 leader

-- ===============================
-- BufferLine 标签页操作
-- ===============================
map("n", "<leader><PageDown>", ":BufferLineCycleNext<CR>", "下一个 Buffer")
map("n", "<leader><PageUp>", ":BufferLineCyclePrev<CR>", "上一个 Buffer")

-- 快速跳转到指定 Tab（1~9）(这些可以在 which-key 里隐藏掉以节省空间)
for i = 1, 9 do
  map("n", "<leader>" .. i, ":BufferLineGoToBuffer " .. i .. "<CR>", "跳转到 Buffer " .. i)
end

-- 关闭当前 Tab
map("n", "<leader>c", ":bdelete!<CR>", "关闭当前 Buffer")

-- 设置显示 / 不显示 tab
map("n", "<leader>tb", function()
  if vim.o.showtabline == 0 then
    vim.o.showtabline = 2
  else
    vim.o.showtabline = 0
  end
end, "切换 Buffer 栏显示")

-- ===============================
-- 分屏与窗口移动 (建议在 which-key 中隐藏提示)
-- ===============================
map("n", "<leader>h", "<C-w>h", "移动到左窗口")
map("n", "<leader>j", "<C-w>j", "移动到下窗口")
map("n", "<leader>k", "<C-w>k", "移动到上窗口")
map("n", "<leader>l", "<C-w>l", "移动到右窗口")

-- ===============================
-- 基础文件操作
-- ===============================
map("n", "<leader>w", ":w<CR>", "保存文件")
map("n", "<leader>q", ":q<CR>", "退出")
map("n", "<leader>e", ":Neotree toggle<CR>", "文件树 (Neotree)")

-- ===============================
-- 搜索与高亮操作
-- ===============================
map("n", "<Esc>", "<cmd>nohlsearch<CR>", "取消搜索高亮")

-- ===============================
-- 终端与系统剪贴板操作
-- ===============================
-- 在终端模式中按 Esc 直接退出到普通模式
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { noremap = true, silent = true, desc = "退出终端插入模式" })

-- 兼容终端中使用 Ctrl+C/X/V 复制粘贴系统剪贴板
vim.keymap.set("v", "<C-c>", [["+y]], { noremap = true, silent = true, desc = "复制到系统剪贴板" })
vim.keymap.set("n", "<C-c>", [["+yy]], { noremap = true, silent = true, desc = "复制整行到剪贴板" })
vim.keymap.set("v", "<C-x>", [["+d]], { noremap = true, silent = true, desc = "剪切到系统剪贴板" })
vim.keymap.set("n", "<C-x>", [["+dd]], { noremap = true, silent = true, desc = "剪切整行到剪贴板" })
vim.keymap.set("n", "<C-v>", [["+p]], { noremap = true, silent = true, desc = "粘贴系统剪贴板" })
vim.keymap.set("v", "<C-v>", [["+p]], { noremap = true, silent = true, desc = "粘贴系统剪贴板" })

-- ===============================
-- 文本选择与缩进
-- ===============================
map("n", "vv", "v%", "选中匹配的括号/标签")
map("n", "vc", "viw", "选中当前单词")
map("n", "vl", "V", "选中整行")

vim.keymap.set("v", "<Tab>", ">", { noremap = true, silent = true, desc = "增加缩进" })
vim.keymap.set("v", "<S-Tab>", "<", { noremap = true, silent = true, desc = "减少缩进" })

-- ===============================
-- 问题诊断 (Trouble)
-- ===============================
map("n", "<leader>xx", ":Trouble diagnostics toggle<CR>", "诊断面板 (Trouble)")

-- ===============================
-- 自定义悬浮终端 (Float Terminal)
-- ===============================
local float_term = {}
float_term.term_buf = nil
float_term.term_win = nil
float_term.term_chan = nil

local float_width = 0.75
local float_height = 0.75

-- 打开或复用浮窗终端
function float_term.open()
  if float_term.term_buf and vim.api.nvim_buf_is_valid(float_term.term_buf) then
    if float_term.term_win and vim.api.nvim_win_is_valid(float_term.term_win) then
      vim.api.nvim_set_current_win(float_term.term_win)
    else
      local width = math.floor(vim.o.columns * float_width)
      local height = math.floor(vim.o.lines * float_height)
      local row = math.floor((vim.o.lines - height) / 2)
      local col = math.floor((vim.o.columns - width) / 2)
      float_term.term_win = vim.api.nvim_open_win(float_term.term_buf, true, {
        style = "minimal",
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        border = "rounded",
      })
    end
    vim.cmd("startinsert")
    return float_term.term_chan
  end

  float_term.term_buf = vim.api.nvim_create_buf(false, true)

  local width = math.floor(vim.o.columns * float_width)
  local height = math.floor(vim.o.lines * float_height)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  float_term.term_win = vim.api.nvim_open_win(float_term.term_buf, true, {
    style = "minimal",
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = "rounded",
  })

  float_term.term_chan = vim.fn.termopen({ "zsh", "-i" }, { detach = 0 })
  vim.cmd("startinsert")
  return float_term.term_chan
end

function float_term.send(cmd)
  local chan = float_term.open()
  vim.fn.chansend(chan, cmd .. "\n")
end

function float_term.clear()
  if float_term.term_buf and vim.api.nvim_buf_is_valid(float_term.term_buf) then
    vim.api.nvim_buf_set_lines(float_term.term_buf, 0, -1, false, {})
  end
end

-- 这里加上了 desc，Which-Key 就能认出它了！
map("n", "<leader>ft", float_term.open, "打开悬浮终端")
