return {
  "saghen/blink.cmp",
  -- optional: provides snippets for the snippet source
  dependencies = { "rafamadriz/friendly-snippets", "onsails/lspkind-nvim", "nvim-tree/nvim-web-devicons" },

  version = "v0.*",
  opts = {
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
      ["<CR>"] = { "accept", "fallback" },
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
          preselect = false,
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
      },
    },

    fuzzy = { implementation = "prefer_rust_with_warning" },
  },
  opts_extend = { "sources.default" },
}
