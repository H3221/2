# Authentisches PowerShell Noise-Script für TryHackMe – Finale Version mit starkem Schutz für "System"
# Erzeugt realistische Struktur + massiven Noise im Ordner "operations"
# Zusätzlich: Viele weitere Unterordner in "operations", damit der bereits vorhandene versteckte Ordner "System" 
#           NICHT der einzige Unterordner ist und dadurch viel unauffälliger wirkt
# Usage: powershell.exe -ExecutionPolicy Bypass -File .\noise.ps1 [-NumFiles 1000] [-Cleanup]

param (
    [int]$NumFiles = 1000,
    [switch]$Cleanup
)

$basePath = "$env:APPDATA\Microsoft\Windows\PowerShell"
$operationsPath = "$basePath\operations"   # Ordner, der den versteckten "System"-Ordner enthält

if ($Cleanup) {
    Remove-Item -Path $basePath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Cleanup abgeschlossen: $basePath und alle Unterordner entfernt."
    return
}

# Basisordner sicherstellen
New-Item -Path $basePath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

# 1. Normale realistische PowerShell-Unterordner
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

# operations-Ordner anlegen (falls nicht vorhanden)
New-Item -Path $operationsPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

# Alle Ordner für die allgemeine Befüllung
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

# 2. ZUSÄTZLICHE UNTERORDNER IM "operations"-Ordner erstellen
#    → Damit "System" nicht der einzige Unterordner ist und sofort auffällt
$operationsSubFolders = @(
    "Logs",
    "Tasks",
    "Schedules",
    "Maintenance",
    "Background",
    "Automation",
    "Updates",
    "HealthCheck",
    "Reports",
    "Archives",
    "Temp",
    "ConfigBackup",
    "Workflows",
    "Diagnostics"
)

foreach ($sub in $operationsSubFolders) {
    $subPath = Join-Path $operationsPath $sub
    New-Item -Path $subPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

    # Einige dieser Unterordner auch zufällig verstecken (wie echte Systemordner)
    if ((Get-Random -Maximum 100) -lt 35) {
        $item = Get-Item $subPath -ErrorAction SilentlyContinue
        if ($item) {
            try { $item.Attributes = $item.Attributes -bor 'Hidden' } catch {}
        }
    }
}

# Authentische Inhalts-Templates
$historyLines = @(
    "Get-Process", "Get-Service", "Import-Module", "Set-Location", "Get-CimInstance Win32_OperatingSystem",
    "Update-Help", "Get-Alias", "Test-NetConnection"
)

$profileContent = @"
# PowerShell Profile
# Copyright (c) Microsoft Corporation.
`$ErrorActionPreference = 'Continue'
function prompt { "`$(Get-Date -Format HH:mm) PS > " }
Set-Alias ll Get-ChildItem
Write-Host "Session ready" -ForegroundColor Green
"@

$moduleContent = @"
# Internal Module
function Get-Status { Get-Date; Get-Process | Select -First 5 }
Export-ModuleMember -Function Get-Status
"@

$manifestContent = @"
@{
    ModuleVersion = '1.0.0'
    GUID = '$(New-Guid)'
    Author = 'Microsoft Corporation'
    Copyright = '(c) Microsoft Corporation.'
    FunctionsToExport = '*'
}
"@

$logEntry = "[{0}] {1} - {2}"

# Spezielle realistische Dateinamen für operations und seine Unterordner
$operationsFileNames = @(
    "TaskLog_2024.log", "TaskLog_2025.log", "Maintenance.log", "BackgroundTasks.log",
    "ScheduledTasks.xml", "AutomationConfig.xml", "UpdateCheck.log", "HealthCheck.xml",
    "OperationStatus.json", "DailyReport_$(Get-Date -Format yyyyMMdd).txt",
    "SystemMaintenance.ps1", "CleanupTask.log", "Workflow.log"
)

