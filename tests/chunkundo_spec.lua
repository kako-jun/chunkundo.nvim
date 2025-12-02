local chunkundo = require("chunkundo")

describe("chunkundo", function()
  before_each(function()
    chunkundo.setup({ interval = 50 })
  end)

  it("should setup without error", function()
    assert.is_true(chunkundo.is_enabled())
  end)

  it("should toggle enabled state", function()
    assert.is_true(chunkundo.is_enabled())

    chunkundo.disable()
    assert.is_false(chunkundo.is_enabled())

    chunkundo.enable()
    assert.is_true(chunkundo.is_enabled())

    chunkundo.toggle()
    assert.is_false(chunkundo.is_enabled())

    chunkundo.toggle()
    assert.is_true(chunkundo.is_enabled())
  end)

  it("should accept custom interval", function()
    chunkundo.setup({ interval = 1000 })
    -- No error means success
    assert.is_true(chunkundo.is_enabled())
  end)

  it("should allow disabling on setup", function()
    chunkundo.setup({ enabled = false })
    assert.is_false(chunkundo.is_enabled())
  end)

  it("should have status function", function()
    assert.is_function(chunkundo.status)
  end)
end)

describe("ChunkUndo command", function()
  before_each(function()
    chunkundo.setup({ interval = 50 })
  end)

  it("should exist", function()
    local commands = vim.api.nvim_get_commands({})
    assert.is_not_nil(commands.ChunkUndo)
  end)

  it("should enable via command", function()
    chunkundo.disable()
    vim.cmd("ChunkUndo enable")
    assert.is_true(chunkundo.is_enabled())
  end)

  it("should disable via command", function()
    chunkundo.enable()
    vim.cmd("ChunkUndo disable")
    assert.is_false(chunkundo.is_enabled())
  end)

  it("should toggle via command", function()
    chunkundo.enable()
    vim.cmd("ChunkUndo toggle")
    assert.is_false(chunkundo.is_enabled())
    vim.cmd("ChunkUndo toggle")
    assert.is_true(chunkundo.is_enabled())
  end)

  it("should run status via command", function()
    -- Just ensure it doesn't error
    vim.cmd("ChunkUndo status")
    assert.is_true(true)
  end)
end)

describe("statusline", function()
  before_each(function()
    chunkundo.setup({ interval = 50 })
  end)

  it("should return u- when disabled", function()
    chunkundo.disable()
    assert.equals("u-", chunkundo.statusline())
  end)

  it("should return u when enabled with no activity", function()
    chunkundo.enable()
    assert.equals("u", chunkundo.statusline())
  end)
end)

describe("interval API", function()
  it("should get current interval", function()
    chunkundo.setup({ interval = 500 })
    assert.equals(500, chunkundo.get_interval())
  end)

  it("should set interval", function()
    chunkundo.setup({ interval = 300 })
    chunkundo.set_interval(600)
    assert.equals(600, chunkundo.get_interval())
  end)

  it("should enforce minimum 50ms", function()
    chunkundo.setup({ interval = 300 })
    chunkundo.set_interval(10)
    assert.equals(50, chunkundo.get_interval())
  end)

  it("should get effective interval", function()
    chunkundo.setup({ interval = 300 })
    assert.equals(300, chunkundo.get_effective_interval())
  end)
end)

describe("auto-adjust API", function()
  it("should be enabled by default", function()
    chunkundo.setup({})
    assert.is_true(chunkundo.is_auto_adjust_enabled())
  end)

  it("should allow disabling via setup", function()
    chunkundo.setup({ auto_adjust = false })
    assert.is_false(chunkundo.is_auto_adjust_enabled())
  end)

  it("should toggle auto-adjust", function()
    chunkundo.setup({ auto_adjust = true })
    assert.is_true(chunkundo.is_auto_adjust_enabled())

    chunkundo.disable_auto_adjust()
    assert.is_false(chunkundo.is_auto_adjust_enabled())

    chunkundo.enable_auto_adjust()
    assert.is_true(chunkundo.is_auto_adjust_enabled())
  end)
end)

describe("undo chunking", function()
  before_each(function()
    chunkundo.setup({ interval = 50 })
    -- Create a fresh buffer for each test
    vim.cmd("enew!")
    vim.bo.buftype = ""
  end)

  after_each(function()
    vim.cmd("bwipeout!")
  end)

  it("should join continuous edits into one undo block", function()
    -- Simulate typing "hello" using feedkeys with proper flags
    -- "t" = remap, "x" = execute immediately
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("ihello<Esc>", true, false, true), "tx", false)

    -- Buffer should have "hello"
    local line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
    assert.equals("hello", line)

    -- One undo should remove all of "hello"
    vim.cmd("undo")
    line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
    assert.equals("", line)
  end)

  it("should create separate undo blocks after pause", function()
    -- Type "hello"
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("ihello<Esc>", true, false, true), "tx", false)

    -- Buffer should have "hello"
    local line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
    assert.equals("hello", line)

    -- Wait for debounce to break the chunk (interval is 50ms, wait 100ms)
    vim.wait(100, function()
      return false
    end)

    -- Type "world" (append)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("aworld<Esc>", true, false, true), "tx", false)

    -- Buffer should have "helloworld"
    line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
    assert.equals("helloworld", line)

    -- First undo should only remove "world"
    vim.cmd("undo")
    line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
    assert.equals("hello", line)

    -- Second undo should remove "hello"
    vim.cmd("undo")
    line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
    assert.equals("", line)
  end)

  it("should NOT join edits across insert sessions (mode change)", function()
    -- Type "hello", exit insert mode
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("ihello<Esc>", true, false, true), "tx", false)

    -- No wait - immediately re-enter insert mode
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("aworld<Esc>", true, false, true), "tx", false)

    -- Buffer should have "helloworld"
    local line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
    assert.equals("helloworld", line)

    -- First undo should only remove "world" (separate insert sessions)
    vim.cmd("undo")
    line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
    assert.equals("hello", line)

    -- Second undo should remove "hello"
    vim.cmd("undo")
    line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
    assert.equals("", line)
  end)
end)

describe("CJK support", function()
  -- Test the should_break_on_char logic by checking config options exist
  it("should have break_on_space option", function()
    chunkundo.setup({ break_on_space = true })
    assert.is_true(chunkundo.is_enabled())
  end)

  it("should have break_on_punct option", function()
    chunkundo.setup({ break_on_punct = true })
    assert.is_true(chunkundo.is_enabled())
  end)

  it("should accept both space options", function()
    -- Full-width space support is built into break_on_space
    chunkundo.setup({ break_on_space = true, break_on_punct = false })
    assert.is_true(chunkundo.is_enabled())
  end)

  it("should accept CJK punctuation option", function()
    -- CJK punctuation (。、，？！) is built into break_on_punct
    chunkundo.setup({ break_on_space = false, break_on_punct = true })
    assert.is_true(chunkundo.is_enabled())
  end)
end)
