# chunkundo.nvim

[![Tests](https://github.com/kako-jun/chunkundo.nvim/actions/workflows/test.yml/badge.svg)](https://github.com/kako-jun/chunkundo.nvim/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[日本語](README.ja.md)

Batch consecutive edits into single undo units for Neovim.

> "Hey Chunk, calm down!" - The Goonies

![demo](https://github.com/kako-jun/chunkundo.nvim/raw/main/assets/demo.gif)

## The Problem

By default, Neovim creates a new undo entry for **every single keystroke** in insert mode. Type "hello" and you get 5 undo entries. This makes undo tedious:

```
Type: h-e-l-l-o w-o-r-l-d
Undo: d → l → r → o → w → (space) → o → l → l → e → h
      ↑ 11 times to undo "hello world"!
```

## The Solution

chunkundo.nvim batches your edits by **time**. Keep typing and all edits become one undo unit. Pause for a moment, and the next edits start a new undo block:

```
Type: hello (pause 300ms) world
Undo: world → hello
      ↑ Just 2 undos!
```

**No similar plugin exists for Neovim.** This is a unique solution powered by [chillout.nvim](https://github.com/kako-jun/chillout.nvim)'s debounce function.

## Requirements

- Neovim >= 0.10
- [chillout.nvim](https://github.com/kako-jun/chillout.nvim)

## Installation

### lazy.nvim

```lua
{
  "kako-jun/chunkundo.nvim",
  dependencies = { "kako-jun/chillout.nvim" },
  config = function()
    require("chunkundo").setup()
  end,
}
```

### packer.nvim

```lua
use {
  "kako-jun/chunkundo.nvim",
  requires = { "kako-jun/chillout.nvim" },
  config = function()
    require("chunkundo").setup()
  end,
}
```

## Usage

```lua
require("chunkundo").setup({
  interval = 300,  -- ms of pause before new undo block (default: 300)
  enabled = true,  -- enable on startup (default: true)
})
```

That's it! Now your edits are automatically chunked.

## Commands

```vim
:ChunkUndo enable   " Enable chunking
:ChunkUndo disable  " Disable (normal undo behavior)
:ChunkUndo toggle   " Toggle on/off
:ChunkUndo status   " Show current status
```

## API

```lua
local chunkundo = require("chunkundo")

chunkundo.enable()      -- Enable chunking
chunkundo.disable()     -- Disable chunking
chunkundo.toggle()      -- Toggle on/off
chunkundo.is_enabled()  -- Returns boolean
chunkundo.statusline()  -- Returns status string for statusline
chunkundo.get_interval() -- Get current interval (ms)
chunkundo.set_interval(ms) -- Set interval dynamically
```

## Statusline Integration

Add `chunkundo.statusline()` to your statusline to see chunking activity:

```
u+5    -- Growing: 5 edits in current chunk
u=12   -- Confirmed: last chunk had 12 edits
u-     -- Disabled
u      -- Enabled, no activity yet
```

### lualine example

```lua
require("lualine").setup({
  sections = {
    lualine_x = { require("chunkundo").statusline },
  }
})
```

### Adjusting interval on the fly

```lua
-- Keymaps to adjust interval
vim.keymap.set("n", "<leader>u+", function()
  local chunkundo = require("chunkundo")
  chunkundo.set_interval(chunkundo.get_interval() + 100)
end)
vim.keymap.set("n", "<leader>u-", function()
  local chunkundo = require("chunkundo")
  chunkundo.set_interval(chunkundo.get_interval() - 100)
end)
```

## Why "Chunk"?

Named after Chunk from The Goonies - the lovable character who's always told to calm down. Just like Chunk needs to chill, your undo history needs to be chunked into manageable pieces.

## Contributing

Issues and PRs welcome.

## License

[MIT](LICENSE)
