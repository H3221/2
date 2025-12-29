# Erweitertes PowerShell Script: Maximale Noise-Struktur mit Hidden/ReadOnly
# Für TryHackMe Lab - Generiert authentische Microsoft-ähnliche Struktur
# Usage: .\noise_advanced.ps1 [-NumFiles 500] [-Cleanup]
param (
    [int]$NumFiles = 500,
    [switch]$Cleanup
)

$basePath = "$env:APPDATA\Microsoft\Windows\PowerShell"

if ($Cleanup) {
    Remove-Item -Path $basePath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Cleanup abgeschlossen."
    return
}

# Basisordner erstellen, falls nicht vorhanden
if (-not (Test-Path $basePath)) {
    New-Item -Path $basePath -ItemType Directory -Force | Out-Null
}

# Erweiterte Subfolders (tiefere Hierarchie)
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

foreach ($sub in $subFolders) {
    $fullPath = Join-Path $basePath $sub
    if (-not (Test-Path $fullPath)) {
        New-Item -Path $fullPath -ItemType Directory -Force | Out-Null
    }
    # Zufällig Hidden setzen (30% Chance)
    if ((Get-Random -Maximum 100) -lt 30) {
        $folderItem = Get-Item $fullPath -ErrorAction SilentlyContinue
        if ($folderItem) {
            $folderItem.Attributes = $folderItem.Attributes -bor [System.IO.FileAttributes]::Hidden
        }
    }
}

# Erweiterte Templates (komplexer, sinnvoller Inhalt)
$historyTemplate = @(
    "Get-Date -Format 'yyyy-MM-dd'", "Import-Module Microsoft.PowerShell.Utility",
    "Get-Process | Select-Object Name, Id", "Invoke-WebRequest -Uri 'https://example.com'",
    "Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned",
    "Get-CimInstance -ClassName Win32_OperatingSystem"
)

