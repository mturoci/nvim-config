local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }

-- TODO: Refactor to init.lua.
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end
