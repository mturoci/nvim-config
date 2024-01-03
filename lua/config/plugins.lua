return {
    { 'numToStr/Comment.nvim', opts = {}, lazy = false },
    { "williamboman/mason.nvim"},
    { 'nvim-telescope/telescope.nvim', tag = '0.1.5', dependencies = { 'nvim-lua/plenary.nvim' }, lazy = false },
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function () 
          local configs = require("nvim-treesitter.configs")

          configs.setup({
              ensure_installed = { "lua", "vim", "vimdoc", "css", "python", "go", "javascript", "typescript", "html", "svelte", "json", "markdown" },
              sync_install = false,
              highlight = { enable = true },
              indent = { enable = true },  
            })
        end
    },
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
