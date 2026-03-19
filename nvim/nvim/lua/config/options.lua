-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

-- Nord / Nordic Palette (用于手动高亮微调)
local C = {
  nord0 = "#2E3440", -- 背景
  nord1 = "#3B4252", -- 稍亮的背景
  nord3 = "#4C566A", -- 灰色/注释
  nord4 = "#D8DEE9", -- 雪夜白
  nord6 = "#ECEFF4", -- 最亮的白色
  nord7 = "#8FBCBB", -- 青色
  nord8 = "#88C0D0", -- 浅蓝
  nord9 = "#81A1C1", -- 典型的 Nord 蓝
  nord13 = "#EBCB8B", -- 黄色
  nord14 = "#A3BE8C", -- 绿色
}

vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.termguicolors = true
vim.opt.swapfile = false
vim.opt.mouse = "a"
vim.opt.laststatus = 3

-- 禁止自动注释续行
vim.opt.formatoptions:remove({ "c", "r", "o" })

-- 防止插件重新加回来（特别是 LazyVim）
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    vim.opt.formatoptions:remove({ "c", "r", "o" })
  end,
})

vim.opt.cursorline = true -- 开启光标行高亮
vim.opt.cursorlineopt = "number" -- 只高亮行号

-- 全局 LSP 诊断配置
vim.diagnostic.config({
  signs = false, 
})

-- 创建 :Hv 命令，在新 tab 中垂直打开帮助
vim.api.nvim_create_user_command("Hv", function(opts)
  vim.cmd("vertical help " .. (opts.args ~= "" and opts.args or ""))
end, { nargs = "*", complete = "help" })

vim.o.modeline = false

-- 添加 '-' 词语识别（对 CSS/KDL 等很有用）
vim.opt.iskeyword:append("-")

-- 💠 自定义高亮函数：适配 Nordic 风格
local function apply_custom_highlights()
  -- 1. 设置透明补全菜单 (Pmenu)
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" }) -- 浮窗背景透明
  vim.api.nvim_set_hl(0, "Pmenu", { bg = "NONE", blend = 0 }) -- 补全菜单背景透明
  
  -- 2. 补全菜单选中项：使用 Nord 的青色(nord7)或浅蓝(nord8)，文字设为深色
  vim.api.nvim_set_hl(0, "PmenuSel", { bg = C.nord8, fg = C.nord0, bold = true }) 
  
  -- 3. 边框颜色：使用更明亮的 Nord 蓝色，解决看不清的问题
  vim.api.nvim_set_hl(0, "FloatBorder", { fg = C.nord9, bg = "NONE" }) 

  -- 4. 搜索高亮：使用 Nord 经典的黄色，确保极其醒目
  vim.api.nvim_set_hl(0, "CurSearch", {
    bg = C.nord13,
    fg = C.nord0,
    bold = true,
  })
  vim.api.nvim_set_hl(0, "Search", {
    bg = C.nord3,
    fg = C.nord6,
  })

  -- 5. 增强注释可见度（如果觉得默认还是太灰）
  vim.api.nvim_set_hl(0, "Comment", { fg = "#7B88A1", italic = true })
end

-- 当主题加载或切换时自动应用
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = apply_custom_highlights,
})

-- 使得左右键可以跨行
vim.o.whichwrap = vim.o.whichwrap .. "<>,h,l"

-- 禁止加载 netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
