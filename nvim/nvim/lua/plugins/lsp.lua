-- 检查系统内存是否充足 (判断 Linux /proc/meminfo)
local function has_enough_memory()
  local f = io.open("/proc/meminfo", "r")
  if not f then
    return true
  end

  local mem_total_kb = 0
  for line in f:lines() do
    local match = line:match("^MemTotal:%s+(%d+)%s+kB")
    if match then
      mem_total_kb = tonumber(match)
      break
    end
  end
  f:close()

  local mem_total_gb = mem_total_kb / (1024 * 1024)

  return mem_total_gb >= 3.5
end

return {
  {
    "neovim/nvim-lspconfig",
    cond = has_enough_memory,
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
      local ignore_next_traceback = false

      vim.notify = function(msg, level, opts)
        if type(msg) == "string" then
          if msg:match("framework") and msg:match("deprecated") then
            ignore_next_traceback = true
            return
          end
          if ignore_next_traceback and msg:match("^stack traceback:") then
            ignore_next_traceback = false
            return
          end
          ignore_next_traceback = false
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
      -- Mason 初始化
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
          "sqls", -- ✨ 星的添加：把咱们 SQL 专用的 LSP 加到自动装箱表里！
        },
      })

      -- =====================================================
      -- 配置各 LSP
      -- =====================================================

      -- 默认配置：无特殊设置的 server（加上了 sqls 哦！）
      local default_servers = { "html", "cssls", "bashls", "marksman", "dockerls", "sqls" }
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
