return {
  "SilverofLight/kd_translate.nvim",
  config = function()
    require("kd").setup({
      -- 1. 窗口样式配置
      window = {
        width = 80, -- 翻译窗口的最大宽度
        height = 10, -- 翻译窗口的最大高度
        border = "rounded", -- 边框样式，可选 "single", "double", "rounded", "solid", "shadow" 等
        title = " 翻译结果 ", -- 窗口标题
        title_pos = "center", -- 标题位置，可选 "left", "center", "right"
        style = "minimal", -- 窗口样式
        relative = "cursor", -- 窗口位置相对于光标
        focusable = true, -- 窗口是否可以获得焦点
        row = 1, -- 相对于光标的垂直偏移量
        col = 0, -- 相对于光标的水平偏移量
      },

      -- 2. 快捷键配置
      keymap = {
        scrollDown = "<C-f>", -- 在不进入窗口的情况下，向下滚动翻译内容
        scrollUp = "<C-b>", -- 在不进入窗口的情况下，向上滚动翻译内容
      },

      -- 3. 自定义高亮颜色和字体样式
      highlights = {
        word = { -- 翻译的主单词高亮
          fg = "#ADD8E6", -- 前景色（文字颜色），可替换为你的主题颜色
          -- bg = "#FFFFFF",-- 背景色，默认注释掉了
          bold = true, -- 是否加粗
          italic = false, -- 是否斜体
          underline = true, -- 是否带有下划线
        },
        phonetic = { -- 音标高亮
          fg = "#7FFFD4", -- 音标前景色
          bg = "NONE", -- 音标背景色
          bold = false, -- 是否加粗
          italic = true, -- 是否斜体
          underline = false, -- 是否带有下划线
        },
        level = { -- 词汇等级（如 CET4/CET6）高亮
          fg = "#FFC0CB", -- 词汇等级前景色
          bg = "NONE", -- 词汇等级背景色
          bold = false, -- 是否加粗
          italic = false, -- 是否斜体
          underline = false, -- 是否带有下划线
        },
      },
    })
  end,
  keys = {
    -- 设置触发翻译的快捷键
    { "<leader>tt", ":TranslateNormal<CR>", mode = "n", desc = "翻译光标下的单词" },
    { "<leader>tt", ":TranslateVisual<CR>", mode = "v", desc = "翻译选中的内容" },
  },
}
