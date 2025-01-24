local M            = {}
local api          = vim.api
local utils        = require 'config.utils'
local is_accepting = false

local function highlight(buf, ns, from, to)
  for i = 1, to do
    api.nvim_buf_set_extmark(buf, ns, from + i - 1, 0, {
      line_hl_group = 'Conflict',
      hl_mode = 'blend',
      hl_eol = true
    })
  end
end

function M.apply_highlights(left_buf, right_buf, conflicts)
  for conflict_idx, conflict in ipairs(conflicts) do
    local ours = conflict.ours.len
    local theirs = conflict.theirs.len
    local ns = api.nvim_create_namespace('conflict_mark:' .. conflict_idx)
    local l_buf_padding = math.max(theirs - ours, 0)
    local r_buf_padding = math.max(ours - theirs, 0)

    highlight(left_buf, ns, conflict.from, ours + l_buf_padding)
    highlight(right_buf, ns, conflict.from, theirs + r_buf_padding)
  end
end

function M.get_file_content(lines, conflicts)
  local ours = {}
  local theirs = {}
  local conflict_idx = 1
  local line_idx = 1

  while line_idx <= #lines do
    local conflict = conflicts[conflict_idx]
    if conflict and conflict.original_from == line_idx then
      line_idx = line_idx + 1
      for _ = 1, conflict.ours.len do
        table.insert(ours, lines[line_idx])
        line_idx = line_idx + 1
      end
      -- Space padding to make sure both sides have the same length.
      if conflict.ours.len < conflict.theirs.len then
        for _ = 1, conflict.theirs.len - conflict.ours.len do
          table.insert(ours, "")
        end
      end
      line_idx = line_idx + 1
      for _ = 1, conflict.theirs.len do
        table.insert(theirs, lines[line_idx])
        line_idx = line_idx + 1
      end
      -- Space padding to make sure both sides have the same length.
      if conflict.theirs.len < conflict.ours.len then
        for _ = 1, conflict.ours.len - conflict.theirs.len do
          table.insert(theirs, "")
        end
      end
      conflict_idx = conflict_idx + 1
    else
      -- Regular lines, add to both.
      table.insert(ours, lines[line_idx])
      table.insert(theirs, lines[line_idx])
    end
    line_idx = line_idx + 1
  end

  return { ours = ours, theirs = theirs }
end

function M.file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

function M.parse(filepath)
  if not M.file_exists(filepath) then error("File does not exist.") end

  local conflicts = {}
  local conflict = {}
  local line_number = 0
  local total_removed_lines = 0

  for line in io.lines(filepath) do
    line_number = line_number + 1
    if line:match("<<<<<<< HEAD") then
      conflict = { from = line_number - total_removed_lines, original_from = line_number }
    elseif line:match("=======") then
      conflict.ours = { len = line_number - conflict.from - 1 - total_removed_lines }
    elseif line:match(">>>>>>>") then
      conflict.theirs = { len = line_number - conflict.from - conflict.ours.len - 2 - total_removed_lines }
      total_removed_lines = total_removed_lines + 3 + math.min(conflict.ours.len, conflict.theirs.len)
      conflict.to = line_number - total_removed_lines -- Is this needed?
      conflict.original_to = line_number
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

local function jump_to_next_conflict(conflicts)
  local curr_line = api.nvim_win_get_cursor(0)[1]

  for _, conflict in ipairs(conflicts) do
    if curr_line < conflict.from then
      api.nvim_win_set_cursor(0, { conflict.from, 0 })
      return
    end
  end

  -- If we are at the end of the file with no more conflicts, jump to the first conflict.
  api.nvim_win_set_cursor(0, { conflicts[1].from, 0 })
end

