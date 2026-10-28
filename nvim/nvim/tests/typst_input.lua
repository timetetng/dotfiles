-- 在配置根目录运行：nvim --headless -u NONE -i NONE -n -l tests/typst_input.lua
-- 仅使用已安装插件，不加载用户 init，不安装依赖、不写笔记。
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.opt.rtp:append(vim.fn.stdpath('data') .. '/site')
for _, name in ipairs({'nvim-autopairs', 'blink.cmp', 'LuaSnip', 'friendly-snippets'}) do
  vim.opt.rtp:append(vim.fn.stdpath('data') .. '/lazy/' .. name)
end
vim.o.swapfile = false
vim.o.undofile = false
vim.o.shadafile = 'NONE'
vim.o.backspace = 'indent,eol,start'
require('nvim-autopairs').setup({check_ts = true, enable_check_bracket_line = true})
require('config.typst')
require('config.cjk')
local n = 0
local function key(s) return vim.api.nvim_replace_termcodes(s, true, false, true) end
local snapshot
_G.input_test_snapshot = function()
  snapshot = { table.concat(vim.api.nvim_buf_get_lines(0,0,-1,false), '\n'), vim.api.nvim_win_get_cursor(0) }
end
local function test(name, typed, expected, row, col)
  vim.cmd('enew!')
  vim.bo.filetype = 'typst'
  snapshot = nil
  vim.api.nvim_feedkeys(key('i' .. typed .. '<Cmd>lua input_test_snapshot()<CR><Esc>'), 'xt', false)
  assert(snapshot, name .. ': missing snapshot')
  assert(snapshot[1] == expected, name .. ': expected ' .. vim.inspect(expected) .. ', got ' .. vim.inspect(snapshot[1]))
  if row then assert(vim.deep_equal(snapshot[2], {row,col}), name .. ': cursor ' .. vim.inspect(snapshot[2])) end
  n=n+1
end
test('dollar', '$', '$$', 1, 1)
test('CJK dollar', '群$', '群 $$', 1, 5)
test('CJK yen', '群¥', '群 $$', 1, 5)
test('full yen', '群￥', '群 $$', 1, 5)
test('wrap', '群 G<C-l>', '群 $G$ ', 1, 8)
test('wrap auto CJK', '群G<C-l>', '群 $G$ ', 1, 8)
test('leave empty', '$<C-l>', '$$ ', 1, 3)
test('leave', '$a + b<C-l>', '$a + b$ ', 1, 8)
test('leave middle', '$a + b<Left><Left><C-l>', '$a + b$ ', 1, 8)
test('leave CJK', '$G<C-l>是群', '$G$ 是群', 1, 10)
test('paren', '(', '()', 1, 1)
test('bracket', '[', '[]', 1, 1)
test('brace', '{', '{}', 1, 1)
test('skip close', '()', '()', 1, 2)
test('math Chinese brackets', '$【a】（b）《c》', '$[a](b)<c>$', 1, 10)
test('text Chinese brackets', '【】（）《》', '【】（）《》', 1, 18)
test('subscript', '$a1', '$a_1$', 1, 4)
test('subscript b4', '$b4', '$b_4$', 1, 4)
test('text number', 'a1', 'a1', 1, 2)
test('word number', '$alpha1', '$alpha1$', 1, 7)
test('existing script', '$a_1', '$a_(1)$', 1, 5)
test('superscript', '$a^', '$a^()$', 1, 4)
test('subscript parens', '$a_', '$a_()$', 1, 4)
test('text caret', 'a^', 'a^', 1, 2)
test('pair backspace', '(<BS>', '', 1, 0)
test('dollar backspace', '$<BS>', '', 1, 0)
test('script backspace', '$a^<BS>', '$a$', 1, 2)
test('raw dollar', '`$a1', '`$a1`', 1, 4)
test('comment dollar', '// $a1', '// $a1', 1, 6)
test('string dollar', '#let s = "$a1', '#let s = "$a1"', 1, 13)
test('escaped dollar', '\\$a1', '\\$a1', 1, 4)
test('multi-line exit', '$<CR>a + b<C-l>', '$\na + b$ ', 2, 7)
test('space chain', '$a  ', '$a #h(0.5em)$', 1, 12)
test('space down', '$a  <BS>', '$a $', 1, 3)
test('manual dollar CJK', '$G$是群', '$G$ 是群', 1, 10)
test('CJK parentheses', '群(x)是', '群 (x) 是', 1, 11)
test('math text no subscript', '$"a1', '$"a1$', 1, 4)
test('math comment', '$// a1<CR>b4', '$// a1\nb_4$', 2, 3)
test('script close', '$a^2)', '$a^(2)$', 1, 6)
-- 一次输入中的自动配对与 API 编辑都不能清空之前的撤销历史。
test('undo base', '基础', '基础', 1, 6)
vim.api.nvim_feedkeys(key('a群$G<C-l><Esc>'), 'xt', false)
vim.cmd('undo')
assert(vim.api.nvim_get_current_line() == '基础', 'undo should keep earlier edit')
vim.cmd('undo')
assert(vim.api.nvim_get_current_line() == '', 'undo history must remain available')
n = n + 2
-- 上下文判定不依赖某次配对是否成功；覆盖已有文档中的边界位置。
local contexts = {
  { '$a|$', true, false },
  { '$a$|', false, false },
  { '$\na|\nb\n$', true, false },
  { '$\na\n|b\n$', true, false },
  { '"正文 $a|$"', true, false },
  { '#let s = "$a|$"', false, true },
  { '`$a|$`', false, true },
  { '```typst\n$a|$\n```', false, true },
  { '// $a|$', false, true },
  { '/* outer /* $ */ a| */', false, true },
  { '$ /* a| */ b $', false, true },
  { '$ /* a */ b| $', true, false },
  { '$\n// comment|\nb\n$', false, true },
  { '$\n// comment\nb|\n$', true, false },
  { '$\n"a|"\n$', false, true },
  { '$a$|正文', false, false },
  { '$ "a|" $', false, true },
  { '\\$a|', false, false },
  { '$a|', true, false },
}
for _, case in ipairs(contexts) do
  vim.cmd('enew!')
  vim.bo.filetype = 'typst'
  local marker = assert(case[1]:find('|', 1, true))
  local before = case[1]:sub(1, marker - 1)
  local text = before .. case[1]:sub(marker + 1)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(text, '\n', {plain=true}))
  local _, row = before:gsub('\n', '')
  vim.o.virtualedit = 'onemore'
  vim.api.nvim_win_set_cursor(0, {row + 1, #(before:match('[^\n]*$') or '')})
  local ctx = require('config.typst_input').context()
  assert(ctx.math == case[2] and ctx.protected == case[3], 'context: ' .. vim.inspect(case))
  n = n + 1
end
-- 长文档异步重解析尚未完成时，也不能丢失已有跨行公式的上下文。
vim.cmd('enew!')
vim.bo.filetype = 'typst'
vim.api.nvim_buf_set_lines(0, 0, -1, false, {'$', 'a', '$'})
local parser = vim.treesitter.get_parser(0, 'typst')
parser:parse()
local parse = parser.parse
parser.parse = function() return nil end -- 模拟异步解析尚未完成。
vim.api.nvim_buf_set_text(0, 1, 0, 1, 1, {'b'})
vim.api.nvim_win_set_cursor(0, {2, 1})
local pending = require('config.typst_input').context()
parser.parse = parse
assert(pending.math and pending.finish.row == 3, 'pending parse must keep multiline math')
n = n + 1
print('PASS basic: ' .. n)
vim.cmd('qa!')
