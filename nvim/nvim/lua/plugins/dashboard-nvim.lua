-- /home/xingjian/.config/nvim/lua/plugins/dashboard-nvim.lua

-- 200行以内，直接返回全部代码

return {
  'nvimdev/dashboard-nvim',
  -- 确保插件在 Vim 启动时加载
  event = 'VimEnter', 
  
  -- 插件的配置函数
  config = function()
    -- 1. 定义 ASCII 艺术头部
    local nvim_header = {
      '╔─────────────────────────────────────────────────────╗',
      '│                                                     │',
      '│ ███╗   ██╗███████╗ ██████╗ ██╗    ██╗██╗███╗   ███╗ │',
      '│ ████╗  ██║██╔════╝██╔═══██╗██║    ██║██║████╗ ████║ │',
      '│ ██╔██╗ ██║█████╗  ██║   ██║██║    ██║██║██╔████╔██║ │',
      '│ ██║╚██╗██║██╔══╝  ██║   ██║╚██╗  ██╔╝██║██║╚██╔╝██║ │',
      '│ ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝  ██║██║ ╚═╝ ██║ │',
      '│ ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝   ╚═╝╚═╝     ╚═╝ │',
      '│                                                     │',
      '╚─────────────────────────────────────────────────────╝',
    }
    
    -- 在 config 函数内部执行 setup
    require('dashboard').setup({
      theme = 'hyper', 
      
      -- 配置 'hyper' 主题的细节
      config = {
        -- 添加 ASCII 艺术头部
        header = nvim_header, 

        -- 1. 快捷方式配置
        shortcut = {
          { 
            desc = ' Find File',                 -- 描述：查找文件
            group = 'Label',                       
            key = 'f',                             
            action = 'Telescope find_files',       
          },
          { 
            desc = ' Live Grep',                 -- 描述：全局搜索
            group = '@text.title',                 
            key = 'g',                             
            action = 'Telescope live_grep',        
          },
          { 
            desc = ' New File',                  -- 描述：创建新文件
            group = 'Identifier',                  
            key = 'n',                             
            action = 'enew',                       -- 使用 vim.cmd 命令简化
          },
          -- 修改后的快捷方式：打开 Lazy 界面
          {
            desc = ' Plugins',              -- 描述：Lazy 插件管理器
            group = 'Constant',
            key = 's',
            action = 'Lazy',                       -- 执行 :Lazy 命令打开 Lazy.nvim 界面
          }
        },
        
        -- 2. 插件数量信息
        packages = { 
          enable = false 
        }, 
        
        -- 3. 项目列表配置
        project = { 
          enable = true, 
          limit = 8, 
          icon = '󰈛 ', 
          label = 'Project List', 
          action = 'Telescope find_files cwd=', 
        },
        
        -- 4. 最近使用文件列表配置
        mru = { 
          enable = true, 
          limit = 10, 
          icon = '󰈙 ', 
          label = 'Recent Files', 
          cwd_only = false 
        },
      }
    })
  end
}
