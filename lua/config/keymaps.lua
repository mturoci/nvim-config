local keymap = vim.keymap.set
local silent = { silent = true }
local builtin = require('telescope.builtin')

-- Telescope find/grep files
keymap('n', '<leader>p', builtin.find_files, {})
keymap('n', '<leader>fg', builtin.live_grep, {})
keymap('n', '<leader>g', builtin.git_status, {})

-- Window management.
keymap("n", "<C-h>", "<C-w>h", silent)
keymap("n", "<C-j>", "<C-w>j", silent)
keymap("n", "<C-k>", "<C-w>k", silent)
keymap("n", "<C-l>", "<C-w>l", silent)
-- TODO: Remap to leader + w instead of CTRL + w
keymap("n", "<C-w>", "<C-w>w", silent)

keymap("n", "<C-l>", ":noh<CR>", silent) -- Clear search occurences highlights
