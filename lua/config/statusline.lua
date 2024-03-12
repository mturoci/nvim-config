local function get_tmux_color(fg, bg)
  return table.concat({ "#[fg=", fg, ",bg=", bg, "]" })
end

local COLOR_BG = "#2C2B2A"
local COLOR_FG = "#3a3a3a"
local COLOR_PRIMARY = "#a7c080"
local COLOR_ERR = vim.api.nvim_get_hl(0, { name = "DiagnosticError" }).fg
local COLOR_WARN = vim.api.nvim_get_hl(0, { name = "DiagnosticWarn" }).fg
local COLOR_HINT = vim.api.nvim_get_hl(0, { name = "DiagnosticHint" }).fg
local COLOR_INFO = vim.api.nvim_get_hl(0, { name = "DiagnosticInfo" }).fg
local HIGHLIGHTS = {
  { name = "Background",      guibg = COLOR_BG, guifg = COLOR_FG },
  { name = "BackgroundLight", guibg = COLOR_FG, guifg = COLOR_PRIMARY },
  { name = "Error",           guibg = COLOR_FG, guifg = "#" .. ("%06x"):format(COLOR_ERR) },
  { name = "Warn",            guibg = COLOR_FG, guifg = "#" .. ("%06x"):format(COLOR_WARN) },
  { name = "Hint",            guibg = COLOR_FG, guifg = "#" .. ("%06x"):format(COLOR_HINT) },
  { name = "Info",            guibg = COLOR_FG, guifg = "#" .. ("%06x"):format(COLOR_INFO) }
}
local POWERLINE_RIGHT = " %#StatuslineBackground#"
local POWERLINE_LEFT = "%#StatuslineBackground#%#StatuslineBackgroundLight# "
local TMUX_POWERLINE_LEFT = '#[fg=#3a3a3a]#[fg=#a7c080,bg=#3a3a3a]'
local TMUX_POWERLINE_RIGHT = '#[bg=#262626,fg=#3a3a3a]#[bg=#262626]'
local TMUX_RIGHT_LENGTH = 18
local TMUX_ORIGINAL_RIGHT = '#(/Users/mturoci/.tmux/right_status.sh)'
local TMUX_ERR = get_tmux_color("#" .. ("%06x"):format(COLOR_ERR), COLOR_FG)
local TMUX_WARN = get_tmux_color("#" .. ("%06x"):format(COLOR_WARN), COLOR_FG)
local TMUX_HINT = get_tmux_color("#" .. ("%06x"):format(COLOR_HINT), COLOR_FG)
local TMUX_INFO = get_tmux_color("#" .. ("%06x"):format(COLOR_INFO), COLOR_FG)
local TMUX_BG_LIGHT = get_tmux_color(COLOR_PRIMARY, COLOR_FG)
local webdevicons = require 'nvim-web-devicons'
local path = require('plenary.path')
local utils = require('config.utils')
local prev_left = ''
local prev_center = ''
local prev_right = ''
local prev_staged = {}
local M = {
  get_staged = function() return prev_staged end,
}

-- Spec: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_documentSymbol
local ALLOWED_SYMBOL_KINDS = {
  [1]  = true, -- File
  [2]  = true, -- Module
  [3]  = true, -- Namespace
  -- [4]  = " ", -- Package
  [5]  = true, -- Class
  [6]  = true, -- Method
  [7]  = true, -- Property
  -- [8]  = " ", -- Field
  [9]  = true, -- Constructor
  [10] = true, -- Enum
  [11] = true, -- Interface
  [12] = true, -- Function
  -- [13] = "󰆧 ", -- Variable
  [14] = true, -- Constant
  -- [15] = "󰀬 ", -- String
  -- [16] = "󰎠 ", -- Number
  -- [17] = "◩ ", -- Boolean
  -- [18] = "󰅪 ", -- Array
  -- [19] = "󰅩 ", -- Object
  [20] = true, -- Key
  [21] = true, -- Null
  [22] = true, -- EnumMember
  [23] = true, -- Struct
  [24] = true, -- Event
  -- [25] = "󰆕 ", -- Operator
  [26] = true, -- TypeParameter
}

local function build_outline(ret, symbols, row)
  for _, symbol in ipairs(symbols) do
    local start = symbol.range.start.line
    local finish = symbol.range["end"].line
    if start <= row and finish >= row then
      local symbol_kind = ALLOWED_SYMBOL_KINDS[symbol.kind]
      -- If last symbol is a constant and has no children, it's a variable - do not show.
      if symbol.kind == 14 and #symbol.children == 0 then symbol_kind = false end
      if symbol_kind then
        local name = symbol.name
        name = name:gsub(" callback", "")
        table.insert(ret, name)
      end
      if symbol.children then build_outline(ret, symbol.children, row) end
      break
    end
  end
