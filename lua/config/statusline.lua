local function get_tmux_color(fg, bg)
  return table.concat({ "#[fg=", fg, ",bg=", bg, "]" })
end

local COLOR_BG = "#262626"
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

local function set_statusline(left, center, right, center_len)
  if left == nil then left = prev_left else prev_left = left end
  if center == nil then center = prev_center else prev_center = center end
  if right == nil then right = prev_right else prev_right = right end

  local left_part = left ~= '' and table.concat({ "%#StatuslineBackgroundLight#", left, POWERLINE_RIGHT }) or ""
  vim.o.statusline = table.concat({ left_part, "%=", "%#StatuslineBackground#", "%#StatuslineBackgroundLight#", right })

  if center_len == nil then return end

  local spaces = ((vim.fn.winwidth(0) - center_len) / 2) - TMUX_RIGHT_LENGTH
  center = table.concat({ center, string.rep(" ", spaces), TMUX_ORIGINAL_RIGHT })
  utils.spawn("tmux", { "set-option", "-g", "status-right", center })
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

  local branch = utils.read_file(git_dir .. "/HEAD")
  if branch then branch = "  " .. branch:match("ref: refs/heads/([^\n\r%s]+)") end

  local staged = 0
  local changed = 0
  local untracked = 0
  local unpushed = 0

  utils.spawn("git", { "status", "-s" },
    function(err, data)
      if err then return end

      if data then
        local lines = vim.split(data, "\n")
        table.remove(lines, #lines)
        prev_staged = {}
        for _, line in pairs(lines) do
          if string.sub(line, 1, 2) == "??" then untracked = untracked + 1 end
          if string.sub(line, 1, 1) ~= " " then
            staged = staged + 1
            table.insert(prev_staged, string.sub(line, 4))
          end
          if string.sub(line, 2, 2) ~= " " then changed = changed + 1 end
        end
      end
    end,
    function()
      local bg_light = "%#StatuslineBackgroundLight#"
      local staged_str = staged > 0 and table.concat({ "%#StatusLineInfo#", "  ", staged, bg_light }) or ""
      local changed_str = changed > 0 and table.concat({ "%#StatusLineWarn#", " 󰏫 ", changed, bg_light }) or ""
      local untracked_str = untracked > 0 and table.concat({ "%#StatusLineError#", "  ", untracked, bg_light }) or ""
      local unpushed_str = unpushed > 0 and table.concat({ "%#StatusLineHint#", "  ", unpushed, bg_light }) or ""

      local git_str = table.concat({ branch, staged_str, changed_str, untracked_str, unpushed_str })
      set_statusline(git_str)
    end)

  return nil
end

local function str_count(...)
  local count = 0
  for _, v in ipairs { ... } do
    if v ~= nil and v ~= 0 then
      count = count + string.len(tostring(v))
    end
  end

  return count
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

  local str_len = str_count(filename, icon)
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
  local str_len = str_count(errors, warnings, hints, info)

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
  local git_str = git_info()
  if git_str == nil or git_str == "" then
    return nil
  end
  return table.concat({ git_str, POWERLINE_RIGHT })
end

local function get_center()
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
  local percent = vim.fn.line(".") / vim.fn.line("$") * 100
  return table.concat({ POWERLINE_LEFT, math.floor(percent + 0.5), " 󱉸 " })
end

local refresh_statusline_async = utils.async(function()
  local center, center_len = get_center()
  set_statusline(get_left(), center, get_right(), center_len)
end)

local status_group = vim.api.nvim_create_augroup('statusline', { clear = true })
vim.api.nvim_create_autocmd(
  { 'WinEnter', 'BufEnter', 'BufWritePost', 'SessionLoadPost', 'FileChangedShellPost' }, {
    group = status_group,
    callback = refresh_statusline_async,
  })
vim.api.nvim_create_autocmd({ 'TextChangedI', 'TextChanged' }, {
  group = status_group,
  callback = utils.debounce(700, refresh_statusline_async)
})
vim.api.nvim_create_autocmd({ 'CursorMoved' }, {
  group = status_group,
  callback = function()
    local center, center_len = get_center()
    set_statusline(nil, center, get_right(), center_len)
  end
})
vim.api.nvim_create_autocmd({ 'VimLeave' }, {
  group = status_group,
  pattern = '*',
  callback = function()
    utils.spawn("tmux", { "set-option", "-g", "status-right", TMUX_ORIGINAL_RIGHT })
  end
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
