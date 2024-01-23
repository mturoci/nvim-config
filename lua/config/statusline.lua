local POWERLINE_RIGHT = " %#StatuslineBackground#"
local POWERLINE_LEFT = "%#StatuslineBackground#%#StatuslineBackgroundLight# "
local TMUX_POWERLINE_LEFT = '#[fg=#3a3a3a]#[fg=#a7c080,bg=#3a3a3a]'
local TMUX_POWERLINE_RIGHT = '#[bg=#262626,fg=#3a3a3a]#[bg=#262626]'
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
local webdevicons = require 'nvim-web-devicons'
local luv = vim.loop
local path = require('plenary.path')
local utils = require('config.utils')
local Job = require('plenary.job')
local prev_left = ''
local prev_center = ''
local prev_right = ''
local original_tmux_left = '#(/Users/mturoci/.tmux/right_status.sh)'
local tmux_right_length = 28
local function get_tmux_color(fg, bg)
  return table.concat({ "#[fg=", fg, ",bg=", bg, "]" })
end

local function set_statusline(left, center, right)
  if left == nil then left = prev_left else prev_left = left end
  if center == nil then center = prev_center else prev_center = center end
  if right == nil then right = prev_right else prev_right = right end

  local spaces = vim.fn.winwidth(0) - #center - tmux_right_length
  center = table.concat({ center, string.rep(" ", spaces), original_tmux_left })
  Job:new({ command = 'tmux', args = { "set-option", "-g", "status-right", center } }):start()
  vim.o.statusline = table.concat({ "%#StatuslineBackgroundLight#", left, "%=", "%#StatuslineBackground#",
    "%#StatuslineBackgroundLight#", right })
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

  local branch = ""
  local staged = 0
  local changed = 0
  local untracked = 0
  local unpushed = 0

  local head_stat = luv.fs_stat(git_dir .. "/HEAD")
  local head_data = ""
  if head_stat and head_stat.mtime then
    local head_file = luv.fs_open(git_dir .. "/HEAD", "r", 438)
    if head_file then
      head_data = luv.fs_read(head_file, head_stat.size, 0)
    end
    luv.fs_close(head_file)
  end

  branch = head_data:match("ref: refs/heads/([^\n\r%s]+)")
  if branch then
    branch = "  " .. branch
  end

  Job:new({
    command = 'git',
    args = { 'status', '-s' },
    on_exit = vim.schedule_wrap(function(j)
      local result = j:result()
      if result == nil then return end
      print(result)
      for line in result[1]:gmatch("[^\r\n]+") do
        if string.sub(line, 1, 2) == "??" then untracked = untracked + 100 end
        if string.sub(line, 1, 1) ~= " " then staged = staged + 1 end
        if string.sub(line, 2, 2) ~= " " then changed = changed + 1 end
      end

      local stagedStr = staged > 0 and
          table.concat({ "%#StatusLineInfo#", "  ", staged, "%#StatuslineBackgroundLight#" }) or
          ""
      local changedStr = changed > 0 and
          table.concat({ "%#StatusLineWarn#", " 󰏫 ", changed, "%#StatuslineBackgroundLight#" }) or ""
      local untrackedStr = untracked > 0 and
          table.concat({ "%#StatusLineError#", "  ", untracked, "%#StatuslineBackgroundLight#" }) or ""
      local unpushedStr = unpushed > 0 and
          table.concat({ "%#StatusLineHint#", "  ", unpushed, "%#StatuslineBackgroundLight#" }) or ""

      local git_str = table.concat({ branch, stagedStr, changedStr, untrackedStr, unpushedStr })
      set_statusline(git_str, nil, nil)
    end),
  }):start()

  return nil
end

local function file_info()
  local filename = vim.fn.expand("%:t")
  local dirty = vim.fn.getbufvar("%", "&modified")
  local extension = vim.fn.fnamemodify(filename, ":e")
  local icon, iconhl = webdevicons.get_icon(filename, extension)
  local color = vim.fn.synIDattr(vim.fn.hlID(iconhl), "fg")
  return filename, dirty, icon, color
end

local function lsp_info()
  local errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
  local warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
  local hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
  local info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })

  local tmux_bg_light = get_tmux_color(COLOR_PRIMARY, COLOR_FG)
  local tmux_err = get_tmux_color("#" .. ("%06x"):format(COLOR_ERR), COLOR_FG)
  local tmux_warn = get_tmux_color("#" .. ("%06x"):format(COLOR_WARN), COLOR_FG)
  local tmux_hint = get_tmux_color("#" .. ("%06x"):format(COLOR_HINT), COLOR_FG)
  local tmux_info = get_tmux_color("#" .. ("%06x"):format(COLOR_INFO), COLOR_FG)

  local errorsStr = errors > 0 and table.concat({ tmux_err, "  ", errors, tmux_bg_light }) or ""
  local warningsStr = warnings > 0 and table.concat({ tmux_warn, "  ", warnings, tmux_bg_light }) or ""
  local hintsStr = hints > 0 and table.concat({ tmux_hint, "  ", hints, tmux_bg_light }) or ""
  local infoStr = info > 0 and table.concat({ tmux_info, "  ", info, tmux_bg_light }) or ""

  return errorsStr, warningsStr, hintsStr, infoStr
end

local function get_left()
  local git_str = git_info()
  if git_str == nil then
    return nil
  end
  return table.concat({ git_str, POWERLINE_RIGHT })
end

local function get_center()
  local filename, dirty, icon, color = file_info()
  local errors, warnings, hints, info = lsp_info()

  return table.concat({
    TMUX_POWERLINE_LEFT,
    " ", get_tmux_color(color, COLOR_FG), icon or "", get_tmux_color(COLOR_PRIMARY, COLOR_FG), " ", filename,
    dirty == 1 and
    "*" or " ",
    errors, warnings, hints, info, " ",
    TMUX_POWERLINE_RIGHT
  })
end

local function get_right()
  local percent = vim.fn.line(".") / vim.fn.line("$") * 100
  return table.concat({ POWERLINE_LEFT, math.floor(percent + 0.5), " 󱉸 " })
end

local function refresh_statusline()
  set_statusline(get_left(), get_center(), get_right())
end

local status_group = vim.api.nvim_create_augroup('statusline', { clear = true })
vim.api.nvim_create_autocmd(
  { 'WinEnter', 'BufEnter', 'BufWritePost', 'SessionLoadPost', 'Filetype', 'FileChangedShellPost' }, {
    group = status_group,
    callback = refresh_statusline,
  })
vim.api.nvim_create_autocmd({ 'TextChangedI', 'TextChanged' }, {
  group = status_group,
  callback = utils.debounce(700, refresh_statusline)
})
vim.api.nvim_create_autocmd({ 'CursorMoved' }, {
  group = status_group,
  callback = function() set_statusline(nil, get_center(), get_right()) end
})

function Statusline_refresh_wrap(callback)
  return function(args)
    callback(args)
    refresh_statusline()
  end
end