local function jump_to_prev_conflict(conflicts)
  local curr_line = api.nvim_win_get_cursor(0)[1]

  for i = #conflicts, 1, -1 do
    local conflict = conflicts[i]
    if curr_line > conflict.from then
      api.nvim_win_set_cursor(0, { conflict.from, 0 })
      return
    end
  end

  -- If we are at the start of the file with no more conflicts, jump to the last conflict.
  api.nvim_win_set_cursor(0, { conflicts[#conflicts].from, 0 })
end

local function on_accept(conflicts, original_buf_nr, other_buf_nr)
  local curr_line = api.nvim_win_get_cursor(0)[1]
  local new_conflicts = {}

  for _, conflict in ipairs(conflicts) do
    if curr_line >= conflict.from and curr_line <= conflict.to then
      local curr_buf = api.nvim_get_current_buf()
      local lines = api.nvim_buf_get_lines(curr_buf, conflict.from - 1, conflict.to, false)
      is_accepting = true
      api.nvim_buf_set_lines(original_buf_nr, conflict.original_from - 1, conflict.original_to, false, lines)
      api.nvim_buf_set_lines(other_buf_nr, conflict.from - 1, conflict.to, false, lines)
      is_accepting = false
    else
      table.insert(new_conflicts, conflict)
    end
  end

  return new_conflicts
end

local CONFLICT_MARKER_COUNT = 3

local function get_offset_for_original_buf(from, to, conflicts, in_conflict, conflict_side)
  local offset = 0
  for _, conflict in ipairs(conflicts) do
    if to < conflict.from then break end

    if from > conflict.to then -- Outside the conflict.
      if conflict_side == 'ours' then
        offset = offset + conflict.theirs.len
      else
        offset = offset + conflict.ours.len
      end
      offset = offset + CONFLICT_MARKER_COUNT
    else -- Inside the conflict.
      if conflict_side == 'ours' then
        local offset_within_conflict = 0
        if from <= conflict.from then
          offset_within_conflict = conflict.ours.len - (to - from)
        end
        offset = offset + CONFLICT_MARKER_COUNT - 2 + offset_within_conflict
      else
        local offset_within_conflict = 0
        if from <= conflict.from then
          offset_within_conflict = conflict.theirs.len - (to - from)
        end
        offset = offset + conflict.ours.len + CONFLICT_MARKER_COUNT - 1 + offset_within_conflict
      end
    end
  end
  return offset
end

local function is_change_in_conflict(from, to, conflicts)
  for _, conflict in ipairs(conflicts) do
    if conflict.from >= from + 1 and conflict.to < to + 1 then return true end
  end
  return false
end

local function on_conflict()
  local bufnr = api.nvim_get_current_buf()
  local filetype = vim.bo.filetype
  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local buf1 = api.nvim_create_buf(false, true)
  local buf2 = api.nvim_create_buf(false, true)
  local conflicts = M.parse(api.nvim_buf_get_name(bufnr))
  local file_content = M.get_file_content(lines, conflicts)

  api.nvim_buf_set_lines(buf1, 0, -1, false, file_content.ours)
  api.nvim_buf_set_lines(buf2, 0, -1, false, file_content.theirs)
  api.nvim_buf_set_option(buf1, 'filetype', filetype)
  api.nvim_buf_set_option(buf2, 'filetype', filetype)

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

  local win1 = api.nvim_open_win(buf1, true, win_config1)
  local win2 = api.nvim_open_win(buf2, true, win_config2)

  -- Sync scroll
  api.nvim_win_set_option(win1, 'scrollbind', true)
  api.nvim_win_set_option(win2, 'scrollbind', true)
  api.nvim_win_set_option(win1, 'cursorbind', true)
  api.nvim_win_set_option(win2, 'cursorbind', true)

  M.apply_highlights(buf1, buf2, conflicts)

  api.nvim_create_autocmd({ 'BufWinLeave' }, {
    group = vim.api.nvim_create_augroup('buf_closed1', { clear = true }),
    buffer = buf1,
    callback = function() api.nvim_win_close(win2, true) end,
  })
  api.nvim_create_autocmd({ 'BufWinLeave' }, {
    group = vim.api.nvim_create_augroup('buf_closed2', { clear = true }),
    buffer = buf2,
    callback = function() api.nvim_win_close(win1, true) end,
  })

  api.nvim_buf_set_keymap(buf1, 'n', '[c', '', { callback = function() jump_to_next_conflict(conflicts) end })
  api.nvim_buf_set_keymap(buf2, 'n', '[c', '', { callback = function() jump_to_next_conflict(conflicts) end })
  api.nvim_buf_set_keymap(buf1, 'n', ']c', '', { callback = function() jump_to_prev_conflict(conflicts) end })
  api.nvim_buf_set_keymap(buf2, 'n', ']c', '', { callback = function() jump_to_prev_conflict(conflicts) end })
  api.nvim_buf_set_keymap(buf1, 'n', '<leader>a', '',
    {
      callback = function()
        local new_conflicts = on_accept(conflicts, bufnr, buf2)
        if #new_conflicts ~= #conflicts then
          conflicts = new_conflicts
          M.apply_highlights(buf1, buf2, conflicts)
        end
      end
    })
  api.nvim_buf_set_keymap(buf2, 'n', '<leader>a', '',
    {
      callback = function()
        local new_conflicts = on_accept(conflicts, bufnr, buf1)
        if #new_conflicts ~= #conflicts then
          conflicts = new_conflicts
          M.apply_highlights(buf1, buf2, conflicts)
        end
      end
    })
  -- When change outside of conflict - update all buffers.
  -- When change inside of conflict - update changed buffer and original.
  -- Undo/Redo - hijack from tmp buffer and proxy to original. Listen for changes, if conflict is brought back, parse it and update both buffers.

  api.nvim_buf_set_option(bufnr, 'bufhidden', 'hide')
  api.nvim_buf_attach(buf2, false, {
    on_lines = function(_, _, _, first_line, last_line, new_end)
      if is_accepting then return end

      local lines_added = new_end - first_line
      local lines_removed = last_line - first_line
      local in_conflict = is_change_in_conflict(first_line, last_line, conflicts)
      local original_file_offset = get_offset_for_original_buf(first_line, last_line, conflicts, in_conflict, 'theirs')

      vim.schedule(function()
        local added_lines = api.nvim_buf_get_lines(buf2, first_line, first_line + 1, false)

        if not in_conflict then
          if lines_added < lines_removed then
            api.nvim_buf_set_lines(buf1, first_line, first_line + 1, false, {})
          else
            api.nvim_buf_set_lines(buf1, first_line, first_line + 1, false, added_lines)
          end
        end

        if lines_added > lines_removed then
          local line = first_line + original_file_offset
          api.nvim_buf_set_lines(bufnr, line, line + lines_added, false, added_lines)
        elseif lines_added < lines_removed then
          api.nvim_buf_set_lines(bufnr, first_line + original_file_offset, last_line + original_file_offset, false, {})
        elseif lines_added == lines_removed then
          local line = first_line + original_file_offset
          api.nvim_buf_set_lines(bufnr, line, line + 1, false, added_lines)
        end

        -- TODO: Once the changes are applied, reparse conflicts and update the highlights.
      end)
    end
  })
end

api.nvim_create_autocmd({ 'BufReadPost' }, {
  -- TODO: Read up on augroups and how to properly use them.
  group = vim.api.nvim_create_augroup('conflict_resolve', { clear = true }),
  callback = utils.async(function()
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
})

return M
