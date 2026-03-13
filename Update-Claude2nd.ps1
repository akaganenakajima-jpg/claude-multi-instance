﻿# Claude 2nd ショートカットを最新バージョンに自動更新

$claudeExe = $null

$aliasDir = "$env:LOCALAPPDATA\Microsoft\WindowsApps"
$alias = Get-ChildItem $aliasDir -Filter "*laude*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($alias) { $claudeExe = $alias.FullName }

if (-not $claudeExe) {
  $pkg = Get-AppxPackage -Name "*Claude*" | Select-Object -First 1
  if (-not $pkg) {
    Write-Error "Claude がインストールされていません"
    exit 1
  }
  $claudeExe = Join-Path $pkg.InstallLocation "app\Claude.exe"
}

$userData     = "$env:APPDATA\Claude2"
$launcherPath = "$env:APPDATA\Claude2nd-launcher.ps1"

$launcherContent = @"
`$psi = New-Object System.Diagnostics.ProcessStartInfo
`$psi.FileName = "$claudeExe"
`$psi.Arguments = '--user-data-dir="$userData"'
`$psi.UseShellExecute = `$true
[System.Diagnostics.Process]::Start(`$psi) | Out-Null
"@
[System.IO.File]::WriteAllText($launcherPath, $launcherContent, [System.Text.Encoding]::ASCII)

Write-Host "更新完了: $claudeExe"
