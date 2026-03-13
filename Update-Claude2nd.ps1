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

$userData = "$env:APPDATA\Claude2"
$vbsPath  = "$env:APPDATA\Claude2nd-launcher.vbs"

$vbsContent = "CreateObject(""WScript.Shell"").Run Chr(34) & """ + $claudeExe + """ & Chr(34) & "" --user-data-dir="" & Chr(34) & """ + $userData + """ & Chr(34), 0, False"
Set-Content -Path $vbsPath -Value $vbsContent -Encoding UTF8

Write-Host "更新完了: $claudeExe"
