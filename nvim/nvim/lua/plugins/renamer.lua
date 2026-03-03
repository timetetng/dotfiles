return {
  "smjonas/inc-rename.nvim",

  config = function()
    require("inc_rename").setup({
      input_buffer_type = "snacks",
    })

    vim.keymap.set("n", "<leader>rn", ":IncRename ")
  end,
}
