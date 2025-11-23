# =============================================
# PowerShell-Skript: Lade und führe test.ps1 aus (sicherer Temp-Pfad)
# =============================================

# URL zum test.ps1-Skript (passe bei Bedarf an, z.B. auf H3221-Repo)
$Url = "https://raw.githubusercontent.com/KunisCode/2/main/test.ps1"
# $Url = "https://raw.githubusercontent.com/H3221/2/main/test.ps1"  # Alternative

# Temporäre Datei im Temp-Ordner
$ScriptPath = Join-Path $env:TEMP "test.ps1"

try {
    Write-Host "Lade Skript von $Url herunter..." -ForegroundColor Cyan
    
    # Invoke-WebRequest durchführen
    $Response = Invoke-WebRequest -Uri $Url -UseBasicParsing
    
    # Prüfe, ob Inhalt vorhanden (nicht leer)
    if ([string]::IsNullOrWhiteSpace($Response.Content)) {
        throw "Der Download hat keinen Inhalt geliefert (leere URL oder 404)."
    }
    
    # Inhalt in Datei schreiben (im Temp-Ordner)
    $Response.Content | Out-File -FilePath $ScriptPath -Encoding UTF8
    
    Write-Host "Skript erfolgreich heruntergeladen als $ScriptPath" -ForegroundColor Green
    
    # Skript ausführen
    Write-Host "Führe $ScriptPath aus..." -ForegroundColor Yellow
    & $ScriptPath
    
    # Optional: Datei nach Ausführung löschen
    # Remove-Item $ScriptPath -Force
}
catch {
    Write-Host "Fehler beim Herunterladen oder Ausführen!" -ForegroundColor Red
    if ($_.Exception.Response) {
        Write-Host "HTTP-Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    }
    Write-Host $_.Exception.Message -ForegroundColor Red
}
finally {
    # Temp-Datei immer löschen, falls vorhanden
    if (Test-Path $ScriptPath) {
        Remove-Item $ScriptPath -Force
    }
}

Write-Host "Fertig." -ForegroundColor Cyan
