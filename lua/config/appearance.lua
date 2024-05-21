local diagnostic_signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }

for type, icon in pairs(diagnostic_signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

vim.fn.sign_define('DapBreakpoint', { text = " ", texthl = 'DiagnosticError', numhl = "" })
vim.fn.sign_define('DapStopped', { text = "", texthl = 'Search', linehl = 'Search', numhl = "Search" })

local colors = {
  background = "#2C2B2A",
  background_light = "#3b3938",
  dark_green = '#A4BC92',
  dark_primary = "#3A4D39",
  dark_yellow = '#DDFFBB',
  err = "#D37676",
  gray = '#908caa',
  green = '#6a8759',
  info = "#E1AFD1",
  light_brown = '#ECE3A1',
  light_gray = '#3a3a3a',
  light_primary = '#c2d69a',
  none = "NONE",
  primary = "#a7c080",
  cyan = '#839e60',
  success = "#A5DD9B",
  blue = '#5382ab',
  text = '#bfbed1',
  warn = "#F6F193",
}

local highlights = {
  Statement                                = { fg = colors.primary },
  Boolean                                  = { fg = colors.err },
  Comment                                  = { fg = colors.gray },
  Conditional                              = { fg = colors.green },
  Constant                                 = { fg = colors.err },
  Conceal                                  = { bg = colors.none },
  CursorLine                               = { bg = colors.light_gray },
  CursorLineNr                             = { fg = colors.text },
  CurSearch                                = { bg = colors.light_gray },
  Search                                   = { bg = colors.dark_primary },
  DiagnosticError                          = { fg = colors.err },
  DiagnosticHint                           = { fg = colors.info },
  DiagnosticInfo                           = { fg = colors.info },
  DiagnosticWarn                           = { fg = colors.warn },
  Directory                                = { fg = colors.primary },
  DiffAdd                                  = { fg = colors.success },
  DiffChange                               = { fg = colors.warn },
  DiffDelete                               = { fg = colors.err },
  DiffText                                 = { fg = colors.err },
  ErrorMsg                                 = { fg = colors.err },
  Exception                                = { fg = colors.green },
  FloatBorder                              = { fg = colors.primary },
  Identifier                               = { fg = colors.text },
  Keyword                                  = { fg = colors.green },
  LineNr                                   = { fg = colors.gray },
  MatchParen                               = { fg = colors.primary },
  NonText                                  = { fg = colors.gray },
  Normal                                   = { bg = colors.background, fg = colors.text },
  NormalFloat                              = { bg = colors.background_light },
  PMenu                                    = { bg = colors.background_light },
  PMenuSel                                 = { bg = colors.dark_primary },
  Repeat                                   = { fg = colors.green },
  SignColumn                               = { bg = colors.background },
  Special                                  = { fg = colors.primary },
  Error                                    = { fg = colors.err },
  String                                   = { fg = colors.green },
  TelescopeBorder                          = { fg = colors.primary },
  TelescopeMatching                        = { fg = colors.primary },
  TelescopePreviewMatch                    = { bg = colors.dark_primary },
  TelescopeMultiSelection                  = { bg = colors.light_gray },
  Type                                     = { fg = colors.cyan },
  Visual                                   = { bg = colors.dark_primary },
  makeTarget                               = { fg = colors.primary },
  makeCommands                             = { fg = colors.text },
  makePreCondit                            = { fg = colors.primary },
  makeIdent                                = { fg = colors.primary },
  ["@constant.builtin"]                    = { fg = colors.primary },
  ["@include"]                             = { fg = colors.primary },
  ["@label"]                               = { fg = colors.text },
  ["@type"]                                = { fg = colors.light_primary },
  ["@text.title"]                          = { fg = colors.primary },
  ["@type.definition"]                     = { fg = colors.light_primary },
  ["@lsp.type.type"]                       = { fg = colors.light_primary },
  ["@lsp.type.type.method"]                = { fg = colors.primary },
  ["@lsp.type.parameter"]                  = { fg = colors.light_brown },
  ["@lsp.type.struct"]                     = { fg = colors.primary },
  ["@lsp.mod.declaration"]                 = { fg = colors.text },
  ["@lsp.typemod.function.defaultLibrary"] = { fg = colors.primary },
  ["@operator"]                            = { fg = colors.gray },
  ["@parameter"]                           = { fg = colors.light_brown },
  ["@property"]                            = { fg = colors.text },
  ["@punctuation.bracket"]                 = { fg = colors.gray },
  ["@punctuation.delimiter"]               = { fg = colors.gray },
  ["@punctuation.special"]                 = { fg = colors.gray },
  ["@text.math"]                           = { fg = colors.primary },
  ["@variable.builtin"]                    = { fg = colors.primary },
  ['@exception']                           = { fg = colors.green },
  ['@function']                            = { fg = colors.text },
  ["@function.builtin"]                    = { fg = colors.primary },
  ['@function.call']                       = { fg = colors.primary },
  ['@method.call']                         = { fg = colors.primary },
  ["@lsp.type.function"]                   = { fg = colors.primary },
  ["@conditional.ternary"]                 = { fg = colors.text },
  ['@tag']                                 = { fg = colors.primary },
  ['@tag.attribute']                       = { fg = colors.light_brown },
  ['@tag.delimiter']                       = { fg = colors.primary },
  netrwDir                                 = { fg = colors.primary },
}


for group, attr in pairs(highlights) do
  vim.api.nvim_set_hl(0, group, attr)
end
