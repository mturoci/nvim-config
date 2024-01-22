local POWERLINE_RIGHT = " %#StatuslineBackground#"
local POWERLINE_LEFT = "%#StatuslineBackground#%#StatuslineBackgroundLight# "
local COLOR_BG = "#262626"
local COLOR_FG = "#444444"
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

  -- TODO: Make a background task.
  local git_status = vim.fn.system("git status -s")
  for line in git_status:gmatch("[^\r\n]+") do
    if string.sub(line, 1, 2) == "??" then untracked = untracked + 100 end
    if string.sub(line, 1, 1) ~= " " then staged = staged + 1 end
    if string.sub(line, 2, 2) ~= " " then changed = changed + 1 end
  end

  local stagedStr = staged > 0 and table.concat({ "%#StatusLineInfo#", "  ", staged, "%#StatuslineBackgroundLight#" }) or
      ""
  local changedStr = changed > 0 and
      table.concat({ "%#StatusLineWarn#", " 󰏫 ", changed, "%#StatuslineBackgroundLight#" }) or ""
  local untrackedStr = untracked > 0 and
      table.concat({ "%#StatusLineError#", "  ", untracked, "%#StatuslineBackgroundLight#" }) or ""
  local unpushedStr = unpushed > 0 and
      table.concat({ "%#StatusLineHint#", "  ", unpushed, "%#StatuslineBackgroundLight#" }) or ""

  return table.concat({ branch, stagedStr, changedStr, untrackedStr, unpushedStr })
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

  local errorsStr = errors > 0 and table.concat({ "%#StatusLineError#", "  ", errors, "%#StatuslineBackgroundLight#" }) or
      ""
  local warningsStr = warnings > 0 and
      table.concat({ "%#StatusLineWarn#", "  ", warnings, "%#StatuslineBackgroundLight# " }) or
      ""
  local hintsStr = hints > 0 and table.concat({ "%#StatusLineHint#", "  ", hints, "%#StatuslineBackgroundLight# " }) or
      ""
  local infoStr = info > 0 and table.concat({ "%#StatusLineInfo#", "  ", info, "%#StatuslineBackgroundLight#" }) or ""

  return errorsStr, warningsStr, hintsStr, infoStr
end

local function cursor_info()
  local percent = vim.fn.line(".") / vim.fn.line("$") * 100
  return math.floor(percent + 0.5)
end

local function get_left()
  local git = git_info()
  return table.concat({ git, POWERLINE_RIGHT })
end

local function get_center()
  local filename, dirty, icon, color = file_info()
  local errors, warnings, hints, info = lsp_info()

  if icon then
    vim.cmd(table.concat({ "highlight StatuslineBackgroundIcon guibg=", COLOR_FG, " guifg=", color }))
  end

  return table.concat({
    POWERLINE_LEFT, "%#StatuslineBackgroundIcon#", icon or "", "%#StatuslineBackgroundLight# ", filename, dirty == 1 and
  "*" or " ",
    errors, warnings, hints, info,
    POWERLINE_RIGHT
  })
end

local function get_right()
  local percent = cursor_info()
  -- TODO: Calculate the precise length of space buffer to get the center section into the screen center, not just the middle of the statusline.
  return table.concat({ POWERLINE_LEFT, percent, " 󱉸 " })
end

local function refresh_statusline()
  local left = get_left()
  local center = get_center()
  local right = get_right()

  vim.o.statusline = table.concat({
    "%#StatuslineBackgroundLight#", left, "%#StatuslineBackground#", "%=",
    "%#StatuslineBackgroundLight#", center, "%#StatuslineBackground#", "%=",
    "                  %#StatuslineBackgroundLight#", right
  })
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


function Statusline_refresh_wrap(callback)
  return function(args)
    callback(args)
    refresh_statusline()
  end
end
