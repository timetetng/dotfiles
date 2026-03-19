return {
  "sphamba/smear-cursor.nvim",
  -- 确保在 UI 加载时启动
  lazy = false,
  opts = {
    -- ==========================================
    -- 光标尾迹与动画物理效果配置
    -- ==========================================

    -- 光标移动时的物理刚度 (0 到 1 之间)
    -- 值越小，光标感觉越重、越像橡皮筋；值越大，反应越快
    stiffness = 0.6,

    -- 尾迹自身的刚度
    trailing_stiffness = 0.3,

    -- 动画停止的最小距离阈值
    distance_stop_animating = 0.1,

    -- 是否在动画期间隐藏真实目标位置的光标
    -- 在终端环境（如 foot）中，如果你发现拖影结束时光标闪烁有异常，可以尝试设为 false
    hide_target_hack = true,

    -- 在哪些情况下禁用尾迹效果（提升性能或避免视觉干扰）
    filetypes_disabled = {
      "NvimTree",
      "neo-tree",
      "lazy",
      "mason",
      "TelescopePrompt",
    },
  },
}
