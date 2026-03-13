# Claude 2nd ショートカットを最新バージョンに自動更新

# WindowsApps 内の exe は直接実行不可のため、実行エイリアスを優先して使用
$claudeExe = $null
$aliasPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps\claude.exe"
if (Test-Path $aliasPath) {
  $claudeExe = $aliasPath
} else {
  $pkg = Get-AppxPackage -Name "*Claude*" | Select-Object -First 1
  if (-not $pkg) {
    Write-Error "Claude がインストールされていません"
    exit 1
  }
  $claudeExe = Join-Path $pkg.InstallLocation "app\Claude.exe"
  if (-not (Test-Path $claudeExe)) {
    Write-Error "実行ファイルが見つかりません: $claudeExe"
    exit 1
  }
}

$userData = "$env:APPDATA\Claude2"
$shortcutPath = "$env:USERPROFILE\Desktop\Claude 2nd.lnk"

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $claudeExe
$shortcut.Arguments = "--user-data-dir=`"$userData`""
$shortcut.Description = "Claude Code 2nd Instance"
$shortcut.Save()

Write-Host "更新完了: $shortcutPath"
