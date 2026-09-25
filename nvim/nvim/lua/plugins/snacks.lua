-- kitty 图形协议终端检测（kitty/ghostty/wezterm）
local function graphics_ok()
  local e = vim.env
  if e.KITTY_WINDOW_ID or e.GHOSTTY_RESOURCES_DIR or e.WEZTERM_PANE then
    return true
  end
  local t = ((e.TERM or "") .. " " .. (e.TERM_PROGRAM or "")):lower()
  return t:find("kitty") ~= nil or t:find("ghostty") ~= nil or t:find("wezterm") ~= nil
end
vim.g.snacks_image_supported = graphics_ok()

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    indent = {
      enabled = true,

      -- 背景灰色普通缩进线
      indent = {
        priority = 1,
        enabled = true, -- enable indent guides
        char = "│",
        only_scope = false, -- only show indent guides of the scope
        only_current = false, -- only show indent guides in the current window
      },

      -- 当前所在代码块
      scope = {
        enabled = true, -- enable highlighting the current scope
        priority = 200,
        char = "│",
        underline = false, -- underline the start of the scope
        only_current = false, -- only show scope in the current window
        hl = "SnacksIndentScope", ---@type string|string[] hl group for scopes
      },
    },

    -- 替代telescope
    picker = {
      enabled = true,
      win = {
        input = {
          keys = {
            ["<S-Tab>"] = { "list_up", mode = { "i", "n" } },
            ["<Tab>"] = { "list_down", mode = { "i", "n" } },
          },
        },

        list = {
          keys = {
            ["<S-Tab>"] = { "list_up", mode = { "i", "n" } },
            ["<Tab>"] = { "list_down", mode = { "i", "n" } },
          },
        },
      },
    },

    notifier = {
      enabled = true,
      timeout = 2000,
    },

    scope = { enabled = true },
    dashboard = { enabled = true },
    input = { enabled = true },

    -- 仅在支持图形协议的终端渲染图片/公式；否则 foot 等会弹出空白浮窗
    image = {
      enabled = vim.g.snacks_image_supported,
      math = { enabled = vim.g.snacks_image_supported },
    },
  },

  keys = {
    {
      "<leader>fb",
      function()
        Snacks.picker.buffers()
      end,
      desc = "Buffers",
    },
    {
      "<leader>ff",
      function()
        Snacks.picker.files()
      end,
      desc = "Find Files",
    },
    {
      "<leader>fg",
      function()
        Snacks.picker.grep()
      end,
      desc = "Find Grep",
    },
    {
      "<leader>fp",
      function()
        Snacks.picker.projects()
      end,
      desc = "Projects",
    },
    {
      "<leader>fr",
      function()
        Snacks.picker.recent()
      end,
      desc = "Recent",
    },
    {
      "<leader>:",
      function()
        Snacks.picker.command_history()
      end,
      desc = "Command History",
    },
    {
      "<leader>/",
      function()
        Snacks.picker.search_history()
      end,
      desc = "Search History",
    },

    {
      "<leader>sd",
      function()
        Snacks.picker.diagnostics()
      end,
      desc = "Diagnostics",
    },

    {
      "gd",
      function()
        Snacks.picker.lsp_definitions()
      end,
      desc = "Goto Definition",
    },
    {
      "gD",
      function()
        Snacks.picker.lsp_declarations()
      end,
      desc = "Goto Declaration",
    },
    {
      "gr",
      function()
        Snacks.picker.lsp_references()
      end,
      nowait = true,
      desc = "References",
    },
    {
      "gI",
      function()
        Snacks.picker.lsp_implementations()
      end,
      desc = "Goto Implementation",
    },
    {
      "gy",
      function()
        Snacks.picker.lsp_type_definitions()
      end,
      desc = "Goto T[y]pe Definition",
    },
    {
      "<leader>gs",
      function()
        Snacks.picker.git_status()
      end,
      desc = "Git Status",
    },
    {
      "<leader>gd",
      function()
        Snacks.picker.git_diff()
      end,
      desc = "Git Diff (Hunks)",
    },

    {
      "gai",
      function()
        Snacks.picker.lsp_incoming_calls()
      end,
      desc = "C[a]lls Incoming",
    },
    {
      "gao",
      function()
        Snacks.picker.lsp_outgoing_calls()
      end,
      desc = "C[a]lls Outgoing",
    },
    {
      "<leader>ss",
      function()
        Snacks.picker.lsp_symbols()
      end,
      desc = "LSP Symbols",
    },
    {
      "<leader>sS",
      function()
        Snacks.picker.lsp_workspace_symbols()
      end,
      desc = "LSP Workspace Symbols",
    },
  },
}
