local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

vim.cmd[[
    let mapleader = "\<space>"
]]
require("lazy").setup({
	{import = "plugins"}
})
vim.o.number = true

vim.o.ts=4
vim.o.softtabstop=4
vim.o.shiftwidth=4
vim.o.expandtab=true
vim.o.autoindent=true

-- 自动将所有 .conf 文件设置为 'config' 文件类型
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.conf" },
  callback = function()
    vim.bo.filetype = "config"
  end,
})

-- 设置剪贴板为系统剪贴板
vim.opt.clipboard = "unnamedplus"

-- 在可视模式下，按 y 复制到系统剪贴板
vim.keymap.set("v", "y", '"+y')

-- 按 Y 复制当前行到系统剪贴板
vim.keymap.set("n", "Y", '"+Y')
require('toggle_terminal')
vim.api.nvim_set_keymap('n', '<C-`>', '<cmd>lua Toggle_Terminal_Below()<CR>', { noremap = true, silent = true, desc = '终端切换（下方）' })
vim.api.nvim_set_keymap('t', '<C-`>', '<C-\\><C-n><cmd>lua Toggle_Terminal_Below()<CR>', { noremap = true, silent = true, desc = '终端切换（从终端模式）' })

-- 从系统剪贴板粘贴
vim.keymap.set("n", "p", '"+p')
vim.keymap.set("v", "p", '"+p')
vim.keymap.set("n", "P", '"+P')
vim.keymap.set("v", "P", '"+P')
require("keymap")
