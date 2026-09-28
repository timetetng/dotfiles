return {
  "saghen/blink.cmp",
  -- optional: provides snippets for the snippet source
  dependencies = {
    "rafamadriz/friendly-snippets",
    "onsails/lspkind-nvim",
    "nvim-tree/nvim-web-devicons",
    -- LuaSnip：提供 typst 数学片段（前缀触发 + 数学区门控）。blink 要求 v2.*
    { "L3MON4D3/LuaSnip", version = "v2.*", config = function()
      require("config.luasnip")
    end },
  },

  version = "v0.*",
  opts = {
    -- 用 LuaSnip 作为片段引擎（默认是 vim.snippet，装不了自定义 Lua 片段）
    snippets = { preset = "luasnip" },

    keymap = {
      preset = "none",

      ["<Tab>"] = {
        function(cmp)
          if cmp.is_visible() then
            return cmp.select_next()
          end
          if cmp.snippet_active({ direction = 1 }) then
            return cmp.snippet_forward()
          end
          return false
        end,
        "fallback",
      },

      ["<S-Tab>"] = {
        function(cmp)
          if cmp.is_visible() then
            return cmp.select_prev()
          end
          if cmp.snippet_active({ direction = -1 }) then
            return cmp.snippet_backward()
          end
          return false
        end,
        "fallback",
      },
      ["<Up>"] = { "select_prev", "fallback" },
      ["<Down>"] = { "select_next", "fallback" },
      ["<C-n>"] = { "select_next", "fallback_to_mappings" },
      ["<C-p>"] = { "select_prev", "fallback_to_mappings" },
      ["<CR>"] = { "accept", "fallback" },
      -- 一键「选中并上屏」（blink 官方默认键）
      ["<C-y>"] = { "select_and_accept", "fallback" },
      -- 菜单开着但不想用当前选中项时：撤掉自动插入并关菜单（配合 preselect=true）
      ["<C-e>"] = { "cancel", "fallback" },
      ["<Esc>"] = { "hide", "fallback" },
      ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
      ["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
    },

    appearance = {
      nerd_font_variant = "mono",
      use_nvim_cmp_as_default = true,
    },

    completion = {
      list = {
        selection = {
          -- 菜单一弹出就选中第一项（回车/ C-y 直接上屏）
          -- 注意：配合下面的 auto_insert，选中会把候选文本实时插到 buffer 里
          -- （数学区打 alp 会被直接补成 alpha）；不想要时按 <C-e> 撤回
          preselect = true,
          auto_insert = true,
        },
      },
      menu = {
        auto_show = true,
        scrollbar = false,
        border = "rounded",
        winhighlight = "Normal:BlinkCmpMenu,FloatBorder:FloatBorder,CursorLine:BlinkCmpMenuSelection,Search:None",

        draw = {
          components = {
            source_name = {
              text = function(ctx)
                return "[" .. ctx.source_name .. "]"
              end,
              highlight = "Comment",
            },
          },

          columns = {
            { "kind_icon", "kind", gap = 1 },
            { "label", "label_description", gap = 1 },
            { "source_name" },
          },
        },
      },
      documentation = {
        auto_show = false,
        window = {
          border = "rounded",
          scrollbar = false,
          winhighlight = "Normal:BlinkCmpDoc,FloatBorder:FloatBorder,EndOfBuffer:BlinkCmpDoc",
        },
      },
    },

    signature = {
      enabled = true,
      window = {
        border = "rounded",
        scrollbar = false,
      },
    },

    -- ✨ 看这里！正确嵌套的 sources 表结构：
    sources = {
      default = { "lsp", "path", "snippets", "buffer", "dadbod" },
      providers = {
        dadbod = {
          name = "Dadbod",
          module = "vim_dadbod_completion.blink",
        },
        snippets = {
          -- blink 的 luasnip provider 不带描述，这里把 LuaSnip 的 dscr 补成
          -- 菜单里 label 右侧的灰字（菜单读的是 item.labelDetails.description）
          transform_items = function(_, items)
            local dscr = require("config.luasnip").snippet_descriptions()
            for _, item in ipairs(items) do
              local id = item.data and item.data.snip_id
              local text = id and dscr[id]
              if text then
                item.labelDetails = { description = text }
              end
            end
            return items
          end,
        },
      },
    },

    fuzzy = { implementation = "prefer_rust_with_warning" },
  },
  opts_extend = { "sources.default" },
}
