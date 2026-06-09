return {
  "folke/lazydev.nvim",
  ft = "lua", -- 只有在打开 lua 文件时才加载，极其轻量
  opts = {
    library = {
      -- 加载 luvit 的类型提示，这对你要用到的 vim.uv 异步 API 很有用
      { path = "luvit-meta/library", words = { "vim%.uv" } },
    },
  },
}
