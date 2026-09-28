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
      math = {
        enabled = vim.g.snacks_image_supported,
        -- cell 宽 16px(假设的8px的2倍)，公式默认 \Large 会渲染成2倍大。
        -- scriptsize(8pt)≈\Large 的一半，让单字符公式≈1格宽，避免过大与换行截断。
        latex = { font_size = "scriptsize" },
      },
    },
  },

  -- 修正 snacks 行内公式的 +2 格 padding bug(placement.lua:490)。
  -- 它把单字符公式撑成 3 格宽、把长行内公式撑超行宽导致换行截断。
  -- 注意：绝不能写在 spec 顶层——lazy 解析 spec 时 snacks 目录尚未加入
  -- runtimepath，require("snacks.image.placement") 会失败被 pcall 吞掉，
  -- 补丁等于没写（实测确认）。必须放进 config 回调，插件加载、rtp 就绪后再 patch。
  config = function(_, opts)
    require("snacks").setup(opts)
    if vim.g.snacks_image_supported then
      local ok, placement = pcall(require, "snacks.image.placement")
      if ok then
        local orig_state = placement.state
        placement.state = function(self, ...)
          local st = orig_state(self, ...)
          if st and st.loc and st.loc.height == 1 then
            local range = self.opts.range
            if range and range[1] == range[3] then
              local line = vim.api.nvim_buf_get_lines(self.buf, range[1] - 1, range[1], false)[1] or ""
              local has_before = line:sub(1, range[2]):find("%S") ~= nil
              local has_after = line:sub(range[4] + 1):find("%S") ~= nil
              if has_before or has_after then
                st.loc.width = math.max(1, st.loc.width - 2)
              end
            end
          end
          return st
        end
      end
    end

    -- 数学公式只在普通模式渲染，插入模式显示源码（方便改公式）。
    -- 做法：插入模式把 math.enabled 关掉，再手动触发一次 WinScrolled——
    -- snacks.image.inline 监听它（buffer-local）→ 重扫可见区，已有公式被
    -- close、新公式也不再生成；离开插入模式再打开并重扫。全程只用公开配置，
    -- 不碰插件私有 API。
    if vim.g.snacks_image_supported then
      local group = vim.api.nvim_create_augroup("snacks_math_normal_mode", { clear = true })
      local function set_math(enabled)
        local image = require("snacks.image")
        if image.config.math.enabled == enabled then
          return
        end
        image.config.math.enabled = enabled
        vim.api.nvim_exec_autocmds("WinScrolled", { buffer = vim.api.nvim_get_current_buf() })
      end
      vim.api.nvim_create_autocmd("InsertEnter", {
        group = group,
        callback = function()
          set_math(false)
        end,
      })
      vim.api.nvim_create_autocmd("InsertLeave", {
        group = group,
        callback = function()
          set_math(true)
        end,
      })

      -- 行内公式靠 extmark 的 conceal 隐藏源码，而 conceal 只在 conceallevel>=2 时生效；
      -- conceallevel=2 + concealcursor 保持默认（空）⇒ 默认全是渲染图，
      -- 光标移到哪行，哪行显示源码。
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = { "markdown", "typst", "tex", "plaintex" },
        callback = function()
          vim.wo.conceallevel = 2
        end,
      })
    end
  end,

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
