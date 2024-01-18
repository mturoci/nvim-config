local powerline_right = " %#Background#"
local powerline_left = "%#Background#%#BackgroundLight# "
local bg = "#262626"
local fg = "#444444"
local primary = "#a7c080"

local function git_info()
  local staged = 0
  local changed = 0
  local branch = 'main'
  -- TODO: Make this more performant.
  -- local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD"):gsub("\n", "")
  -- local staged = vim.fn.system("git diff --cached --numstat | wc -l"):gsub("\n", ""):gsub(" ", "")
  -- local changed = vim.fn.system("git diff --numstat | wc -l"):gsub("\n", ""):gsub(" ", "")
  -- local unpushed = vim.fn.system("git log @{u}.."):gsub("\n", "")
  -- local unpulled = vim.fn.system("git log ..@{u}"):gsub("\n", "")
  local unpushed = -1
  local unpulled = -1
  return branch, staged, changed, unpushed, unpulled
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
  return errors, warnings, hints, info
end

local function cursor_info()
  local percent = vim.fn.line(".") / vim.fn.line("$") * 100
  return math.floor(percent + 0.5)
end

local function get_left()
  local branch, staged, changed, unpushed, unpulled = git_info()
  return table.concat({
    "  ", branch, "  ", staged, "  ", changed, "  ", unpushed, "  ", unpulled, powerline_right
  })
end

local function get_center()
  local filename, dirty, icon, color = file_info()
  local errors, warnings, hints, info = lsp_info()

  if icon then
    vim.cmd(table.concat({ "highlight BackgroundIcon guibg=", fg, " guifg=", color }))
  end

  return table.concat({
    powerline_left, "%#BackgroundIcon#", icon or "", "%#BackgroundLight# ", filename, dirty == 1 and "*" or " ", "  ",
    errors,
    "  ", warnings, "  ", hints,
    "  ", info,
    powerline_right
  })
end

local function get_right()
  local percent = cursor_info()
  -- TODO: Calculate the precise length of space buffer to get the center section into the screen center, not just the middle of the statusline.
  return table.concat({
    powerline_left, percent, " 󱉸 "
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
    "%#BackgroundLight#", left, "%#Background#", "%=",
    "%#BackgroundLight#", center, "%#Background#", "%=",
    "                  %#BackgroundLight#", right
  })
  -- prevStatusline = statusline
  -- vim.o.statusline = statusline
  -- return prevStatusline
  return statusline
end

-- _G.statusline = debounce(get_statusline, 1000)
_G.statusline = get_statusline

vim.cmd(table.concat({ "highlight Background guibg=", bg, " guifg=", fg }))
vim.cmd(table.concat({ "highlight BackgroundLight guibg=", fg, " guifg=", primary }))
vim.o.statusline = "%!v:lua.statusline()"
