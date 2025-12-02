-- Simple test runner (no plenary required)
local passed = 0
local failed = 0

local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    passed = passed + 1
    print("✓ " .. name)
  else
    failed = failed + 1
    print("✗ " .. name .. ": " .. tostring(err))
  end
end

local function assert_true(val, msg)
  if not val then
    error(msg or "expected true")
  end
end

local function assert_false(val, msg)
  if val then
    error(msg or "expected false")
  end
end

local function assert_eq(a, b, msg)
  if a ~= b then
    error(msg or string.format("expected %s, got %s", tostring(b), tostring(a)))
  end
end

print("\n=== chunkundo.nvim tests ===\n")

local chunkundo = require("chunkundo")

-- Setup tests
test("setup without error", function()
  chunkundo.setup({ interval = 50 })
  assert_true(chunkundo.is_enabled())
end)

test("toggle enabled state", function()
  chunkundo.setup({ interval = 50 })
  assert_true(chunkundo.is_enabled())

  chunkundo.disable()
  assert_false(chunkundo.is_enabled())

  chunkundo.enable()
  assert_true(chunkundo.is_enabled())

  chunkundo.toggle()
  assert_false(chunkundo.is_enabled())

  chunkundo.toggle()
  assert_true(chunkundo.is_enabled())
end)

test("custom interval", function()
  chunkundo.setup({ interval = 1000 })
  assert_true(chunkundo.is_enabled())
end)

test("disabling on setup", function()
  chunkundo.setup({ enabled = false })
  assert_false(chunkundo.is_enabled())
end)

test("status function exists", function()
  assert_true(type(chunkundo.status) == "function")
end)

-- Command tests
test("ChunkUndo command exists", function()
  local commands = vim.api.nvim_get_commands({})
  assert_true(commands.ChunkUndo ~= nil)
end)

test("ChunkUndo enable command", function()
  chunkundo.setup({ interval = 50 })
  chunkundo.disable()
  vim.cmd("ChunkUndo enable")
  assert_true(chunkundo.is_enabled())
end)

test("ChunkUndo disable command", function()
  chunkundo.setup({ interval = 50 })
  chunkundo.enable()
  vim.cmd("ChunkUndo disable")
  assert_false(chunkundo.is_enabled())
end)

test("ChunkUndo toggle command", function()
  chunkundo.setup({ interval = 50 })
  chunkundo.enable()
  vim.cmd("ChunkUndo toggle")
  assert_false(chunkundo.is_enabled())
  vim.cmd("ChunkUndo toggle")
  assert_true(chunkundo.is_enabled())
end)

test("ChunkUndo status command", function()
  chunkundo.setup({ interval = 50 })
  vim.cmd("ChunkUndo status")
  assert_true(true)
end)

-- Statusline tests
test("statusline function exists", function()
  assert_true(type(chunkundo.statusline) == "function")
end)

test("statusline returns u- when disabled", function()
  chunkundo.setup({ interval = 50 })
  chunkundo.disable()
  assert_eq(chunkundo.statusline(), "u-")
end)

test("statusline returns u when enabled with no activity", function()
  chunkundo.setup({ interval = 50 })
  chunkundo.enable()
  assert_eq(chunkundo.statusline(), "u")
end)

-- Interval API tests
test("get_interval returns current interval", function()
  chunkundo.setup({ interval = 500 })
  assert_eq(chunkundo.get_interval(), 500)
end)

test("set_interval changes interval", function()
  chunkundo.setup({ interval = 300 })
  chunkundo.set_interval(600)
  assert_eq(chunkundo.get_interval(), 600)
end)

test("set_interval enforces minimum 50ms", function()
  chunkundo.setup({ interval = 300 })
  chunkundo.set_interval(10)
  assert_eq(chunkundo.get_interval(), 50)
end)

-- Summary
print(string.format("\n=== Results: %d passed, %d failed ===\n", passed, failed))

if failed > 0 then
  vim.cmd("cquit 1")
else
  vim.cmd("quit")
end
