# 宣伝計画

## 作業手順

### Phase 1: ツール準備
- [ ] vhs (charmbracelet/vhs) をインストール
- [ ] screenkey をインストール（キー表示用）

### Phase 2: 素材準備
- [ ] デモスクリプトを作成（demo.tape）
  - シナリオ1: 問題編 - chunkundo無効で長文入力→undoで全部消える
  - シナリオ2: 解決編 - chunkundo有効で段階的にundo
- [ ] screenkey を起動した状態で vhs 実行
- [ ] 横長GIF生成（GitHub README用）
- [ ] 横長MP4生成（Zenn/X用）
- [ ] 縦長動画生成（Instagram Reels用、余裕があれば）

### Phase 3: GitHub README更新
- [ ] assets/demo.gif を差し替え
- [ ] コミット＆プッシュ

### Phase 4: Zenn記事（メイン）
- [ ] 記事を執筆
  - タイトル案:「Neovimでundoしたら全部消えた問題を解決するプラグインを作った」
  - 技術詳細＋体験談
  - 動画/GIFを埋め込む
- [ ] 投稿（余裕のある日に）

### Phase 5: 他プラットフォーム
- [ ] Qiita: 短い紹介＋Zennへのリンク
- [ ] Note: Zennと同じか体験談寄りにアレンジ
- [ ] X: Zenn記事の紹介（GIF付き、#Neovim #Vim）
- [ ] Instagram: Reels に動画投稿（余裕があれば）

### Phase 6: Reddit
- [ ] r/neovim 投稿文を準備
  - タイトル: "chunkundo.nvim - Break insert sessions into smaller undo chunks"
  - 問題/解決の形式
- [ ] 投稿（英語圏の朝〜昼 = 日本の夜〜深夜）

---

## ツール

### vhs (charmbracelet/vhs)
ターミナル操作を自動化して録画するツール。

```bash
# インストール (Arch)
yay -S vhs

# 実行
vhs demo.tape
```

### screenkey
押したキーを画面下にオーバーレイ表示。

```bash
# インストール (Arch)
sudo pacman -S screenkey

# 起動（vhs実行前に）
screenkey &
```

---

## vhs スクリプト例

```tape
# demo.tape
Output assets/demo.gif
Set FontSize 18
Set Width 800
Set Height 600

# 問題編: chunkundo無効
Type "nvim"
Enter
Sleep 500ms
Type ":ChunkUndo disable"
Enter
Sleep 500ms
Type "i"
Type "function hello()" Sleep 100ms
Enter
Type "  print('world')" Sleep 100ms
Enter
Type "end"
Escape
Sleep 500ms
Type "u"
Sleep 1s
# 全部消える

# 解決編: chunkundo有効
Type ":ChunkUndo enable"
Enter
Sleep 500ms
Type "i"
Type "function hello()" Sleep 100ms
Enter
Type "  print('world')" Sleep 100ms
Enter
Type "end"
Escape
Sleep 500ms
Type "u"
Sleep 500ms
# endだけ消える
Type "u"
Sleep 500ms
# print行だけ消える
Type "u"
Sleep 1s
# function行だけ消える
```

---

## 動画フォーマット

| 用途 | サイズ | フォーマット |
|------|--------|-------------|
| GitHub README | 横長 800x600 | GIF |
| Zenn/Note/X | 横長 | MP4 or GIF |
| Instagram Reels | 縦長 1080x1920 | MP4 |

---

## コンテンツ案

### Zenn記事（メイン）
- トーン: 技術詳細＋体験談
- 内容:
  - 問題: Neovimのデフォルトundo動作
  - 解決: chunkundo.nvim の紹介
  - 機能: 時間ベース、単語ベース、自動学習
  - インストール方法
  - 設定例
  - CJKサポート（日本語句読点対応）
- 動画/GIFを埋め込む

### Qiita
```
# Neovimでundoしたら全部消える問題を解決した

詳しくはZennに書きました。

https://zenn.dev/xxx/articles/yyy

簡単に言うと、タイピングの休止や単語境界で自動的にundo単位を分割するプラグインです。
```

### Note
- Zennと同じ内容、または体験談寄りにアレンジ
- 「小説を書いていて...」のような導入も可

### X投稿
```
Neovimでundoしたら全部消えた経験ありませんか？

chunkundo.nvim作りました。
タイピングの休止で自動的にundo単位を分割。
日本語の句読点にも対応。

[GIF]

詳しくはZennで→ [URL]

#Neovim #Vim
```

### Reddit投稿
```
Title: chunkundo.nvim - Break insert sessions into smaller undo chunks

By default, Neovim treats an entire insert session as one undo unit.
Type many lines, press u → everything disappears.

chunkundo.nvim breaks your insert session by:
- Time (pause = new undo block)
- Word boundaries (space/punctuation)
- Auto-learns your typing pattern
- CJK support (Japanese/Chinese punctuation)

GitHub: https://github.com/kako-jun/chunkundo.nvim

[GIF]
```

---

## タイミング
- レスできる余裕がある日に投稿（週末推奨）
- 投稿後数時間が重要
- Reddit: 英語圏の朝〜昼（日本の夜〜深夜）が効果的

---

## 素材チェックリスト
- [ ] demo.tape（vhsスクリプト）
- [ ] assets/demo.gif（横長、キー表示付き）
- [ ] assets/demo.mp4（横長、キー表示付き）
- [ ] assets/demo-vertical.mp4（縦長、余裕があれば）
