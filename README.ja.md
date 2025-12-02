# chunkundo.nvim

[![Tests](https://github.com/kako-jun/chunkundo.nvim/actions/workflows/test.yml/badge.svg)](https://github.com/kako-jun/chunkundo.nvim/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

連続した編集を1つのundoにまとめる Neovim プラグイン。

> *うっかりuを押してしまう* "Hey Chunk, calm down!" - グーニーズ

![demo](https://github.com/kako-jun/chunkundo.nvim/raw/main/assets/demo.gif)

## 問題

Neovimのデフォルトでは、**インサートセッション全体が1つのundo単位**になる。10行入力してEscを押した後にundoすると、全部が一瞬で消える：

```
入力: (何行ものコード...)
Esc
u → 全部消えた！積み上げた成果が一瞬で台無しに。
```

映画「グーニーズ」のチャンクがうっかり全てを台無しにするように、不用意な`u`一発であなたの作業が吹き飛ぶ。

## 解決策

chunkundo.nvim は**インサートセッションを時間と単語境界で分割**する。長い編集中でも、段階的にundoできる：

```
入力: function hello()   (300ms休止)   print("world")   (休止)   end
undo: end → print("world") → function hello()
      ↑ 一気にではなく、段階的にundo！
```

**Neovimに同様のプラグインは存在しない。** [chillout.nvim](https://github.com/kako-jun/chillout.nvim) の debounce/throttle/batch 関数で実現したユニークなソリューション。

## 特徴

- **時間ベースのチャンキング**: タイピング休止後に自動でundo区切り
- **単語ベースのチャンキング**: スペース/改行で区切り（単語境界のように）
- **自動調整**: タイピングパターンを学習してintervalを自動調整
- **ステータスライン連携**: チャンキング状態をステータスラインで確認
- **chillout.nvim完全統合**: 3機能すべてを活用（debounce, throttle, batch）

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
  enabled = true,           -- 起動時に有効 (デフォルト: true)

  -- 時間ベースのチャンキング
  interval = 300,           -- 新しいundoブロックまでの休止時間ms (デフォルト: 300)
  max_chunk_time = 10000,   -- 連続入力中でも強制区切りする時間ms (デフォルト: 10000)
  auto_adjust = true,       -- タイピングパターンからintervalを学習 (デフォルト: true)

  -- 文字ベースのチャンキング
  break_on_space = true,    -- スペース・タブ・改行で区切る (デフォルト: true)
  break_on_punct = false,   -- 句読点(.,?!;:)で区切る (デフォルト: false)
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
| `:ChunkUndo interval` | 現在のintervalを表示（学習値含む） | - |
| `:ChunkUndo interval 500` | intervalを500msに設定 | セッションのみ |
| `:ChunkUndo auto` | 自動調整の状態を表示 | - |
| `:ChunkUndo auto on` | 自動調整を有効化 | セッションのみ |
| `:ChunkUndo auto off` | 自動調整を無効化 | セッションのみ |
| `:ChunkUndo space` | スペース区切りの状態を表示 | - |
| `:ChunkUndo space on` | スペース/改行での区切りを有効化 | セッションのみ |
| `:ChunkUndo space off` | スペース/改行での区切りを無効化 | セッションのみ |
| `:ChunkUndo punct` | 句読点区切りの状態を表示 | - |
| `:ChunkUndo punct on` | 句読点での区切りを有効化 | セッションのみ |
| `:ChunkUndo punct off` | 句読点での区切りを無効化 | セッションのみ |

**永続的**に変更するにはsetupで指定:

```lua
require("chunkundo").setup({
  interval = 500,           -- 永続: デフォルトintervalを変更
  enabled = false,          -- 永続: 無効状態で起動
  auto_adjust = false,      -- 永続: 自動学習を無効化
  break_on_space = false,   -- 永続: 単語ベースのチャンキングを無効化
})
```

## API

| 関数 | 説明 | 永続性 |
|------|------|--------|
| `enable()` | 有効化 | セッションのみ |
| `disable()` | 無効化 | セッションのみ |
| `toggle()` | 切り替え | セッションのみ |
| `is_enabled()` | boolean を返す | - |
| `get_interval()` | 設定されたintervalを取得 (ms) | - |
| `set_interval(ms)` | intervalを変更（学習値はリセット） | セッションのみ |
| `get_effective_interval()` | 実際に使用中のinterval（学習値または設定値） | - |
| `enable_auto_adjust()` | 自動学習を有効化 | セッションのみ |
| `disable_auto_adjust()` | 自動学習を無効化 | セッションのみ |
| `is_auto_adjust_enabled()` | boolean を返す | - |
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

### 素の Neovim での例

```lua
vim.opt.statusline = "%f %m %= %{%luaeval(\"require('chunkundo').statusline()\")%} "
```

## 自動調整機能

chunkundo.nvim は**指数移動平均 (EMA)** を使ってタイピングパターンを学習:

1. 5秒ごとに編集タイムスタンプを収集（chillout.batch使用）
2. 休止パターンを分析（100ms〜5000msの休止 = 「考える休止」）
3. 中央値を計算（外れ値に強い）
4. 中央値の80%をintervalに（休止が終わる少し前に区切る）
5. 前の値とブレンド（EMA alpha=0.3）で急激な変化を防止

使い込むほど、あなたのタイピングスタイルに合っていく！

学習したintervalを確認:
```vim
:ChunkUndo interval
" 出力: chunkundo: interval 245ms (learned), base 300ms
```

## chillout.nvim 連携

このプラグインは [chillout.nvim](https://github.com/kako-jun/chillout.nvim) のショーケースとして、3機能すべてを活用:

| 機能 | 用途 |
|------|------|
| **debounce** | タイピング休止検出、maxWaitで強制区切り |
| **throttle** | ステータスライン更新を100msに制限（パフォーマンス向上） |
| **batch** | 3回の休止を収集してタイピングパターンを学習 |

## なぜ "Chunk"?

映画「グーニーズ」のチャンクから命名。うっかり全てを台無しにしてしまう愛すべきキャラクター。石像を壊してしまうチャンクのように、不用意な`u`一発であなたの作業が吹き飛ぶ。このプラグインは編集をチャンク分けして、破滅的ではなく段階的にundoできるようにする。

## デモを試す

```bash
git clone https://github.com/kako-jun/chunkundo.nvim
cd chunkundo.nvim
nvim -u demo/init.lua
```

lazy.nvimやpackerでchillout.nvimをインストール済みなら自動検出します。未インストールなら同じ親ディレクトリにクローンしてください。

## コントリビュート

Issue や PR を歓迎します。

## ライセンス

[MIT](LICENSE)
