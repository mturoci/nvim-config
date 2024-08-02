local M = {}

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
      conflict.ours = { len = line_number - conflict.from  - 1}
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

return M
