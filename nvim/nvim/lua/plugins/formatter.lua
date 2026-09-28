return {
  {
    "stevearc/conform.nvim",
    opts = {
      -- 中英混排：自研纯 Lua 规则（零外部依赖），规则本体见 lua/cjk/init.lua
      formatters = {
        cjk = {
          format = function(_, ctx, lines, callback)
            require("config.cjk").conform_format(ctx, lines, callback)
          end,
        },
      },
      formatters_by_ft = {
        markdown = { "cjk" },
        typst = { "cjk" },
        tex = { "cjk" },
        plaintex = { "cjk" },
        lua = { "stylua" },
        python = { "black" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        json = { "jq" },
        sh = { "shfmt" },
        c = { "clang-format" }, -- 添加 C 语言
        cc = { "clang-format" },
        cpp = { "clang-format" }, -- 如果写 C++ 也用 clang-format
        html = { "prettier" }, -- 添加 HTML 格式化工具
        css = { "prettier" }, -- 添加 CSS 格式化工具
      },
      -- 注意：lsp_fallback = false，所以这些 filetype 保存时只跑 cjk 规则
      -- （typst/tex 的 LSP 格式化本来就未启用）
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = false,
      },
    },
  },
}
