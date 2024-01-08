local keymap = vim.keymap.set
local silent = { silent = true }
local builtin = require('telescope.builtin')
local silent_shell = function(cmd)
  return ':!' .. cmd .. ' > /dev/null 2>&1<CR> '
end
local commit = function()
  local last_commit = vim.fn.system('git log -1 --pretty=%B')
  local message = vim.fn.input('Commit message: ', last_commit)
  vim.cmd('!git commit -am "' .. message .. '"')
end

-- Telescope find/grep files.
keymap('n', '<leader>p', builtin.find_files, {})
keymap('n', '<leader>ff', builtin.live_grep, {})
keymap('n', '<leader>g', require('config.functions').my_git_status, {})
keymap('n', '<leader>c', require('config.functions').my_git_bcommits, {})

-- Window management.
keymap("n", "<C-h>", "<C-w>h", silent)
keymap("n", "<C-j>", "<C-w>j", silent)
keymap("n", "<C-k>", "<C-w>k", silent)
keymap("n", "<C-l>", "<C-w>l", silent)
keymap("n", "<C-w>", "<C-w>w", silent) -- TODO: Remap to leader + w instead of CTRL + w

-- Git.
keymap('n', '<leader>ga', silent_shell('git add .'), {})
keymap('n', '<leader>gr', silent_shell('git reset .'), {})
keymap('n', '<leader>gs', silent_shell('git stash'), {})
keymap('n', '<leader>gp', silent_shell('git stash pop'), {})
keymap('n', '<leader>grh', silent_shell('git reset --hard'), {})
keymap('n', '<leader>grs', silent_shell('git reset --soft HEAD~1'), {})
keymap('n', '<leader>gc', commit, {})

-- Utils.
keymap("n", "<C-l>", ":noh<CR>", silent) -- Clear search occurences highlights

-- LSP.
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

-- Show help in a new buffer.
vim.api.nvim_create_autocmd('BufWinEnter', {
  pattern = '*',
  callback = function(event)
    if vim.bo[event.buf].filetype == 'help' then vim.cmd.only() end
  end,
})

-- Harpoon.
local harpoon = require("harpoon")
keymap("n", "<leader>a", function() harpoon:list():append() end)
keymap("n", "<C-p>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

keymap("n", "<leader>1", function() harpoon:list():select(1) end)
keymap("n", "<leader>2", function() harpoon:list():select(2) end)
keymap("n", "<leader>3", function() harpoon:list():select(3) end)
keymap("n", "<leader>4", function() harpoon:list():select(4) end)

keymap("n", "<C-S-P>", function() harpoon:list():prev() end)
keymap("n", "<C-S-N>", function() harpoon:list():next() end)
