# Erweitertes PowerShell Noise-Script für TryHackMe
# Generiert eine authentisch aussehende Microsoft PowerShell-Struktur mit viel Noise
# Usage: powershell.exe -ExecutionPolicy Bypass -File .\noise.ps1 [-NumFiles 500] [-Cleanup]

param (
    [int]$NumFiles = 500,
    [switch]$Cleanup
)

$basePath = "$env:APPDATA\Microsoft\Windows\PowerShell"

if ($Cleanup) {
    Remove-Item -Path $basePath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Cleanup abgeschlossen: $basePath entfernt."
    return
}

# Basisordner anlegen
if (-not (Test-Path $basePath)) {
    New-Item -Path $basePath -ItemType Directory -Force | Out-Null
}

# Alle Unterordner (tief und realistisch)
$subFolders = @(
    "PSReadLine", "PSReadLine\Archives", "PSReadLine\Backups", "PSReadLine\Verbose",
    "Modules\Microsoft.PowerShell.Core\5.1\Types", "Modules\Microsoft.PowerShell.Core\5.1\Formats", "Modules\Microsoft.PowerShell.Core\7.4",
    "Modules\Microsoft.PowerShell.Utility\7.0\NestedModules", "Modules\Microsoft.PowerShell.Utility\7.4",
    "Modules\CimCmdlets\5.1", "Modules\CimCmdlets\7.4\Help",
    "Modules\BitsTransfer\7.4", "Modules\Microsoft.WSMan.Management\7.4",
    "Scripts\Utilities", "Scripts\Profiles", "Scripts\Logs\Error", "Scripts\Logs\Warning", "Scripts\Logs\Info", "Scripts\Archives",
    "Cache\ModuleCache", "Cache\CommandCache",
    "Configs\Settings", "Configs\Dependencies",
    "Temp", "Backups", "Extensions\Debuggers", "Help\Languages\en-US", "Telemetry\Logs"
)

# Ordner erstellen und teilweise verstecken
foreach ($sub in $subFolders) {
    $fullPath = Join-Path $basePath $sub
    New-Item -Path $fullPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

    if ((Get-Random -Maximum 100) -lt 30) {
        $item = Get-Item $fullPath -ErrorAction SilentlyContinue
        if ($item -and $item.PSObject.Properties['Attributes']) {
            try { $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::Hidden } catch {}
        }
    }
}

# Templates für authentische Inhalte
$historyTemplate = @(
    "Get-Date -Format 'yyyy-MM-dd'", "Import-Module Microsoft.PowerShell.Utility",
    "Get-Process | Select Name, Id", "Get-Service", "Get-CimInstance Win32_OperatingSystem",
    "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser", "Update-Help -ErrorAction SilentlyContinue"
)

$profileTemplate = @"
# Microsoft PowerShell Profile
# Copyright (c) Microsoft Corporation
`$ErrorActionPreference = 'Continue'
function Prompt {
    "PS `$PWD> "
}
Import-Module CimCmdlets -ErrorAction SilentlyContinue
Write-Host "PowerShell `$(`$PSVersionTable.PSVersion) ready." -ForegroundColor Green
"@

