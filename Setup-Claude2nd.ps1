# Claude Code 2つ目のインスタンス セットアップ（バージョン非依存ランチャー方式）
# 管理者権限不要・ユーザー権限で実行可能

# 1. ランチャーを恒久ディレクトリに配置
$dir = "$env:LOCALAPPDATA\Claude2Launcher"
New-Item -ItemType Directory -Force $dir | Out-Null
Copy-Item "$PSScriptRoot\Launch-Claude2nd.ps1" "$dir\Launch-Claude2nd.ps1" -Force
Write-Host "ランチャー配置完了: $dir\Launch-Claude2nd.ps1"

# 2. 現行 Claude.exe からアイコンを抽出して恒久保存
$pkg = Get-AppxPackage -Name "*Claude*" | Select-Object -First 1
if (-not $pkg) {
  Write-Error "Claude がインストールされていません。先に Claude をインストールしてください。"
  exit 1
}
$exe = Join-Path $pkg.InstallLocation "app\Claude.exe"
Add-Type -AssemblyName System.Drawing
$icon = [System.Drawing.Icon]::ExtractAssociatedIcon($exe)
$fs = [System.IO.File]::Create("$dir\claude2.ico")
$icon.Save($fs)
$fs.Close()
Write-Host "アイコン抽出完了: $dir\claude2.ico"

# 3. デスクトップにショートカット作成
#    ターゲットは powershell.exe（絶対に消えないパス）なのでアップデートで壊れない
$desktop = [Environment]::GetFolderPath('Desktop')  # OneDrive リダイレクト対応
$shell = New-Object -ComObject WScript.Shell
$sc = $shell.CreateShortcut("$desktop\Claude 2nd.lnk")
$sc.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$sc.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$dir\Launch-Claude2nd.ps1`""
$sc.IconLocation = "$dir\claude2.ico,0"
$sc.WindowStyle = 7
$sc.Description = "Claude Code 2nd Instance (バージョン非依存ランチャー)"
$sc.Save()

Write-Host ""
Write-Host "セットアップ完了！ (現行バージョン: v$($pkg.Version))"
Write-Host "デスクトップの「Claude 2nd」をダブルクリックして起動してください。"
Write-Host "初回はGoogleアカウントへのログインが必要です。"
