return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "glepnir/lspsaga.nvim",
      "folke/trouble.nvim",
      "j-hui/fidget.nvim",
      "saghen/blink.cmp",
      "b0o/schemastore.nvim",
    },
    config = function()
      local original_notify = vim.notify
      vim.notify = function(msg, level, opts)
        if type(msg) == "string" and msg:match("framework") and msg:match("deprecated") then
          return
        end
        original_notify(msg, level, opts)
      end

      local lspconfig = require("lspconfig")

      local has_blink, blink = pcall(require, "blink.cmp")
      local capabilities = has_blink and blink.get_lsp_capabilities() or vim.lsp.protocol.make_client_capabilities()

      local on_attach = function(client, bufnr)
        if client.server_capabilities.inlayHintProvider then
          vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end
      end

      -- =====================================================
      -- Mason 初始化（v2.0：移除 automatic_installation）
      -- =====================================================
      require("mason").setup()

      require("mason-lspconfig").setup({
        ensure_installed = {
          "pyright",
          "gopls",
          "marksman",
          "texlab",
          "bashls",
          "lua_ls",
          "html",
          "cssls",
          "jsonls",
          "yamlls",
          "dockerls",
        },
        -- ❌ 删除 automatic_installation，v2.0 已移除该选项
      })

      -- =====================================================
      -- 直接配置各 LSP（替代已废弃的 setup_handlers）
      -- =====================================================

      -- 默认配置：无特殊设置的 server（html, cssls, bashls, marksman, dockerls）
      local default_servers = { "html", "cssls", "bashls", "marksman", "dockerls" }
      for _, server in ipairs(default_servers) do
        lspconfig[server].setup({
          capabilities = capabilities,
          on_attach = on_attach,
        })
      end

      -- Pyright
      lspconfig.pyright.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          python = {
            analysis = {
              typeCheckingMode = "basic",
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = "workspace",
            },
          },
        },
      })

      -- gopls
      lspconfig.gopls.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          gopls = {
            analyses = { unusedparams = true },
            staticcheck = true,
            gofumpt = true,
          },
        },
      })

      -- lua_ls
      lspconfig.lua_ls.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
            },
            telemetry = { enable = false },
          },
        },
      })

      -- jsonls
      lspconfig.jsonls.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          json = {
            schemas = (function()
              local ok, store = pcall(require, "schemastore")
              return ok and store.json.schemas() or {}
            end)(),
            validate = { enable = true },
          },
        },
      })

      -- yamlls
      lspconfig.yamlls.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          yaml = { keyOrdering = false },
        },
      })

      -- texlab
      lspconfig.texlab.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          texlab = {
            build = { onSave = true },
          },
        },
      })

      -- =================== 组件配置 ===================

      local has_lspsaga, lspsaga = pcall(require, "lspsaga")
      if has_lspsaga then
        lspsaga.setup({
          ui = { border = "rounded" },
          symbol_in_winbar = { enable = false },
          lightbulb = { enable = false, virtual_text = false },
        })
      end

      local has_trouble, trouble = pcall(require, "trouble")
      if has_trouble then
        trouble.setup({
          win = { position = "bottom", height = 0.3 },
          icons = {
            error = " ",
            warning = " ",
            hint = " ",
            information = " ",
          },
        })
      end
    end,
  },
}
