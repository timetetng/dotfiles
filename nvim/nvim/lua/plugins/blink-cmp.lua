return {
  "saghen/blink.cmp",
  -- optional: provides snippets for the snippet source
  dependencies = { "rafamadriz/friendly-snippets", "onsails/lspkind-nvim", "nvim-tree/nvim-web-devicons" },

  -- use a release tag to download pre-built binaries
  version = "v0.*", -- 建议改为 v0.* 因为目前 1.0 还没正式发布，或者保持你原来的 "1.*" 如果你确认你在用 pre-release

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
      -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      nerd_font_variant = "mono",
      -- 如果你想自定义图标，可以在这里定义 kind_icons
      use_nvim_cmp_as_default = true,
    },

    completion = {
      list = {
        selection = {
          preselect = false,
          auto_insert = true, -- 建议加上这个
        },
      },
      menu = {
        auto_show = true,
        scrollbar = false,
        border = "rounded",
        winhighlight = "Normal:BlinkCmpMenu,FloatBorder:FloatBorder,CursorLine:BlinkCmpMenuSelection,Search:None",

        draw = {
          -- 修改点：删除了导致报错的自定义 kind_icon 组件
          -- Blink 现在原生支持非常漂亮的图标渲染，不需要手动写函数了

          components = {
            -- 保留你自定义的 source_name (显示来源)
            source_name = {
              text = function(ctx)
                return "[" .. ctx.source_name .. "]"
              end,
              highlight = "Comment",
            },
          },

          -- 定义列的布局
          columns = {
            { "kind_icon", "kind", gap = 1 },
            { "label", "label_description", gap = 1 },
            { "source_name" }, -- 使用上面定义的 source_name
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

    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },

    fuzzy = { implementation = "prefer_rust_with_warning" },
  },
  opts_extend = { "sources.default" },
}
