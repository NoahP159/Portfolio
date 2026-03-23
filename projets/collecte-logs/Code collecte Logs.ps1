# --- Configuration des Chemins de Logs des Serveurs ---
$cheminsLogsServeurs = @(
    "\\IPDuServeurTC\C$\Temp\Logs",        # Logs du TC Server
    "\\IPDuServeurWeb\C$\Apache\Logs",    # Logs Apache du Web Server
    "\\IPDuServeurWeb\C$\Tomcat\Logs"     # Logs Tomcat du Web Server
)

# --- Définition du dossier de destination ---
$cheminBureau = [Environment]::GetFolderPath("Desktop")
$dossierDestination = Join-Path -Path $cheminBureau -ChildPath "LogsCollectes"

Write-Host "Démarrage du processus de collecte des logs..."

# --- Création du dossier si nécessaire ---
if (-not (Test-Path $dossierDestination)) {
    New-Item -ItemType Directory -Path $dossierDestination | Out-Null
    Write-Host "Dossier de destination créé : $dossierDestination"
}
else {
    Write-Host "Le dossier de destination existe déjà : $dossierDestination"
}

# --- Parcours des chemins de logs ---
foreach ($cheminLog in $cheminsLogsServeurs) {

    Write-Host "`nTentative de collecte des logs depuis : $cheminLog"

    if (Test-Path $cheminLog) {
        try {
            Get-ChildItem -Path $cheminLog -Recurse -Include *.log | ForEach-Object {

                $fichierSource = $_.FullName
                $fichierDestination = Join-Path -Path $dossierDestination -ChildPath $_.Name

                Write-Host "Copie de $($_.Name) depuis $cheminLog..."

                Copy-Item -Path $fichierSource `
                          -Destination $fichierDestination `
                          -Force `
                          -ErrorAction Stop
            }

            Write-Host "Logs copiés avec succès depuis $cheminLog."
        }
        catch {
            Write-Warning "Échec de la copie des logs depuis $cheminLog. Erreur : $($_.Exception.Message)"
        }
    }
    else {
        Write-Warning "Chemin introuvable ou inaccessible : $cheminLog. Vérifiez le chemin et les autorisations."
    }
}

Write-Host "`nCollecte des logs terminée."
Write-Host "Tous les logs sont dans : $dossierDestination"

# --- Création de l'archive ZIP ---
Write-Host "`nCréation d'une archive ZIP des logs collectés..."

$nomFichierZip = "LogsCollectes_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".zip"
$cheminFichierZip = Join-Path -Path $cheminBureau -ChildPath $nomFichierZip

try {
    Compress-Archive -Path "$dossierDestination\*" `
                     -DestinationPath $cheminFichierZip `
                     -Force

    Write-Host "Archive ZIP créée : $cheminFichierZip"
}
catch {
    Write-Warning "Échec de la création de l'archive ZIP. Erreur : $($_.Exception.Message)"
}

Write-Host "`nScript terminé."