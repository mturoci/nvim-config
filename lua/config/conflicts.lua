local M     = {}
local api   = vim.api
local utils = require 'config.utils'

function M.file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

-- TODO: Add origin from and to to every conflict to mark original conflict location for accepting.
function M.parse(filepath)
  if not M.file_exists(filepath) then error("File does not exist.") end

  local conflicts = {}
  local conflict = {}
  local line_number = 0

  for line in io.lines(filepath) do
    line_number = line_number + 1
    if line:match("<<<<<<< HEAD") then
      conflict = { from = line_number }
    elseif line:match("=======") then
      conflict.ours = { len = line_number - conflict.from - 1 }
    elseif line:match(">>>>>>>") then
      conflict.theirs = { len = line_number - conflict.from - conflict.ours.len - 2 }
      conflict.to = line_number
      table.insert(conflicts, conflict)
      conflict = nil
    end
  end

  return conflicts
end

function M.update_lines(conflicts, from, to, side, is_delete)
  local length = to - from + 1

  if is_delete then length = -length end

  for _, conflict in ipairs(conflicts) do
    -- Inside of a conflict.
    if from >= conflict.from and to <= conflict.to and to <= (conflict.from + conflict[side].len) then
      conflict.to = conflict.to + length
      conflict[side].len = conflict[side].len + length
      -- Before a conflict.
    elseif from < conflict.from and to < conflict.from then
      conflict.from = conflict.from + length
      conflict.to = conflict.to + length
      -- Start border of a conflict.
    elseif is_delete and from < conflict.from and to <= conflict.from + conflict[side].len then
      length = math.abs(length) - (conflict.from - from)
      conflict.from = from
      conflict.to = conflict.to - length
      conflict[side].len = conflict[side].len - length
    end
  end
end

local function on_conflict()
  local bufnr = api.nvim_get_current_buf()
  local filetype = vim.bo.filetype
  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- Hide the current buffer
  api.nvim_buf_set_option(bufnr, 'bufhidden', 'hide')

  -- Create new buffers
  local buf1 = api.nvim_create_buf(false, true)
  local buf2 = api.nvim_create_buf(false, true)

  -- Set the content of the buffers
  api.nvim_buf_set_lines(buf1, 0, -1, false, { "hello1", "world" })
  api.nvim_buf_set_lines(buf2, 0, -1, false, { "hello2", "world" })
  -- Set the filetype of the buffers
  api.nvim_buf_set_option(buf1, 'filetype', filetype)
  api.nvim_buf_set_option(buf2, 'filetype', filetype)

  -- Define the window configuration
  local win_config1 = {
    relative = 'editor',
    width = vim.o.columns / 2,
    height = vim.o.lines,
    col = 0,
    row = 0
  }

  local win_config2 = {
    relative = 'editor',
    width = vim.o.columns / 2,
    height = vim.o.lines,
    col = vim.o.columns / 2,
    row = 0
  }

  -- Open new windows with the buffers
  local win1 = api.nvim_open_win(buf1, true, win_config1)
  local win2 = api.nvim_open_win(buf2, true, win_config2)
  local ns = api.nvim_create_namespace('diff')

  api.nvim_buf_set_extmark(buf1, ns, 0, 0, {
    line_hl_group = 'Conflict',
    hl_mode = 'blend',
    hl_eol = true
  })
  api.nvim_buf_set_extmark(buf2, ns, 1, 0, {
    line_hl_group = 'Conflict',
    hl_mode = 'blend',
    hl_eol = true
  })

  api.nvim_create_autocmd({ 'BufWinLeave' }, {
    group = vim.api.nvim_create_augroup('buf_closed2', { clear = true }),
    buffer = buf2,
    callback = function()
      api.nvim_win_close(win1, true)
    end,
  })
  api.nvim_create_autocmd({ 'BufWinLeave' }, {
    group = vim.api.nvim_create_augroup('buf_closed1', { clear = true }),
    buffer = buf1,
    callback = function()
      api.nvim_win_close(win2, true)
    end,
  })

  api.nvim_buf_attach(bufnr, false, {
    on_lines = function(_, _, _, first_line, last_line, new_end)
      local lines_added = new_end - first_line
      local lines_removed = last_line - first_line

      if lines_added > lines_removed then
        print("Lines were added from line " .. first_line + 1 .. " to line " .. new_end)
      elseif lines_added < lines_removed then
        print("Lines were removed from line " .. first_line + 1 .. " to line " .. last_line)
      elseif lines_added == lines_removed then
        print("A single line was changed at line " .. first_line + 1)
      end
    end
  })
end

local on_buf_read = utils.async(function()
  local nvm_env = os.getenv('NVIM_ENV')
  if nvm_env == 'test' then return on_conflict() end

  local git_status = utils.spawn("git", { 'diff', '--name-only', '--diff-filter=U' })
  if git_status == "" then return end

  utils.vim_loop(function()
    local bufname = api.nvim_buf_get_name(0)
    for file in git_status:gmatch("[^\r\n]+") do
      if bufname:match(file .. '$') then return on_conflict() end
    end
  end)
end)

api.nvim_create_autocmd({ 'BufReadPost' }, {
  -- TODO: Read up on augroups and how to properly use them.
  group = vim.api.nvim_create_augroup('conflict_resolve', { clear = true }),
  callback = on_buf_read,
})

return M
