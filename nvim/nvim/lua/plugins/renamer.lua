return {
  {
    "shaunsingh/nord.nvim",
    lazy = false, -- 确保在启动时加载，而不是延迟加载
    priority = 1000, -- 设置最高优先级，确保它在其他所有插件之前加载
    config = function()
      -- 全局配置选项 (可根据个人喜好修改 true/false)
      vim.g.nord_contrast = true -- 开启高对比度
      vim.g.nord_borders = false -- 禁用浮动窗口边框
      vim.g.nord_disable_background = false -- 设为 true 可将背景设为透明（配合终端透明）
      vim.g.nord_italic = false -- 禁用斜体字
      vim.g.nord_uniform_diff_background = true -- 使差异视图(diff)背景统一
      vim.g.nord_bold = false -- 禁用粗体字

      -- 激活并应用主题
      vim.cmd.colorscheme("nord")
    end,
  },
}
