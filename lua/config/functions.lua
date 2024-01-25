local previewers     = require('telescope.previewers')
local builtin        = require('telescope.builtin')
local M              = {}
local api            = vim.api
local popup          = require('plenary.popup')
local illuminate     = require('illuminate')

local delta_bcommits = previewers.new_termopen_previewer {
  get_command = function(entry)
    return { 'git', '-c', 'core.pager=delta', '-c', 'delta.side-by-side=false', 'diff', entry.value .. '^!', '--',
      entry.current_file }
  end
}

local delta          = previewers.new_termopen_previewer {
  get_command = function(entry)
    return { 'git', '-c', 'core.pager=delta', '-c', 'delta.side-by-side=false', 'diff', entry.path }
  end
}

local function submitCommitPopup(win_id)
  local bufnr = vim.api.nvim_win_get_buf(0)
  local commit_msg = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  ClosePopup(win_id)
  vim.cmd(':!git commit -am "' .. commit_msg[1] .. '"')
end

SubmitCommitPopup = Statusline_refresh_wrap(submitCommitPopup)

function SubmitRenamePopup(win_id)
  local bufnr = vim.api.nvim_win_get_buf(0)
  local val = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  ClosePopup(win_id)

  local params = vim.lsp.util.make_position_params()
  params.newName = val[1]
  vim.lsp.buf_request(0, "textDocument/rename", params)
end

function ClosePopup(win_id)
  vim.api.nvim_win_close(win_id, true)
  vim.api.nvim_input('<Esc>')
  illuminate.toggle()
end

function OpenPopup(title, val, submit)
  local borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }
  local ui          = vim.api.nvim_list_uis()[1]
  local height      = 1
  local width       = ui.width / 2

  local win_id      = popup.create({}, {
    title = title,
    line = math.floor(((vim.o.lines - height) / 2) - 1),
    col = math.floor((vim.o.columns - width) / 2),
    minwidth = width,
    minheight = height,
    borderchars = borderchars,
    -- Not implemented yet by plenary.
    callback = nil,
  })
  illuminate.toggle()

  local bufnr       = vim.api.nvim_win_get_buf(win_id)
  local keymap_opts = { silent = true, nowait = true, noremap = true }
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { val })
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<CR>', "<cmd>lua " .. submit .. "(" .. win_id .. ")<CR>", keymap_opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'i', '<CR>', "<cmd>lua " .. submit .. "(" .. win_id .. ")<CR>", keymap_opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'q', "<cmd>lua ClosePopup(" .. win_id .. ")<CR>", keymap_opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'i', 'q', "<cmd>lua ClosePopup(" .. win_id .. ")<CR>", keymap_opts)
end

M.my_git_status   = function(opts)
  opts = opts or {}
  opts.previewer = delta

  builtin.git_status(opts)
end

M.my_git_commits  = function(opts)
  opts = opts or {}
  opts.previewer = {
    delta,
    previewers.git_commit_message.new(opts),
    previewers.git_commit_diff_as_was.new(opts),
  }

  builtin.git_commits(opts)
end

M.my_git_bcommits = function(opts)
  opts = opts or {}
  opts.previewer = {
    delta_bcommits,
    previewers.git_commit_message.new(opts),
    previewers.git_commit_diff_as_was.new(opts),
  }

  builtin.git_bcommits(opts)
end

function Rename()
  local win = api.nvim_get_current_win()
  local buf = api.nvim_win_get_buf(win)
  local cursor = api.nvim_win_get_cursor(win)
  local line = api.nvim_buf_get_lines(buf, cursor[1] - 1, cursor[1], false)[1]
  local cursor_pos = cursor[2] + 1
  local current_char = line:sub(cursor_pos, cursor_pos)

  if not current_char:match('[%w_-]') then
    return
  end

  local prefix = ''
  local suffix = ''

  current_char = line:sub(cursor_pos, cursor_pos)
  while current_char:match('[%w_-]') do
    prefix = current_char .. prefix
    cursor_pos = cursor_pos - 1
    current_char = line:sub(cursor_pos, cursor_pos)
  end

  cursor_pos = cursor[2] + 1 + 1
  current_char = line:sub(cursor_pos, cursor_pos)
  while current_char:match('[%w_-]') do
    suffix = suffix .. current_char
    cursor_pos = cursor_pos + 1
    current_char = line:sub(cursor_pos, cursor_pos)
  end

  local var_name = prefix .. suffix
  OpenPopup('Refactor', var_name, 'SubmitRenamePopup')
end

return M
