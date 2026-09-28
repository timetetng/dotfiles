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
          -- ⚠ tinymist 的设置必须嵌在 `tinymist` 键下，扁平写法不生效
          settings = {
            tinymist = {
              exportPdf = "onSave", -- 保存时生成 PDF
              formatterMode = "typstyle", -- 用 typstyle 格式化（需装 typstyle，否则改 "disable"）
              semanticTokens = "enable", -- 语义高亮
            },
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
    -- 快捷键在 lua/config/typst.lua 的 FileType autocmd 里定义（<leader>tp/tP/ts/tc）
    opts = {
      -- 注意：typst-preview.nvim 没有 auto_open/open_mode 这两个选项（旧配置里写了但不生效）
      --
      -- 预览暗色：直接透传给 `tinymist preview --invert-colors`，这是反转渲染结果
      -- （白眼背景→黑底白字），只影响预览页，**不影响 `typst compile` 出的 PDF**。
      --   "never"  不反转（默认，白得刺眼）
      --   "auto"   跟随浏览器的深色模式设置
      --   "always" 总是反转（图片也一起反转）
      --   JSON 形式可以分开控制：rest = 文字/页面，image = 图片
      -- 这里选的是「文字页面反转、图片保持原样」（图表、截图不会变负片）
      invert_colors = '{"rest":"always","image":"never"}',
      -- debug：把 tinymist 的启动参数与 stderr（含编译报错）写进
      -- ~/.local/share/nvim/typst-preview/log.txt。不开的话预览起不来时没有任何线索。
      -- 查看方式：<leader>tL（:TypstPreviewLog）
      debug = true,
      follow_cursor = true, -- 编辑器移动时浏览器跟随
      dependencies_bin = {
        ["tinymist"] = "tinymist", -- 使用系统安装的 tinymist
      },
    },
  },

  -- 语法高亮 parser 已在 ui.lua 的 install 列表中注册（"typst"）
}
