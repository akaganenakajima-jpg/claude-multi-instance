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

$userData     = "$env:APPDATA\Claude2"
$vbsPath      = "$env:APPDATA\Claude2nd-launcher.vbs"
$shortcutPath = "$env:USERPROFILE\Desktop\Claude 2nd.lnk"

# VBScript ランチャーを作成（コンソールウィンドウなしで起動するため）
$vbsContent = "CreateObject(""WScript.Shell"").Run Chr(34) & """ + $claudeExe + """ & Chr(34) & "" --user-data-dir="" & Chr(34) & """ + $userData + """ & Chr(34), 0, False"
[System.IO.File]::WriteAllText($vbsPath, $vbsContent, [System.Text.Encoding]::ASCII)
Write-Host "  -> ランチャー作成完了: $vbsPath"

# ショートカット: wscript.exe でランチャーを実行
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath  = "wscript.exe"
$shortcut.Arguments   = "`"$vbsPath`""
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
