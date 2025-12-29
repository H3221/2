# Authentisches PowerShell Noise-Script für TryHackMe – Erweiterte Version
# Erzeugt realistische Microsoft-ähnliche Struktur + zusätzlichen Noise im Ordner "operations"
# Schützt den bereits vorhandenen versteckten Unterordner "System" durch massiven, authentischen Noise
# Usage: powershell.exe -ExecutionPolicy Bypass -File .\noise.ps1 [-NumFiles 800] [-Cleanup]

param (
    [int]$NumFiles = 800,
    [switch]$Cleanup
)

$basePath = "$env:APPDATA\Microsoft\Windows\PowerShell"
$operationsPath = "$basePath\operations"   # Der Ordner, in dem der versteckte "System"-Ordner liegt

if ($Cleanup) {
    Remove-Item -Path $basePath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Cleanup abgeschlossen: $basePath und alle Unterordner entfernt."
    return
}

# Basisordner sicherstellen
New-Item -Path $basePath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

# 1. Normale realistische PowerShell-Unterordner (wie zuvor)
$normalFolders = @(
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

# operations-Ordner explizit erstellen (falls nicht vorhanden)
New-Item -Path $operationsPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

# operations als zusätzlichen Ordner zur allgemeinen Befüllung hinzufügen
$allFolders = $normalFolders + "operations"

# Ordner erstellen und teilweise verstecken
foreach ($sub in $allFolders) {
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

Export-ModuleMember -Function Get-SystemSummary
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
    FunctionsToExport = @('Get-SystemSummary')
}
"@

$logEntry = "[{0}] {1} - {2}"

# Spezielle Noise-Namen für den "operations"-Ordner – sehr authentisch und unauffällig
$operationsFileNames = @(
    "TaskLog_2024.log", "TaskLog_2025.log",
    "ScheduledTasks.xml", "TaskHistory.txt",
    "Maintenance.log", "BackgroundTasks.log",
    "AutomationConfig.xml", "RunHistory_202412.log",
    "OperationStatus.json", "Workflow.log",
    "DailyOperations_$(Get-Date -Format yyyyMMdd).txt",
    "SystemMaintenance.ps1", "CleanupTask.log",
    "UpdateCheck.log", "HealthCheck.xml"
)

# Funktion: Eine authentische Datei erstellen
function Add-AuthenticFile {
    param([string]$FolderPath)

    $possibleNames = @()
    $content = ""

    # Spezieller Noise für den operations-Ordner → viel Inhalt, um "System" zu überdecken
    if ($FolderPath -like "*operations") {
        $possibleNames = $operationsFileNames
        $content = switch ((Get-Random -Maximum 5)) {
            0 { (1..(Get-Random -Min 80 -Max 200) | ForEach-Object { $logEntry -f (Get-Date).AddDays(-$_), (Get-Random @("INFO","SUCCESS")), "Scheduled task completed: Daily backup" }) -join "`n" }
            1 { "<Tasks><Task Name=`"Maintenance`" LastRun=`"$(Get-Date -Format o)`" /><Task Name=`"UpdateCheck`" Status=`"Success`" /></Tasks>" }
            2 { $profileContent + "`n# Operations-specific script`nStart-Sleep -Seconds 30" }
            3 { "{`"lastCheck`": `"$(Get-Date -Format o)`", `"tasksCompleted`": $(Get-Random -Min 50 -Max 200)}" }
            default { "Operation log entry $(Get-Random -Maximum 99999)`nTimestamp: $(Get-Date -Format o)`nStatus: Completed" }
        }
    }
    else {
        switch -Wildcard ($FolderPath) {
            "*PSReadLine*" { $possibleNames = @("HistoryBackup.txt", "SavedCommands.txt", "CommandLog_$(Get-Random -Min 2021 -Max 2025).txt"); $content = ($historyLines | Get-Random -Count (Get-Random -Min 20 -Max 80)) -join "`n" }
            "*Profiles*"   { $possibleNames = @("Microsoft.PowerShell_profile.ps1", "profile.ps1"); $content = $profileContent }
            "*Modules*"    { 
                if ((Get-Random) % 2 -eq 0) { $possibleNames = @("Utilities.psm1", "CoreFunctions.psm1"); $content = $moduleContent }
                else { $possibleNames = @("Utilities.psd1", "ModuleManifest.psd1"); $content = $manifestContent }
            }
            "*Logs\Error*"   { $possibleNames = @("Error_$(Get-Date -Format yyyyMMdd).log"); $content = (1..60 | ForEach-Object { $logEntry -f (Get-Date).AddDays(-$_), "ERROR", "Module load failed" }) -join "`n" }
            "*Logs\Warning*" { $possibleNames = @("Warnings.log"); $content = (1..40 | ForEach-Object { $logEntry -f (Get-Date).AddDays(-$_), "WARNING", "Deprecated feature" }) -join "`n" }
            "*Logs\Info*"    { $possibleNames = @("Session_$(Get-Date -Format yyyyMMdd_HHmm).log"); $content = (1..80 | ForEach-Object { $logEntry -f (Get-Date).AddDays(-$_), "INFO", "Command executed" }) -join "`n" }
            "*Telemetry*"    { $possibleNames = @("UsageData.log"); $content = "Telemetry enabled - events: $(Get-Random -Min 100 -Max 1000)" }
            "*Configs*"      { $possibleNames = @("preferences.xml", "execution.config"); $content = "<configuration><ExecutionPolicy>RemoteSigned</ExecutionPolicy></configuration>" }
            "*Cache*"        { $possibleNames = @("modulecache.dat", "commandcache.json"); $content = "{`"cached`": $(Get-Random -Min 20 -Max 100)}" }
            "*Temp*"         { $possibleNames = @("tmp_$(Get-Random -Maximum 99999).tmp"); $content = "# Temp script" }
            "*Backups*"      { $possibleNames = @("profile_backup_$(Get-Date -Format yyyyMMdd).ps1"); $content = $profileContent }
            default          { $possibleNames = @("notes.txt", "internal.txt"); $content = "Internal note - $(Get-Date)" }
        }
    }

    $fileName = $possibleNames | Get-Random
    $filePath = Join-Path $FolderPath $fileName

    if (-not (Test-Path $filePath)) {
        try {
            Set-Content -Path $filePath -Value $content -Force -ErrorAction Stop
        } catch { return }
    }

    if (Test-Path $filePath) {
        $item = Get-Item $filePath -ErrorAction SilentlyContinue
        if ($item) {
            try {
                if ((Get-Random -Maximum 100) -lt 45) { $item.Attributes = $item.Attributes -bor 'ReadOnly' }
                if ((Get-Random -Maximum 100) -lt 55) { $item.Attributes = $item.Attributes -bor 'Hidden' }
                $item.LastWriteTime = (Get-Date).AddDays(- (Get-Random -Maximum 1825))  # 2020–2025
            } catch {}
        }
    }
}

# 1. Zufällige Dateien über alle Ordner verteilen
for ($i = 1; $i -le $NumFiles; $i++) {
    $targetFolder = Join-Path $basePath ($allFolders | Get-Random)
    Add-AuthenticFile -FolderPath $targetFolder
}

# 2. Garantierte Befüllung aller normalen Ordner (3–6 Dateien)
foreach ($sub in $normalFolders) {
    $fullSub = Join-Path $basePath $sub
    $extraCount = Get-Random -Minimum 3 -Maximum 6
    for ($j = 1; $j -le $extraCount; $j++) {
        Add-AuthenticFile -FolderPath $fullSub
    }
}

# 3. MASSIVER NOISE im operations-Ordner → Schutz für den versteckten "System"-Ordner
$operationsFullPath = $operationsPath
$heavyNoiseCount = 40 + (Get-Random -Minimum 20 -Maximum 60)  # 60–100 Dateien im operations-Ordner
for ($k = 1; $k -le $heavyNoiseCount; $k++) {
    Add-AuthenticFile -FolderPath $operationsFullPath
}

Write-Host "Erweiterte authentische Noise-Struktur erfolgreich erstellt!"
Write-Host "Pfad: $basePath"
Write-Host "Besonderer Schutz: Der Ordner 'operations' enthält nun $heavyNoiseCount+ realistische Dateien"
Write-Host "→ Der bereits vorhandene versteckte Unterordner 'System' ist nun stark durch Noise geschützt."
Write-Host "Gesamt: Über $NumFiles Dateien + intensive Befüllung aller Ordner."