end

local function get_symbols_outline()
  local clients = vim.lsp.get_active_clients()
  local client = nil

  for _, c in pairs(clients) do
    if c.server_capabilities.documentSymbolProvider then
      client = c
      break
    end
  end

  if not client then return '', 0 end

  local bufnr = vim.api.nvim_get_current_buf()
  local winnr = vim.api.nvim_get_current_win()
  local params = vim.lsp.util.make_position_params(winnr)
  -- TODO: Leverage client.request() instead of vim.lsp.buf_request.
  local err, result, _, _ = utils.await(vim.lsp.buf_request, bufnr, "textDocument/documentSymbol", params)
  if err or not result then return '', 0 end

  local outline = {}
  local row = vim.api.nvim_win_get_cursor(winnr)[1] - 1
  build_outline(outline, result, row)
  local str_outline = table.concat(outline, " > ")
  return str_outline, utils.str_count(str_outline)
end

local function get_bottom_center()
  if vim.bo.filetype == "netrw" then return '', 0 end

  local center, center_len = get_symbols_outline()
  if center_len == 0 then return '', 0 end
  return table.concat({ POWERLINE_LEFT, center, POWERLINE_RIGHT, "%#StatuslineBackground#" }), center_len
end

local function set_statusline(left, top_center, center, right, top_center_len, right_len, center_len)
  if left == nil then left = prev_left else prev_left = left end
  if top_center == nil then top_center = prev_center else prev_center = top_center end
  if right == nil then right = prev_right else prev_right = right end

  top_center_len = top_center_len or 0

  local total_width = utils.vim_loop(function()
    local total_width = 0
    for _, win_id in ipairs(vim.api.nvim_list_wins()) do
      total_width = total_width + vim.fn.winwidth(win_id)
    end
    return total_width
  end)
  local top_center_padding = ((total_width - top_center_len) / 2) - TMUX_RIGHT_LENGTH
  local bottom_center_padding = ((total_width - center_len) / 2) - right_len

  -- TODO: Create async versions that will not block the coroutine.
  utils.vim_loop(function()
    local left_part = table.concat({ "%#StatuslineBackgroundLight#", left })
    local center_part = table.concat({ center, string.rep(" ", bottom_center_padding) })
    local right_part = table.concat({ "%#StatuslineBackgroundLight#", right })
    vim.o.statusline = table.concat({ left_part, "%=", center_part, right_part })
  end)

  top_center = table.concat({ top_center, string.rep(" ", top_center_padding or 0), TMUX_ORIGINAL_RIGHT })
  utils.spawn("tmux", { "set-option", "-g", "status-right", top_center })
end

for _, highlight in ipairs(HIGHLIGHTS) do
  vim.cmd(table.concat({ "highlight Statusline", highlight.name, " guibg=", highlight.guibg, " guifg=", highlight.guifg }))
end

local dir = path:new(vim.loop.cwd())
local git_dir = ""
while dir.filename ~= "" and dir.filename ~= "/" do
  local git_path = dir:joinpath(".git")
  if git_path:exists() then
    git_dir = git_path.filename
    break
  end
  dir = path:new(dir:parent())
end