# Funktion: Authentische Datei erstellen
function Add-AuthenticFile {
    param([string]$FolderPath)

    $possibleNames = @()
    $content = ""

    # Spezieller starker Noise für alles unter "operations"
    if ($FolderPath -like "*operations*") {
        $possibleNames = $operationsFileNames
        $content = switch ((Get-Random -Maximum 6)) {
            0 { (1..(Get-Random -Min 80 -Max 250) | ForEach-Object { $logEntry -f (Get-Date).AddDays(-$_), "INFO", "Task completed: $_" }) -join "`n" }
            1 { "<Tasks><Task Name=`"Backup`" LastRun=`"$(Get-Date -Format o)`" /></Tasks>" }
            2 { $profileContent + "`n# Operations task`nStart-Sleep -Seconds 10" }
            3 { "{`"status`":`"running`",`"lastCheck`":`"$(Get-Date -Format o)`"}" }
            4 { "Maintenance run at $(Get-Date)`nResult: Success" }
            default { "Log entry $(Get-Random -Maximum 99999)`n$(Get-Date -Format o)" }
        }
    }
    else {
        # Normale Ordner (wie bisher)
        switch -Wildcard ($FolderPath) {
            "*PSReadLine*" { $possibleNames = @("HistoryBackup.txt", "CommandLog_2024.txt"); $content = ($historyLines | Get-Random -Count 40) -join "`n" }
            "*Profiles*"   { $possibleNames = @("Microsoft.PowerShell_profile.ps1", "profile.ps1"); $content = $profileContent }
            "*Modules*"    { 
                if ((Get-Random) % 2 -eq 0) { $possibleNames = @("Utilities.psm1"); $content = $moduleContent }
                else { $possibleNames = @("Utilities.psd1"); $content = $manifestContent }
            }
            "*Logs*"       { $possibleNames = @("Error_$(Get-Date -Format yyyyMMdd).log", "Session.log"); $content = (1..60 | ForEach-Object { $logEntry -f (Get-Date).AddDays(-$_), "INFO", "Event $_" }) -join "`n" }
            "*Telemetry*"  { $possibleNames = @("UsageData.log"); $content = "Events collected: $(Get-Random -Min 100 -Max 1000)" }
            "*Configs*"    { $possibleNames = @("settings.xml"); $content = "<config><policy>RemoteSigned</policy></config>" }
            "*Cache*"      { $possibleNames = @("cache.dat"); $content = "{`"entries`": $(Get-Random -Min 20 -Max 100)}" }
            default        { $possibleNames = @("notes.txt"); $content = "Note from $(Get-Date)" }
        }
    }

    $fileName = $possibleNames | Get-Random
    $filePath = Join-Path $FolderPath $fileName

    if (-not (Test-Path $filePath)) {
        try {
            Set-Content -Path $filePath -Value $content -Force -ErrorAction Stop
        } catch { return }
    }

    # Attribute + alte Timestamps
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

# 1. Zufällige Dateien verteilen
for ($i = 1; $i -le $NumFiles; $i++) {
    $target = ($allFolders | Get-Random)
    $targetPath = Join-Path $basePath $target
    Add-AuthenticFile -FolderPath $targetPath
}

# 2. Normale Ordner befüllen
foreach ($sub in $normalFolders) {
    $full = Join-Path $basePath $sub
    3..6 | ForEach-Object { Add-AuthenticFile -FolderPath $full }
}

# 3. MASSIVER NOISE im operations-Ordner selbst
$heavyCount = 50 + (Get-Random -Minimum 30 -Maximum 80)  # 80–130 Dateien direkt in operations
for ($k = 1; $k -le $heavyCount; $k++) {
    Add-AuthenticFile -FolderPath $operationsPath
}

# 4. Befüllung der neuen Unterordner in operations (jeder bekommt 5–15 Dateien)
foreach ($sub in $operationsSubFolders) {
    $fullSub = Join-Path $operationsPath $sub
    $subCount = Get-Random -Minimum 5 -Maximum 15
    for ($m = 1; $m -le $subCount; $m++) {
        Add-AuthenticFile -FolderPath $fullSub
    }
}

Write-Host "Finale Noise-Struktur mit starkem Schutz für den 'System'-Ordner erstellt!"
Write-Host "Pfad: $basePath"
Write-Host "- Ordner 'operations' enthält nun $(($operationsSubFolders.Count)) weitere Unterordner:"
Write-Host "     Logs, Tasks, Schedules, Maintenance, Background, Automation, Updates, ..."
Write-Host "- Dadurch ist der bereits vorhandene versteckte Ordner 'System' nur einer von vielen und fällt nicht auf."
Write-Host "- Zusätzlich ca. $heavyCount Dateien direkt in 'operations' + weitere in den Unterordnern."
Write-Host "Perfekter Noise-Schutz erreicht – viel Erfolg bei der Challenge!"
