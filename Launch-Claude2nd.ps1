# Claude Code 2nd instance launcher.
# Resolves the current Claude.exe at launch time, so app updates never break this shortcut.
# ASCII only on purpose: Windows PowerShell 5.1 misreads UTF-8 files without BOM
# (Japanese comments caused a swallowed-newline parse bug that commented out real code).

$ErrorActionPreference = 'Stop'

function Show-LauncherError([string]$Message) {
  Add-Type -AssemblyName System.Windows.Forms
  [void][System.Windows.Forms.MessageBox]::Show($Message, 'Claude 2nd Launcher')
}

# Primary: Appx cmdlet
$exe = $null
try {
  $pkg = Get-AppxPackage -Name '*Claude*' -ErrorAction Stop | Select-Object -First 1
  if ($pkg) { $exe = Join-Path $pkg.InstallLocation 'app\Claude.exe' }
} catch { }

# Fallback: user-readable package registry (works even if the Appx module fails)
if (-not $exe -or -not (Test-Path $exe)) {
  $repo = 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\Repository\Packages'
  $key = Get-ChildItem $repo -ErrorAction SilentlyContinue |
    Where-Object { $_.PSChildName -like 'Claude_*' } |
    Select-Object -First 1
  if ($key) {
    $root = (Get-ItemProperty $key.PSPath -ErrorAction SilentlyContinue).PackageRootFolder
    if ($root) { $exe = Join-Path $root 'app\Claude.exe' }
  }
}

if (-not $exe -or -not (Test-Path $exe)) {
  Show-LauncherError 'Claude installation not found. Is the Claude desktop app installed?'
  exit 1
}

Start-Process $exe -ArgumentList "--user-data-dir=`"$env:APPDATA\Claude2`""
