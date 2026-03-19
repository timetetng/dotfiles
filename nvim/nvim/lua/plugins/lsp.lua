return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      -- 1. 强制依赖 mason，确保环境变量注入在 lspconfig 启动之前
      "williamboman/mason.nvim",
      -- 2. 核心桥接插件：自动将 mason 安装的 server 注册给 lspconfig
      "williamboman/mason-lspconfig.nvim",

      "glepnir/lspsaga.nvim",
      "folke/trouble.nvim",
      "j-hui/fidget.nvim",
      "saghen/blink.cmp",
      "b0o/schemastore.nvim",
    },
    config = function()
      -- 优化 notify，屏蔽冗余信息
      local original_notify = vim.notify
      vim.notify = function(msg, level, opts)
        if type(msg) == "string" and msg:match("framework") and msg:match("deprecated") then
          return
        end
        original_notify(msg, level, opts)
      end

      local lspconfig = require("lspconfig")

      -- 安全加载 blink.cmp，获取 LSP capabilities
      local has_blink, blink = pcall(require, "blink.cmp")
      local capabilities = has_blink and blink.get_lsp_capabilities() or vim.lsp.protocol.make_client_capabilities()

      local on_attach = function(client, bufnr)
        if client.server_capabilities.inlayHintProvider then
          vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end
      end

      -- =======================================================
      -- 核心修复：初始化 Mason 及其桥接插件
      -- =======================================================
      require("mason").setup()

      require("mason-lspconfig").setup({
        -- 确保自动安装你常用的 LSP，不用再手动去 Mason 里点
        ensure_installed = {
          "pyright",
          "gopls",
          "marksman",
          "texlab",
          "jdtls",
          "bashls",
          "lua_ls",
          "html",
          "cssls",
          "jsonls",
          "yamlls",
          "dockerls",
        },
        automatic_installation = true,
      })

      -- =======================================================
      -- 使用 setup_handlers 自动接管所有已安装的 LSP 配置
      -- =======================================================
      require("mason-lspconfig").setup_handlers({
        -- 1. 默认处理函数 (会自动作用于 html, cssls, bashls 等没有特殊设置的 server)
        function(server_name)
          lspconfig[server_name].setup({
            capabilities = capabilities,
            on_attach = on_attach,
          })
        end,

        -- 2. 针对特定语言的个性化覆盖配置
        ["pyright"] = function()
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
        end,

        ["gopls"] = function()
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
        end,

        ["lua_ls"] = function()
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
        end,

        ["jsonls"] = function()
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
        end,

        ["yamlls"] = function()
          lspconfig.yamlls.setup({
            capabilities = capabilities,
            on_attach = on_attach,
            settings = {
              yaml = { keyOrdering = false },
            },
          })
        end,

        ["texlab"] = function()
          lspconfig.texlab.setup({
            capabilities = capabilities,
            on_attach = on_attach,
            settings = {
              texlab = {
                build = { onSave = true },
              },
            },
          })
        end,
      })

      -- =================== 组件配置 ===================

      -- Lspsaga
      local has_lspsaga, lspsaga = pcall(require, "lspsaga")
      if has_lspsaga then
        lspsaga.setup({
          ui = { border = "rounded" },
          symbol_in_winbar = { enable = false },
          lightbulb = { enable = false, virtual_text = false },
        })
      end

      -- Trouble
      local has_trouble, trouble = pcall(require, "trouble")
      if has_trouble then
        trouble.setup({
          win = { position = "bottom", height = 0.3 },
          icons = {
            error = " ",
            warning = " ",
            hint = " ",
            information = " ",
          },
        })
      end
    end,
  },
}
