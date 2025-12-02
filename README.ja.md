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

| コマンド | 説明 | 永続性 |
|----------|------|--------|
| `:ChunkUndo enable` | 有効化 | セッションのみ |
| `:ChunkUndo disable` | 無効化 | セッションのみ |
| `:ChunkUndo toggle` | 切り替え | セッションのみ |
| `:ChunkUndo status` | 現在の状態を表示 | - |
| `:ChunkUndo show` | ステータスライン表示 | セッションのみ |
| `:ChunkUndo hide` | ステータスライン非表示 | セッションのみ |
| `:ChunkUndo interval` | 現在のintervalを表示 | - |
| `:ChunkUndo interval 500` | intervalを500msに設定 | セッションのみ |

**永続的**に変更するにはsetupで指定:

```lua
require("chunkundo").setup({
  interval = 500,   -- 永続: デフォルトintervalを変更
  enabled = false,  -- 永続: 無効状態で起動
})
```

## API

| 関数 | 説明 | 永続性 |
|------|------|--------|
| `enable()` | 有効化 | セッションのみ |
| `disable()` | 無効化 | セッションのみ |
| `toggle()` | 切り替え | セッションのみ |
| `is_enabled()` | boolean を返す | - |
| `get_interval()` | 現在のintervalを取得 (ms) | - |
| `set_interval(ms)` | intervalを変更 | セッションのみ |
| `statusline()` | ステータス文字列を返す | - |
| `statusline_component` | lualine用（show/hideを反映） | - |
| `show_statusline()` | ステータスライン表示 | セッションのみ |
| `hide_statusline()` | ステータスライン非表示 | セッションのみ |

## ステータスライン連携

`statusline_component` をステータスラインに追加すると、チャンキングの状態が見える:

```
u+5    -- 成長中: 現在のチャンクに5編集
u=12   -- 確定: 前回のチャンクは12編集
u-     -- 無効
u      -- 有効、まだ編集なし
(空)   -- :ChunkUndo hide で非表示
```

### lualine での例

```lua
require("lualine").setup({
  sections = {
    lualine_x = { require("chunkundo").statusline_component },
  }
})
```

### interval をその場で調整

```lua
-- キーマップでintervalを調整（セッションのみ）
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
