return {
  {
    "saghen/blink.cmp",
    -- 遵循文档：使用 function(_, opts) 来扩展/修改默认配置
    opts = function(_, opts)
      -- part 1: 核心按键逻辑
      -- 我们将 preset 设置为 "none"，以免 LazyVim 的默认按键干扰我们的自定义逻辑
      opts.keymap = {
        preset = "none",

        -- 【Tab 键】：这是你最想要的功能
        -- 逻辑：如果菜单可见 -> 确认当前选中的项（配合下面的 preselect，即确认第一项）
        --       如果在代码片段里 -> 跳到下一个位置
        --       否则 -> 执行原始 Tab（缩进）
        ["<Tab>"] = { "select_and_accept", "snippet_forward", "fallback" },

        -- 【Shift+Tab 键】：向上选或回跳
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },

        -- 【回车键】：纯净换行
        -- 除非你按 Tab，否则回车永远只是换行，不会意外补全代码
        ["<CR>"] = { "fallback" },

        -- 【其他标准键位】
        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback" },
        ["<C-n>"] = { "select_next", "fallback" },
        ["<C-e>"] = { "hide", "fallback" }, -- Ctrl+e 关闭菜单
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },
      }

      -- part 2: 选中行为配置
      -- 为了让 Tab 能直接“应用第一个补全提示”，我们需要让菜单一出来就“默认选中第一项”
      opts.completion = opts.completion or {}
      opts.completion.list = opts.completion.list or {}

      opts.completion.list.selection = {
        -- preselect = true: 菜单弹出时，自动高亮第一项
        preselect = true,
        -- auto_insert = false: 虽然高亮了，但不要自动把字打进代码里，直到我按 Tab
        auto_insert = false,
      }

      -- 返回修改后的配置给 LazyVim
      return opts
    end,
  },
}
