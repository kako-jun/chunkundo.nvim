# chunkundo.nvim

[![Tests](https://github.com/kako-jun/chunkundo.nvim/actions/workflows/test.yml/badge.svg)](https://github.com/kako-jun/chunkundo.nvim/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

連続した編集を1つのundoにまとめる Neovim プラグイン。

> "Hey Chunk, calm down!" - グーニーズ

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
入力: hello (500ms休止) world
undo: world → hello
      ↑ たった2回！
```

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

chunkundo.enable()      -- 有効化
chunkundo.disable()     -- 無効化
chunkundo.toggle()      -- 切り替え
chunkundo.is_enabled()  -- boolean を返す
```

## 仕組み

1. インサートモードでのキー入力ごとに `undojoin` で前の編集と結合
2. タイピングが止まると（デフォルト: 300ms）undoシーケンスが切れる
3. 次の編集は新しいundoブロックを開始

[chillout.nvim](https://github.com/kako-jun/chillout.nvim) の debounce 関数で実現。

## なぜ "Chunk"?

映画「グーニーズ」のチャンクから命名。いつも「落ち着け」と言われているキャラクター。チャンクが落ち着く必要があるように、undoの履歴もまとめて落ち着かせる必要がある。

## コントリビュート

Issue や PR を歓迎します。

## ライセンス

[MIT](LICENSE)