local function git_info()
  if git_dir == '' then
    return ""
  end

  local branch, git_status = utils.await_all({
    { utils.read_file, git_dir .. "/HEAD" },
    { utils.spawn,     "git",             { "status", "-s" } },
  })
  branch = branch:match("ref: refs/heads/([^\n\r%s]+)")
  local unpulled, unpushed = utils.await_all({
    { utils.spawn, "git", { "rev-list", "--count", "HEAD..origin/" .. branch } },
    { utils.spawn, "git", { "rev-list", "--count", "origin/" .. branch .. "..HEAD" } }
  })

  if branch then branch = "  " .. branch end

  unpulled = tonumber(unpulled) or 0
  unpushed = tonumber(unpushed) or 0

  local staged = 0
  local changed = 0
  local untracked = 0

  local git_status_lines = vim.split(git_status, "\n")
  table.remove(git_status_lines, #git_status_lines)
  prev_staged = {}
  for _, line in pairs(git_status_lines) do
    if string.sub(line, 1, 2) == "??" then untracked = untracked + 1 end
    if string.sub(line, 1, 1) ~= " " then
      staged = staged + 1
      table.insert(prev_staged, string.sub(line, 4))
    end
    if string.sub(line, 2, 2) ~= " " then changed = changed + 1 end
  end

  local bg_light = "%#StatuslineBackgroundLight#"
  local staged_str = staged > 0 and table.concat({ "%#StatusLineInfo#", "  ", staged, bg_light }) or ""
  local changed_str = changed > 0 and table.concat({ "%#StatusLineWarn#", " 󰏫 ", changed, bg_light }) or ""
  local untracked_str = untracked > 0 and table.concat({ "%#StatusLineError#", "  ", untracked, bg_light }) or ""
  local unpushed_str = unpushed > 0 and table.concat({ "%#StatusLineHint#", "  ", unpushed, bg_light }) or ""
  local unpulled_str = unpulled > 0 and table.concat({ "%#StatusLineHint#", "  ", unpulled, bg_light }) or ""

  return table.concat({ branch, staged_str, changed_str, untracked_str, unpushed_str, unpulled_str })
end

local function file_info()
  local filename = vim.fn.expand("%:t")
  local dirty = vim.fn.getbufvar("%", "&modified")
  local extension = vim.fn.fnamemodify(filename, ":e")
  local icon, iconhl = webdevicons.get_icon(filename, extension)
  local color = vim.fn.synIDattr(vim.fn.hlID(iconhl), "fg")

  if icon then
    icon = " " .. icon
  end

  local str_len = utils.str_count(filename, icon)
  if str_len > 0 then
    str_len = str_len + 1 -- account for dirty.
    str_len = str_len + 4 -- account for powerline arrows.
  end

  return filename, dirty, icon, color, str_len
end

local function lsp_info()
  local errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
  local warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
  local hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
  local info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
  local str_len = utils.str_count(errors, warnings, hints, info)

  local errors_str = ""
  local warnings_str = ""
  local hints_str = ""
  local info_str = ""

  if errors > 0 then
    errors_str = errors > 0 and table.concat({ TMUX_ERR, "  ", errors, TMUX_BG_LIGHT }) or ""
    str_len = str_len + 3
  end
  if warnings > 0 then
    warnings_str = warnings > 0 and table.concat({ TMUX_WARN, "  ", warnings, TMUX_BG_LIGHT }) or ""
    str_len = str_len + 3
  end
  if hints > 0 then
    hints_str = hints > 0 and table.concat({ TMUX_HINT, "  ", hints, TMUX_BG_LIGHT }) or ""
    str_len = str_len + 3
  end
  if info > 0 then
    info_str = info > 0 and table.concat({ TMUX_INFO, "  ", info, TMUX_BG_LIGHT }) or ""
    str_len = str_len + 3
  end

  return errors_str, warnings_str, hints_str, info_str, str_len
end

local function get_left()
  local git = git_info()
  local ret = table.concat({ git, POWERLINE_RIGHT })
  return ret
end

local function get_top_center()
  local filename, dirty, icon, color, file_str_len = file_info()
  local errors, warnings, hints, info, lsp_str_len = lsp_info()

  if file_str_len == 0 then
    return nil, nil
  end

  return table.concat({
    TMUX_POWERLINE_LEFT,
    " ", get_tmux_color(color, COLOR_FG), icon or "", get_tmux_color(COLOR_PRIMARY, COLOR_FG), " ", filename,
    dirty == 1 and "  " or "   ",
    errors, warnings, hints, info, " ",
    TMUX_POWERLINE_RIGHT
  }), file_str_len + lsp_str_len
end

local function get_right()
  local percent = utils.vim_loop(function() return vim.fn.line(".") / vim.fn.line("$") * 100 end)
  local percentStr = table.concat({ math.floor(percent + 0.5), " 󱉸 " })
  return table.concat({ POWERLINE_LEFT, percentStr }), utils.str_count(percentStr)
end

local refresh_statusline_async = utils.async(function()
  local top_center, top_center_len = get_top_center()
  local center, center_len = get_bottom_center()
  local right, right_len = get_right()
  set_statusline(get_left(), top_center, center, right, top_center_len, right_len, center_len)
end)

local status_group = vim.api.nvim_create_augroup('statusline', { clear = true })
vim.api.nvim_create_autocmd(
  { 'WinEnter', 'BufEnter', 'BufWritePost', 'SessionLoadPost', 'FileChangedShellPost', 'CursorMoved' }, {
    group = status_group,
    callback = refresh_statusline_async,
  })
vim.api.nvim_create_autocmd({ 'TextChangedI', 'TextChanged' }, {
  group = status_group,
  callback = utils.debounce(700, refresh_statusline_async)
})
vim.api.nvim_create_autocmd({ 'VimLeave' }, {
  group = status_group,
  pattern = '*',
  callback = utils.async(function()
    utils.spawn("tmux", { "set-option", "-g", "status-right", TMUX_ORIGINAL_RIGHT })
  end)
})

-- TODO: Refactor into M.
function Statusline_refresh_wrap(callback)
  return function(args)
    callback(args)
    refresh_statusline_async()
  end
end

-- TODO: Refactor into M.
Refresh_statusline = refresh_statusline_async
M.refresh = refresh_statusline_async

return M
