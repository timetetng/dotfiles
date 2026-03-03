-- lua/plugins/noice.lua
return {
  "folke/noice.nvim",
  dependencies = {
    "MunifTanjim/nui.nvim", -- 必须
  },
  config = function()
    require("noice").setup({
      -- 命令行配置
      cmdline = {
        enabled = true, -- 启用 Noice 命令行
        view = "cmdline_popup", -- 浮窗形式
        format = {
          cmdline = { pattern = "^:", icon = "", lang = "vim" },
          search_down = { pattern = "^/", icon = "", lang = "regex" },
          search_up = { pattern = "^%?", icon = "", lang = "regex" },
          lua = { pattern = "^:%s*lua%s+", icon = "", lang = "lua" },
        },
      },

      -- 将命令行移动到上方
      views = {
        cmdline_popup = {
          position = {
            row = 3, -- 距离顶部 2 行，你可以改为 0 或其他数字
            col = "50%",
          },
          size = {
            width = 60,
            height = "auto",
          },
        },
        popupmenu = {
          relative = "editor",
          position = {
            row = 8, -- 输入命令时的补全菜单也要相应下移，否则会遮挡输入框
            col = "50%",
          },
          size = {
            width = 60,
            height = 10,
          },
          border = {
            style = "rounded",
            padding = { 0, 1 },
          },
          win_options = {
            winhighlight = { Normal = "Normal", FloatBorder = "DiagnosticInfo" },
          },
        },
      },

      -- LSP 配置
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
        },
        progress = { enabled = false, view = "mini" },
        hover = { enabled = false },
        signature = { enabled = false },
        message = { enabled = false, view = "notify" },
      },

      notify = {
        enabled = false,
      },

      -- 预设
      presets = {
        bottom_search = false,
        command_palette = false,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = false,
      },
    })
  end,
}
