# Authentisches PowerShell Noise-Script für TryHackMe
# Erzeugt eine hochrealistische Microsoft PowerShell-Struktur ohne verdächtige Nummern
# Usage: powershell.exe -ExecutionPolicy Bypass -File .\noise.ps1 [-NumFiles 600] [-Cleanup]

param (
    [int]$NumFiles = 600,
    [switch]$Cleanup
)

$basePath = "$env:APPDATA\Microsoft\Windows\PowerShell"

if ($Cleanup) {
    Remove-Item -Path $basePath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Cleanup abgeschlossen: $basePath entfernt."
    return
}

# Basisordner sicherstellen
New-Item -Path $basePath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

# Realistische Unterordner-Struktur (basierend auf echten Windows 10/11 + PowerShell 7 Installationen)
$subFolders = @(
    "PSReadLine\Archives",
    "PSReadLine\Backups",
    "Modules\Microsoft.PowerShell.Core\Types",
    "Modules\Microsoft.PowerShell.Core\Formats",
    "Modules\Microsoft.PowerShell.Utility",
    "Modules\CimCmdlets",
    "Modules\BitsTransfer",
    "Scripts\Profiles",
    "Scripts\Logs\Error",
    "Scripts\Logs\Warning",
    "Scripts\Logs\Info",
    "Scripts\Utilities",
    "Configs\Settings",
    "Configs\Dependencies",
    "Cache\ModuleCache",
    "Cache\CommandCache",
    "Telemetry\Logs",
    "Temp",
    "Backups"
)

# Ordner erstellen und teilweise verstecken
foreach ($sub in $subFolders) {
    $fullPath = Join-Path $basePath $sub
    New-Item -Path $fullPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

    if ((Get-Random -Maximum 100) -lt 25) {
        $item = Get-Item $fullPath -ErrorAction SilentlyContinue
        if ($item) {
            try { $item.Attributes = $item.Attributes -bor 'Hidden' } catch {}
        }
    }
}

# Authentische Inhalts-Templates
$historyLines = @(
    "Get-ChildItem -Recurse",
    "Import-Module Microsoft.PowerShell.Utility",
    "Get-Process -Name chrome",
    "Set-Location C:\Users",
    "Get-Service | Where Status -eq Running",
    "Get-CimInstance Win32_OperatingSystem | Select LastBootUpTime",
    "Update-Help -ErrorAction SilentlyContinue",
    "Get-Alias",
    "Test-NetConnection google.com"
)

$profileContent = @"
# PowerShell Profile - Microsoft Corporation
# Copyright (c) Microsoft Corporation. All rights reserved.

