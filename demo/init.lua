-- Demo for chunkundo.nvim
-- Run: nvim -u demo/init.lua

-- Setup paths
local demo_path = debug.getinfo(1, "S").source:sub(2)
local demo_dir = vim.fn.fnamemodify(demo_path, ":h")
local plugin_dir = vim.fn.fnamemodify(demo_dir, ":h")
local parent_dir = vim.fn.fnamemodify(plugin_dir, ":h")

-- Add plugin paths
vim.opt.runtimepath:prepend(plugin_dir)
vim.opt.runtimepath:prepend(parent_dir .. "/chillout.nvim")

-- Basic settings
vim.opt.number = true
vim.opt.swapfile = false
vim.opt.undolevels = 1000

-- Setup chunkundo
require("chunkundo").setup({
  interval = 500, -- 500ms of no typing = new undo block
})

-- Create demo buffer
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_current_buf(buf)

local lines = {
  "╔══════════════════════════════════════════════════════════════╗",
  "║              chunkundo.nvim Demo                             ║",
  '║         "Hey Chunk, calm down!" - The Goonies                ║',
  "╠══════════════════════════════════════════════════════════════╣",
  "║                                                              ║",
  "║  How it works:                                               ║",
  "║  - Type continuously: all edits become ONE undo unit         ║",
  "║  - Pause 500ms+: next edits become a NEW undo unit           ║",
  "║                                                              ║",
  "║  Try this:                                                   ║",
  "║  1. Press 'i' to enter insert mode                           ║",
  "║  2. Type 'hello world' quickly (no pause)                    ║",
  "║  3. Press Escape, then 'u' to undo                           ║",
  "║  → The ENTIRE 'hello world' is undone at once!               ║",
  "║                                                              ║",
  "║  Now try:                                                    ║",
  "║  1. Type 'hello', pause 1 second, type 'world'               ║",
  "║  2. Press Escape, then 'u' to undo                           ║",
  "║  → Only 'world' is undone (separate undo blocks)             ║",
  "║                                                              ║",
  "╠══════════════════════════════════════════════════════════════╣",
  "║  Commands:                                                   ║",
  "║    :ChunkUndo enable   - Enable chunking                     ║",
  "║    :ChunkUndo disable  - Disable (normal undo behavior)      ║",
  "║    :ChunkUndo toggle   - Toggle on/off                       ║",
  "║    :ChunkUndo status   - Show current status                 ║",
  "╚══════════════════════════════════════════════════════════════╝",
  "",
  "Type below this line:",
  "─────────────────────────────────────────────────────────────────",
  "",
}

vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

-- Add commands
vim.api.nvim_create_user_command("ChunkUndo", function(opts)
  local chunkundo = require("chunkundo")
  local arg = opts.args

  if arg == "enable" then
    chunkundo.enable()
    print("chunkundo: enabled")
  elseif arg == "disable" then
    chunkundo.disable()
    print("chunkundo: disabled")
  elseif arg == "toggle" then
    chunkundo.toggle()
    print("chunkundo: " .. (chunkundo.is_enabled() and "enabled" or "disabled"))
  elseif arg == "status" then
    print("chunkundo: " .. (chunkundo.is_enabled() and "enabled" or "disabled"))
  else
    print("Usage: :ChunkUndo [enable|disable|toggle|status]")
  end
end, {
  nargs = "?",
  complete = function()
    return { "enable", "disable", "toggle", "status" }
  end,
})

-- Move cursor to typing area
vim.api.nvim_win_set_cursor(0, { #lines, 0 })

print("chunkundo.nvim demo loaded! Type below the line, use 'u' to undo.")
