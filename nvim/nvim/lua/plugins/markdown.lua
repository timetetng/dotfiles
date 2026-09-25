return {
  -- Markdown 渲染：标题/代码块/表格/链接
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>um", "<cmd>RenderMarkdown toggle<cr>", desc = "Markdown 渲染开关" },
    },
    -- 数学公式二选一：kitty 图形协议（snacks）优先，否则回退 unicode（utftex/latex2text）
    opts = function()
      if vim.g.snacks_image_supported then
        return { latex = { enabled = false } }
      end
      return {
        latex = {
          enabled = true,
          converter = { "utftex", "latex2text" },
          inline = true,
          block = true,
        },
      }
    end,
  },
}
