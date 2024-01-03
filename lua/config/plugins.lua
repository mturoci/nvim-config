return {
    { 'numToStr/Comment.nvim', opts = {}, lazy = false },
    { 'williamboman/mason.nvim', },
    { 'williamboman/mason-lspconfig.nvim' },
    { 'neovim/nvim-lspconfig' },
    { 'nvim-tree/nvim-web-devicons'},
    {
      'lewis6991/gitsigns.nvim',
      config = function ()
        require('gitsigns').setup {
          current_line_blame = true,
          current_line_blame_formatter = '<author>, <author_time:%R> • <summary>',
        }
      end
    },
    {
       "folke/trouble.nvim",
       dependencies = { "nvim-tree/nvim-web-devicons" },
       config = function ()
         require('trouble').setup {
            signs = {
               error = "",
               warning = "",
               hint = "",
               information = "",
               other = "",
            },
         }
       end
    },
    { 
      'nvim-telescope/telescope.nvim',
      tag = '0.1.5',
      dependencies = { 'nvim-lua/plenary.nvim' },
      lazy = false,
      config = function ()
        local actions = require('telescope.actions')
        require("telescope").setup({
         defaults = {
            mappings = {
              n = {
                ["<S-CR>"] = actions.select_vertical,
              },
              i = {
                ["<S-CR>"] = actions.select_vertical,
              }
            }
          }
        })
      end
    },
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
        "kylechui/nvim-surround",
        version = "*", -- Use for stability; omit to use `main` branch for the latest features
        event = "VeryLazy",
        config = function()
            require("nvim-surround").setup({})
        end
    },
    {
      "folke/tokyonight.nvim",
      lazy = false,
      priority = 1000,
      config = function()
        vim.cmd([[colorscheme tokyonight-storm]])
      end,
    },
}
