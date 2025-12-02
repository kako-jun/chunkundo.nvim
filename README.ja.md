# chunkundo.nvim

[![Tests](https://github.com/kako-jun/chunkundo.nvim/actions/workflows/test.yml/badge.svg)](https://github.com/kako-jun/chunkundo.nvim/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

連続した編集を1つのundoにまとめる Neovim プラグイン。

> "Hey Chunk, calm down!" - グーニーズ

![demo](https://github.com/kako-jun/chunkundo.nvim/raw/main/assets/demo.gif)

## 問題

Neovim のデフォルトでは、インサートモードで**1キー入力ごと**にundoエントリが作られる。「hello」と入力すると5個のundoエントリができる。undoが面倒：

```
入力: h-e-l-l-o w-o-r-l-d
undo: d → l → r → o → w → (空白) → o → l → l → e → h
      ↑ "hello world" を消すのに11回！
```

## 解決策

chunkundo.nvim は編集を**時間**でまとめる。タイプし続ければ全編集が1つのundoになる。少し止まると、次の編集は新しいundoブロックになる：

```
入力: hello (300ms休止) world
undo: world → hello
      ↑ たった2回！
```

**Neovimに同様のプラグインは存在しない。** [chillout.nvim](https://github.com/kako-jun/chillout.nvim) の debounce 関数で実現したユニークなソリューション。

## 必要環境

- Neovim >= 0.10
- [chillout.nvim](https://github.com/kako-jun/chillout.nvim)

## インストール

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

## 使い方

```lua
require("chunkundo").setup({
  interval = 300,  -- 新しいundoブロックまでの休止時間 (デフォルト: 300ms)
  enabled = true,  -- 起動時に有効 (デフォルト: true)
})
```

これだけ！編集が自動的にまとめられる。

## コマンド

```vim
:ChunkUndo enable   " 有効化
:ChunkUndo disable  " 無効化（通常のundo動作）
:ChunkUndo toggle   " 切り替え
:ChunkUndo status   " 現在の状態を表示
```

## API

```lua
local chunkundo = require("chunkundo")

chunkundo.enable()       -- 有効化
chunkundo.disable()      -- 無効化
chunkundo.toggle()       -- 切り替え
chunkundo.is_enabled()   -- boolean を返す
chunkundo.statusline()   -- ステータスライン用文字列を返す
chunkundo.get_interval() -- 現在のintervalを取得 (ms)
chunkundo.set_interval(ms) -- intervalを動的に変更
```

## ステータスライン連携

`chunkundo.statusline()` をステータスラインに追加すると、チャンキングの状態が見える:

```
u+5    -- 成長中: 現在のチャンクに5編集
u=12   -- 確定: 前回のチャンクは12編集
u-     -- 無効
u      -- 有効、まだ編集なし
```

### lualine での例

```lua
require("lualine").setup({
  sections = {
    lualine_x = { require("chunkundo").statusline },
  }
})
```

### interval をその場で調整

```lua
-- キーマップでintervalを調整
vim.keymap.set("n", "<leader>u+", function()
  local chunkundo = require("chunkundo")
  chunkundo.set_interval(chunkundo.get_interval() + 100)
end)
vim.keymap.set("n", "<leader>u-", function()
  local chunkundo = require("chunkundo")
  chunkundo.set_interval(chunkundo.get_interval() - 100)
end)
```

## なぜ "Chunk"?

映画「グーニーズ」のチャンクから命名。いつも「落ち着け」と言われているキャラクター。チャンクが落ち着く必要があるように、undoの履歴もまとめて落ち着かせる必要がある。

## コントリビュート

Issue や PR を歓迎します。

## ライセンス

[MIT](LICENSE)
