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
    New-Item -Path $basePath -ItemType Directory | Out-Null
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
    $fullPath = "$basePath\$sub"
    New-Item -Path $fullPath -ItemType Directory -Force | Out-Null
    # Zufällig Hidden setzen (30% Chance)
    if ((Get-Random -Maximum 100) -lt 30) {
        (Get-Item $fullPath).Attributes = 'Hidden'
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
$logTemplate = "[{0}] {1}: {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), (Get-Random -InputObject @("INFO", "DEBUG", "WARNING", "ERROR")), "Simulated event - Module {3} loaded"
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
            $filePath = "$basePath\$sub\HistoryVariant_$i.txt"
            $content = $historyTemplate + (1..(Get-Random -Min 20 -Max 50) | ForEach-Object { $historyTemplate | Get-Random })
        }
        2 { # Profile PS1 (in Scripts/Profiles)
            $filePath = "$basePath\Scripts\Profiles\ProfileVariant_$i.ps1"
            $content = $profileTemplate + "`n# Additional Code`nfunction ExtraFunc { Write-Output 'Extra' }"
        }
        3 { # Module PSM1 (in Modules)
            $mod = Get-Random -InputObject @("Modules\Microsoft.PowerShell.Core\5.1", "Modules\Microsoft.PowerShell.Utility\7.4", "Modules\CimCmdlets\7.4", "Modules\BitsTransfer\7.4")
            $filePath = "$basePath\$mod\ModuleVariant_$i.psm1"
            $content = $moduleTemplate + "`n# More Functions`nfunction AnotherFunc { param([int]`$Num) `$Num * 2 }"
        }
        4 { # Manifest PSD1 (in Modules)
            $mod = Get-Random -InputObject @("Modules\Microsoft.PowerShell.Core\7.4", "Modules\Microsoft.PowerShell.Utility\7.0", "Modules\Microsoft.WSMan.Management\7.4")
            $filePath = "$basePath\$mod\ManifestVariant_$i.psd1"
            $content = $manifestTemplate
        }
        5 { # Logs (in Scripts/Logs)
            $logSub = Get-Random -InputObject @("Scripts\Logs\Error", "Scripts\Logs\Warning", "Scripts\Logs\Info")
            $filePath = "$basePath\$logSub\SessionLog_$i.log"
            $content = 1..(Get-Random -Min 50 -Max 100) | ForEach-Object { $logTemplate -f (Get-Date), (Get-Random -InputObject @("INFO", "DEBUG")), "Event $_", (Get-Random -InputObject @("Core", "Utility")) }
        }
        6 { # XML Configs (in Configs)
            $confSub = Get-Random -InputObject @("Configs\Settings", "Configs\Dependencies")
            $filePath = "$basePath\$confSub\ConfigVariant_$i.xml"
            $content = $xmlTemplate
        }
        default { # Misc (Cache, Temp, etc.)
            $miscSub = Get-Random -InputObject @("Cache\ModuleCache", "Temp", "Backups", "Extensions\Debuggers", "Help\Languages\en-US", "Telemetry\Logs")
            $filePath = "$basePath\$miscSub\MiscFile_$i.txt"
            $content = "Fake content for noise: $(New-Guid)`n" + ($historyTemplate -join "`n")
        }
    }

    if ($filePath) {
        Set-Content -Path $filePath -Value $content -ErrorAction SilentlyContinue
        $item = Get-Item $filePath
        # Zufällig ReadOnly setzen (40% Chance)
        if ((Get-Random -Maximum 100) -lt 40) {
            $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::ReadOnly
        }
        # Zufällig Hidden setzen (50% Chance)
        if ((Get-Random -Maximum 100) -lt 50) {
            $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::Hidden
        }
        # Fake Timestamp (2020-2025)
        $item.LastWriteTime = (Get-Date).AddDays(- (Get-Random -Maximum 1825))
    }
}

# Zusätzliche fixed Files für Authentizität
Set-Content -Path "$basePath\PSReadLine\ConsoleHost_history.txt" -Value ($historyTemplate * 10)
(Get-Item "$basePath\PSReadLine\ConsoleHost_history.txt").Attributes = 'ReadOnly, Hidden'

Write-Host "Erweiterte Noise-Struktur erstellt: Ca. $NumFiles Dateien in $basePath (mit Hidden/ReadOnly)."
