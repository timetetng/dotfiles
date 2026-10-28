-- 配置根目录运行：nvim --headless -u NONE -i NONE -n -l tests/typst_input_perf.lua
-- 合成长文档，不读取笔记；检查全文读取、重复 parse 和实际增量编辑耗时。
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.opt.rtp:append(vim.fn.stdpath('data') .. '/site')
vim.o.swapfile = false
vim.o.undofile = false
vim.o.shadafile = 'NONE'
local input = require('config.typst_input')
for _, n in ipairs({100, 1000, 5000}) do
  vim.cmd('enew!')
  vim.bo.filetype = 'typst'
  local lines = {}
  for i = 1, n do lines[i] = '正文 "说明" 与公式 $G$，以及其他文字。' end
  lines[n] = '末尾 $a$'
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  local parser = vim.treesitter.get_parser(0, 'typst')
  local original_parse, parse_calls = parser.parse, 0
  original_parse(parser) -- 测试预热：首次打开文件的解析不算逐键耗时。
  parser.parse = function(self, ...)
    parse_calls = parse_calls + 1
    return original_parse(self, ...)
  end
  local original_lines, requested = vim.api.nvim_buf_get_lines, 0
  vim.api.nvim_buf_get_lines = function(buf, first, last, strict)
    assert(last ~= -1 and last - first <= 1, 'input must not read the whole buffer')
    requested = requested + last - first
    return original_lines(buf, first, last, strict)
  end
  -- 冷启动 parse 不计入逐键时间。
  vim.api.nvim_win_set_cursor(0, {n, 8})
  assert(input.context().math)
  local calls_after_warmup = parse_calls
  local t = vim.uv.hrtime()
  for i = 1, 100 do
    vim.api.nvim_win_set_cursor(0, {n, i % 2 == 0 and 8 or 9})
    input.context()
  end
  local move_ms = (vim.uv.hrtime() - t) / 1e6 / 100
  assert(parse_calls == calls_after_warmup, 'moving cursor must reuse parsed tree')
  local edit_ns = 0
  for i = 1, 30 do
    vim.api.nvim_buf_set_text(0, n - 1, 8, n - 1, 9, {i % 2 == 0 and 'a' or 'b'})
    t = vim.uv.hrtime()
    assert(input.context().math)
    edit_ns = edit_ns + vim.uv.hrtime() - t
    vim.wait(15) -- 让异步任务实际运行，避免只测到堆积的回调。
  end
  local edit_ms = edit_ns / 1e6 / 30
  vim.api.nvim_buf_get_lines = original_lines
  parser.parse = original_parse
  -- 宽松上限只拦截严重回退，实际耗时输出供人工比较。
  assert(move_ms < 20 and edit_ms < 50, 'interactive input too slow')
  print(string.format('PASS %d lines: move %.3f ms, edit %.3f ms, Lua lines read %d', n, move_ms, edit_ms, requested))
end
vim.cmd('qa!')
