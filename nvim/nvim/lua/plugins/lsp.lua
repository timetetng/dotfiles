return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "glepnir/lspsaga.nvim",
      "folke/trouble.nvim",
      "j-hui/fidget.nvim",
      "saghen/blink.cmp",
      "b0o/schemastore.nvim",
    },
    config = function()
      -- 1. 优化 notify，屏蔽冗余信息
      local original_notify = vim.notify
      vim.notify = function(msg, level, opts)
        if type(msg) == "string" and msg:match("framework") and msg:match("deprecated") then
          return
        end
        original_notify(msg, level, opts)
      end

      local lspconfig = require("lspconfig")

      -- FIX 1: 安全加载 blink.cmp
      local has_blink, blink = pcall(require, "blink.cmp")
      local capabilities = has_blink and blink.get_lsp_capabilities() or vim.lsp.protocol.make_client_capabilities()

      local on_attach = function(client, bufnr)
        if client.server_capabilities.inlayHintProvider then
          vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end
      end

      -- 获取当前环境下 lspconfig 支持的所有 server 列表
      local available_servers = lspconfig.util.available_servers()
      local function is_server_supported(name)
        for _, v in ipairs(available_servers) do
          if v == name then
            return true
          end
        end
        return false
      end

      -- setup_server 包装函数
      local function setup_server(server_name, config)
        -- 如果 lspconfig 根本不支持这个名字，直接跳过，防止 __index 报错
        if not is_server_supported(server_name) then
          return
        end

        config = config or {}
        config.capabilities = vim.tbl_deep_extend("force", capabilities, config.capabilities or {})
        config.on_attach = on_attach

        -- 再次使用 pcall 确保万无一失
        pcall(function()
          lspconfig[server_name].setup(config)
        end)
      end

      -- =======================================================
      -- 1. 主力语言配置
      -- =======================================================

      setup_server("pyright", {
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

      setup_server("gopls", {
        settings = {
          gopls = {
            analyses = { unusedparams = true },
            staticcheck = true,
            gofumpt = true,
          },
        },
      })

      setup_server("marksman", {})

      setup_server("texlab", {
        settings = {
          texlab = {
            build = { onSave = true },
          },
        },
      })

      -- =======================================================
      -- 2. 其他语言与工具
      -- =======================================================

      setup_server("jdtls", {})
      setup_server("bashls", {})

      setup_server("lua_ls", {
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

      setup_server("html", {})
      setup_server("cssls", {})

      -- JSON (带 SchemaStore 保护)
      setup_server("jsonls", {
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

      setup_server("yamlls", {
        settings = {
          yaml = { keyOrdering = false },
        },
      })

      setup_server("dockerls", {})

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
