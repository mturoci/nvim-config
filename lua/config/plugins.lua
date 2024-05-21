return {
  {
    'numToStr/Comment.nvim',
    opts = {},
    lazy = false,
    dependencies = { "nvim-treesitter/nvim-treesitter", 'JoosepAlviste/nvim-ts-context-commentstring' },
    event = "BufReadPre",
    config = function()
      require("Comment").setup({ pre_hook = function() return vim.bo.commentstring end })
    end
  },
  { 'williamboman/mason.nvim' },
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      {
        'mxsdev/nvim-dap-vscode-js',
        config = function()
          require("dap-vscode-js").setup({
            debugger_path = vim.fn.stdpath('data') .. "/lazy/vscode-js-debug",
            adapters = { 'chrome', 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost', 'node', 'chrome' }, -- which adapters to register in nvim-dap
          })
          local js_based_languages = { "typescript", "javascript", "typescriptreact" }

          for _, language in ipairs(js_based_languages) do
            require("dap").configurations[language] = {
              {
                type = "pwa-node",
                request = "launch",
                name = "Launch file",
                program = "${file}",
                cwd = "${workspaceFolder}",
              },
              {
                type = "pwa-node",
                request = "attach",
                name = "Attach",
                processId = require 'dap.utils'.pick_process,
                cwd = "${workspaceFolder}",
              },
              {
                type = "pwa-chrome",
                request = "launch",
                name = "Start Chrome with \"localhost\"",
                url = "http://localhost:3000",
                webRoot = "${workspaceFolder}",
                userDataDir = "${workspaceFolder}/.vscode/vscode-chrome-debug-userdatadir"
              },
              {
                name = "Debug Vitest Tests",
                type = "pwa-node",
                runtimeExecutable = "node",
                request = "launch",
                program = "node_modules/vitest/vitest.mjs",
                protocol = "inspector",
                args = { "run", "${file}", },
                cwd = "${workspaceFolder}/ui",
                resolveSourceMapLocations = {
                  "${workspaceFolder}/**",
                  "!**/node_modules/**"
                }
              }
            }
          end
        end
      },
      {
        "nvim-telescope/telescope-dap.nvim",
        config = function() require("telescope").load_extension("dap") end
      },
      {
        "microsoft/vscode-js-debug",
        -- After install, build it and rename the dist directory to out
        build = "npm install --legacy-peer-deps --no-save && npx gulp vsDebugServerBundle && rm -rf out && mv dist out",
        version = "1.*",
      },
    },
  },
  {
    'theHamsta/nvim-dap-virtual-text',
    config = function() require("nvim-dap-virtual-text").setup() end
  },
  { 'williamboman/mason-lspconfig.nvim' },
  { 'neovim/nvim-lspconfig' },
  { 'nvim-tree/nvim-web-devicons' },
  { 'github/copilot.vim' },
  { 'tpope/vim-abolish' },
  { 'https://github.com/windwp/nvim-ts-autotag' },
  {
    'windwp/nvim-autopairs',
    event = "InsertEnter",
    opts = {}
  },
  {
    'RRethy/vim-illuminate',
    config = function()
      require("illuminate").configure {}

      -- change the highlight style
      vim.api.nvim_set_hl(0, "IlluminatedWordText", { link = "Visual" })
      vim.api.nvim_set_hl(0, "IlluminatedWordRead", { link = "Visual" })
      vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { link = "Visual" })

      --- auto update the highlight style on colorscheme change
      vim.api.nvim_create_autocmd({ "ColorScheme" }, {
        pattern = { "*" },
        callback = function()
          vim.api.nvim_set_hl(0, "IlluminatedWordText", { link = "Visual" })
          vim.api.nvim_set_hl(0, "IlluminatedWordRead", { link = "Visual" })
          vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { link = "Visual" })
        end
      })
    end
  },
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local harpoon = require("harpoon")
      harpoon:setup()
    end,
  },
  {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup {
        current_line_blame = true,
        current_line_blame_formatter = '<author>, <author_time:%R> • <summary>',
      }
    end
  },
  {
    "stevearc/conform.nvim",
    lazy = true,
    event = { "BufReadPre", "BufNewFile" }, -- to disable, comment this out
    config = function()
      local conform = require("conform")

      conform.setup({
        formatters_by_ft = {
          javascript = { "prettierd" },
          typescript = { "prettierd" },
          javascriptreact = { "prettierd" },
          typescriptreact = { "prettierd" },
          svelte = { "prettierd" },
          css = { "prettierd" },
          html = { "prettierd" },
          json = { "prettierd" },
          yaml = { "prettierd" },
          markdown = { "prettierd" },
          graphql = { "prettierd" },
          lua = { "luaformatter" },
          -- python = { "isort", "black" },
        },
        format_on_save = {
          lsp_fallback = true,
          async = false,
          timeout_ms = 1000,
        },
      })
    end,
  },
  {
    "mfussenegger/nvim-lint",
    lazy = true,
    event = { "BufReadPre", "BufNewFile" }, -- to disable, comment this out
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        svelte = { "eslint_d" },
      }

      local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group = lint_augroup,
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.5',
    dependencies = { 'nvim-lua/plenary.nvim' },
    lazy = false,
    config = function()
      local actions = require('telescope.actions')
      local function filename_first(_, path)
        local tail = vim.fs.basename(path)
        local parent = vim.fs.dirname(path)
        if parent == "." then return tail end
        return string.format("%s\t\t%s", tail, parent)
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "TelescopeResults",
        callback = function(ctx)
          vim.api.nvim_buf_call(ctx.buf, function()
            vim.fn.matchadd("TelescopeParent", "\t\t.*$")
            vim.api.nvim_set_hl(0, "TelescopeParent", { link = "TelescopeResultsComment" })
          end)
        end,
      })

      require("telescope").setup({
        pickers = {
          live_grep = {
            additional_args = function() return { "--max-count=1" } end
          },
          find_files = {
            find_command = { "rg", "--files", "--hidden", "-g", "!**/.git/*", },
          },
        },
        defaults = {
          mappings = {
            n = {
              ["<CR>"] = actions.select_default + actions.center,
              ["<M-CR>"] = actions.select_vertical + actions.center,
            },
            i = {
              ["<CR>"] = actions.select_default + actions.center,
              ["<M-CR>"] = actions.select_vertical + actions.center,
            }
          },
          sorting_strategy = "ascending",
          layout_config = { prompt_position = "top", preview_width = 0.65 },
          prompt_prefix = " ",
          -- TODO: Doesn't work for git_status. Needs to be fixed in telescope itself.
          path_display = filename_first,
        }
      })
    end
  },
  {
    'natecraddock/telescope-zf-native.nvim',
    config = function()
      require("telescope").load_extension("zf-native")
    end
  },
  {
    'stevearc/oil.nvim',
    opts = {},
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("oil").setup({
        skip_confirm_for_simple_edits = true,
        lsp_file_methods = {
          timeout_ms = 1000,
          autosave_changes = true,
        },
        view_options = {
          show_hidden = true,
        }
      })
    end
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local configs = require("nvim-treesitter.configs")

      configs.setup({
        ensure_installed = { "lua", "vim", "vimdoc", "css", "python", "go", "javascript", "typescript", "html", "svelte", "json", "markdown", "tsx" },
        sync_install = false,
        highlight = { enable = true },
        indent = { enable = true },
        autotag = { enable = true, enable_rename = true },
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
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      'hrsh7th/cmp-nvim-lsp', -- LSP source for nvim-cmp
      "hrsh7th/cmp-buffer",   -- source for text in buffer
      "hrsh7th/cmp-path",     -- source for file system paths
      "L3MON4D3/LuaSnip",
      -- snippet engine
      "saadparwaiz1/cmp_luasnip",     -- for autocompletion
      "rafamadriz/friendly-snippets", -- useful snippets
      "onsails/lspkind.nvim",         -- vs-code like pictograms
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local lspkind = require("lspkind")

      -- loads vscode style snippets from installed plugins (e.g. friendly-snippets)
      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        completion = { completeopt = "menu,menuone,preview", },
        snippet = { -- configure how nvim-cmp interacts with snippet engine
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-k>"] = cmp.mapping.select_prev_item(), -- previous suggestion
          ["<C-j>"] = cmp.mapping.select_next_item(), -- next suggestion
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(), -- show completion suggestions
          ["<C-e>"] = cmp.mapping.abort(),        -- close completion window
          ["<CR>"] = cmp.mapping.confirm({ select = false }),
        }),
        -- sources for autocompletion
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" }, -- snippets
          { name = "buffer" },  -- text within current buffer
          { name = "path" },    -- file system paths
        }),
        -- configure lspkind for vs-code like pictograms in completion menu
        formatting = {
          format = lspkind.cmp_format({
            mode = "symbol",
            maxwidth = 150,
            ellipsis_char = "...",
          }),
        },
      })
    end,
  },
}
