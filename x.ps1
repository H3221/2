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
        if ($folderItem -and $folderItem.PSObject.Properties['Attributes'] -ne $null) {
            try {
                $folderItem.Attributes = $folderItem.Attributes -bor [System.IO.FileAttributes]::Hidden
            } catch {
                # Überspringen bei Fehlern
            }
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

$miscTemplate = "Fake content for noise: $(New-Guid)`nAdditional lines:`n" + ($historyTemplate -join "`n")

# Funktion zum Erzeugen einer Datei in einem spezifischen Ordner (mit Typ-Anpassung)
function Create-FileInFolder {
    param (
        [string]$subPath,
        [int]$index
    )
    $filePath = ""
    $content = ""
    $randType = Get-Random -Minimum 1 -Maximum 7

    # Ordner-spezifische Anpassung
    if ($subPath -like "*Logs*") { $randType = 5 }  # Logs für Log-Ordner
    elseif ($subPath -like "*Modules*") { $randType = Get-Random -InputObject @(3,4) }  # Modules/Manifests für Module-Ordner
    elseif ($subPath -like "*Configs*") { $randType = 6 }  # XML für Configs
    elseif ($subPath -like "*PSReadLine*") { $randType = 1 }  # History für PSReadLine
    elseif ($subPath -like "*Scripts*") { $randType = Get-Random -InputObject @(2,5) }  # Profiles/Logs für Scripts
    elseif ($subPath -like "*Cache*" -or $subPath -like "*Temp*" -or $subPath -like "*Backups*") { $randType = 7 }  # Misc für Cache/Temp/Backups
    elseif ($subPath -like "*Help*" -or $subPath -like "*Telemetry*" -or $subPath -like "*Extensions*") { $randType = 7 }  # Misc für Help/Telemetry/Extensions

    switch ($randType) {
        1 { # History TXT
            $filePath = Join-Path $basePath "$subPath\HistoryVariant_$index.txt"
            $content = ($historyTemplate + (1..(Get-Random -Min 10 -Max 30) | ForEach-Object { $historyTemplate | Get-Random })) -join "`n"
        }
        2 { # Profile PS1
            $filePath = Join-Path $basePath "$subPath\ProfileVariant_$index.ps1"
            $content = $profileTemplate + "`n# Folder-Specific Code`nfunction FolderFunc { Write-Output 'In $subPath' }"
        }
        3 { # Module PSM1
            $filePath = Join-Path $basePath "$subPath\ModuleVariant_$index.psm1"
            $content = $moduleTemplate + "`n# Folder-Specific Func`nfunction SubFunc { 'Sub' }"
        }
        4 { # Manifest PSD1
            $filePath = Join-Path $basePath "$subPath\ManifestVariant_$index.psd1"
            $content = $manifestTemplate
        }
        5 { # Logs
            $filePath = Join-Path $basePath "$subPath\SessionLog_$index.log"
            $content = (1..(Get-Random -Min 20 -Max 50) | ForEach-Object { 
                $logTemplate -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), (Get-Random -InputObject @("INFO", "DEBUG", "WARNING", "ERROR")), "Event in $subPath - $_", (Get-Random -InputObject @("Core", "Utility")) 
            }) -join "`n"
        }
        6 { # XML Configs
            $filePath = Join-Path $basePath "$subPath\ConfigVariant_$index.xml"
            $content = $xmlTemplate
        }
        default { # Misc
            $filePath = Join-Path $basePath "$subPath\MiscFile_$index.txt"
            $content = $miscTemplate
        }
    }

    if ($filePath -and -not (Test-Path $filePath)) {
        try {
            Set-Content -Path $filePath -Value $content -Force -ErrorAction Stop
        } catch {
            return  # Überspringen
        }
    }

    if (Test-Path $filePath) {
        $item = Get-Item $filePath -ErrorAction SilentlyContinue
        if ($item -and $item.PSObject.Properties['Attributes'] -ne $null) {
            try {
                # Zufällig ReadOnly (40%)
                if ((Get-Random -Maximum 100) -lt 40) {
                    $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::ReadOnly
                }
                # Zufällig Hidden (50%)
                if ((Get-Random -Maximum 100) -lt 50) {
                    $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::Hidden
                }
            } catch {}
        }
        if ($item -and $item.PSObject.Properties['LastWriteTime'] -ne $null) {
            try {
                $item.LastWriteTime = (Get-Date).AddDays(- (Get-Random -Maximum 1825))
            } catch {}
        }
    }
}

