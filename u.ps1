# Authentisches PowerShell Noise-Script für TryHackMe – Ultimative Version
# Erzeugt realistische Struktur + massiven Noise im Ordner "operations"
# Zusätzliche Unterordner in "operations" → "System" ist nicht mehr allein
# Zusätzlich: Sicheren Noise IM versteckten "System"-Ordner selbst
# → Nur harmlose Dateitypen: .txt .log .xml .json .config .yaml – KEINE .ps1/.psm1/.psd1 etc.
# Usage: powershell.exe -ExecutionPolicy Bypass -File .\noise.ps1 [-NumFiles 1200] [-Cleanup]

param (
    [int]$NumFiles = 1200,
    [switch]$Cleanup
)

$basePath = "$env:APPDATA\Microsoft\Windows\PowerShell"
$operationsPath = "$basePath\operations"
$systemPath = "$operationsPath\System"   # Der bereits vorhandene versteckte Ordner

if ($Cleanup) {
    Remove-Item -Path $basePath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Cleanup abgeschlossen: $basePath und alle Unterordner entfernt."
    return
}

# Basisordner sicherstellen
New-Item -Path $basePath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

# 1. Normale PowerShell-Unterordner
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

# operations anlegen
New-Item -Path $operationsPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

$allFolders = $normalFolders + "operations"

# Ordner erstellen + teilweise verstecken
foreach ($sub in $allFolders) {
    $fullPath = Join-Path $basePath $sub
    New-Item -Path $fullPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    if ((Get-Random -Maximum 100) -lt 25) {
        $item = Get-Item $fullPath -ErrorAction SilentlyContinue
        if ($item) { try { $item.Attributes = $item.Attributes -bor 'Hidden' } catch {} }
    }
}

# 2. Viele realistische Unterordner in "operations" (damit System nicht allein ist)
$operationsSubFolders = @(
    "Logs", "Tasks", "Schedules", "Maintenance", "Background", "Automation",
    "Updates", "HealthCheck", "Reports", "Archives", "Temp", "ConfigBackup",
    "Workflows", "Diagnostics", "Monitoring", "Events"
)

foreach ($sub in $operationsSubFolders) {
    $subPath = Join-Path $operationsPath $sub
    New-Item -Path $subPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    if ((Get-Random -Maximum 100) -lt 35) {
        $item = Get-Item $subPath -ErrorAction SilentlyContinue
        if ($item) { try { $item.Attributes = $item.Attributes -bor 'Hidden' } catch {} }
    }
}

# 3. System-Ordner selbst mit Unterordnern und harmlosen Dateien füllen
#    → Nur .txt, .log, .xml, .json, .config, .yaml
New-Item -Path $systemPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

$systemSubFolders = @(
    "Config", "Logs", "Data", "Cache", "State", "Backup", "Temp", "Metadata"
)

foreach ($sub in $systemSubFolders) {
    $subPath = Join-Path $systemPath $sub
    New-Item -Path $subPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    if ((Get-Random -Maximum 100) -lt 40) {
        $item = Get-Item $subPath -ErrorAction SilentlyContinue
        if ($item) { try { $item.Attributes = $item.Attributes -bor 'Hidden' } catch {} }
    }
}

# Templates für harmlose Dateitypen (System-Ordner)
$systemLogEntry = "[{0}] {1}: {2}"

$systemHarmlessNames = @(
    "status.log", "runtime.txt", "config.xml", "settings.json", "state.yaml",
    "metadata.config", "cache.txt", "backup_$(Get-Date -Format yyyyMMdd).log",
    "health.json", "events.log", "diagnostic.txt", "info.xml"
)

$systemContentTemplates = @(
    { "System status: Online`nLast check: $(Get-Date -Format o)`nVersion: 1.0" },
    { (1..(Get-Random -Min 30 -Max 100) | ForEach-Object { $systemLogEntry -f (Get-Date).AddDays(-$_), "INFO", "Service running normally" }) -join "`n" },
    { "<system><status>active</status><timestamp>$(Get-Date -Format o)</timestamp></system>" },
    { "{`"running`": true, `"uptime`": `"$(Get-Random -Min 1000 -Max 9999)h`", `"lastUpdate`": `"$(Get-Date -Format o)`"}" },
    { "system:`n  enabled: true`n  mode: background`n  version: 7.4" },
    { "Internal data - $(New-Guid)`nProcessed: $(Get-Random -Min 100 -Max 1000) entries" }
)

# Funktion: Harmlose Datei im System-Ordner erstellen
function Add-SystemNoiseFile {
    param([string]$FolderPath)

    $fileName = $systemHarmlessNames | Get-Random
    $filePath = Join-Path $FolderPath $fileName

    if (Test-Path $filePath) { return }  # Keine Duplikate

    $contentFunc = $systemContentTemplates | Get-Random
    $content = & $contentFunc

    try {
        Set-Content -Path $filePath -Value $content -Force -ErrorAction Stop
    } catch { return }

    $item = Get-Item $filePath -ErrorAction SilentlyContinue
    if ($item) {
        try {
            if ((Get-Random -Maximum 100) -lt 50) { $item.Attributes = $item.Attributes -bor 'ReadOnly' }
            if ((Get-Random -Maximum 100) -lt 60) { $item.Attributes = $item.Attributes -bor 'Hidden' }
            $item.LastWriteTime = (Get-Date).AddDays(- (Get-Random -Maximum 1825))
        } catch {}
    }
}

