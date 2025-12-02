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
