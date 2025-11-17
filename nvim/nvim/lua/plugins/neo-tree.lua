-- ~/.config/nvim/lua/plugins/neo-tree.lua
return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x", -- 推荐使用 v3.x 分支
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons", -- 可选：用于显示文件图标
    "MunifTanjim/nui.nvim",
  }
}
