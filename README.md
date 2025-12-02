# chunkundo.nvim

[![Tests](https://github.com/kako-jun/chunkundo.nvim/actions/workflows/test.yml/badge.svg)](https://github.com/kako-jun/chunkundo.nvim/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[日本語](README.ja.md)

Batch consecutive edits into single undo units for Neovim.

> u u u u u u u u u u u "Hey Chunk, calm down!" - The Goonies

![demo](https://github.com/kako-jun/chunkundo.nvim/raw/main/assets/demo.gif)

## The Problem

By default, Neovim creates a new undo entry for **every single keystroke** in insert mode. Type "hello" and you get 5 undo entries. This makes undo tedious:

```
Type: h-e-l-l-o w-o-r-l-d
Undo: d → l → r → o → w → (space) → o → l → l → e → h
      ↑ 11 times to undo "hello world"!
```

## The Solution

chunkundo.nvim batches your edits by **time** and **word boundaries**. Keep typing and all edits become one undo unit. Pause for a moment or press space, and the next edits start a new undo block:

```
Type: hello (pause 300ms) world
Undo: world → hello
      ↑ Just 2 undos!

Type: hello world (space breaks chunk)
Undo: world → hello
      ↑ Just 2 undos!
```

**No similar plugin exists for Neovim.** This is a unique solution powered by [chillout.nvim](https://github.com/kako-jun/chillout.nvim)'s debounce, throttle, and batch functions.

## Features

- **Time-based chunking**: Automatically break undo after typing pause
- **Word-based chunking**: Break on space/enter (like word boundaries)
- **Auto-adjust**: Learn your typing pattern and adjust interval automatically
- **Statusline integration**: See chunking activity in your statusline
- **Full chillout.nvim integration**: Uses all three features (debounce, throttle, batch)

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
  enabled = true,           -- enable on startup (default: true)

  -- Time-based chunking
  interval = 300,           -- ms of pause before new undo block (default: 300)
  max_chunk_time = 10000,   -- ms before forced chunk break (default: 10000)
  auto_adjust = true,       -- learn interval from typing pattern (default: true)

  -- Character-based chunking
  break_on_space = true,    -- break on space and enter (default: true)
  break_on_punct = false,   -- break on punctuation .,?!;: (default: false)
})
```

That's it! Now your edits are automatically chunked.

## Commands

| Command | Description | Persistence |
|---------|-------------|-------------|
| `:ChunkUndo enable` | Enable chunking | Session only |
| `:ChunkUndo disable` | Disable chunking | Session only |
| `:ChunkUndo toggle` | Toggle on/off | Session only |
| `:ChunkUndo status` | Show current status | - |
| `:ChunkUndo show` | Show statusline | Session only |
| `:ChunkUndo hide` | Hide statusline | Session only |
| `:ChunkUndo interval` | Show current interval (incl. learned) | - |
| `:ChunkUndo interval 500` | Set interval to 500ms | Session only |
| `:ChunkUndo auto` | Show auto-adjust status | - |
| `:ChunkUndo auto on` | Enable auto-adjust | Session only |
| `:ChunkUndo auto off` | Disable auto-adjust | Session only |
| `:ChunkUndo space` | Show break on space status | - |
| `:ChunkUndo space on` | Enable break on space/enter | Session only |
| `:ChunkUndo space off` | Disable break on space/enter | Session only |
| `:ChunkUndo punct` | Show break on punctuation status | - |
| `:ChunkUndo punct on` | Enable break on punctuation | Session only |
| `:ChunkUndo punct off` | Disable break on punctuation | Session only |

For **permanent** changes, modify your setup:

```lua
require("chunkundo").setup({
  interval = 500,           -- permanent: change default interval
  enabled = false,          -- permanent: start disabled
  auto_adjust = false,      -- permanent: disable auto-learning
  break_on_space = false,   -- permanent: disable word-based chunking
})
```

## API

| Function | Description | Persistence |
|----------|-------------|-------------|
| `enable()` | Enable chunking | Session only |
| `disable()` | Disable chunking | Session only |
| `toggle()` | Toggle on/off | Session only |
| `is_enabled()` | Returns boolean | - |
| `get_interval()` | Get configured interval (ms) | - |
| `set_interval(ms)` | Set interval (clears learned) | Session only |
| `get_effective_interval()` | Get actual interval (learned or configured) | - |
| `enable_auto_adjust()` | Enable auto-learning | Session only |
| `disable_auto_adjust()` | Disable auto-learning | Session only |
| `is_auto_adjust_enabled()` | Returns boolean | - |
| `statusline()` | Returns status string | - |
| `statusline_component` | For lualine (respects show/hide) | - |
| `show_statusline()` | Show statusline | Session only |
| `hide_statusline()` | Hide statusline | Session only |

## Statusline Integration

Add `statusline_component` to your statusline to see chunking activity:

```
u+5    -- Growing: 5 edits in current chunk
u=12   -- Confirmed: last chunk had 12 edits
u-     -- Disabled
u      -- Enabled, no activity yet
(empty) -- Hidden via :ChunkUndo hide
```

### lualine example

```lua
require("lualine").setup({
  sections = {
    lualine_x = { require("chunkundo").statusline_component },
  }
})
```

## Auto-adjust Feature

chunkundo.nvim learns your typing pattern using **exponential moving average (EMA)**:

1. Collects edit timestamps every 5 seconds (using chillout.batch)
2. Analyzes pause patterns (100ms-5000ms pauses = "thinking pauses")
3. Calculates median pause (robust against outliers)
4. Adjusts interval to 80% of median (break just before pause ends)
5. Blends with previous value (EMA alpha=0.3) to prevent sudden changes

This means the more you use it, the better it fits your typing style!

Check learned interval:
```vim
:ChunkUndo interval
" Output: chunkundo: interval 245ms (learned), base 300ms
```

## chillout.nvim Integration

This plugin is a showcase for [chillout.nvim](https://github.com/kako-jun/chillout.nvim), using all three features:

| Feature | Usage |
|---------|-------|
| **debounce** | Detect typing pause, with maxWait for forced breaks |
| **throttle** | Limit statusline updates to 100ms for performance |
| **batch** | Collect timestamps every 5s for pattern learning |

## Why "Chunk"?

Named after Chunk from The Goonies - the lovable character who's always told to calm down. Just like Chunk needs to chill, your undo history needs to be chunked into manageable pieces.

## Contributing

Issues and PRs welcome.

## License

[MIT](LICENSE)
