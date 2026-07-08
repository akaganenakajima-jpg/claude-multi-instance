# Claude Code 2nd インスタンス起動ランチャー
# 起動のたびに最新バージョンの Claude.exe を解決するため、アップデートしても壊れない
$pkg = Get-AppxPackage -Name "*Claude*" | Select-Object -First 1
if (-not $pkg) {
  Add-Type -AssemblyName System.Windows.Forms
  [System.Windows.Forms.MessageBox]::Show("Claude がインストールされていません")
  exit 1
}

$exe = Join-Path $pkg.InstallLocation "app\Claude.exe"
if (-not (Test-Path $exe)) {
  Add-Type -AssemblyName System.Windows.Forms
  [System.Windows.Forms.MessageBox]::Show("Claude.exe が見つかりません: $exe")
  exit 1
}

Start-Process $exe -ArgumentList "--user-data-dir=`"$env:APPDATA\Claude2`""
