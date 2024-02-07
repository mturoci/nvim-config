local M = {}
local uv = vim.loop

M.setTimeout = function(timeout, callback)
  local timer = vim.loop.new_timer()
  timer:start(timeout, 0, vim.schedule_wrap(callback))
  return timer
end

M.clearTimeout = function(timer)
  timer:stop()
  timer:close()
end

M.debounce = function(timeout, callback)
  local timer = nil
  return function()
    if timer ~= nil then M.clearTimeout(timer) end
    timer = M.setTimeout(timeout, callback)
  end
end

local function cleanup(handle)
  if handle and not uv.is_closing(handle) then
    handle:close()
  end
end

M.spawn = function(cmd, args, on_data, on_exit)
  local stdout = uv.new_pipe()
  local fd = nil

  fd = uv.spawn(cmd, { args = args, stdio = { nil, stdout, nil } }, vim.schedule_wrap(function()
    if on_exit then on_exit() end
    cleanup(fd)
    cleanup(stdout)
  end))
  uv.read_start(stdout, vim.schedule_wrap(function(err, data)
    if on_data then on_data(err, data) end
  end))
end

return M
