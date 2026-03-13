﻿# Claude Code 2つ目のインスタンス 初回セットアップ
# 管理者権限不要・ユーザー権限で実行可能

Write-Host "ショートカットを作成中..."

# Claude AppX パッケージ情報を取得
$pkg = Get-AppxPackage -Name "*Claude*" | Select-Object -First 1
if (-not $pkg) {
  Write-Error "Claude がインストールされていません。先に Claude をインストールしてください。"
  exit 1
}

# AppxManifest から AppId を取得して AUMID を構築
$manifestPath = Join-Path $pkg.InstallLocation "AppxManifest.xml"
[xml]$manifest = Get-Content $manifestPath
$appId = $manifest.Package.Applications.Application.Id
$aumid = "$($pkg.PackageFamilyName)!$appId"
Write-Host "  -> AUMID: $aumid"

$userData     = "$env:APPDATA\Claude2"
$launcherPath = "$env:APPDATA\Claude2nd-launcher.ps1"
$shortcutPath = "$env:USERPROFILE\Desktop\Claude 2nd.lnk"

# PS1 ランチャーを作成（IApplicationActivationManager 経由で MSIX を引数付き起動）
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
public class ApplicationActivationManager {}
"@ -ErrorAction SilentlyContinue

PLACEHOLDER_AUMID
PLACEHOLDER_USERDATA

$mgr = [Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]"45BA127D-10A8-46EA-8AB7-56EA9078943C")) -as [IApplicationActivationManager]
$pid = [uint32]0
$mgr.ActivateApplication($aumid, "--user-data-dir=`"$userData`"", 0, [ref]$pid)
'@

$launcherContent = $launcherContent `
  -replace 'PLACEHOLDER_AUMID',   "`$aumid = '$aumid'" `
  -replace 'PLACEHOLDER_USERDATA', "`$userData = `"$userData`""

[System.IO.File]::WriteAllText($launcherPath, $launcherContent, [System.Text.Encoding]::ASCII)
Write-Host "  -> ランチャー作成完了: $launcherPath"

# ショートカット: powershell.exe でランチャーを実行
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath  = "powershell.exe"
$shortcut.Arguments   = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$launcherPath`""
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
