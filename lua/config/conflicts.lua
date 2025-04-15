local M             = {}
local api           = vim.api
local utils         = require 'config.utils'
local is_locked     = false
local NO_FOCUS_FLAG = "conflicts_no_focus"

local _conflicts    = {}
local function join_tables(t1, t2)
  local t = {}
  for _, v in ipairs(t1) do table.insert(t, v) end
  for _, v in ipairs(t2) do table.insert(t, v) end
  return t
end

local function highlight(buf, ns, from, to)
  for i = 1, to do
    api.nvim_buf_set_extmark(buf, ns, from + i - 2, 0, {
      line_hl_group = 'Conflict',
      hl_mode = 'blend',
      hl_eol = true
    })
  end
end

function M.apply_highlights(left_buf, right_buf, conflicts)
  -- Remove previous highlights
  api.nvim_buf_clear_namespace(left_buf, -1, 0, -1)
  api.nvim_buf_clear_namespace(right_buf, -1, 0, -1)

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

local function refresh_buffers_content(original_buf, buf1, buf2)
  _conflicts = M.parse(api.nvim_buf_get_name(original_buf))
  local lines = api.nvim_buf_get_lines(original_buf, 0, -1, false)
  local file_content = M.get_file_content(lines, _conflicts)

  api.nvim_buf_set_lines(buf1, 0, -1, false, file_content.ours)
  api.nvim_buf_set_lines(buf2, 0, -1, false, file_content.theirs)

  M.apply_highlights(buf1, buf2, _conflicts)
end

local function undo(original_buf, buf1, buf2)
  api.nvim_buf_call(original_buf, function()
    is_locked = true
    api.nvim_cmd({ cmd = "undo", args = {} }, {})
    api.nvim_cmd({ cmd = "write", args = {}, mods = { silent = true } }, {})
    -- PERF: Relatively expensive on every undo but good enough for now.
    refresh_buffers_content(original_buf, buf1, buf2)
    is_locked = false
  end)
end

local function jump_to_next_conflict()
  if #_conflicts == 0 then return end
  local curr_line = api.nvim_win_get_cursor(0)[1]

  for _, conflict in ipairs(_conflicts) do
    if curr_line < conflict.from then
      api.nvim_win_set_cursor(0, { conflict.from, 0 })
      return
    end
  end

  -- If we are at the end of the file with no more conflicts, jump to the first conflict.
  api.nvim_win_set_cursor(0, { _conflicts[1].from, 0 })
end

