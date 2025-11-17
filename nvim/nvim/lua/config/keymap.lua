local map = vim.keymap.set
-- 可视模式的缩进保持选中
map("v",">",">gv",{ noremap = true, silent = true })
map("v","<","<gv",{ noremap = true, silent = true })
