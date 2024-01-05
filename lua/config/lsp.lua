require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = { "lua_lsp", "tsserver", "gopls", "pyright" },
  automatic_installation = true
})
local capabilities = require("cmp_nvim_lsp").default_capabilities()
require("mason-lspconfig").setup_handlers {
  function(server_name)
    require("lspconfig")[server_name].setup {
      capabilities = capabilities
    }
  end,
  ["lua_ls"] = function()
    require("lspconfig").lua_ls.setup({
      capabilities = capabilities,
      settings = {
        Lua = {
          diagnostics = {
            globals = { "vim" }
          }
        }
      }
    })
  end
}
