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

return M
