# === DÉBUT DU SCRIPT DE FERMETURE DE SESSION ===

# Chemins sources et extensions (identiques à avant)
$fichier_a_sauvegarder_Documents = Join-Path $env:USERPROFILE "Documents"
$fichier_a_sauvegarder_Images = Join-Path $env:USERPROFILE "Pictures"
$extensions = @("*.pdf", "*.doc", "*.docs", "*.xls", "*.xlsx", "*.ppt", "*.pptx", "*.odt", "*.ods", "*.odp", "*.txt", "*.wm1", "*.png", "*.jpg", "*.gif")

# Chemin local de sauvegarde
$sauvegardePath = Join-Path $env:USERPROFILE "Desktop\Sauvegarde"
$sauvegardeDocs = Join-Path $sauvegardePath "Documents"
$sauvegardeImgs = Join-Path $sauvegardePath "Pictures"
$logPath = Join-Path $sauvegardePath "log_sauvegarde.txt"

# Création du log
function Log {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "$timestamp - $message"
}
Set-Content -Path $logPath -Value "===== LOG DE SAUVEGARDE =====`n"

# Créer les dossiers
New-Item -Path $sauvegardeDocs -ItemType Directory -Force | Out-Null
New-Item -Path $sauvegardeImgs -ItemType Directory -Force | Out-Null
Log "Dossiers de sauvegarde créés"

# Fonction de copie
function Copier-Fichiers {
    param (
        [string]$source,
        [string]$destination,
        [string]$type
    )
    $fichiers = Get-ChildItem -Path $source -Recurse -File | Where-Object {
        $extensions -contains "*$($_.Extension)"
    }
    if ($fichiers.Count -gt 0) {
        Log "$($fichiers.Count) fichiers trouvés dans $type"
        foreach ($f in $fichiers) {
            try {
                Copy-Item -Path $f.FullName -Destination $destination -Force
                Log "Copie réussie : $($f.FullName)"
            } catch {
                Log "Erreur de copie : $($f.FullName) - $_"
            }
        }
    } else {
        Log "Aucun fichier à copier dans $type"
    }
}

Copier-Fichiers -source $fichier_a_sauvegarder_Documents -destination $sauvegardeDocs -type "Documents"
Copier-Fichiers -source $fichier_a_sauvegarder_Images -destination $sauvegardeImgs -type "Images"

# Compression du dossier Sauvegarde en .zip
$zipPath = "$env:TEMP\sauvegarde.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path $sauvegardePath\* -DestinationPath $zipPath
Log "Fichiers compressés dans : $zipPath"

try { # Envoi vers le FTP
$ftp = "ftp://192.168.50.40/faure/sauvegarde.zip"
$username = "sisr"
$password = "P@55aran"

$webclient = New-Object System.Net.WebClient
$webclient.Credentials = New-Object System.Net.NetworkCredential($username, $password)
} catch {
    Log "Erreur lors de la connection au serveur"
}
try {
    $webclient.UploadFile($ftp, $zipPath)
    Log "Sauvegarde envoyée avec succès vers le FTP"
} catch {
    Log "Erreur lors de l'envoi FTP : $_"
}

# === FIN DU SCRIPT DE FERMETURE DE SESSION ===
