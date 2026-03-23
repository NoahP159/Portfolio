# --- Liste des services à contrôler ---
$servicesAControle = @(
    "W3SVC",
    "MSSQLSERVER",
    "Spooler",
    "BITS",
    "Dhcp",
    "TermService",
    "LanmanWorkstation", # Service Workstation
    "Netlogon",           # Ouverture de session réseau
    "Dnscache",           # Client DNS
    "RpcSs",              # RPC
    "SysMain",            # Superfetch
    "Themes",             # Thèmes Windows
    "DoSvc",              # Optimisation de livraison
    "CertSvc"             # Services de certificat AD (si applicable)
)

# --- Initialisation ---
$rapport = @()
$dateExecutionScript = Get-Date
$statutEnCours = 'Running'

Write-Host "Initialisation de la surveillance des services Windows..." -ForegroundColor DarkYellow
Write-Host "Date et heure de début : $($dateExecutionScript.ToString('F'))" -ForegroundColor DarkGray

# --- Boucle de contrôle des services ---
foreach ($svc in $servicesAControle) {

    Write-Host "Traitement du service : $($svc.ToUpper())" -ForegroundColor Cyan

    try {
        $etat = Get-Service -Name $svc -ErrorAction Stop
        $tempStatusCheck = $etat.Status

        Write-Host "Statut actuel de '$svc' : $tempStatusCheck" -ForegroundColor White
    }
    catch {
        Write-Warning "Le service '$svc' n'a pas été trouvé ou est inaccessible. Ignoré."

        $ligneErreur = [PSCustomObject]@{
            Service = $svc
            Etat    = "Introuvable/Inaccessible"
            Date    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Relance = "N/A"
        }

        $rapport += $ligneErreur
        continue
    }

    # --- Création de la ligne de rapport ---
    $ligne = [PSCustomObject]@{
        Service = $svc
        Etat    = $etat.Status
        Date    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Relance = ""
    }

    $rapport += $ligne

    # --- Vérification et relance si nécessaire ---
    if ($etat.Status -ne $statutEnCours) {

        Write-Host "Le service '$svc' n'est PAS en cours d'exécution. Tentative de démarrage..." -ForegroundColor Yellow

        try {
            Start-Service -Name $svc -ErrorAction Stop
            $ligne.Relance = "Tentative de relance effectuée"

            Write-Host "Le service '$svc' a été démarré avec succès." -ForegroundColor Green
        }
        catch {
            $ligne.Relance = "Échec de la relance"

            Write-Error "Échec du démarrage du service '$svc'. Erreur : $($_.Exception.Message)"
        }

    } else {
        Write-Host "Le service '$svc' est déjà en cours d'exécution. OK." -ForegroundColor Green
        $ligne.Relance = "OK"
    }

    Write-Host ""
}

# --- Affichage du rapport ---
Write-Host "--- Rapport de Surveillance des Services ---" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host ""

$rapport | Format-Table -AutoSize

Write-Host ""

# --- Sauvegarde du rapport ---
$cheminBureau = [Environment]::GetFolderPath("Desktop")
$nomFichier = "RapportServices_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$cheminLog = Join-Path -Path $cheminBureau -ChildPath $nomFichier

$fichierEcritAvecSucces = $false

try {
    $rapport | Out-File -FilePath $cheminLog -Encoding UTF8 -Force
    $fichierEcritAvecSucces = $true
}
catch {
    Write-Error "Échec de l'enregistrement du rapport dans '$cheminLog'. Erreur : $($_.Exception.Message)"
}

# --- Résultat de la sauvegarde ---
if ($fichierEcritAvecSucces) {
    Write-Host "Rapport généré et sauvegardé avec succès :" -ForegroundColor Green
    Write-Host $cheminLog -ForegroundColor Green
}
else {
    Write-Host "Le rapport n'a pas pu être sauvegardé. Vérifiez les erreurs ci-dessus." -ForegroundColor Red
}

# --- Fin du script ---
$dateFinExecution = Get-Date
$dureeExecution = $dateFinExecution - $dateExecutionScript

Write-Host ""
Write-Host "--- Surveillance des services terminée ---" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "Temps d'exécution total : $($dureeExecution.TotalSeconds) secondes." -ForegroundColor DarkGray