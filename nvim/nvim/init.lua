-- init.lua

-- bootstrap
require("config.options")
require("config.keymaps")
require("config.lazy")
-- 启用 OSC 52 剪贴板提供程序
vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
    ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
  },
  paste = {
    ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
    ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
  },
}

vim.opt.clipboard = "unnamedplus"

-- 光标闪烁
vim.opt.guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250"
-- 开启 24-bit RGB 真色彩支持（foot 完美支持）
vim.opt.termguicolors = true
