return {
  "Yggdroot/indentLine",
  -- 使用 init 字段在插件加载前设置全局变量
  init = function()
    -- 告诉 indentLine 不要自己设置 conceallevel，这样它就不会覆盖其他配置了
    vim.g.indentLine_setConceal = 0
  end,
  -- 可选：如果您的配置中没有其他地方设置，可以在 config 中再次设置 JSON 文件的选项
  config = function()
    -- 确保 JSON 文件中的隐藏级别是 0
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "json",
      callback = function()
        vim.opt_local.conceallevel = 0
        -- 阻止 JSON 语法脚本隐藏引号
        vim.g.vim_json_conceal = 0 
      end,
    })
  end,
}
