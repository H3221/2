# Professional Noise Generator for PowerShell Obfuscation
# Author: Conceptualized for Advanced Cybersecurity Labs (Professor-Level)
# Version: 1.6 - Removed -Parallel for compatibility with PS5.1+; Pure PS Gaussian
# Usage: .\revere.ps1 [-MaxFiles <int>] [-Seed <int>] [-DryRun] [-Cleanup]
# Note: Compatible with PowerShell 5.1+. For large MaxFiles, it may be slower.

param (
    [int]$MaxFiles = 1000,  # Target number of files (scalable to 5000+)
    [int]$Seed = (Get-Date).Millisecond,  # For reproducible randomness
    [switch]$DryRun,  # Simulate without writing
    [switch]$Cleanup  # Remove all generated content
)

# Pure PowerShell Gaussian function (Box-Muller transform)
function NextGaussian {
    param (
        [double]$mu = 0,
        [double]$sigma = 1
    )
    $rand = New-Object System.Random
    $u1 = $rand.NextDouble()
    $u2 = $rand.NextDouble()
    $randStdNormal = [math]::Sqrt(-2.0 * [math]::Log($u1)) * [math]::Sin(2.0 * [math]::PI * $u2)
    return $mu + $sigma * $randStdNormal
}

class NoiseGenerator {
    [string]$BasePath = "$env:APPDATA\Microsoft\Windows\PowerShell"
    [System.Random]$Rng
    [hashtable]$Templates
    [array]$SubFolders
    [bool]$DryRun  # Added as class property for scope safety

    NoiseGenerator([int]$Seed, [bool]$DryRun) {
        $this.Rng = [System.Random]::new($Seed)
        $this.DryRun = $DryRun
        $this.InitializeTemplates()
        $this.InitializeFolders()
    }

