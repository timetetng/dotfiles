-- lua/plugins/which-key.lua
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,
  config = function()
    local wk = require("which-key")
    wk.setup({
      preset = "classic",
      win = {
        -- 设置为右下角
        border = "rounded",
        -- 调整宽度和位置偏移
        width = 0.3,
        row = 0.99,
        col = 0.99,
      },
      layout = {
        height = { min = 4, max = 25 },
        width = { min = 20, max = 50 },
        spacing = 3,
        align = "left",
      },
    })

    -- 示例注册
    wk.add({
      { "<leader>f", group = "文件操作" },
      { "<leader>g", group = "Git" },
    })
  end,
}
