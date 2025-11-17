vim.cmd[[
    " 恢复标准移动键
    noremap <silent> h h
    noremap <silent> j j  
    noremap <silent> k k
    noremap <silent> l l

    " 可视模式的缩进保持选中
    map("v",">",">gv",{ noremap = true, silent = true })
    map("v","<","<gv",{ noremap = true, silent = true })
        " 文件树操作
    nmap tt :NvimTreeToggle<CR>
    nmap <leader>n :NvimTreeFocus<CR>

    " Coc代码操作
    xmap <leader>a <Plug>(coc-codeaction-selected)
    nmap <leader>a <Plug>(coc-codeaction-selected)

    " Markdown预览
    nmap md <Plug>MarkdownPreview

    " Joshuto文件管理器
    nmap ra :Joshuto<CR>

    " Telescope文件查找
    nmap <C-f> :Telescope find_files<CR>

    " 表格模式
    map tm :TableModeToggle<CR>

    " Leap跳转
    map r <Plug>(leap-backward-to)
]]
