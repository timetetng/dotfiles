return {
  -- Mason: 用来管理 LSP、DAP、Linter、Formatter 的安装
  {
    "williamboman/mason.nvim",
    opts = {
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    },
  },

  -- Mason-LSPConfig: Mason 和 nvim-lspconfig 之间的桥梁
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
  },

  -- nvim-lspconfig: LSP 核心配置
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "saghen/blink.cmp",
      "williamboman/mason-lspconfig.nvim",
    },
    opts = {
      -- 在这里为特定的 LSP 服务器设置选项
      -- 例如:
      -- lua_ls = {
      --   settings = {
      --     Lua = {
      --       diagnostics = {
      --         globals = { "vim" },
      --       },
      --     },
      --   },
      -- },
    },
    config = function(_, opts)
      -- 获取 cmp 提供的 lsp capabilities
      local lsp_capabilities = require("blink.cmp").get_lsp_capabilities()

      -- 使用 mason-lspconfig 来自动化 LSP 服务器的安装和设置
      require("mason-lspconfig").setup({
        -- 确保这些服务器已经通过 Mason 安装
        ensure_installed = { "lua_ls", "pyright" },
        handlers = {
          -- 默认的 handler，为每个服务器应用通用配置
          function(server_name)
            local server_opts = vim.tbl_deep_extend("force", {}, opts[server_name] or {})

            require("lspconfig")[server_name].setup({
              capabilities = vim.tbl_deep_extend("force", {}, lsp_capabilities, server_opts.capabilities or {}),
              settings = server_opts.settings,
              on_attach = function(client, bufnr)
                -- 在这里可以设置每个 buffer 的 on_attach 回调
                -- 例如：vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = bufnr })
              end,
            })
          end,
        },
      })
    end,
  },
}
