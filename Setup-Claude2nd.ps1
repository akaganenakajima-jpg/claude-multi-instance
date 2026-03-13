﻿# Claude Code 2つ目のインスタンス 初回セットアップ
# 管理者権限不要・ユーザー権限で実行可能

Write-Host "ショートカットを作成中..."

# Claude の実行ファイルを探す
$claudeExe = $null

# 1. 実行エイリアスを確認（ワイルドカードで検索）
$aliasDir = "$env:LOCALAPPDATA\Microsoft\WindowsApps"
$alias = Get-ChildItem $aliasDir -Filter "*laude*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($alias) { $claudeExe = $alias.FullName }

# 2. AppX パッケージから探す
if (-not $claudeExe) {
  $pkg = Get-AppxPackage -Name "*Claude*" | Select-Object -First 1
  if (-not $pkg) {
    Write-Error "Claude がインストールされていません。先に Claude をインストールしてください。"
    exit 1
  }
  $claudeExe = Join-Path $pkg.InstallLocation "app\Claude.exe"
}
Write-Host "  -> 実行ファイル: $claudeExe"

$userData       = "$env:APPDATA\Claude2"
$launcherPath   = "$env:APPDATA\Claude2nd-launcher.ps1"
$shortcutPath   = "$env:USERPROFILE\Desktop\Claude 2nd.lnk"

# PS1 ランチャーを作成（UseShellExecute で MSIX 起動コンテキストを正しく設定）
$launcherContent = @"
`$psi = New-Object System.Diagnostics.ProcessStartInfo
`$psi.FileName = "$claudeExe"
`$psi.Arguments = '--user-data-dir="$userData"'
`$psi.UseShellExecute = `$true
[System.Diagnostics.Process]::Start(`$psi) | Out-Null
"@
[System.IO.File]::WriteAllText($launcherPath, $launcherContent, [System.Text.Encoding]::ASCII)
Write-Host "  -> ランチャー作成完了: $launcherPath"

# ショートカット: powershell.exe でランチャーを実行
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath  = "powershell.exe"
$shortcut.Arguments   = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$launcherPath`""
$shortcut.Description = "Claude Code 2nd Instance"
$shortcut.Save()
Write-Host "  -> ショートカット作成完了: $shortcutPath"

# ログイン時の自動更新タスクを登録
Write-Host "自動更新タスクを登録中..."
$scriptPath = "$env:USERPROFILE\Desktop\Update-Claude2nd.ps1"
Copy-Item "$PSScriptRoot\Update-Claude2nd.ps1" $scriptPath -Force

$action   = New-ScheduledTaskAction -Execute "powershell.exe" `
              -Argument "-NonInteractive -WindowStyle Hidden -File `"$scriptPath`""
$trigger  = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName "Update-Claude2nd-Shortcut" `
  -Action $action -Trigger $trigger -Settings $settings -Force | Out-Null
Write-Host "  -> 自動更新タスク登録完了 (ログイン時に自動実行)"

Write-Host ""
Write-Host "セットアップ完了！"
Write-Host "デスクトップの「Claude 2nd」をダブルクリックして起動してください。"
Write-Host "初回はGoogleアカウントへのログインが必要です。"
