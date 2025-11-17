return {
  'ggandor/leap.nvim',
  config = function()
    require('leap').setup({
      -- 可选：添加一些自定义设置
      max_phase_one_targets = nil,
      highlight_unlabeled_phase_one_targets = false,
    })
    
    -- 基本映射
    vim.keymap.set({'n', 'x', 'o'}, 's', '<Plug>(leap-forward)')
    vim.keymap.set({'n', 'x', 'o'}, 'S', '<Plug>(leap-backward)')
    
    -- 跨窗口跳转
    vim.keymap.set({'n', 'x', 'o'}, 'gs', '<Plug>(leap-from-window)')
  end,
}