$profileTemplate = @"
# Microsoft PowerShell Profile Variant
# Copyright (c) Microsoft Corporation
`$ErrorActionPreference = 'Stop'
function Get-SystemInfo {
    param([switch]`$Detailed)
    if (`$Detailed) { Get-ComputerInfo | Select-Object * } else { Get-ComputerInfo | Select-Object CsName, OsVersion }
}
Import-Module CimCmdlets -ErrorAction SilentlyContinue
Write-Host "PowerShell Initialized - Version `$(`$PSVersionTable.PSVersion)"
"@

$moduleTemplate = @"
# Microsoft Module Example
# Copyright (c) Microsoft Corporation
function UtilityFunc {
    param([string]`$Param = 'Default')
    try { Write-Output "`$Param processed" } catch { Write-Error "`$_" }
}
function AdvancedLoop {
    param([int]`$Count = 20)
    1..`$Count | ForEach-Object { Write-Output "Loop `$_" }
}
Export-ModuleMember -Function UtilityFunc, AdvancedLoop
"@

$manifestTemplate = @"
@{
    ModuleVersion = '$(Get-Random -InputObject @("5.1.0", "7.0.1", "7.4.2"))'
    GUID = '$(New-Guid)'
    Author = 'Microsoft Corporation'
    CompanyName = 'Microsoft'
    Copyright = '(c) Microsoft Corporation. All rights reserved.'
    FunctionsToExport = '*'
    NestedModules = @('Nested.psm1')
    RequiredModules = @('Microsoft.PowerShell.Core')
}
"@

$logTemplate = "[{0}] {1}: {2}" # Wird später formatiert

$xmlTemplate = @"
<Configuration>
    <Settings>
        <ExecutionPolicy>RemoteSigned</ExecutionPolicy>
        <Modules>
            <Module Name="$(Get-Random -InputObject @("BitsTransfer", "CimCmdlets"))" Version="7.4" />
        </Modules>
    </Settings>
</Configuration>
"@

# Dateien generieren (sehr viel Noise)
for ($i = 1; $i -le $NumFiles; $i++) {
    $randType = Get-Random -Minimum 1 -Maximum 7
    $filePath = ""
    $content = ""

    switch ($randType) {
        1 { # History TXT (in PSReadLine)
            $sub = Get-Random -InputObject @("PSReadLine", "PSReadLine\Archives", "PSReadLine\Backups")
            $filePath = Join-Path $basePath "$sub\HistoryVariant_$i.txt"
            $content = ($historyTemplate + (1..(Get-Random -Min 20 -Max 50) | ForEach-Object { $historyTemplate | Get-Random })) -join "`n"
        }
        2 { # Profile PS1 (in Scripts/Profiles)
            $filePath = Join-Path $basePath "Scripts\Profiles\ProfileVariant_$i.ps1"
            $content = $profileTemplate + "`n# Additional Code`nfunction ExtraFunc { Write-Output 'Extra' }"
        }
        3 { # Module PSM1 (in Modules)
            $mod = Get-Random -InputObject @("Modules\Microsoft.PowerShell.Core\5.1", "Modules\Microsoft.PowerShell.Utility\7.4", "Modules\CimCmdlets\7.4", "Modules\BitsTransfer\7.4")
            $filePath = Join-Path $basePath "$mod\ModuleVariant_$i.psm1"
            $content = $moduleTemplate + "`n# More Functions`nfunction AnotherFunc { param([int]`$Num) `$Num * 2 }"
        }
        4 { # Manifest PSD1 (in Modules)
            $mod = Get-Random -InputObject @("Modules\Microsoft.PowerShell.Core\7.4", "Modules\Microsoft.PowerShell.Utility\7.0", "Modules\Microsoft.WSMan.Management\7.4")
            $filePath = Join-Path $basePath "$mod\ManifestVariant_$i.psd1"
            $content = $manifestTemplate
        }
        5 { # Logs (in Scripts/Logs)
            $logSub = Get-Random -InputObject @("Scripts\Logs\Error", "Scripts\Logs\Warning", "Scripts\Logs\Info")
            $filePath = Join-Path $basePath "$logSub\SessionLog_$i.log"
            $content = (1..(Get-Random -Min 50 -Max 100) | ForEach-Object { 
                $logTemplate -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), (Get-Random -InputObject @("INFO", "DEBUG", "WARNING", "ERROR")), "Simulated event - Module loaded $_", (Get-Random -InputObject @("Core", "Utility")) 
            }) -join "`n"
        }
        6 { # XML Configs (in Configs)
            $confSub = Get-Random -InputObject @("Configs\Settings", "Configs\Dependencies")
            $filePath = Join-Path $basePath "$confSub\ConfigVariant_$i.xml"
            $content = $xmlTemplate
        }
        default { # Misc (Cache, Temp, etc.)
            $miscSub = Get-Random -InputObject @("Cache\ModuleCache", "Temp", "Backups", "Extensions\Debuggers", "Help\Languages\en-US", "Telemetry\Logs")
            $filePath = Join-Path $basePath "$miscSub\MiscFile_$i.txt"
            $content = "Fake content for noise: $(New-Guid)`n" + ($historyTemplate -join "`n")
        }
    }

    if ($filePath -and -not (Test-Path $filePath)) {
        try {
            Set-Content -Path $filePath -Value $content -Force -ErrorAction Stop
        } catch {
            continue  # Überspringen bei Fehlern (z.B. Verzeichnisprobleme)
        }
    }

    if (Test-Path $filePath) {
        $item = Get-Item $filePath -ErrorAction SilentlyContinue
        if ($item) {
            # Zufällig ReadOnly setzen (40% Chance) - vor Hidden, da ReadOnly Metadaten erlaubt
            if ((Get-Random -Maximum 100) -lt 40) {
                $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::ReadOnly
            }
            # Zufällig Hidden setzen (50% Chance)
            if ((Get-Random -Maximum 100) -lt 50) {
                $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::Hidden
            }
            # Fake Timestamp (2020-2025) - Metadaten, funktioniert oft trotz ReadOnly
            $item.LastWriteTime = (Get-Date).AddDays(- (Get-Random -Maximum 1825))
        }
    }
}

# Zusätzliche fixed Files für Authentizität
$fixedHistoryPath = Join-Path $basePath "PSReadLine\ConsoleHost_history.txt"
if (-not (Test-Path $fixedHistoryPath)) {
    Set-Content -Path $fixedHistoryPath -Value (($historyTemplate * 10) -join "`n") -Force
}
if (Test-Path $fixedHistoryPath) {
    $fixedItem = Get-Item $fixedHistoryPath
    $fixedItem.Attributes = $fixedItem.Attributes -bor [System.IO.FileAttributes]::ReadOnly -bor [System.IO.FileAttributes]::Hidden
    $fixedItem.LastWriteTime = (Get-Date).AddDays(- (Get-Random -Maximum 1825))
}

Write-Host "Erweiterte Noise-Struktur erstellt: Ca. $NumFiles Dateien in $basePath (mit Hidden/ReadOnly)."