# Zuerst randomisierte Dateien generieren (wie zuvor, aber mit erweiterten subs)
for ($i = 1; $i -le $NumFiles; $i++) {
    $randType = Get-Random -Minimum 1 -Maximum 7
    $filePath = ""
    $content = ""

    switch ($randType) {
        1 { # History TXT (erweitert)
            $sub = Get-Random -InputObject @("PSReadLine", "PSReadLine\Archives", "PSReadLine\Backups", "PSReadLine\Verbose")
            $filePath = Join-Path $basePath "$sub\HistoryVariant_$i.txt"
            $content = ($historyTemplate + (1..(Get-Random -Min 20 -Max 50) | ForEach-Object { $historyTemplate | Get-Random })) -join "`n"
        }
        2 { # Profile PS1
            $sub = Get-Random -InputObject @("Scripts\Profiles", "Scripts\Utilities", "Scripts\Archives")
            $filePath = Join-Path $basePath "$sub\ProfileVariant_$i.ps1"
            $content = $profileTemplate + "`n# Additional Code`nfunction ExtraFunc { Write-Output 'Extra' }"
        }
        3 { # Module PSM1 (erweitert)
            $mod = Get-Random -InputObject @("Modules\Microsoft.PowerShell.Core\5.1", "Modules\Microsoft.PowerShell.Core\5.1\Types", "Modules\Microsoft.PowerShell.Core\5.1\Formats", "Modules\Microsoft.PowerShell.Core\7.4", "Modules\Microsoft.PowerShell.Utility\7.0\NestedModules", "Modules\Microsoft.PowerShell.Utility\7.4", "Modules\CimCmdlets\5.1", "Modules\CimCmdlets\7.4\Help", "Modules\BitsTransfer\7.4", "Modules\Microsoft.WSMan.Management\7.4")
            $filePath = Join-Path $basePath "$mod\ModuleVariant_$i.psm1"
            $content = $moduleTemplate + "`n# More Functions`nfunction AnotherFunc { param([int]`$Num) `$Num * 2 }"
        }
        4 { # Manifest PSD1 (erweitert)
            $mod = Get-Random -InputObject @("Modules\Microsoft.PowerShell.Core\7.4", "Modules\Microsoft.PowerShell.Core\5.1\Types", "Modules\Microsoft.PowerShell.Utility\7.0", "Modules\Microsoft.PowerShell.Utility\7.0\NestedModules", "Modules\Microsoft.WSMan.Management\7.4", "Modules\CimCmdlets\7.4\Help")
            $filePath = Join-Path $basePath "$mod\ManifestVariant_$i.psd1"
            $content = $manifestTemplate
        }
        5 { # Logs
            $logSub = Get-Random -InputObject @("Scripts\Logs\Error", "Scripts\Logs\Warning", "Scripts\Logs\Info", "Telemetry\Logs")
            $filePath = Join-Path $basePath "$logSub\SessionLog_$i.log"
            $content = (1..(Get-Random -Min 50 -Max 100) | ForEach-Object { 
                $logTemplate -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), (Get-Random -InputObject @("INFO", "DEBUG", "WARNING", "ERROR")), "Simulated event - Module loaded $_", (Get-Random -InputObject @("Core", "Utility")) 
            }) -join "`n"
        }
        6 { # XML Configs
            $confSub = Get-Random -InputObject @("Configs\Settings", "Configs\Dependencies")
            $filePath = Join-Path $basePath "$confSub\ConfigVariant_$i.xml"
            $content = $xmlTemplate
        }
        default { # Misc (erweitert)
            $miscSub = Get-Random -InputObject @("Cache\ModuleCache", "Cache\CommandCache", "Temp", "Backups", "Extensions\Debuggers", "Help\Languages\en-US", "Telemetry\Logs", "Scripts\Utilities", "Scripts\Archives")
            $filePath = Join-Path $basePath "$miscSub\MiscFile_$i.txt"
            $content = $miscTemplate
        }
    }

    if ($filePath -and -not (Test-Path $filePath)) {
        try {
            Set-Content -Path $filePath -Value $content -Force -ErrorAction Stop
        } catch {
            continue
        }
    }

    if (Test-Path $filePath) {
        $item = Get-Item $filePath -ErrorAction SilentlyContinue
        if ($item -and $item.PSObject.Properties['Attributes'] -ne $null) {
            try {
                if ((Get-Random -Maximum 100) -lt 40) {
                    $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::ReadOnly
                }
                if ((Get-Random -Maximum 100) -lt 50) {
                    $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::Hidden
                }
            } catch {}
        }
        if ($item -and $item.PSObject.Properties['LastWriteTime'] -ne $null) {
            try {
                $item.LastWriteTime = (Get-Date).AddDays(- (Get-Random -Maximum 1825))
            } catch {}
        }
    }
}

# Zusätzliche systematische Befüllung: Mindestens 1-3 Dateien pro Ordner
foreach ($sub in $subFolders) {
    $minFilesPerFolder = Get-Random -Minimum 1 -Maximum 3
    for ($j = 1; $j -le $minFilesPerFolder; $j++) {
        $uniqueIndex = "min$(Get-Random -Maximum 10000)_$j"  # Eindeutig, um Duplikate zu vermeiden
        Create-FileInFolder -subPath $sub -index $uniqueIndex
    }
}

Write-Host "Erweiterte Noise-Struktur erstellt: Ca. $NumFiles + zusätzliche Dateien in $basePath. Fast jeder Ordner enthält nun sinnvolle Dateien."
