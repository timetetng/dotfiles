-- 在配置根目录运行：nvim --headless -u NONE -i NONE -n -l tests/blink_input.lua
-- RPC 子进程用真实事件循环与真实 Blink 菜单；固定本地候选，不连接 LSP。
local child = vim.fn.jobstart({'nvim','--headless','--embed','-u','NONE','-i','NONE','-n'}, {rpc=true})
local function lua(code, ...)
  return vim.rpcrequest(child, 'nvim_exec_lua', code, {...})
end
local function press(s)
  vim.rpcrequest(child,'nvim_input',s)
  vim.wait(150)
end
local function line() return lua('return vim.api.nvim_get_current_line()') end
local function visible() return lua("return require('blink.cmp').is_visible()") end
lua([[
vim.opt.rtp:prepend(vim.fn.getcwd())
for _, name in ipairs({'nvim-autopairs','blink.cmp','LuaSnip','friendly-snippets'}) do
  vim.opt.rtp:append(vim.fn.stdpath('data') .. '/lazy/'..name)
end
vim.o.swapfile=false
vim.o.undofile=false
vim.o.shadafile='NONE'
vim.o.backspace='indent,eol,start'
require('nvim-autopairs').setup({check_ts=true})
require('luasnip').setup({})
require('config.typst')
require('config.cjk')
package.preload.input_test_source = function()
  return { new = function() return {
    get_completions = function(_, _, callback)
      callback({items={{label='alpha',kind=1},{label='alphabet',kind=1}},is_incomplete_forward=false,is_incomplete_backward=false})
    end,
  } end }
end
local opts=dofile('lua/plugins/blink-cmp.lua').opts
opts.fuzzy={implementation='lua'}
opts.sources={default={'input_test'},providers={input_test={name='Test',module='input_test_source'}}}
opts.signature.enabled=false
opts.completion.menu.auto_show=false
require('blink.cmp').setup(opts)
]])
local function reset()
  press('<Esc>')
  lua("vim.cmd('enew!'); vim.bo.filetype='typst'")
  press('ialp')
  lua("require('blink.cmp').show()")
  assert(vim.wait(2000,visible,10),'menu must show')
  assert(line()=='alp','no auto insertion')
end
local ok,err=pcall(function()
reset()
press('<Tab>')
assert(line()=='alpha','Tab accepts selected item: '..line())
reset()
press('<Down>')
press('<Tab>')
assert(line()=='alphabet','Tab accepts moved selection: '..line())
reset()
press('<CR>')
local lines=lua('return vim.api.nvim_buf_get_lines(0,0,-1,false)')
assert(vim.deep_equal(lines,{'alp',''}),'Enter only newlines: '..vim.inspect(lines))
press('<Esc>')
lua("vim.cmd('enew!'); vim.bo.filetype='typst'")
press('i$a')
lua("require('blink.cmp').show()")
assert(vim.wait(2000,visible,10),'math menu must show')
press('1')
assert(line()=='$a_1$','subscript works with menu visible: '..line())
press('<Esc>')
lua("vim.cmd('enew!'); vim.bo.filetype='typst'")
press('i群$【a1】（b4）《c》<C-l>是群')
assert(line()=='群 $[a_1](b_4)<c>$ 是群','IME commit and Pangu spacing: '..line())
press('<Esc>')
lua("vim.cmd('enew!'); vim.bo.filetype='typst'")
press('i')
lua([[local ls=require('luasnip'); ls.snip_expand(ls.snippet('test',{
  ls.text_node('('), ls.insert_node(1,'a'), ls.text_node(','), ls.insert_node(2,'b'), ls.text_node(')'),
}))]])
press('<Tab>')
local selected=lua([[return vim.fn.mode():match('[sS]') ~= nil]])
assert(selected,'Tab still jumps to next snippet field when menu absent')
end)
vim.fn.jobstop(child)
assert(ok,err)
print('PASS blink: Tab, selected candidate, Enter, no preview, subscript with menu, IME commit, snippet jump')
vim.cmd('qa!')
