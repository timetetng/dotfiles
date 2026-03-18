-- lua/plugins/which-key.lua
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,
  config = function()
    local wk = require("which-key")

    wk.setup({
      preset = "classic",
      win = {
        border = "rounded",
        width = 0.3,
        row = 0.99,
        col = 0.99,
      },
      layout = {
        height = { min = 4, max = 25 },
        width = { min = 20, max = 50 },
        spacing = 3,
        align = "left",
      },
    })

    wk.add({
      -- ==========================================
      -- 1. 空格键 (Leader) 菜单
      -- ==========================================
      { "<leader>f", group = "文件与搜索 (File)" },
      { "<leader>g", group = "代码管理 (Git)" },
      { "<leader>s", group = "符号与诊断 (Search)" },
      { "<leader>t", group = "工具切换 (Toggle)" },
      { "<leader>d", group = "调试与诊断 (Debug)" },
      { "<leader>x", group = "问题面板 (Trouble)" },

      -- 恢复并汉化大纲树快捷键
      { "<leader>o", desc = "代码大纲 (Outline)" },
      { "<leader>r", desc = "重命名" },

      -- 隐藏数字键提示
      { "<leader>1", desc = "切换 Buffer 1..9" },
      { "<leader>2", hidden = true },
      { "<leader>3", hidden = true },
      { "<leader>4", hidden = true },
      { "<leader>5", hidden = true },
      { "<leader>6", hidden = true },
      { "<leader>7", hidden = true },
      { "<leader>8", hidden = true },
      { "<leader>9", hidden = true },

      -- ==========================================
      -- 2. Ctrl + W 窗口管理菜单 (Window)
      -- ==========================================
      { "<C-w>", group = "窗口操作 (Window)" },
      { "<C-w>d", desc = "光标下显示诊断" },
      { "<C-w>h", desc = "移动到左窗口" },
      { "<C-w>H", desc = "将窗口移至最左侧" },
      { "<C-w>j", desc = "移动到下窗口" },
      { "<C-w>J", desc = "将窗口移至最下方" },
      { "<C-w>k", desc = "移动到上窗口" },
      { "<C-w>K", desc = "将窗口移至最上方" },
      { "<C-w>l", desc = "移动到右窗口" },
      { "<C-w>L", desc = "将窗口移至最右侧" },
      { "<C-w>o", desc = "关闭其他所有窗口" },
      { "<C-w>q", desc = "关闭当前窗口" },
      { "<C-w>s", desc = "水平分割窗口" },
      { "<C-w>T", desc = "移动到新标签页" },
      { "<C-w>v", desc = "垂直分割窗口" },
      { "<C-w>w", desc = "切换窗口" },
      { "<C-w>x", desc = "与下一个窗口互换" },
      { "<C-w>+", desc = "增加高度" },
      { "<C-w>-", desc = "减少高度" },
      { "<C-w><", desc = "减少宽度" },
      { "<C-w>=", desc = "恢复等宽等高" },
      { "<C-w>>", desc = "增加宽度" },
      { "<C-w>_", desc = "最大化高度" },

      -- ==========================================
      -- 3. g 前缀：跳转与代码操作 (Go)
      -- ==========================================
      { "g", group = "代码跳转与操作 (Go)" },
      { "gd", desc = "跳转到定义 (Definition)" },
      { "gD", desc = "跳转到声明 (Declaration)" },
      { "gr", desc = "查看引用 (References)" },
      { "gi", desc = "跳转到实现 (Implementation)" },
      { "gy", desc = "跳转到类型定义 (Type Def)" },
      { "gf", desc = "跳转到光标下的文件" },
      { "gx", desc = "在浏览器中打开链接" },
      { "ge", desc = "跳转到上一个词尾" },
      { "gg", desc = "跳转到第一行" },

      { "gn", desc = "向前搜索并选中" },
      { "gN", desc = "向后搜索并选中" },
      { "g%", desc = "在结果中反向循环" },

      { "gO", desc = "文档符号大纲 (LSP)" },
      { "gw", desc = "格式化代码" },
      { "gI", desc = "跳转到实现 (LSP)" },

      { "gt", desc = "下一个标签页 (Tab)" },
      { "gT", desc = "上一个标签页 (Tab)" },

      { "gu", desc = "转换为小写" },
      { "gU", desc = "转换为大写" },
      { "g~", desc = "切换大小写" },
      { "gv", desc = "选中上次可视区域" },

      { "g,", desc = "跳转到较新的修改位置" },
      { "g;", desc = "跳转到较旧的修改位置" },

      { "ga", group = "代码动作 (Actions)" },
      { "gb", group = "块注释切换" },
      { "g'", group = "书签 (Marks)" },
      { "g`", group = "书签 (Marks)" },

      -- ==========================================
      -- 4. [ 前缀：上一个 (Previous)
      -- ==========================================
      { "[", group = "上一个 (Prev)" },
      { "[a", desc = "上一个项 (Argument)" },
      { "[A", desc = "回到首个项" },
      { "[b", desc = "上一个 Buffer" },
      { "[B", desc = "回到首个 Buffer" },
      { "[c", desc = "上一个 Git 更改 (Hunk)" },
      { "[d", desc = "上一个诊断报错" },
      { "[D", desc = "跳到首个诊断报错" },
      { "[e", desc = "上一个错误 (Error)" },
      { "[i", desc = "跳到作用域顶部" },
      { "[l", desc = "上一个位置 (Loc List)" },
      { "[L", desc = "回到首个位置" },
      { "[m", desc = "上一个方法开始" },
      { "[M", desc = "上一个方法结束" },
      { "[q", desc = "上一个快表项 (Quickfix)" },
      { "[Q", desc = "回到首个快表项" },
      { "[s", desc = "上一个拼写错误" },
      { "[t", desc = "上一个标签 (Tag)" },
      { "[T", desc = "回到首个标签" },
      { "[%", desc = "上一个未匹配组" },
      { "[(", desc = "上一个 (" },
      { "[<", desc = "上一个 <" },
      { "[{", desc = "上一个 {" },

      -- ==========================================
      -- 5. ] 前缀：下一个 (Next)
      -- ==========================================
      { "]", group = "下一个 (Next)" },
      { "]a", desc = "下一个项 (Argument)" },
      { "]A", desc = "跳到末尾项" },
      { "]b", desc = "下一个 Buffer" },
      { "]B", desc = "跳到末尾 Buffer" },
      { "]c", desc = "下一个 Git 更改 (Hunk)" },
      { "]d", desc = "下一个诊断报错" },
      { "]D", desc = "跳到末尾诊断报错" },
      { "]e", desc = "下一个错误 (Error)" },
      { "]i", desc = "跳到作用域底部" },
      { "]l", desc = "下一个位置 (Loc List)" },
      { "]L", desc = "跳到末尾位置" },
      { "]m", desc = "下一个方法开始" },
      { "]M", desc = "下一个方法结束" },
      { "]q", desc = "下一个快表项 (Quickfix)" },
      { "]Q", desc = "跳到末尾快表项" },
      { "]s", desc = "下一个拼写错误" },
      { "]t", desc = "下一个标签 (Tag)" },
      { "]T", desc = "跳到末尾标签" },
      { "]%", desc = "下一个未匹配组" },
      { "])", desc = "下一个 )" },
      { "]>", desc = "下一个 >" },
      { "]}", desc = "下一个 }" },

      -- ==========================================
      -- 6. z 前缀：折叠与视图 (Fold & View)
      -- ==========================================
      { "z", group = "折叠与拼写 (Fold/Spell)" },
      { "za", desc = "切换当前折叠 (Toggle)" },
      { "zc", desc = "关闭当前折叠 (Close)" },
      { "zo", desc = "打开当前折叠 (Open)" },
      { "zM", desc = "全部折叠 (Close All)" },
      { "zR", desc = "展开全部 (Open All)" },
      { "zz", desc = "光标所在行居中" },
      { "zt", desc = "光标所在行置顶" },
      { "zb", desc = "光标所在行置底" },
      { "z=", desc = "获取拼写建议 (Spell Suggest)" },
    })
  end,
}
