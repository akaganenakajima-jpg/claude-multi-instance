# Claude Code 多重起動セットアップ

Claude Code デスクトップアプリ（Windows）を複数ウィンドウで同時起動するためのセットアップスクリプト。

## 仕組み

Claude Code は Electron 製アプリのため、通常はシングルインスタンスロックにより2つ目の起動がブロックされる。
`--user-data-dir` フラグで別プロファイルディレクトリを指定することでこの制限を回避できる。

```
1つ目: %APPDATA%\Claude   （通常起動）
2つ目: %APPDATA%\Claude2  （--user-data-dir で別プロファイル）
```

### バージョン非依存ランチャー方式

Claude は MSIX パッケージのため、実行ファイルは `C:\Program Files\WindowsApps\Claude_<バージョン>\app\Claude.exe`
という**バージョン番号入りのパス**に配置される。ここを直接指すショートカットはアップデートのたびにリンク切れになり消える。

そこでショートカットは `powershell.exe`（絶対に消えないパス）を指し、
起動のたびにランチャースクリプトが `Get-AppxPackage` で最新の Claude.exe を動的に解決する。
**アップデートしても一切壊れない。**

```
Claude 2nd.lnk
  └→ powershell.exe -File %LOCALAPPDATA%\Claude2Launcher\Launch-Claude2nd.ps1
       └→ Get-AppxPackage で現行の Claude.exe を解決して --user-data-dir 付きで起動
```

## セットアップ

PowerShell でセットアップスクリプトを実行する（管理者権限不要）:

```powershell
.\Setup-Claude2nd.ps1
```

以下が自動で行われる:

1. ランチャーを `%LOCALAPPDATA%\Claude2Launcher\` に配置
2. 現行 Claude.exe からアイコンを抽出して保存（アップデート後もアイコンが残る）
3. デスクトップに「Claude 2nd」ショートカットを作成（OneDrive リダイレクト対応）

## 使い方

1. 通常通り Claude Code を起動（1つ目）
2. デスクトップの「Claude 2nd」をダブルクリック（2つ目）
   - 初回のみ Google アカウントへのログインが必要

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

## 変更履歴

- **v2 (2026-07-08)**: バージョン非依存ランチャー方式に変更。アップデートのたびにショートカットが消える問題を根本解決。旧方式（ログオン時のショートカット自動修復タスク）は廃止
- **v1**: `--user-data-dir` 方式の初期実装（ショートカットが Claude.exe を直接参照）