# Allgemeine Funktion für normale Ordner (wie zuvor, aber ohne .ps1 im System-Bereich)
function Add-AuthenticFile {
    param([string]$FolderPath)

    # System-Ordner und Unterordner: Nur harmlose Dateien
    if ($FolderPath -like "*System*") {
        Add-SystemNoiseFile -FolderPath $FolderPath
        return
    }

    # operations-Bereich (außer System)
    if ($FolderPath -like "*operations*") {
        $names = @("TaskLog_2025.log", "Maintenance.xml", "Status.json", "Report.yaml", "Events.log", "ConfigBackup.config")
        $fileName = $names | Get-Random
        $content = switch ((Get-Random -Maximum 4)) {
            0 { (1..100 | ForEach-Object { $systemLogEntry -f (Get-Date).AddDays(-$_), "INFO", "Operation $_ completed" }) -join "`n" }
            1 { "<operations><task>running</task><time>$(Get-Date -Format o)</time></operations>" }
            2 { "{`"active`": true, `"count`": $(Get-Random -Min 50 -Max 300)}" }
            default { "data:`n  processed: $(Get-Random -Min 1000 -Max 5000)" }
        }
    }
    else {
        # Normale Ordner
        $names = @("History.txt", "profile_backup.xml", "cache.json", "log_$(Get-Date -Format yyyyMM).log", "notes.txt")
        $fileName = $names | Get-Random
        $content = "Generic content - $(Get-Date -Format o)`nEntries: $(Get-Random -Min 10 -Max 100)"
    }

    $filePath = Join-Path $FolderPath $fileName
    if (Test-Path $filePath) { return }

    try { Set-Content -Path $filePath -Value $content -Force } catch { return }

    $item = Get-Item $filePath -ErrorAction SilentlyContinue
    if ($item) {
        try {
            if ((Get-Random -Maximum 100) -lt 45) { $item.Attributes = $item.Attributes -bor 'ReadOnly' }
            if ((Get-Random -Maximum 100) -lt 55) { $item.Attributes = $item.Attributes -bor 'Hidden' }
            $item.LastWriteTime = (Get-Date).AddDays(- (Get-Random -Maximum 1825))
        } catch {}
    }
}

# 1. Zufällige Dateien verteilen
for ($i = 1; $i -le $NumFiles; $i++) {
    $target = ($allFolders | Get-Random)
    Add-AuthenticFile -FolderPath (Join-Path $basePath $target)
}

# 2. Normale Ordner befüllen
foreach ($sub in $normalFolders) {
    $full = Join-Path $basePath $sub
    3..7 | ForEach-Object { Add-AuthenticFile -FolderPath $full }
}

# 3. Massiver Noise in operations selbst
$heavyCount = 80 + (Get-Random -Minimum 40 -Maximum 100)
for ($k = 1; $k -le $heavyCount; $k++) {
    Add-AuthenticFile -FolderPath $operationsPath
}

# 4. Unterordner in operations befüllen
foreach ($sub in $operationsSubFolders) {
    $full = Join-Path $operationsPath $sub
    $cnt = Get-Random -Minimum 6 -Maximum 18
    for ($m = 1; $m -le $cnt; $m++) {
        Add-AuthenticFile -FolderPath $full
    }
}

# 5. Noise IM System-Ordner und seinen Unterordnern (nur harmlos!)
# Haupt-System-Ordner
$systemMainCount = 20 + (Get-Random -Minimum 10 -Maximum 30)
for ($s = 1; $s -le $systemMainCount; $s++) {
    Add-SystemNoiseFile -FolderPath $systemPath
}

# Unterordner im System befüllen
foreach ($sub in $systemSubFolders) {
    $fullSub = Join-Path $systemPath $sub
    $subCount = Get-Random -Minimum 8 -Maximum 20
    for ($t = 1; $t -le $subCount; $t++) {
        Add-SystemNoiseFile -FolderPath $fullSub
    }
}

Write-Host "Ultimativer Noise-Schutz fertiggestellt!"
Write-Host "- Ordner 'operations' hat jetzt $($operationsSubFolders.Count) weitere Unterordner"
Write-Host "- Versteckter Ordner 'System' ist nur einer von vielen und enthält selbst:"
Write-Host "     $($systemSubFolders.Count) Unterordner + ca. $($systemMainCount + ($systemSubFolders.Count * 12)) harmlose Dateien"
Write-Host "- Nur .txt .log .xml .json .config .yaml – KEINE ausführbaren Scripts"
Write-Host "Dein Payload ist jetzt maximal getarnt und geschützt. Viel Erfolg bei der Challenge!"
