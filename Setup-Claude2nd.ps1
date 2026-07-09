# Claude Code 2nd instance setup (version-independent launcher method).
# No admin rights required.
# ASCII only on purpose: Windows PowerShell 5.1 misreads UTF-8 files without BOM,
# so non-ASCII comments/strings can silently corrupt the script when run via
# right-click "Run with PowerShell".

# 1. Install the launcher into a permanent directory
$dir = "$env:LOCALAPPDATA\Claude2Launcher"
New-Item -ItemType Directory -Force $dir | Out-Null
Copy-Item "$PSScriptRoot\Launch-Claude2nd.ps1" "$dir\Launch-Claude2nd.ps1" -Force
Write-Host "Launcher installed: $dir\Launch-Claude2nd.ps1"

# 2. Extract the icon from the current Claude.exe and keep a permanent copy
$pkg = Get-AppxPackage -Name '*Claude*' | Select-Object -First 1
if (-not $pkg) {
  Write-Error 'Claude is not installed. Install the Claude desktop app first.'
  exit 1
}
$exe = Join-Path $pkg.InstallLocation 'app\Claude.exe'
Add-Type -AssemblyName System.Drawing
$icon = [System.Drawing.Icon]::ExtractAssociatedIcon($exe)
$fs = [System.IO.File]::Create("$dir\claude2.ico")
$icon.Save($fs)
$fs.Close()
Write-Host "Icon extracted: $dir\claude2.ico"

# 3. Create the desktop shortcut.
#    Target is powershell.exe (a path that never disappears), so app updates
#    cannot break the shortcut.
$desktop = [Environment]::GetFolderPath('Desktop')  # OneDrive redirection safe
$shell = New-Object -ComObject WScript.Shell
$sc = $shell.CreateShortcut("$desktop\Claude 2nd.lnk")
$sc.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$sc.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$dir\Launch-Claude2nd.ps1`""
$sc.IconLocation = "$dir\claude2.ico,0"
$sc.WindowStyle = 7
$sc.Description = 'Claude Code 2nd Instance (version-independent launcher)'
$sc.Save()

Write-Host ''
Write-Host "Setup complete! (current version: v$($pkg.Version))"
Write-Host 'Double-click "Claude 2nd" on the desktop to launch.'
Write-Host 'A Google account sign-in is required on first launch only.'
