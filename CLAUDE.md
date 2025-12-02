# chunkundo.nvim 開発者ドキュメント

連続した編集を単一のundoユニットにまとめるNeovimプラグイン。

## コンセプト

「Hey Chunk, calm down!」- 映画『グーニーズ』のチャンクにちなんで命名。チャンクが落ち着く必要があるように、あなたのundo履歴も管理しやすい塊にチャンク化する必要がある。

**重要**: このプラグインはタイピング方法を変更しません。連続した編集を論理的なグループに結合することで、undoの動作を変更します。

## コア機能

| 機能 | API | 説明 |
|------|-----|------|
| Chunk Undo | `require("chunkundo").setup(opts?)` | タイピングの一時停止に基づいて連続編集を単一のundoブロックに結合 |

## オプション

```lua
require("chunkundo").setup({
  enabled = true,           -- 起動時に有効化（デフォルト: true）

  -- 時間ベースのチャンキング
  interval = 300,           -- 新しいundoブロックを開始するまでの一時停止時間ms（デフォルト: 300）
  max_chunk_time = 10000,   -- 連続入力中でも強制的にチャンクを区切る時間ms（デフォルト: 10000）
  auto_adjust = true,       -- タイピングパターンからintervalを自動学習（デフォルト: true）

  -- 文字ベースのチャンキング
  break_on_space = true,    -- スペース・改行でチャンクを区切る（デフォルト: true）
  break_on_punct = false,   -- 句読点(.,?!;:)でチャンクを区切る（デフォルト: false）
})
```

## API

```lua
local chunkundo = require("chunkundo")

-- 基本操作
chunkundo.setup(opts)       -- オプションで初期化
chunkundo.enable()          -- チャンキングを有効化
chunkundo.disable()         -- チャンキングを無効化
chunkundo.toggle()          -- オン/オフを切り替え
chunkundo.is_enabled()      -- booleanを返す
chunkundo.status()          -- 現在の状態を通知

-- Interval調整
chunkundo.get_interval()           -- 設定されたintervalを取得
chunkundo.set_interval(ms)         -- intervalを変更（学習値はリセット）
chunkundo.get_effective_interval() -- 実際に使用中のinterval（学習値または設定値）

-- 自動調整
chunkundo.enable_auto_adjust()     -- 自動学習を有効化
chunkundo.disable_auto_adjust()    -- 自動学習を無効化（設定値に戻る）
chunkundo.is_auto_adjust_enabled() -- 自動学習が有効か

-- ステータスライン
chunkundo.statusline()             -- ステータス文字列を返す
chunkundo.statusline_component     -- lualine用（show/hideを反映）
chunkundo.show_statusline()        -- ステータスライン表示
chunkundo.hide_statusline()        -- ステータスライン非表示
chunkundo.toggle_statusline()      -- 表示/非表示切り替え
```

## コマンド

| コマンド | 説明 |
|----------|------|
| `:ChunkUndo enable` | 有効化 |
| `:ChunkUndo disable` | 無効化 |
| `:ChunkUndo toggle` | 切り替え |
| `:ChunkUndo status` | 現在の状態を表示 |
| `:ChunkUndo show` | ステータスライン表示 |
| `:ChunkUndo hide` | ステータスライン非表示 |
| `:ChunkUndo interval` | 現在のintervalを表示（学習値含む） |
| `:ChunkUndo interval 500` | intervalを500msに設定 |
| `:ChunkUndo auto` | 自動調整の状態を表示 |
| `:ChunkUndo auto on` | 自動調整を有効化 |
| `:ChunkUndo auto off` | 自動調整を無効化 |

## 動作の仕組み

### デフォルトのNeovim Undo動作

```
入力: h-e-l-l-o
Undo: o → l → l → e → h（5回のundo操作！）
```

### chunkundo.nvim使用時

```
入力: hello（300ms一時停止）world
Undo: world → hello（2回のundo操作）

入力: hello world（スペースで区切り）
Undo: world → hello（2回のundo操作）
```

### 内部メカニズム

1. `TextChangedI`イベントでdebounceタイマーをリセット
2. 休止検出（interval経過）で`<C-g>u`を挿入してundoブレークポイントを作成
3. `InsertCharPre`でスペース/句読点を検出して即座に区切り
4. `InsertLeave`でチャンクを確定

```
T=0   'h'を押す → タイマー開始
T=50  'e'を押す → タイマーリセット
T=100 'l'を押す → タイマーリセット
T=150 'l'を押す → タイマーリセット
T=200 'o'を押す → タイマーリセット
（ユーザーが一時停止）
T=500 debounce発火 → <C-g>u挿入（undoブレークポイント）
T=600 'w'を押す → 新しいチャンク開始
```

