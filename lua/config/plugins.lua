return {
    { 'numToStr/Comment.nvim', opts = {}, lazy = false },
    { "williamboman/mason.nvim"},
    {
      "folke/tokyonight.nvim",
      lazy = false,
      priority = 1000,
      config = function()
        vim.cmd([[colorscheme tokyonight-storm]])
        -- require("config.colorscheme")
      end,
    },
}
