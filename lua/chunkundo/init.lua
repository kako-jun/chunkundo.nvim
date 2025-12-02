-- chunkundo.nvim
-- Batch consecutive edits into single undo units
-- Inspired by Chunk from The Goonies - "Hey Chunk, calm down!"

local M = {}

local chillout_ok, chillout = pcall(require, "chillout")
if not chillout_ok then
  error("chunkundo.nvim requires chillout.nvim: https://github.com/kako-jun/chillout.nvim")
end

local config = {
  interval = 300, -- ms to wait before breaking undo sequence
  enabled = true,
}

local state = {
  in_chunk = false,
  debounced_break = nil,
}

-- Break the undo sequence
local function break_undo_sequence()
  if state.in_chunk then
    state.in_chunk = false
    -- Next edit will start a new undo block
  end
end

-- Join current edit to previous undo block
local function join_undo()
  if state.in_chunk and config.enabled then
    -- undojoin must be called before the edit, but we're in TextChangedI
    -- So we set up for the NEXT edit to be joined
    vim.cmd("silent! undojoin")
  end
end

-- Called on every text change in insert mode
local function on_text_changed()
  if not config.enabled then
    return
  end

  if state.in_chunk then
    -- Continue the chunk - join this edit
    pcall(vim.cmd, "silent! undojoin")
  else
    -- Start a new chunk
    state.in_chunk = true
  end

  -- Reset the timer - break sequence after interval of no edits
  if state.debounced_break then
    state.debounced_break()
  end
end

-- Called when leaving insert mode
local function on_insert_leave()
  break_undo_sequence()
end

local augroup = nil

function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})

  -- Create debounced break function
  state.debounced_break = chillout.debounce(break_undo_sequence, config.interval)

  -- Set up autocommands
  if augroup then
    vim.api.nvim_del_augroup_by_id(augroup)
  end
  augroup = vim.api.nvim_create_augroup("chunkundo", { clear = true })

  vim.api.nvim_create_autocmd("TextChangedI", {
    group = augroup,
    callback = on_text_changed,
  })

  vim.api.nvim_create_autocmd("InsertLeave", {
    group = augroup,
    callback = on_insert_leave,
  })
end

function M.enable()
  config.enabled = true
end

function M.disable()
  config.enabled = false
  break_undo_sequence()
end

function M.toggle()
  if config.enabled then
    M.disable()
  else
    M.enable()
  end
end

function M.is_enabled()
  return config.enabled
end

return M
