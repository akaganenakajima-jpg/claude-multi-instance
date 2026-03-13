﻿# Claude 2nd ショートカットを最新バージョンに自動更新

$pkg = Get-AppxPackage -Name "*Claude*" | Select-Object -First 1
if (-not $pkg) { Write-Error "Claude がインストールされていません"; exit 1 }

$manifestPath = Join-Path $pkg.InstallLocation "AppxManifest.xml"
[xml]$manifest = Get-Content $manifestPath
$appId = $manifest.Package.Applications.Application.Id
$aumid = "$($pkg.PackageFamilyName)!$appId"

$userData     = "$env:APPDATA\Claude2"
$launcherPath = "$env:APPDATA\Claude2nd-launcher.ps1"

$launcherContent = @'
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
[ComImport, Guid("2e941141-7f97-4756-ba1d-9decde894a3d"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IApplicationActivationManager {
    int ActivateApplication([MarshalAs(UnmanagedType.LPWStr)] string appUserModelId,
                            [MarshalAs(UnmanagedType.LPWStr)] string arguments,
                            int options, out uint processId);
    int ActivateForFile([MarshalAs(UnmanagedType.LPWStr)] string appUserModelId,
                        IntPtr pItemArray, [MarshalAs(UnmanagedType.LPWStr)] string verb,
                        out uint processId);
    int ActivateForProtocol([MarshalAs(UnmanagedType.LPWStr)] string appUserModelId,
                            IntPtr pItemArray, out uint processId);
}
[ComImport, Guid("45BA127D-10A8-46EA-8AB7-56EA9078943C")]
public class ApplicationActivationManagerClass {}
public static class AppLauncher {
    public static void Launch(string aumid, string args) {
        var mgr = new ApplicationActivationManagerClass() as IApplicationActivationManager;
        uint pid;
        mgr.ActivateApplication(aumid, args, 0, out pid);
    }
}
"@

PLACEHOLDER_AUMID
PLACEHOLDER_USERDATA

[AppLauncher]::Launch($aumid, "--user-data-dir=`"$userData`"")
'@

$launcherContent = $launcherContent `
  -replace 'PLACEHOLDER_AUMID',    "`$aumid = '$aumid'" `
  -replace 'PLACEHOLDER_USERDATA', "`$userData = `"$userData`""

[System.IO.File]::WriteAllText($launcherPath, $launcherContent, [System.Text.Encoding]::ASCII)
Write-Host "更新完了: $aumid"
