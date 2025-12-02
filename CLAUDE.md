# chunkundo.nvim 開発者ドキュメント

時間ベースのチャンキングを使用して、連続した編集を単一のundoユニットにまとめるNeovimプラグイン。

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
  interval = 300,   -- 新しいundoブロックを開始するまでの一時停止時間（ミリ秒）（デフォルト: 300）
  enabled = true,   -- 起動時に有効化（デフォルト: true）
})
```

## API

```lua
local chunkundo = require("chunkundo")

chunkundo.setup(opts)   -- オプションで初期化
chunkundo.enable()      -- チャンキングを有効化
chunkundo.disable()     -- チャンキングを無効化（通常のundo動作）
chunkundo.toggle()      -- オン/オフを切り替え
chunkundo.is_enabled()  -- booleanを返す
```

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
```

### 内部メカニズム

1. `TextChangedI`イベントで`undojoin`を呼び出し、前の編集とマージ
2. `chillout.debounce`を使用してタイピングの一時停止を検出
3. 一時停止を検出したら（デフォルト: 300ms）、結合を停止
4. 次の編集で新しいundoブロックを開始

```
T=0   'h'を押す → undojoin（チャンク開始）
T=50  'e'を押す → undojoin（チャンク継続）
T=100 'l'を押す → undojoin（チャンク継続）
T=150 'l'を押す → undojoin（チャンク継続）
T=200 'o'を押す → undojoin（チャンク継続）
（ユーザーが一時停止）
T=500 debounce発火 → チャンク終了
T=600 'w'を押す → undojoin（新しいチャンク開始）
...
```

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