local function jump_to_prev_conflict()
  if #_conflicts == 0 then return end
  local curr_line = api.nvim_win_get_cursor(0)[1]

  for i = #_conflicts, 1, -1 do
    local conflict = _conflicts[i]
    if curr_line > conflict.from then
      api.nvim_win_set_cursor(0, { conflict.from, 0 })
      return
    end
  end

  -- If we are at the start of the file with no more conflicts, jump to the last conflict.
  api.nvim_win_set_cursor(0, { _conflicts[#_conflicts].from, 0 })
end

local function on_accept_both(original_buf_nr, ours_buf, theirs_buf)
  local curr_line = api.nvim_win_get_cursor(0)[1]

  for _, conflict in ipairs(_conflicts) do
    if curr_line >= conflict.from and curr_line <= conflict.to then
      local start = conflict.from - 1
      local ours_buf_lines = api.nvim_buf_get_lines(ours_buf, start, start + conflict.ours.len, false)
      local theirs_buf_lines = api.nvim_buf_get_lines(theirs_buf, start, start + conflict.theirs.len, false)
      local all_lines = join_tables(ours_buf_lines, theirs_buf_lines)

      is_locked = true
      api.nvim_buf_set_lines(original_buf_nr, conflict.original_from - 1, conflict.original_to, false, all_lines)
      api.nvim_buf_call(original_buf_nr, function()
        api.nvim_cmd({ cmd = "write", args = {}, mods = { silent = true } }, {})
        -- PERF: Relatively expensive on every accept but good enough for now.
        refresh_buffers_content(original_buf_nr, ours_buf, theirs_buf)
        is_locked = false
      end)
    end
  end
end

local function on_accept(original_buf_nr, ours_buf, theirs_buf, side)
  local curr_line = api.nvim_win_get_cursor(0)[1]

  for _, conflict in ipairs(_conflicts) do
    if curr_line >= conflict.from and curr_line <= conflict.to then
      local curr_buf = api.nvim_get_current_buf()
      local start = conflict.from - 1
      local len = conflict[side].len
      local lines = api.nvim_buf_get_lines(curr_buf, start, start + len, false)

      is_locked = true
      api.nvim_buf_set_lines(original_buf_nr, conflict.original_from - 1, conflict.original_to, false, lines)
      api.nvim_buf_call(original_buf_nr, function()
        api.nvim_cmd({ cmd = "write", args = {}, mods = { silent = true } }, {})
        -- PERF: Relatively expensive on every accept but good enough for now.
        refresh_buffers_content(original_buf_nr, ours_buf, theirs_buf)
        is_locked = false
      end)
    end
  end
end

local CONFLICT_MARKER_COUNT = 3

local function get_offset_for_original_buf(from, to, conflicts, conflict_side)
  local offset = 0
  for _, conflict in ipairs(conflicts) do
    if to < conflict.from then break end

    if from >= conflict.to then -- Outside the conflict.
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

local function on_lines_change(buf, other_buf, original_buf, side)
  return function(_, _, _, first_line, last_line, new_end)
    if is_locked then return end

    vim.schedule(function()
      local lines_added = new_end - first_line
      local lines_removed = last_line - first_line
      local in_conflict = is_change_in_conflict(first_line, last_line, _conflicts)
      local original_file_offset = get_offset_for_original_buf(first_line, last_line, _conflicts, side)

      local added_lines = api.nvim_buf_get_lines(buf, first_line, new_end, false)
      is_locked = true

      if not in_conflict then
        if lines_added < lines_removed then
          api.nvim_buf_set_lines(other_buf, first_line, last_line, false, {})
        else
          api.nvim_buf_set_lines(other_buf, first_line, last_line, false, added_lines)
        end
      end

      if lines_added > lines_removed then
        local line = first_line + original_file_offset
        api.nvim_buf_set_lines(original_buf, line, line + lines_added, false, added_lines)
      elseif lines_added < lines_removed then
        api.nvim_buf_set_lines(original_buf, first_line + original_file_offset, last_line + original_file_offset, false,
          {})
      elseif lines_added == lines_removed then
        local line = first_line + original_file_offset
        api.nvim_buf_set_lines(original_buf, line, line + 1, false, added_lines)
      end

      api.nvim_buf_call(original_buf, function()
        api.nvim_cmd({ cmd = "write", args = {}, mods = { silent = true } }, {})
        is_locked = false
      end)
    end)
  end
end


local function redo(original_buf, buf1, buf2)
  api.nvim_buf_call(original_buf, function()
    is_locked = true
    api.nvim_cmd({ cmd = "redo", args = {} }, {})
    api.nvim_cmd({ cmd = "write", args = {}, mods = { silent = true } }, {})
    -- PERF: Relatively expensive on every redo but good enough for now.
    refresh_buffers_content(original_buf, buf1, buf2)
    is_locked = false
  end)
end

local function main()
  _conflicts = M.parse(api.nvim_buf_get_name(0))
  if #_conflicts == 0 then return end

  local buf = api.nvim_get_current_buf()
  local filetype = vim.bo.filetype
  local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
  local buf1 = api.nvim_create_buf(false, true)
  local buf2 = api.nvim_create_buf(false, true)
  local winnr = api.nvim_get_current_win()
  local file_content = M.get_file_content(lines, _conflicts)

  api.nvim_buf_set_lines(buf1, 0, -1, false, file_content.ours)
  api.nvim_buf_set_lines(buf2, 0, -1, false, file_content.theirs)
  api.nvim_buf_set_option(buf1, 'filetype', filetype)
  api.nvim_buf_set_option(buf2, 'filetype', filetype)
  api.nvim_win_set_var(winnr, NO_FOCUS_FLAG, true)

  local win_config1 = { relative = 'editor', width = vim.o.columns / 2, height = vim.o.lines, col = 0, row = 0 }
  local win_config2 = vim.tbl_extend("force", win_config1, { col = vim.o.columns / 2 })
  local win1 = api.nvim_open_win(buf1, true, win_config1)
  local win2 = api.nvim_open_win(buf2, true, win_config2)

  -- Sync scroll
  api.nvim_win_set_option(win1, 'scrollbind', true)
  api.nvim_win_set_option(win2, 'scrollbind', true)
  api.nvim_win_set_option(win1, 'cursorbind', true)
  api.nvim_win_set_option(win2, 'cursorbind', true)

  M.apply_highlights(buf1, buf2, _conflicts)

  local buf_enter_autocmd_id = api.nvim_create_autocmd("BufEnter", {
    callback = function()
      local ok, skip = pcall(api.nvim_win_get_var, 0, NO_FOCUS_FLAG)
      -- Skip this window and move to the next.
      if ok and skip then vim.cmd("wincmd w") end
    end,
  })
  api.nvim_create_autocmd({ 'BufWinLeave' }, {
    group = vim.api.nvim_create_augroup('buf_closed1', { clear = true }),
    buffer = buf1,
    callback = function()
      api.nvim_win_close(win2, true)
      api.nvim_win_set_var(winnr, NO_FOCUS_FLAG, false)
      api.nvim_del_autocmd(buf_enter_autocmd_id)
    end,
  })
  api.nvim_create_autocmd({ 'BufWinLeave' }, {
    group = vim.api.nvim_create_augroup('buf_closed2', { clear = true }),
    buffer = buf2,
    callback = function()
      api.nvim_win_close(win1, true)
      api.nvim_win_set_var(winnr, NO_FOCUS_FLAG, false)
      api.nvim_del_autocmd(buf_enter_autocmd_id)
    end,
  })

  api.nvim_buf_set_keymap(buf1, 'n', 'u', '', { callback = function() undo(buf, buf1, buf2) end })
  api.nvim_buf_set_keymap(buf2, 'n', 'u', '', { callback = function() undo(buf, buf1, buf2) end })
  api.nvim_buf_set_keymap(buf1, 'n', '<C-r>', '', { callback = function() redo(buf, buf1, buf2) end })
  api.nvim_buf_set_keymap(buf2, 'n', '<C-r>', '', { callback = function() redo(buf, buf1, buf2) end })
  api.nvim_buf_set_keymap(buf1, 'n', '[c', '', { callback = jump_to_next_conflict })
  api.nvim_buf_set_keymap(buf2, 'n', '[c', '', { callback = jump_to_next_conflict })
  api.nvim_buf_set_keymap(buf1, 'n', ']c', '', { callback = jump_to_prev_conflict })
  api.nvim_buf_set_keymap(buf2, 'n', ']c', '', { callback = jump_to_prev_conflict })
  api.nvim_buf_set_keymap(buf1, 'n', '<leader>b', '', { callback = function() on_accept_both(buf, buf1, buf2) end })
  api.nvim_buf_set_keymap(buf2, 'n', '<leader>b', '', { callback = function() on_accept_both(buf, buf1, buf2) end })
  api.nvim_buf_set_keymap(buf1, 'n', '<leader>a', '', { callback = function() on_accept(buf, buf1, buf2, "ours") end })
  api.nvim_buf_set_keymap(buf2, 'n', '<leader>a', '', { callback = function() on_accept(buf, buf1, buf2, "theirs") end })

  api.nvim_buf_set_option(buf, 'bufhidden', 'hide')
  api.nvim_buf_attach(buf1, false, { on_lines = on_lines_change(buf1, buf2, buf, 'ours') })
  api.nvim_buf_attach(buf2, false, { on_lines = on_lines_change(buf2, buf1, buf, 'theirs') })
end

api.nvim_create_autocmd({ 'BufReadPost' }, {
  -- TODO: Read up on augroups and how to properly use them.
  group = vim.api.nvim_create_augroup('conflict_resolve', { clear = true }),
  callback = utils.async(function()
    local nvim_env = os.getenv('NVIM_ENV')
    if nvim_env == 'test' then return main() end

    local git_status = utils.spawn("git", { 'diff', '--name-only', '--diff-filter=U' })
    if git_status == "" then return end

    utils.vim_loop(function()
      local bufname = api.nvim_buf_get_name(0)
      for file in git_status:gmatch("[^\r\n]+") do
        if bufname:match(file .. '$') then return main() end
      end
    end)
  end)
})

return M