`$ErrorActionPreference = 'Continue'

function prompt {
    "`$(Get-Date -Format HH:mm) [PS`$(`$PSVersionTable.PSVersion)] `$(Get-Location)> "
}

Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name which -Value Get-Command

Write-Host "Welcome to PowerShell" -ForegroundColor Cyan
"@

$moduleContent = @"
# Custom PowerShell Module
# Copyright (c) Microsoft Corporation. All rights reserved.

function Get-SystemSummary {
    Get-ComputerInfo | Select-Object WindowsProductName, OsVersion, TotalPhysicalMemory
}

function Test-Admin {
    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Export-ModuleMember -Function Get-SystemSummary, Test-Admin
"@

$manifestContent = @"
@{
    ModuleVersion     = '1.0.0'
    GUID              = '$(New-Guid)'
    Author            = 'Microsoft Corporation'
    CompanyName       = 'Microsoft Corporation'
    Copyright         = '(c) Microsoft Corporation. All rights reserved.'
    Description       = 'Internal utility module'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Get-SystemSummary', 'Test-Admin')
}
"@

$logEntry = "[{0}] {1} - {2}"

# Funktion: Eine authentische Datei in einem Ordner erstellen
function Add-AuthenticFile {
    param([string]$FolderPath)

    $possibleNames = @()
    $content = ""

    switch -Wildcard ($FolderPath) {
        "*PSReadLine*" {
            $possibleNames = @("HistoryBackup.txt", "SavedCommands.txt", "CommandLog_$(Get-Random -Min 2021 -Max 2025).txt")
            $content = ($historyLines | Get-Random -Count (Get-Random -Min 20 -Max 80)) -join "`n"
        }
        "*Profiles*" {
            $possibleNames = @("Microsoft.PowerShell_profile.ps1", "profile.ps1", "Microsoft.VSCode_profile.ps1")
            $content = $profileContent
        }
        "*Modules*" {
            if ((Get-Random) % 2 -eq 0) {
                $possibleNames = @("Utilities.psm1", "CoreFunctions.psm1", "Internal.psm1")
                $content = $moduleContent
            } else {
                $possibleNames = @("Utilities.psd1", "CoreFunctions.psd1", "ModuleManifest.psd1")
                $content = $manifestContent
            }
        }
        "*Logs\Error*"   { $possibleNames = @("Error_$(Get-Date -Format yyyyMMdd).log", "PowerShellErrors.log"); $content = (1..60 | ForEach-Object { $logEntry -f (Get-Date).AddDays(-$_), "ERROR", "Failed to load module X" }) -join "`n" }
        "*Logs\Warning*" { $possibleNames = @("Warnings.log", "Deprecation.log"); $content = (1..40 | ForEach-Object { $logEntry -f (Get-Date).AddDays(-$_), "WARNING", "Deprecated cmdlet used" }) -join "`n" }
        "*Logs\Info*"    { $possibleNames = @("Session_$(Get-Date -Format yyyyMMdd_HHmm).log", "Activity.log"); $content = (1..80 | ForEach-Object { $logEntry -f (Get-Date).AddDays(-$_), "INFO", "Command executed successfully" }) -join "`n" }
        "*Telemetry*"    { $possibleNames = @("UsageData.log", "Telemetry_$(Get-Random -Min 2022 -Max 2025).txt"); $content = "Telemetry collection enabled`nData sent: $(Get-Random -Maximum 1000) events" }
        "*Configs*"      { $possibleNames = @("preferences.xml", "settings.config", "execution.config"); $content = "<configuration><ExecutionPolicy>RemoteSigned</ExecutionPolicy><LoggingEnabled>true</LoggingEnabled></configuration>" }
        "*Cache*"        { $possibleNames = @("modulecache.dat", "commandcache.json", "tempdata_$(New-Guid).tmp"); $content = "{`"cachedAt`": `"$(Get-Date -Format o)`", `"entries`": $(Get-Random -Min 10 -Max 100)}" }
        "*Temp*"         { $possibleNames = @("tmp_$(Get-Random -Maximum 99999).tmp", "scratch.ps1"); $content = "# Temporary script`nGet-Date" }
        "*Backups*"      { $possibleNames = @("profile_backup_$(Get-Date -Format yyyyMMdd).ps1", "config_backup.xml"); $content = $profileContent }
        default          { $possibleNames = @("notes.txt", "todo.txt", "internal.txt"); $content = "Internal notes - created $(Get-Date)" }
    }

    $fileName = $possibleNames | Get-Random
    $filePath = Join-Path $FolderPath $fileName

    if (-not (Test-Path $filePath)) {
        try {
            Set-Content -Path $filePath -Value $content -Force -ErrorAction Stop
        } catch { return }
    }

    # Attribute und Timestamp setzen
    if (Test-Path $filePath) {
        $item = Get-Item $filePath -ErrorAction SilentlyContinue
        if ($item) {
            try {
                if ((Get-Random -Maximum 100) -lt 45) { $item.Attributes = $item.Attributes -bor 'ReadOnly' }
                if ((Get-Random -Maximum 100) -lt 55) { $item.Attributes = $item.Attributes -bor 'Hidden' }
                $item.LastWriteTime = (Get-Date).AddDays(- (Get-Random -Maximum 1825))
            } catch {}
        }
    }
}

# 1. Zufällige Dateien über alle Ordner verteilen
$allFolders = @("PSReadLine\Archives", "PSReadLine\Backups") + $subFolders
for ($i = 1; $i -le $NumFiles; $i++) {
    $targetFolder = Join-Path $basePath ($allFolders | Get-Random)
    Add-AuthenticFile -FolderPath $targetFolder
}

# 2. Garantierte Befüllung: Jeder Ordner bekommt 3–6 Dateien
foreach ($sub in $allFolders) {
    $fullSub = Join-Path $basePath $sub
    $extraCount = Get-Random -Minimum 3 -Maximum 6
    for ($j = 1; $j -le $extraCount; $j++) {
        Add-AuthenticFile -FolderPath $fullSub
    }
}

Write-Host "Authentische Microsoft-ähnliche PowerShell-Noise-Struktur erfolgreich erstellt!"
Write-Host "Pfad: $basePath"
Write-Host "Enthält realistische Dateinamen wie:"
Write-Host "   - Microsoft.PowerShell_profile.ps1"
Write-Host "   - Error_20241229.log"
Write-Host "   - Utilities.psm1 / .psd1"
Write-Host "   - HistoryBackup_2023.txt"
Write-Host "   - Telemetry-Daten, Cache, Configs usw."
Write-Host "Gesamt: Über $NumFiles Dateien + garantierte Befüllung aller Ordner."
