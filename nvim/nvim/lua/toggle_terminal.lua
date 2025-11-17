-- File: ~/.config/nvim/lua/toggle_terminal.lua (使用 API 稳定版)

local terminal_cmd = 'botright split | terminal' 

--- 终端切换逻辑函数 (全局函数)
function Toggle_Terminal_Below()
    local terminal_buf_id = nil
    local current_win = vim.api.nvim_get_current_win()

    -- 1. 查找已存在的终端缓冲区
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_buf_get_option(bufnr, 'buftype') == 'terminal' then
            terminal_buf_id = bufnr
            break
        end
    end

    if terminal_buf_id then
        local winid = vim.fn.bufwinid(terminal_buf_id)
        if winid ~= -1 then
            -- 终端窗口可见，执行关闭/隐藏操作
            
            -- 检查当前标签页中的窗口数量
            if vim.fn.winnr('$') == 1 then
                -- 关键修正：如果只有一个窗口，删除缓冲区并关闭窗口
                -- flags={hide=true} 确保如果缓冲区仍然打开，窗口会被关闭
                vim.api.nvim_buf_delete(terminal_buf_id, {force=true, unload=true}) 
            else
                -- 关键修正：使用 nvim_win_hide 安全地隐藏窗口
                vim.api.nvim_win_hide(current_win)
            end
            
        else
            -- 终端缓冲区存在但被隐藏，打开它
            vim.cmd(terminal_cmd .. ' ' .. terminal_buf_id) -- 使用已有的缓冲区打开
            vim.cmd('startinsert')
        end
    else
        -- 终端不存在，创建新终端
        vim.cmd(terminal_cmd)
        vim.cmd('startinsert')
    end
end
