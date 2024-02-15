local M = {}
local uv = vim.loop
local unpack = table.unpack or unpack

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

M.vim_loop = function(f)
  local co = coroutine.running()
  assert(co, "await must be called from a coroutine")
  assert(type(f) == "function", "expected a function")
  local ret = nil

  vim.schedule(function()
    ret = f()
    coroutine.resume(co)
  end)
  coroutine.yield()
  if ret == nil then return nil else return ret end
end

M.spawn = function(cmd, args)
  local co = coroutine.running()
  assert(co, "await must be called from a coroutine")

  local fd = nil
  local ret = ''
  local error = ''
  local stdout = uv.new_pipe()
  local stderr = uv.new_pipe()

  fd = uv.spawn(cmd, { args = args, stdio = { nil, stdout, stderr } }, function()
    cleanup(fd)
    cleanup(stdout)
    cleanup(stderr)
    coroutine.resume(co)
  end)
  uv.read_start(stdout, function(err, data)
    if err then error(err) end
    if data then ret = ret .. data end
  end)
  uv.read_start(stderr, function(err, data)
    if err then error(err) end
    if data then error = error .. data end
  end)

  coroutine.yield()
  return error, ret
end

function M.await(func, ...)
  assert(type(func) == "function", "expected a function")

  local co = coroutine.running()
  assert(co, "await must be called from a coroutine")

  local ret = nil
  local args = { ... }
  table.insert(args, function(...)
    ret = { ... }
    coroutine.resume(co)
  end)
  func(unpack(args))
  coroutine.yield()

  if ret == nil then return nil else return unpack(ret) end
end

function M.await_all(funcs)
  assert(type(funcs) == "table", "expected a table")

  local co = coroutine.running()
  assert(co, "await_all must be called from a coroutine")

  local ret = {}
  local count = 0
  for i, f in ipairs(funcs) do
    local func = f[1]
    assert(type(func) == "function", "expected a function as first argument")

    coroutine.resume(coroutine.create(function()
      ret[i] = func(unpack(f, 2))
      count = count + 1
      if count == #funcs then coroutine.resume(co) end
    end))
  end

  coroutine.yield()
  return ret
end

function M.async(func)
  assert(type(func) == "function", "expected a function")
  return function(...)
    local co = coroutine.create(func)
    assert(coroutine.resume(co, ...))
  end
end

function M.read_file(path)
  local open_err, fd = M.await(uv.fs_open, path, "r", 438)
  if open_err then error(open_err) end

  local stat_err, stat = M.await(uv.fs_fstat, fd)
  if stat_err then error(stat_err) end
  if stat == nil then error("file not found") end

  local read_err, data = M.await(uv.fs_read, fd, stat.size, 0)
  if read_err then error(read_err) end

  local close_err = M.await(uv.fs_close, fd)
  if close_err then error(close_err) end

  return data
end

return M
