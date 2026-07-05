return {
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
    },
    cmd = {
      "DBUI",
      "DBUIToggle",
      "DBUIAddConnection",
      "DBUIFindBuffer",
    },
    -- 咱们在这里绑定超级快捷键！
    keys = {
      -- 按 <leader>du (Database UI) 瞬间呼出/关闭侧边栏
      { "<leader>pg", "<cmd>DBUIToggle<cr>", desc = "Toggle Database UI" },
      -- 按 <leader>dc (Database Connect) 直接自动聚焦到你配置好的数据库
      { "<leader>pc", "<cmd>DBUIFindBuffer<cr>", desc = "Connect to Current DB" },
    },
    init = function()
      -- 咱们的数据都存在本地，不要被 git 追踪到连接信息
      vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui"
      vim.g.db_ui_use_nerd_fonts = 1

      -- 【核心魔法】：预注册你的远程数据库连接！
      -- 注意看端口改成你要求的 5433 了，密码也将 / 替换成了 %2F 哦！
      vim.g.dbs = {
        EQ14db = "postgres://xingjian:lsb%2F%2F332211@10.0.0.2:5433/testdb",
      }

      -- 默认打开 DBUI 时，直接自动展开上面的预设连接，免去反复点回车！
      vim.g.db_ui_auto_execute_table_helpers = 1
    end,
  },
}