$moduleTemplate = @"
# Microsoft-like Module
# Copyright (c) Microsoft Corporation
function Get-ExampleData {
    param([int]`$Count = 10)
    1..`$Count | ForEach-Object { [PSCustomObject]@{Index=`$_; Value=`$_*2} }
}
Export-ModuleMember -Function Get-ExampleData
"@

$manifestTemplate = @"
@{
    ModuleVersion = '7.4.0'
    GUID = '$(New-Guid)'
    Author = 'Microsoft Corporation'
    CompanyName = 'Microsoft'
    Copyright = '(c) Microsoft Corporation. All rights reserved.'
    FunctionsToExport = @('Get-ExampleData')
    RequiredModules = @('Microsoft.PowerShell.Core')
}
"@

$logEntry = "[{0}] {1}: {2}"

$miscTemplate = "Temporary cache data - $(New-Guid)`nGenerated on $(Get-Date -Format o)"

# Funktion: Datei in einem bestimmten Ordner erstellen (typabhängig)
function New-NoiseFile {
    param(
        [string]$SubPath,
        [string]$IndexSuffix
    )

    $fullSub = Join-Path $basePath $SubPath
    $rand = Get-Random -Minimum 1 -Maximum 8

    if ($SubPath -like "*Logs*" -or $SubPath -like "*Telemetry*") { $rand = 5 }
    elseif ($SubPath -like "*Modules*") { $rand = Get-Random -InputObject 3,4 }
    elseif ($SubPath -like "*Configs*") { $rand = 6 }
    elseif ($SubPath -like "*PSReadLine*") { $rand = 1 }
    elseif ($SubPath -like "*Scripts*") { $rand = Get-Random -InputObject 2,5 }

    switch ($rand) {
        1 { $file = "$fullSub\History_$IndexSuffix.txt";          $content = ($historyTemplate | Get-Random -Count (Get-Random -Min 15 -Max 40)) -join "`n" }
        2 { $file = "$fullSub\Profile_$IndexSuffix.ps1";          $content = $profileTemplate + "`n# Custom $IndexSuffix" }
        3 { $file = "$fullSub\Module_$IndexSuffix.psm1";          $content = $moduleTemplate }
        4 { $file = "$fullSub\Manifest_$IndexSuffix.psd1";        $content = $manifestTemplate }
        5 { $file = "$fullSub\Log_$IndexSuffix.log";              $content = (1..(Get-Random -Min 30 -Max 80) | ForEach-Object { $logEntry -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), (Get-Random -InputObject "INFO","WARN","ERROR"), "Event $_ in $SubPath" }) -join "`n" }
        6 { $file = "$fullSub\Config_$IndexSuffix.xml";           $content = "<Config><Version>7.4</Version><Enabled>true</Enabled></Config>" }
        default { $file = "$fullSub\Misc_$IndexSuffix.txt";       $content = $miscTemplate }
    }

    if (-not (Test-Path $file)) {
        try {
            Set-Content -Path $file -Value $content -Force -ErrorAction Stop
        } catch { return }
    }

    if (Test-Path $file) {
        $item = Get-Item $file -ErrorAction SilentlyContinue
        if ($item) {
            if ($item.PSObject.Properties['Attributes']) {
                try {
                    if ((Get-Random -Maximum 100) -lt 40) { $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::ReadOnly }
                    if ((Get-Random -Maximum 100) -lt 50) { $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::Hidden }
                } catch {}
            }
            if ($item.PSObject.Properties['LastWriteTime']) {
                try {
                    $item.LastWriteTime = (Get-Date).AddDays(- (Get-Random -Maximum 1825))  # 2020-2025
                } catch {}
            }
        }
    }
}

# 1. Zufällige Haupt-Noise-Dateien
for ($i = 1; $i -le $NumFiles; $i++) {
    $type = Get-Random -Minimum 1 -Maximum 8
    $sub = switch ($type) {
        1 { Get-Random -InputObject @("PSReadLine","PSReadLine\Archives","PSReadLine\Backups","PSReadLine\Verbose") }
        2 { Get-Random -InputObject @("Scripts\Profiles","Scripts\Utilities") }
        3 { Get-Random -InputObject $subFolders | Where-Object { $_ -like "*Modules*" } }
        4 { Get-Random -InputObject $subFolders | Where-Object { $_ -like "*Modules*" } }
        5 { Get-Random -InputObject @("Scripts\Logs\Error","Scripts\Logs\Warning","Scripts\Logs\Info","Telemetry\Logs") }
        6 { Get-Random -InputObject @("Configs\Settings","Configs\Dependencies") }
        default { Get-Random -InputObject $subFolders }
    }
    New-NoiseFile -SubPath $sub -IndexSuffix $i
}

# 2. Garantierte Befüllung: Jeder Ordner bekommt 1–3 zusätzliche Dateien
foreach ($sub in $subFolders) {
    $count = Get-Random -Minimum 1 -Maximum 4
    for ($j = 1; $j -le $count; $j++) {
        $suffix = "fill_$(Get-Random -Maximum 99999)_$j"
        New-NoiseFile -SubPath $sub -IndexSuffix $suffix
    }
}

Write-Host "Noise-Struktur erfolgreich erstellt!"
Write-Host "Pfad: $basePath"
Write-Host "Ca. $($NumFiles + ($subFolders.Count * 2)) Dateien verteilt auf $(($subFolders.Count) + 1) Ordner."
Write-Host "Alle Ordner enthalten nun authentische, microsoft-ähnliche Dateien."
