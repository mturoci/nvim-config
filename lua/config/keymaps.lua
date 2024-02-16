local keymap       = vim.keymap.set
local silent       = { silent = true }
local builtin      = require('telescope.builtin')
local functions    = require('config.functions')

local silent_shell = function(cmd)
  return Statusline_refresh_wrap(function()
    vim.cmd('silent !' .. cmd .. ' > /dev/null 2>&1')
  end)
end

local function git_with_curr_file(cmd)
  return function()
    silent_shell(cmd .. ' ' .. vim.fn.expand('%:p'))()
  end
end

-- Telescope find/grep files.
keymap('n', '<leader>p', builtin.find_files, {})
keymap('n', '<leader>ff', builtin.live_grep, {})
keymap('n', '<leader>fh', builtin.help_tags, {})
keymap('n', '<leader>gl', functions.my_git_status, {})
keymap('n', '<leader>c', functions.my_git_bcommits, {})

-- Window management.
keymap("n", "<C-h>", "<C-w>h", silent)
keymap("n", "<C-j>", "<C-w>j", silent)
keymap("n", "<C-k>", "<C-w>k", silent)
keymap("n", "<C-l>", "<C-w>l", silent)
keymap("n", "<C-w>", "<C-w>w", silent) -- TODO: Remap to leader + w instead of CTRL + w

-- Git.
keymap('n', '<leader>ga', silent_shell('git add .'), {})
keymap('n', '<leader>gr', silent_shell('git reset .'), {})
keymap('n', '<leader>gfr', git_with_curr_file('git reset'), {})
keymap('n', '<leader>gfc', git_with_curr_file('git checkout --'), {}) -- Git file clean - remove changes.
keymap('n', '<leader>gfa', git_with_curr_file('git add'), {})
keymap('n', '<leader>gs', silent_shell('git stash'), {})
keymap('n', '<leader>gp', silent_shell('git stash pop'), {})
keymap('n', '<leader>gpl', silent_shell('git pull'), {})
keymap('n', '<leader>gps', silent_shell('git push'), {})
keymap('n', '<leader>grh', silent_shell('git reset --hard'), {})
keymap('n', '<leader>grs', silent_shell('git reset --soft HEAD~1'), {})
keymap('n', '<leader>gc', functions.commit, {})
keymap('n', '<leader>gbl', builtin.git_branches, {})
keymap('n', '<leader>gbt', silent_shell('git checkout -'), {})

-- Utils.
keymap("n", "<C-l>", ":noh<CR>", silent) -- Clear search occurences highlights
keymap('n', '<leader>e', ':Ex<CR><CR>', silent)
keymap('n', '<leader>w', ':write<CR>', silent)
keymap('n', '<leader>q', ':q!<CR>', silent)
keymap('n', '<C-u>', '<C-u>zz', silent)
keymap('n', '<C-d>', '<C-d>zz', silent)
keymap('n', '<C-o>', '<C-o>zz', silent)
keymap('n', '<C-i>', '<C-i>zz', silent)

-- LSP.
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local opts = { buffer = ev.buf }
    keymap('n', 'gD', vim.lsp.buf.declaration, opts)
    keymap('n', 'gd', builtin.lsp_definitions, opts)
    keymap('n', 'K', vim.lsp.buf.hover, opts)
    keymap('n', 'gi', builtin.lsp_implementations, opts)
    keymap('n', 'gu', functions.go_to_usages, opts)
    keymap('n', '<C-k>', vim.lsp.buf.signature_help, opts)
    keymap('n', '<M-m>', vim.diagnostic.goto_prev, opts)
    keymap('n', '<C-m>', vim.diagnostic.goto_next, opts)
    keymap('n', '<space>D', vim.lsp.buf.type_definition, opts)
    keymap('n', '<space>rn', Rename, opts)
    keymap({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
    keymap('n', 'so', builtin.lsp_document_symbols, opts)
    keymap('n', '<space>f', function()
      vim.lsp.buf.format { async = true }
    end, opts)
  end,
})

-- Show help in a new buffer.
vim.api.nvim_create_autocmd('BufWinEnter', {
  pattern = '*',
  callback = function(event)
    if vim.bo[event.buf].filetype == 'help' then vim.cmd.only() end
  end,
})

-- Harpoon.
local harpoon = require("harpoon")
keymap("n", "<leader>ha", function() harpoon:list():append() end)
keymap("n", "<leader>hl", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
keymap("n", "<leader>1", function() harpoon:list():select(1) end)
keymap("n", "<leader>2", function() harpoon:list():select(2) end)
keymap("n", "<leader>3", function() harpoon:list():select(3) end)
keymap("n", "<leader>4", function() harpoon:list():select(4) end)
-- TODO: Figure out these.
keymap("n", "<C-S-P>", function() harpoon:list():prev() end)
keymap("n", "<C-S-N>", function() harpoon:list():next() end)

-- Git signs
require('gitsigns').setup {
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns

    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    -- Navigation.
    map('n', '<C-h>', function()
      vim.schedule(function() gs.next_hunk() end)
      return '<Ignore>'
    end, { expr = true })

    map('n', '<S-h>', function()
      vim.schedule(function() gs.prev_hunk() end)
      return '<Ignore>'
    end, { expr = true })

    -- Actions.
    map('n', '<leader>hr', gs.reset_hunk)
    map('n', '<leader>hv', gs.preview_hunk)
  end
}
