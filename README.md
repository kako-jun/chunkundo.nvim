# chunkundo.nvim

[![Tests](https://github.com/kako-jun/chunkundo.nvim/actions/workflows/test.yml/badge.svg)](https://github.com/kako-jun/chunkundo.nvim/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[日本語](README.ja.md)

Batch consecutive edits into single undo units for Neovim.

> "Hey Chunk, calm down!" - The Goonies

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
Type: hello (pause 500ms) world
Undo: world → hello
      ↑ Just 2 undos!
```

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
```

## How It Works

1. On each keystroke in insert mode, the plugin uses `undojoin` to merge the edit with the previous one
2. When you pause typing (default: 300ms), the undo sequence breaks
3. The next edit starts a fresh undo block

This is powered by [chillout.nvim](https://github.com/kako-jun/chillout.nvim)'s debounce function.

## Why "Chunk"?

Named after Chunk from The Goonies - the lovable character who's always told to calm down. Just like Chunk needs to chill, your undo history needs to be chunked into manageable pieces.

## Contributing

Issues and PRs welcome.

## License

[MIT](LICENSE)
