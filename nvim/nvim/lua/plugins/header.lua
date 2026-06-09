-- 在 lazy.nvim 中配置 header.nvim 插件
return {
  "attilarepka/header.nvim",
  opts = {
    -- 你可以在这里自定义配置
    allow_autocmds = true,
    file_name = true,
    author = "timetetng", -- 你的名字
    project = nil, -- 项目名
    date_created = true,
    date_created_fmt = "%Y-%m-%d %H:%M:%S",
    date_modified = true,
    date_modified_fmt = "%Y-%m-%d %H:%M:%S",
    line_separator = "------",
    use_block_header = true,
    copyright_text = {
      "Copyright (c) 2026 timetetng",
      "timetetng",
      "All rights reserved.",
    },
    license_from_file = true,
    author_from_git = true,
  },
}
