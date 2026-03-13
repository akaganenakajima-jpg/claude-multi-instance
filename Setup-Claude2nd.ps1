# Claude Code 2つ目のインスタンス 初回セットアップ
# 管理者権限不要・ユーザー権限で実行可能

# 1. ショートカット作成
Write-Host "ショートカットを作成中..."
$pkg = Get-AppxPackage -Name "*Claude*" | Select-Object -First 1
if (-not $pkg) {
  Write-Error "Claude がインストールされていません。先に Claude をインストールしてください。"
  exit 1
}

$claudeExe = Join-Path $pkg.InstallLocation "app\Claude.exe"
$userData = "$env:USERPROFILE\AppData\Roaming\Claude2"
$shortcutPath = "$env:USERPROFILE\Desktop\Claude 2nd.lnk"

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $claudeExe
$shortcut.Arguments = "--user-data-dir=`"$userData`""
$shortcut.Description = "Claude Code 2nd Instance"
$shortcut.Save()
Write-Host "  -> ショートカット作成完了: $shortcutPath"

# 2. ログイン時の自動更新タスクを登録
Write-Host "自動更新タスクを登録中..."
$scriptPath = "$env:USERPROFILE\Desktop\Update-Claude2nd.ps1"
Copy-Item "$PSScriptRoot\Update-Claude2nd.ps1" $scriptPath -Force

$action = New-ScheduledTaskAction -Execute "powershell.exe" `
  -Argument "-NonInteractive -WindowStyle Hidden -File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName "Update-Claude2nd-Shortcut" `
  -Action $action -Trigger $trigger -Settings $settings -Force | Out-Null
Write-Host "  -> 自動更新タスク登録完了 (ログイン時に自動実行)"

Write-Host ""
Write-Host "セットアップ完了！"
Write-Host "デスクトップの「Claude 2nd」をダブルクリックして起動してください。"
Write-Host "初回はGoogleアカウントへのログインが必要です。"
