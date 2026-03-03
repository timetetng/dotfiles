-- ===========================================
-- 0. 终极修正：使用 schedule 延迟执行关闭拼写
-- ===========================================
local function force_disable_spell()
  -- vim.schedule 会将任务放入主循环的队列尾部
  -- 确保它在所有其他插件（如 LazyVim 默认配置）执行完之后才运行
  vim.schedule(function()
    vim.cmd("setlocal nospell")
  end)
end

-- 1. 针对未来打开的文件（注册监听器）
vim.api.nvim_create_autocmd("FileType", {
  pattern = "typst",
  callback = force_disable_spell,
})

-- 2. 针对当前已经加载的文件（立即补救）
-- 因为 typst.lua 是懒加载的，加载时 FileType 事件可能已经跑完了
if vim.bo.filetype == "typst" then
  force_disable_spell()
end
return {
  -- ===========================================
  -- 1. 配置 LSP (Tinymist)
  -- ===========================================
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        tinymist = {
          -- 即使是单文件（没有 git 目录）也启动 LSP
          single_file_support = true,
          -- 强制设置根目录为当前工作目录，防止 LSP 不启动
          root_dir = function()
            return vim.fn.getcwd()
          end,
          -- Tinymist 的具体设置
          settings = {
            exportPdf = "onSave", -- 核心功能：保存时生成 PDF
            formatterMode = "typstyle", -- 使用 typstyle 格式化
            semanticTokens = "enable", -- 开启语义高亮
          },
        },
      },
    },
  },

  -- ===========================================
  -- 2. 配置实时预览插件 (typst-preview.nvim)
  -- ===========================================
  {
    "chomosuke/typst-preview.nvim",
    ft = "typst", -- 仅在打开 typst 文件时加载
    version = "1.*",
    build = function()
      require("typst-preview").update()
    end,
    -- 按键绑定
    keys = {
      { "<leader>tp", "<cmd>TypstPreview<cr>", desc = "Typst Preview" },
    },
    opts = {
      auto_open = true, -- 打开文件自动开启预览
      open_mode = "browser", -- 默认用浏览器打开
      invert_colors = "never", -- 只有在深色模式看不清 PDF 时才改为 "auto"
      follow_cursor = true, -- 编辑器移动，浏览器跟随
      dependencies_bin = {
        ["tinymist"] = "tinymist", -- 指定使用系统安装的 tinymist
      },
    },
  },

  -- ===========================================
  -- 3. 语法高亮支持
  -- ===========================================
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "typst" })
      end
    end,
  },
}
