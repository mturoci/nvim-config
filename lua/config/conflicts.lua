local M = {}

function M.file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

function M.parse(filepath)
  if not M.file_exists(filepath) then
    error("File does not exist.")
  end

  local conflicts = {}
  local conflict = nil
  local line_number = 0

  for line in io.lines(filepath) do
    line_number = line_number + 1
    if line:match("<<<<<<< HEAD") then
      conflict = {from = line_number}
    elseif line:match("=======") then
      conflict.ours = {from = conflict.from, to = line_number - 1}
    elseif line:match(">>>>>>>") then
      conflict.theirs = {from = conflict.ours.to + 2, to = line_number}
      conflict.to = line_number
      table.insert(conflicts, conflict)
      conflict = nil
    end
  end

  return conflicts
end

function M.update_lines(conflicts, from, to, side, is_delete)
  local length = to - from + 1

  if is_delete then
    length = -length
  end

  for _, conflict in ipairs(conflicts) do
    if is_delete and from < conflict.from and to >= conflict.from then
      conflict.from = from
      conflict.to = conflict.to + length
      conflict[side].from = from
      conflict[side].to = conflict[side].to + length
    elseif is_delete and from > conflict.to then
      -- noop
    elseif is_delete and from >= conflict.from and to > conflict.to then
      conflict.to = to
      conflict[side].to = to
    elseif from < conflict.from then
      conflict.from = conflict.from + length
      conflict.to = conflict.to + length
      conflict[side].from = conflict[side].from + length
      conflict[side].to = conflict[side].to + length
    elseif from >= conflict.from and from <= conflict.to then
      conflict.to = conflict.to + length
      if conflict[side].to >= from then
        conflict[side].to = conflict[side].to + length
      end
    end
  end
end

return M
