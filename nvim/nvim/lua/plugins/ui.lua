return {
  -- 状态栏
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {},
  },

  -- 语法高亮 & Treesitter（main 分支，适配 Neovim 0.12）
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").install({
        "c",
        "cpp",
        "lua",
        "python",
        "cmake",
        "markdown",
        "markdown_inline",
        "latex",
        "typst",
        "vim",
        "vimdoc",
        "query",
      })

      -- main 分支不再自动开启高亮/缩进，按文件类型手动启动
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(ev)
          local lang = vim.treesitter.language.get_lang(ev.match) or ev.match
          if pcall(vim.treesitter.start, 0, lang) then
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },
}