    [void]InitializeTemplates() {
        $this.Templates = @{
            History = @(
                "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'",
                "Import-Module -Name Microsoft.PowerShell.Utility -ErrorAction SilentlyContinue",
                "Get-Process | Where-Object { $_.Name -like '*power*'} | Select-Object Id, Name",
                "Invoke-WebRequest -Uri 'https://docs.microsoft.com' -UseBasicParsing -Method Head",
                "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force",
                "Get-CimInstance -ClassName Win32_LogicalDisk | Select-Object DeviceID, FreeSpace",
                "Update-Help -Module Microsoft.PowerShell.Core -Force",
                "Test-NetConnection -ComputerName localhost -Port 5985"
            )
            Profile = @"
# Microsoft PowerShell Profile - Advanced Environment Configuration
# Copyright (c) Microsoft Corporation. All rights reserved.

`$global:ErrorActionPreference = 'Continue'
class SystemHelper {
    static [psobject] GetInfo([bool]`$Detailed) {
        if (`$Detailed) {
            return Get-ComputerInfo | Select-Object -Property CsManufacturer, OsArchitecture, PsVersion
        } else {
            return Get-ComputerInfo | Select-Object -Property OsName, OsBuildNumber
        }
    }
}
function Invoke-StartupCheck {
    param([int]`$Level = 1)
    try {
        if (`$Level -gt 0) { Write-Verbose 'Performing system check...' }
        [SystemHelper]::GetInfo(`$true)
    } catch {
        Write-Error "Startup check failed: `$_"
    }
}
Invoke-StartupCheck
Write-Host "PowerShell Environment Loaded - Version `$(`$PSVersionTable.PSVersion.Major).`$(`$PSVersionTable.PSVersion.Minor)"
"@
            Module = @"
# Advanced Microsoft-Compatible Module
# Copyright (c) Microsoft Corporation

function Get-AdvancedUtility {
    param(
        [Parameter(Mandatory=`$true)][string]`$Target,
        [ValidateSet('Low','Medium','High')][string]`$Complexity = 'Medium'
    )
    try {
        switch (`$Complexity) {
            'Low' { Write-Output "Simple processing for `$Target" }
            'Medium' {
                for (`$i = 1; `$i -le 15; `$i++) {
                    Write-Verbose "Iteration `$i on `$Target"
                }
            }
            'High' { 1..30 | ForEach-Object { "Complex calc: `$_ * (Get-Random -Max 100)" } }
        }
    } catch {
        throw "Error in utility: `$_"
    }
}
function Invoke-ProcGen {
    param([int]`$Iterations = 25)
    `$result = @()
    for (`$i = 0; `$i -lt `$Iterations; `$i++) {
        `$result += [math]::Pow(`$i, 2)
    }
    return `$result
}
Export-ModuleMember -Function Get-AdvancedUtility, Invoke-ProcGen
"@
            Manifest = @"
@{
    ModuleVersion = '{0}'
    GUID = '{1}'
    Author = 'Microsoft Corporation'
    CompanyName = 'Microsoft'
    Copyright = '(c) Microsoft Corporation. All rights reserved.'
    Description = 'Simulated module for {2} utility functions'
    PowerShellVersion = '7.0'
    FunctionsToExport = '*'
    CmdletsToExport = '*'
    NestedModules = @('Nested{3}.psm1')
    RequiredAssemblies = @('System.Management.Automation.dll')
    PrivateData = @{
        PSData = @{
            Tags = @('Utility', 'Core', 'Management')
            LicenseUri = 'https://www.microsoft.com/licensing'
            ProjectUri = 'https://github.com/PowerShell/PowerShell'
        }
    }
    FileList = @('Module.psm1', 'Manifest.psd1')
}
"@
            Log = @"
[{0}] {1} Microsoft.PowerShell.Host: {2}
"@
            XmlConfig = @"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <runtime>
    <assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1">
      <dependentAssembly>
        <assemblyIdentity name="System.Management.Automation" publicKeyToken="31bf3856ad364e35" culture="neutral" />
        <bindingRedirect oldVersion="0.0.0.0-7.4.0.0" newVersion="7.4.0.0" />
      </dependentAssembly>
    </assemblyBinding>
  </runtime>
  <powershell>
    <modules>
      <module name="CimCmdlets" version="7.0" guid="{0}" />
      <module name="BitsTransfer" version="5.1" />
    </modules>
    <settings>
      <executionPolicy>RemoteSigned</executionPolicy>
      <transcriptEnabled>true</transcriptEnabled>
    </settings>
  </powershell>
</configuration>
"@
        }
    }

    [void]InitializeFolders() {
        $this.SubFolders = @(
            "PSReadLine\History\Archives\Old", "PSReadLine\History\Backups\v$($this.Rng.Next(5,8))", "PSReadLine\Verbose\Details\Level$($this.Rng.Next(1,4))",
            "Modules\Microsoft.PowerShell.Core\7.4\NestedModules\Internal", "Modules\Microsoft.PowerShell.Core\5.1\TypeData\Extended", "Modules\Microsoft.PowerShell.Core\7.4\FormatData",
            "Modules\Microsoft.PowerShell.Utility\7.4\Help\en-US\About", "Modules\Microsoft.PowerShell.Utility\7.0\Cmdlets\Advanced",
            "Modules\CimCmdlets\7.4\Providers\Win32", "Modules\CimCmdlets\5.1\Classes\WMI",
            "Modules\BitsTransfer\7.4\Jobs\Background", "Modules\Microsoft.WSMan.Management\7.4\WSMan\Configs",
            "Modules\NetTCPIP\7.4\Adapters\IPv6", "Modules\Az.Accounts\2.10\Authentication",  # Inspired by Azure modules for realism
            "Scripts\Utilities\Diagnostics\Performance", "Scripts\Profiles\AllUsers\CurrentHost", "Scripts\Profiles\CurrentUser\ISE",
            "Scripts\Logs\Analytic\ETW\Traces", "Scripts\Logs\Operational\Events\v$($this.Rng.Next(1,3))", "Scripts\Archives\Legacy\201$($this.Rng.Next(8,10))",
            "Cache\ModuleCache\JIT\Compiled", "Cache\CommandCache\History\Serialized",
            "Configs\Settings\Machine\Policies", "Configs\Dependencies\Assemblies\Redirects",
            "Temp\Scratch\Sessions\$([guid]::NewGuid().ToString('N').Substring(0,8))", "Backups\System\Snapshots\Daily",
            "Extensions\VSCode\PowerShell\LanguageServer\Binaries", "Help\Languages\en-US\Topics\Advanced",
            "Telemetry\Metrics\Performance\Counters", "Telemetry\Logs\Diagnostic\Errors\Handled",
            "Security\Certificates\FakeStore\Trusted", "PackageManagement\Providers\NuGet\v2.8\Bootstrap"
        )
    }

    [void]CreateStructure() {
        foreach ($sub in $this.SubFolders) {
            $fullPath = Join-Path $this.BasePath $sub
            if (-not $this.DryRun) { New-Item -Path $fullPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null }
            $this.SetAttributes($fullPath, 'Directory')
        }
    }

    [void]GenerateFiles([int]$MaxFiles) {
        $fileTypes = @('History', 'Profile', 'Module', 'Manifest', 'Log', 'XmlConfig')
        $baseCount = [math]::Round($MaxFiles / $this.SubFolders.Count)
        
        foreach ($sub in $this.SubFolders) {
            $localRng = [System.Random]::new((Get-Date).Millisecond + $Seed)
            $localBasePath = $this.BasePath
            $localTemplates = $this.Templates
            $localDryRun = $this.DryRun

            # Local SetAttributes function
            function LocalSetAttributes ([string]$Path, [string]$ItemType, [System.Random]$LocalRng) {
                $item = Get-Item $Path -ErrorAction SilentlyContinue
                if ($item) {
                    $attrs = $item.Attributes
                    if ($LocalRng.NextDouble() -lt 0.6) { $attrs = $attrs -bor [System.IO.FileAttributes]::ReadOnly }
                    if ($LocalRng.NextDouble() -lt 0.45) { $attrs = $attrs -bor [System.IO.FileAttributes]::Hidden }
                    if ($LocalRng.NextDouble() -lt 0.3) { $attrs = $attrs -bor [System.IO.FileAttributes]::Archive }
                    $item.Attributes = $attrs
                }
            }

            for ($i = 1; $i -le $baseCount; $i++) {
                $type = $fileTypes[$localRng.Next(0, $fileTypes.Count)]
                $ext = switch ($type) { 'History' {'.txt'}; 'Profile' {'.ps1'}; 'Module' {'.psm1'}; 'Manifest' {'.psd1'}; 'Log' {'.log'}; 'XmlConfig' {'.xml'} }
                $name = "Variant$($localRng.Next(10000,99999))_$type$ext"
                $filePath = Join-Path (Join-Path $localBasePath $sub) $name
                
                $content = switch ($type) {
                    'History' {
                        $localTemplates.History + ("`n# Procedural Addition: $($localRng.Next(100))" * $localRng.Next(5,20)) -join "`n"
                    }
                    'Profile' {
                        $localTemplates.Profile
                    }
                    'Module' {
                        $localTemplates.Module
                    }
                    'Manifest' {
                        $version = "$($localRng.Next(5,8)).$($localRng.Next(0,5)).$($localRng.Next(0,10))"
                        $guid = [guid]::NewGuid().ToString()
                        $utils = $localRng.Next(1000)
                        $nested = $localRng.Next(1,5)
                        $localTemplates.Manifest -f $version, $guid, $utils, $nested
                    }
                    'Log' {
                        $levels = @('TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL')
                        $events = @('Session initialized', "Module loaded: Microsoft.PowerShell.$($localRng.Next(1,10))", 'Command executed: Get-Process', 'Error encountered: Simulated exception', "Performance metric: $($localRng.Next(10,500))ms")
                        $lines = @()
                        for ($j = 1; $j -le $localRng.Next(100, 300); $j++) {
                            $date = (Get-Date).AddSeconds(-$localRng.Next(3600 * 24 * 365)).ToString('yyyy-MM-dd HH:mm:ss.fff')
                            $level = $levels[$localRng.Next(0, $levels.Count)]
                            $event = $events[$localRng.Next(0, $events.Count)]
                            $lines += $localTemplates.Log -f $date, $level, $event
                        }
                        $lines -join ''
                    }
                    'XmlConfig' {
                        $localTemplates.XmlConfig -f [guid]::NewGuid().ToString()
                    }
                }
                
                if (-not $localDryRun) {
                    try {
                        Set-Content -Path $filePath -Value $content -ErrorAction Stop
                        $item = Get-Item $filePath
                        # Gaussian timestamp
                        $daysBack = [math]::Round( (NextGaussian -mu 730 -sigma 365) )
                        $item.LastWriteTime = (Get-Date).AddDays(-$daysBack)
                        LocalSetAttributes -Path $filePath -ItemType 'File' -LocalRng $localRng
                    } catch {
                        Write-Verbose "Failed to create ${filePath}: $_"  # Fixed variable reference
                    }
                }
            }
        }
    }

