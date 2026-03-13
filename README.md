# Claude Code 多重起動セットアップ

Claude Code デスクトップアプリを複数ウィンドウで同時起動するためのセットアップスクリプト。
Windows / macOS / Linux に対応。

## 仕組み

Claude Code は Electron 製アプリのため、通常はシングルインスタンスロックにより2つ目の起動がブロックされる。
`--user-data-dir` フラグで別プロファイルディレクトリを指定することでこの制限を回避できる。

```
1つ目: デフォルトのプロファイルディレクトリ  （通常起動）
2つ目: Claude2 という別プロファイルディレクトリ （--user-data-dir で指定）
```

| OS | 1つ目（デフォルト） | 2つ目（別プロファイル） |
|---|---|---|
| Windows | `%APPDATA%\Claude` | `%APPDATA%\Claude2` |
| macOS | `~/Library/Application Support/Claude` | `~/Library/Application Support/Claude2` |
| Linux | `~/.local/share/Claude` | `~/.local/share/Claude2` |

## セットアップ

### Windows

PowerShell でセットアップスクリプトを実行する（管理者権限不要）:

```powershell
.\Setup-Claude2nd.ps1
```

以下が自動で行われる:

1. デスクトップに「Claude 2nd」ショートカットを作成
2. Windows ログイン時にショートカットを自動更新するタスクを登録

### macOS / Linux

```bash
chmod +x setup-claude2nd.sh
./setup-claude2nd.sh
```

以下が自動で行われる:

**macOS**:
1. デスクトップに「Claude 2nd.command」ランチャーを作成
2. `~/Applications/Claude 2nd.app`（AppleScript アプリ）を作成 → Dock に追加可能

**Linux**:
1. `~/.local/share/applications/claude-2nd.desktop` を作成（アプリメニューに表示）
2. デスクトップにも `.desktop` ファイルをコピー
3. systemd ユーザーサービスで Claude 更新時にショートカットを自動修復

## 使い方

1. 通常通り Claude Code を起動（1つ目）
2. 以下の方法で2つ目を起動:
   - **Windows**: デスクトップの「Claude 2nd」をダブルクリック
   - **macOS**: デスクトップの「Claude 2nd.command」をダブルクリック、または Dock の「Claude 2nd」アイコンをクリック
   - **Linux**: デスクトップの「Claude 2nd」アイコンをダブルクリック、またはアプリメニューから起動
   - **共通**: `claude --user-data-dir="<Claude2プロファイルパス>"` をターミナルで実行
3. 初回のみ Google アカウントへのログインが必要

## アップデート後の対応

Claude がアップデートされると実行ファイルのパスが変わり、ショートカットが壊れる場合がある。

| OS | 自動修復 | 手動修復 |
|---|---|---|
| Windows | ログイン時にタスクスケジューラが自動実行 | `Update-Claude2nd.ps1` をダブルクリック |
| macOS | なし（手動のみ） | `./update-claude2nd.sh` を実行 |
| Linux | systemd path ユニットで Claude 更新を検知して自動実行 | `update-claude2nd.sh` を実行 |

## 並列運用のコツ

| ウィンドウ | 用途 |
|---|---|
| 1つ目 | 調査・設計・コードレビューなど読み中心のタスク |
| 2つ目 | 実装・テスト実行など書き中心のタスク |

git worktree で作業ディレクトリを分けると競合リスクを最小化できる:

```bash
git worktree add -b feature/task-b ../repo-agent-b main
```

## 注意事項

- 同じファイルを両ウィンドウで同時編集しない
- 同一アカウントで2セッション同時使用のため、API レート制限に引っかかる可能性がある
- MCP ツール（ファイル操作・プロセス操作系）は両ウィンドウから同時に使うと干渉する場合がある
