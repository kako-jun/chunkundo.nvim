# chunkundo.nvim Developer Documentation

A Neovim plugin that batches consecutive edits into single undo units using time-based chunking.

## Concept

"Hey Chunk, calm down!" - Named after Chunk from The Goonies. Just like Chunk needs to chill, your undo history needs to be chunked into manageable pieces.

**Important**: This plugin does NOT change how you type. It changes how undo behaves by joining consecutive edits into logical groups.

## Core Feature

| Feature | API | Description |
|---------|-----|-------------|
| Chunk Undo | `require("chunkundo").setup(opts?)` | Join consecutive edits into single undo blocks based on typing pauses |

## Options

```lua
require("chunkundo").setup({
  interval = 300,   -- ms of pause before starting a new undo block (default: 300)
  enabled = true,   -- enable on startup (default: true)
})
```

## API

```lua
local chunkundo = require("chunkundo")

chunkundo.setup(opts)   -- Initialize with options
chunkundo.enable()      -- Enable chunking
chunkundo.disable()     -- Disable chunking (normal undo behavior)
chunkundo.toggle()      -- Toggle on/off
chunkundo.is_enabled()  -- Returns boolean
```

## How It Works

### Default Neovim Undo Behavior

```
Type: h-e-l-l-o
Undo: o → l → l → e → h (5 undo operations!)
```

### With chunkundo.nvim

```
Type: hello (pause 300ms) world
Undo: world → hello (2 undo operations)
```

### Internal Mechanism

1. On `TextChangedI` event, call `undojoin` to merge with previous edit
2. Use `chillout.debounce` to detect typing pauses
3. When pause detected (default: 300ms), stop joining
4. Next edit starts a fresh undo block

```
T=0   'h' pressed → undojoin (start chunk)
T=50  'e' pressed → undojoin (continue chunk)
T=100 'l' pressed → undojoin (continue chunk)
T=150 'l' pressed → undojoin (continue chunk)
T=200 'o' pressed → undojoin (continue chunk)
(user pauses)
T=500 debounce fires → break chunk
T=600 'w' pressed → undojoin (start new chunk)
...
```

## Project Structure

```
chunkundo.nvim/
├── lua/
│   └── chunkundo/
│       └── init.lua    -- Core implementation
├── demo/
│   └── init.lua        -- Interactive demo
├── tests/
│   ├── minimal_init.lua
│   └── chunkundo_spec.lua
├── CLAUDE.md           -- This file
└── README.md           -- User documentation
```

## Dependencies

- [chillout.nvim](https://github.com/kako-jun/chillout.nvim) - For debounce functionality

## Test Execution

```bash
cd chunkundo.nvim
nvim -u demo/init.lua
```

## Implementation Notes

- Uses `vim.cmd("undojoin")` to merge edits
- Wraps undojoin in pcall to handle edge cases
- Autocommands: `TextChangedI` for edit detection, `InsertLeave` for chunk break
- Timer management via chillout.nvim's debounce

## Design Principles

- Single responsibility: Only handles undo chunking
- Depends on chillout.nvim for timing logic
- Minimal configuration (just interval)
- Non-intrusive: Can be toggled on/off