    [void]SetAttributes([string]$Path, [string]$ItemType, [System.Random]$LocalRng = $null) {
        if ($null -eq $LocalRng) { $LocalRng = $this.Rng }
        $item = Get-Item $Path -ErrorAction SilentlyContinue
        if ($item) {
            $attrs = $item.Attributes
            # Probabilistic attributes for unauffälligkeit
            if ($LocalRng.NextDouble() -lt 0.6) { $attrs = $attrs -bor [System.IO.FileAttributes]::ReadOnly }
            if ($LocalRng.NextDouble() -lt 0.45) { $attrs = $attrs -bor [System.IO.FileAttributes]::Hidden }
            if ($LocalRng.NextDouble() -lt 0.3) { $attrs = $attrs -bor [System.IO.FileAttributes]::Archive }
            $item.Attributes = $attrs
        }
    }

    [void]Cleanup() {
        Remove-Item -Path $this.BasePath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$generator = [NoiseGenerator]::new($Seed, $DryRun.IsPresent)

if ($Cleanup) {
    $generator.Cleanup()
    Write-Host "Professional cleanup completed."
} else {
    try {
        $generator.CreateStructure()
        $generator.GenerateFiles($MaxFiles)
        Write-Host "Generated maximal noise (~$MaxFiles files) with minimal detectability in $($generator.BasePath)"
    } catch {
        Write-Error "Generation failed: $_"
    }
}

if ($DryRun) { Write-Host "Dry run completed - no changes made." }
