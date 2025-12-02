-- Demo for chunkundo.nvim
-- Run: nvim -u demo/init.lua

-- Setup paths
local demo_path = debug.getinfo(1, "S").source:sub(2)
local demo_dir = vim.fn.fnamemodify(demo_path, ":h")
local plugin_dir = vim.fn.fnamemodify(demo_dir, ":h")
local parent_dir = vim.fn.fnamemodify(plugin_dir, ":h")

-- Add plugin path
vim.opt.runtimepath:prepend(plugin_dir)

-- Find chillout.nvim in various locations
local chillout_paths = {
  parent_dir .. "/chillout.nvim", -- sibling directory (git clone)
  vim.fn.stdpath("data") .. "/lazy/chillout.nvim", -- lazy.nvim
  vim.fn.stdpath("data") .. "/site/pack/packer/start/chillout.nvim", -- packer
}

local chillout_found = false
for _, path in ipairs(chillout_paths) do
  if vim.fn.isdirectory(path) == 1 then
    vim.opt.runtimepath:prepend(path)
    chillout_found = true
    break
  end
end

if not chillout_found then
  print("ERROR: chillout.nvim not found. Install it or clone to: " .. parent_dir .. "/chillout.nvim")
  return
end

-- Basic settings
vim.opt.number = true
vim.opt.swapfile = false
vim.opt.undolevels = 1000

-- Setup chunkundo
require("chunkundo").setup({
  interval = 500, -- 500ms of no typing = new undo block
})

-- Setup statusline to show chunk status (u+5, u=12, etc.)
vim.opt.statusline = "%f %m %= %{%luaeval(\"require('chunkundo').statusline()\")%} "

-- Create demo buffer (not tied to a file, so edits won't save)
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_current_buf(buf)
vim.bo[buf].buftype = "nofile"
vim.bo[buf].modifiable = true

local lines = {
  "chunkundo.nvim Demo",
  '*accidentally presses u* "Hey Chunk, calm down!"',
  "",
  "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
  "",
  "The Problem:",
  "  Neovim's default: entire insert session = one undo unit.",
  "  Type many lines in insert mode, press u → ALL GONE!",
  "",
  "The Solution:",
  "  chunkundo breaks your INSERT SESSION by TIME and WORD BOUNDARIES.",
  "",
  "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
  "",
  "Test 1: Time-based chunking (INSERT MODE)",
  "  1. Press 'o' to open a new line below",
  "  2. Type 'hello', pause 1 second, type 'world'",
  "  3. Press Escape, then 'u'",
  "  → Only 'world' is undone!",
  "",
  "Test 2: Space-based chunking (INSERT MODE)",
  "  1. Press 'o' to open a new line below",
  "  2. Type 'hello world' (with space, no pause needed)",
  "  3. Press Escape, then 'u'",
  "  → Only 'world' is undone!",
  "",
  "Test 3: See the problem (DISABLE chunkundo first)",
  "  1. Run :ChunkUndo disable",
  "  2. Press 'o', type several lines without leaving insert mode",
  "  3. Press Escape, then 'u'",
  "  → EVERYTHING is undone at once! (This is the default Neovim behavior)",
  "",
  "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
  "",
  "Commands:",
  "  :ChunkUndo enable/disable/toggle/status",
  "  :ChunkUndo interval [ms]  - Show/set interval",
  "  :ChunkUndo auto on/off    - Auto-adjust learning",
  "  :ChunkUndo space on/off   - Break on space/tab/enter",
  "  :ChunkUndo punct on/off   - Break on punctuation",
  "  :ChunkUndo show/hide      - Statusline visibility",
  "",
  "Statusline (bottom right):",
  "  u+5  - Growing: 5 edits in current chunk",
  "  u=12 - Confirmed: last chunk had 12 edits",
  "  u-   - Disabled",
  "  u    - Enabled, no activity yet",
  "",
}

vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
vim.api.nvim_win_set_cursor(0, { 1, 0 })

print("chunkundo.nvim demo loaded! Use INSERT MODE (i/o/a) to test undo chunking.")