### 自動学習アルゴリズム

ユーザーのタイピングパターンから最適なintervalを学習:

1. **タイムスタンプ収集**: chillout.batchで5秒ごとに編集タイムスタンプを収集
2. **休止パターン分析**: 100ms〜5000msの休止を「考える休止」として抽出
3. **中央値計算**: 外れ値に強い中央値を使用
4. **interval決定**: 中央値の80%をintervalに（休止が終わる少し前に区切る）
5. **指数移動平均(EMA)**: alpha=0.3で新旧値をブレンド、急激な変化を防止
6. **範囲制限**: 100ms〜2000msにクランプ

```lua
-- 指数移動平均
new_interval = learned_interval * 0.7 + suggested * 0.3
```

## chillout.nvim機能の活用

chillout.nvimの3つの機能をすべて活用:

| 機能 | 用途 | 詳細 |
|------|------|------|
| debounce | チャンク区切り検出 | interval経過で`<C-g>u`挿入。maxWaitで強制区切り |
| throttle | ステータスライン更新 | 100msに1回に制限してパフォーマンス向上 |
| batch | 自動学習 | 5秒ごとにタイムスタンプ収集・パターン分析 |

### debounce + maxWait

```lua
state.debounced_break = chillout.debounce(on_debounce_timeout, config.interval, {
  maxWait = config.max_chunk_time,  -- 10秒で強制区切り
})
```

- **debounce**: 休止検出（interval経過で発火）
- **maxWait**: 連続入力中でも強制的に区切り（巨大チャンク防止）

### throttle

```lua
state.throttled_statusline = chillout.throttle(function()
  -- ステータスライン文字列を更新
end, 100)
```

- 高速タイピング時でも100msに1回だけ更新
- 不要な再計算を防止

### batch

```lua
state.batched_timestamps = chillout.batch(function(timestamps)
  local suggested = analyze_pause_pattern(timestamps)
  -- EMAで学習値を更新
end, 5000)
```

- 5秒間のタイムスタンプを収集
- バッチ処理でパターン分析
- 学習したintervalでdebounceを再作成

## プロジェクト構造

```
chunkundo.nvim/
├── lua/
│   └── chunkundo/
│       └── init.lua    -- コア実装
├── demo/
│   └── init.lua        -- インタラクティブデモ
├── tests/
│   ├── minimal_init.lua
│   └── chunkundo_spec.lua
├── CLAUDE.md           -- このファイル
└── README.md           -- ユーザードキュメント
```

## 依存関係

- [chillout.nvim](https://github.com/kako-jun/chillout.nvim) - debounce/throttle/batch機能

## テスト実行

```bash
# テスト実行（plenary.nvim必須）
nvim --headless -u tests/minimal_init.lua \
  -c "lua require('plenary.busted'); require('plenary.busted').run('tests/chunkundo_spec.lua')"

# 手動デモ
nvim -u demo/init.lua
```

## 設計原則

- 単一責任: undoチャンキングのみを処理
- chillout.nvimの全機能を活用（ショーケースとして機能）
- 自動学習でユーザーに最適化
- 非侵入的: オン/オフの切り替えが可能

## 設計判断の記録

### なぜ`undojoin`ではなく`<C-g>u`か

当初は`undojoin`で編集を結合するアプローチを試みた:

```lua
-- InsertCharPreでundojoinを呼ぶ
pcall(vim.cmd, "undojoin")
```

**問題点**:
- `vim.schedule_wrap`による遅延でrace conditionが発生
- debounceコールバックと次のキー入力のタイミング競合
- 一度結合すると取り消せない

**解決策**: `<C-g>u`（Neovim標準のundoブレークポイント）を使用

```lua
-- 休止検出時に<C-g>u挿入
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-g>u", true, false, true), "n", false)
```

- 「結合する」ではなく「区切る」アプローチ
- Neovim標準機能なので安定
- タイミング問題なし

### なぜスペース/句読点で区切るか

日本語と英語でundo単位が異なる問題:
- 日本語: 変換確定単位（「こんにちは」→ 1undo）
- 英語: 文字単位（「hello」→ 時間ベースで1undo）

英語でも単語ごとにundoできると便利:
- 「hello world」→ スペースで区切り → 「world」「hello」の2undo
- 時間ベースと併用可能

### なぜ自動学習か

**課題**: 固定の`interval = 300ms`は万能ではない
- 高速タイピストは休止が短い（150msとか）
- ゆっくり打つ人は休止が長い（500msとか）
- 同じ人でも集中度で変わる

**解決策**: ユーザーの実際の休止パターンから学習
- 使い込むほど「ちょうどいい」区切りになる
- 指数移動平均で急激な変化を防止
