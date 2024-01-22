local M = {}

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

return M
