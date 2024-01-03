local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("config.options")
require("lazy").setup("config.plugins")
-- TODO: Move into a separate file.
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
require("mason").setup()
require("config.keymaps")

