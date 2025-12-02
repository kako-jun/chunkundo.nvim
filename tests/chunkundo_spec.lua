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
end)
