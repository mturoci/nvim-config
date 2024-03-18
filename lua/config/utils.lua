local uv = vim.loop
local unpack = table.unpack or unpack

local function setTimeout(timeout, callback)
  local timer = vim.loop.new_timer()
  timer:start(timeout, 0, vim.schedule_wrap(callback))
  return timer
end

local function clearTimeout(timer)
  timer:stop()
  timer:close()
end

local function debounce(timeout, callback)
  local timer = nil
  return function()
    if timer ~= nil then clearTimeout(timer) end
    timer = setTimeout(timeout, callback)
  end
end

local function cleanup(handle)
  if handle and not uv.is_closing(handle) then
    handle:close()
  end
end

local function vim_loop(f)
  local co = coroutine.running()
  assert(co, "vim_loop must be called from a coroutine")
  assert(type(f) == "function", "expected a function")
  local ret = nil

  vim.schedule(function()
    ret = f()
    coroutine.resume(co)
  end)
  coroutine.yield()
  if ret == nil then return nil else return ret end
end

local function spawn(cmd, args)
  local co = coroutine.running()
  assert(co, "await must be called from a coroutine")

  local fd = nil
  local ret = ''
  local stdout = uv.new_pipe()
  local stderr = uv.new_pipe()

  fd = uv.spawn(cmd, { args = args, stdio = { nil, stdout, stderr } }, function()
    cleanup(fd)
    cleanup(stdout)
    cleanup(stderr)
    coroutine.resume(co)
  end)
  uv.read_start(stdout, function(err, data)
    if err then print(err) end
    if data then ret = ret .. data end
  end)
  uv.read_start(stderr, function(err, data)
    if err then print(err) end
    -- Some commands print to stderr even if they succeed (e.g. git).
    if data then ret = ret .. data end
  end)

  coroutine.yield()
  return ret
end

local function await(func, ...)
  assert(type(func) == "function", "expected a function")

  local co = coroutine.running()
  assert(co, "await must be called from a coroutine")

  local ret = nil
  local args = { ... }
  local callback_set = false
  local callback = function(...)
    ret = { ... }
    coroutine.resume(co)
  end

  -- Check if any arg is a callback
  for i, v in ipairs(args) do
    if type(v) == "function" then
      args[i] = callback
      callback_set = true
    end
  end
  if not callback_set then
    table.insert(args, callback)
  end
  func(unpack(args))
  coroutine.yield()

  if ret == nil then return nil else return unpack(ret) end
end

local function await_all(funcs)
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
  return unpack(ret)
end

local function async(func)
  assert(type(func) == "function", "expected a function")
  return function(...)
    local co = coroutine.create(func)
    assert(coroutine.resume(co, ...))
  end
end

local function read_file(path)
  local open_err, fd = await(uv.fs_open, path, "r", 438)
  if open_err then error(open_err) end

  local stat_err, stat = await(uv.fs_fstat, fd)
  if stat_err then error(stat_err) end
  if stat == nil then error("file not found") end

  local read_err, data = await(uv.fs_read, fd, stat.size, 0)
  if read_err then error(read_err) end

  local close_err = await(uv.fs_close, fd)
  if close_err then error(close_err) end

  return data
end

local function str_count(...)
  local count = 0
  for _, v in ipairs { ... } do
    if v ~= nil and v ~= 0 then
      count = count + string.len(tostring(v))
    end
  end

  return count
end

return {
  setTimeout = setTimeout,
  clearTimeout = clearTimeout,
  debounce = debounce,
  cleanup = cleanup,
  vim_loop = vim_loop,
  spawn = spawn,
  await = await,
  await_all = await_all,
  async = async,
  read_file = read_file,
  str_count = str_count,
  noop = function() end,
}