- [chillout.nvim](https://github.com/kako-jun/chillout.nvim) - debounce機能用

## テスト実行

```bash
# テスト実行（plenary.nvim必須）
nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

# 手動デモ
nvim -u demo/init.lua
```

## 実装ノート

- 編集をマージするために`vim.cmd("undojoin")`を使用
- エッジケースを処理するためにundojoinをpcallでラップ
- Autocommands: 編集検出用の`TextChangedI`、チャンク終了用の`InsertLeave`
- chillout.nvimのdebounceによるタイマー管理

## 設計原則

- 単一責任: undoチャンキングのみを処理
- タイミングロジックはchillout.nvimに依存
- 最小限の設定（intervalのみ）
- 非侵入的: オン/オフの切り替えが可能

## 将来の機能追加案

### 課題: 固定intervalの限界

固定の`interval = 300ms`は万能ではない:
- コード作成時: 考えながら書くので短い停止が多い → 長めのintervalが良い
- 文章作成時: 流れるように書く → 短めのintervalで細かくチャンク
- 修正作業時: 細かい編集が断続的 → 長めのintervalが良い

**暴発（意図しない単位でのundo）は悪印象に直結するため、ユーザーが簡単に調整できる仕組みが必要。**

### 案1: リアルタイム調整API（優先度: 高）

```lua
chunkundo.set_interval(n)  -- intervalを動的に変更
chunkundo.get_interval()   -- 現在のintervalを取得

-- キーマップ例
vim.keymap.set("n", "<leader>u+", function()
  local new = chunkundo.get_interval() + 100
  chunkundo.set_interval(new)
  vim.notify("chunkundo interval: " .. new .. "ms")
end)
vim.keymap.set("n", "<leader>u-", function()
  local new = math.max(100, chunkundo.get_interval() - 100)
  chunkundo.set_interval(new)
  vim.notify("chunkundo interval: " .. new .. "ms")
end)
```

### 案2: プリセットモード（優先度: 中）

```lua
chunkundo.mode("code")   -- interval = 500（考えながら書く）
chunkundo.mode("prose")  -- interval = 200（流れるように書く）
chunkundo.mode("edit")   -- interval = 1000（細かい修正）

-- setup時にプリセットをカスタマイズ可能
setup({
  modes = {
    code = 500,
    prose = 200,
    edit = 1000,
  }
})
```

### 案3: ファイルタイプ別デフォルト（優先度: 中）

```lua
setup({
  interval = 300,
  ft_intervals = {
    markdown = 200,   -- 文章は細かく
    lua = 400,        -- コードは粗く
    python = 400,
    text = 200,
  }
})
```

### 案4: 自動学習（優先度: 低 / 要検討）

DQ4のAIのように、undo→redo パターンを検出して自動調整する案。

```
undo → redo → undo の検出
↓
「ユーザーは今のundo単位に不満」と解釈
↓
intervalを自動調整
```

**懸念点:**
- undo→redoは「戻しすぎた」なのか「間違えてundo押した」なのか区別困難
- 学習データが溜まるまで時間がかかる
- ユーザーの意図推測は暴発の原因になりやすい
- 「賢そうに見えて暴発する」リスク

**結論:** まず案1〜3を実装してユーザーフィードバックを収集し、自動化の需要があれば検討。

### 実装優先順位

1. **案1（リアルタイム調整）**: 最小限の実装で即座に不満解消可能
2. **案3（ファイルタイプ別）**: setup時の設定だけで多くのケースをカバー
3. **案2（プリセット）**: ユーザーが意識的に切り替える必要があり、やや面倒
4. **案4（自動学習）**: リスクが高いため慎重に検討

## chillout.nvim機能の活用案

chillout.nvimは3つの機能を提供している。これらを最大限活用する:

| 機能 | 説明 | 現状 |
|------|------|------|
| debounce | 入力停止後N ms経過で実行 | チャンク区切り検出に使用中 |
| throttle | N msに最大1回だけ実行 | 未使用 |
| batch | 複数呼び出しをまとめて処理 | 未使用 |

### 案5: throttleを使ったステータス表示（優先度: 高）

interval調整時やチャンク状態をステータスラインに表示。throttleで更新頻度を制限:

```lua
local chillout = require("chillout")

-- 100msに1回だけステータス更新（高頻度の再描画を防止）
local update_status = chillout.throttle(function(info)
  -- lualineやステータスライン用のデータを更新
  M.status = {
    enabled = info.enabled,
    interval = info.interval,
    chunk_count = info.chunk_count,  -- 現在のセッションでのチャンク数
  }
end, 100)

-- API: ステータスライン連携
function M.statusline()
  if not M.status.enabled then return "[undo: off]" end
  return string.format("[undo: %dms]", M.status.interval)
end
```

### 案6: batchを使った編集パターン分析（優先度: 中）

undo/redoイベントをバッチ収集して分析。自動学習の基盤:

```lua
local chillout = require("chillout")

-- 5秒間のundo/redoイベントをバッチ収集
local analyze_undo_pattern = chillout.batch(function(events)
  -- events = { {"undo", timestamp}, {"redo", timestamp}, {"undo", timestamp}, ... }

  local undo_redo_pairs = 0
  for i = 2, #events do
    if events[i-1][1] == "undo" and events[i][1] == "redo" then
      undo_redo_pairs = undo_redo_pairs + 1
    end
  end

  -- undo→redoが多い = チャンクが大きすぎる可能性
  if undo_redo_pairs >= 3 then
    vim.notify("Hint: intervalを短くすると細かくundoできます", vim.log.levels.INFO)
  end
end, 5000)

-- undo/redo時にイベント収集
vim.api.nvim_create_autocmd("User", {
  pattern = { "UndoPost", "RedoPost" },  -- 要確認: 実際のイベント名
  callback = function(ev)
    analyze_undo_pattern(ev.match, vim.uv.now())
  end,
})
```

### 案7: debounce + throttleの組み合わせ（優先度: 中）

タイピング速度に応じてintervalを動的調整:

```lua
local chillout = require("chillout")

-- タイピング速度計測（throttleで100msごとにサンプリング）
local keystrokes = 0
local sample_speed = chillout.throttle(function()
  local speed = keystrokes * 10  -- keys per second (100ms * 10 = 1sec)
  keystrokes = 0

  -- 速いタイピング → 短いinterval（流れるように書いている）
  -- 遅いタイピング → 長いinterval（考えながら書いている）
  if speed > 50 then
    M.set_interval(200)  -- 高速タイピング
  elseif speed < 10 then
    M.set_interval(500)  -- 低速タイピング
  end
end, 100)

-- InsertCharPreでキーストローク計測
vim.api.nvim_create_autocmd("InsertCharPre", {
  callback = function()
    keystrokes = keystrokes + 1
    sample_speed()
  end,
})
```

### chillout.nvim活用まとめ

| 案 | 使用機能 | 目的 |
|----|----------|------|
| 現状 | debounce | チャンク区切り検出 |
| 案5 | throttle | ステータス表示の更新制限 |
| 案6 | batch | undo/redoパターン収集・分析 |
| 案7 | debounce + throttle | タイピング速度による動的調整 |

**設計思想:** chillout.nvimの全機能を活用することで、chunkundo.nvimはchillout.nvimの「ショーケース」としても機能する。
