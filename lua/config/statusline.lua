local POWERLINE_RIGHT = " %#StatuslineBackground#"
local POWERLINE_LEFT = "%#StatuslineBackground#%#StatuslineBackgroundLight# "
local COLOR_BG = "#262626"
local COLOR_FG = "#444444"
local COLOR_PRIMARY = "#a7c080"
local COLOR_ERR = vim.api.nvim_get_hl(0, { name = "DiagnosticError" }).fg
local COLOR_WARN = vim.api.nvim_get_hl(0, { name = "DiagnosticWarn" }).fg
local COLOR_HINT = vim.api.nvim_get_hl(0, { name = "DiagnosticHint" }).fg
local COLOR_INFO = vim.api.nvim_get_hl(0, { name = "DiagnosticInfo" }).fg

local highlights = {
  { name = "Background",      guibg = COLOR_BG, guifg = COLOR_FG },
  { name = "BackgroundLight", guibg = COLOR_FG, guifg = COLOR_PRIMARY },
  { name = "Error",           guibg = COLOR_FG, guifg = "#" .. ("%06x"):format(COLOR_ERR) },
  { name = "Warn",            guibg = COLOR_FG, guifg = "#" .. ("%06x"):format(COLOR_WARN) },
  { name = "Hint",            guibg = COLOR_FG, guifg = "#" .. ("%06x"):format(COLOR_HINT) },
  { name = "Info",            guibg = COLOR_FG, guifg = "#" .. ("%06x"):format(COLOR_INFO) }
}

for _, highlight in ipairs(highlights) do
  vim.cmd(table.concat({ "highlight Statusline", highlight.name, " guibg=", highlight.guibg, " guifg=", highlight.guifg }))
end

-- vim.cmd(table.concat({ "highlight Background guibg=", COLOR_BG, " guifg=", COLOR_FG }))
-- vim.cmd(table.concat({ "highlight BackgroundLight guibg=", COLOR_FG, " guifg=", COLOR_PRIMARY }))
-- vim.cmd(table.concat({ "highlight StatusLineError guibg=", COLOR_FG, " guifg=#", ("%06x"):format(COLOR_ERR) }))
-- vim.cmd(table.concat({ "highlight StatusLineWarn guibg=", COLOR_FG, " guifg=#", ("%06x"):format(COLOR_WARN) }))
-- vim.cmd(table.concat({ "highlight StatusLineHint guibg=", COLOR_FG, " guifg=#", ("%06x"):format(COLOR_HINT) }))
-- vim.cmd(table.concat({ "highlight StatusLineInfo guibg=", COLOR_FG, " guifg=#", ("%06x"):format(COLOR_INFO) }))

local function git_info()
  local staged = 1
  local changed = 1
  local branch = 'main'
  -- TODO: Make this more performant.
  -- local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD"):gsub("\n", "")
  -- local staged = vim.fn.system("git diff --cached --numstat | wc -l"):gsub("\n", ""):gsub(" ", "")
  -- local changed = vim.fn.system("git diff --numstat | wc -l"):gsub("\n", ""):gsub(" ", "")
  -- local unpushed = vim.fn.system("git log @{u}.."):gsub("\n", "")
  -- local unpulled = vim.fn.system("git log ..@{u}"):gsub("\n", "")
  local unpushed = -1
  local unpulled = -1

  local stagedStr = staged > 0 and table.concat({ "%#StatusLineInfo#", "  ", staged, "%#StatuslineBackgroundLight#" }) or
      ""
  local changedStr = changed > 0 and
      table.concat({ "%#StatusLineWarn#", " 󰏫 ", changed, "%#StatuslineBackgroundLight#" }) or ""

  return branch, stagedStr, changedStr, unpushed, unpulled
end
local webdevicons = require 'nvim-web-devicons'

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
  local branch, staged, changed, unpushed, unpulled = git_info()
  return table.concat({
    "  ", branch, staged, changed, "  ", unpushed, "  ", unpulled, POWERLINE_RIGHT
  })
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
  return table.concat({
    POWERLINE_LEFT, percent, " 󱉸 "
  })
end

-- local function setTimeout(timeout, callback)
--   local timer = vim.uv.new_timer()
--   timer:start(timeout, 0, function()
--     timer:stop()
--     timer:close()
--     callback()
--   end)
--   return timer
-- end
--
-- local function clearTimeout(timer)
--   timer:stop()
--   timer:close()
-- end
--
-- local function debounce(callback, timeout)
--   local timer = nil
--   return function()
--     if timer ~= nil then
--       clearTimeout(timer)
--     end
--     timer = setTimeout(timeout, callback)
--   end
-- end

-- local prevStatusline = ''
local function get_statusline()
  local left = get_left()
  local center = get_center()
  local right = get_right()

  local statusline = table.concat({
    "%#StatuslineBackgroundLight#", left, "%#StatuslineBackground#", "%=",
    "%#StatuslineBackgroundLight#", center, "%#StatuslineBackground#", "%=",
    "                  %#StatuslineBackgroundLight#", right
  })
  -- prevStatusline = statusline
  -- vim.o.statusline = statusline
  -- return prevStatusline
  return statusline
end

-- _G.statusline = debounce(get_statusline, 1000)
_G.statusline = get_statusline

vim.o.statusline = "%!v:lua.statusline()"
