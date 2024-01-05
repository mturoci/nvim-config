local keymap = vim.keymap.set
local silent = { silent = true }
local builtin = require('telescope.builtin')

-- Telescope find/grep files
keymap('n', '<leader>p', builtin.find_files, {})
keymap('n', '<leader>f', builtin.live_grep, {})
keymap('n', '<leader>g', builtin.git_status, {})

-- Window management.
keymap("n", "<C-h>", "<C-w>h", silent)
keymap("n", "<C-j>", "<C-w>j", silent)
keymap("n", "<C-k>", "<C-w>k", silent)
keymap("n", "<C-l>", "<C-w>l", silent)
-- TODO: Remap to leader + w instead of CTRL + w
keymap("n", "<C-w>", "<C-w>w", silent)

keymap("n", "<C-l>", ":noh<CR>", silent) -- Clear search occurences highlights

-- LSP
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local opts = { buffer = ev.buf }
    keymap('n', 'gD', vim.lsp.buf.declaration, opts)
    keymap('n', 'gd', vim.lsp.buf.definition, opts)
    keymap('n', 'K', vim.lsp.buf.hover, opts)
    keymap('n', 'gi', vim.lsp.buf.implementation, opts)
    keymap('n', '<C-k>', vim.lsp.buf.signature_help, opts)
    keymap('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
    keymap('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
    keymap('n', '<space>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, opts)
    keymap('n', '<space>D', vim.lsp.buf.type_definition, opts)
    keymap('n', '<space>rn', vim.lsp.buf.rename, opts)
    keymap({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
    keymap('n', 'gr', vim.lsp.buf.references, opts)
    keymap('n', '<space>f', function()
      vim.lsp.buf.format { async = true }
    end, opts)
  end,
})
