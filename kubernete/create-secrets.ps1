# Script pour creer les secrets Kubernetes depuis le .env
# Utilisation: ./create-secrets.ps1

param(
    [string]$EnvFile = "../compose/.env",
    [string]$Namespace = "app"
)

# Verifier que le fichier .env existe
if (-not (Test-Path $EnvFile)) {
    Write-Error "Fichier .env introuvable: $EnvFile"
    exit 1
}

Write-Host "Lecture du fichier .env depuis: $EnvFile" -ForegroundColor Green

# Lire le fichier .env et creer un hashtable
$envVars = @{}
Get-Content $EnvFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#")) {
        $parts = $line -split "=", 2
        if ($parts.Count -eq 2) {
            $envVars[$parts[0].Trim()] = $parts[1].Trim()
        }
    }
}

Write-Host "Variables lues du .env:" -ForegroundColor Cyan
$envVars.Keys | ForEach-Object { Write-Host "   - $_" }

# Verifier que le namespace existe
Write-Host "`nVerification du namespace: $Namespace" -ForegroundColor Green
$nsExists = kubectl get namespace $Namespace 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERREUR: Le namespace '$Namespace' n'existe pas!" -ForegroundColor Red
    Write-Host "Creez-le avec: kubectl apply -f 0-namespace.yml" -ForegroundColor Yellow
    exit 1
}
Write-Host "Namespace trouve" -ForegroundColor Green

# Creer le secret MySQL
Write-Host "`nCreation du secret 'mysql-secret'..." -ForegroundColor Green

$mysqlSecretData = @{
    "MYSQL_ROOT_PASSWORD" = $envVars["DB_PASSWORD"]
    "MYSQL_DATABASE"      = $envVars["DB_NAME"]
    "MYSQL_USER"          = $envVars["DB_USER"]
    "MYSQL_PASSWORD"      = $envVars["DB_PASSWORD"]
}

# Verifier les valeurs requises
$missingVars = @()
if (-not $mysqlSecretData["MYSQL_ROOT_PASSWORD"]) { $missingVars += "DB_PASSWORD" }
if (-not $mysqlSecretData["MYSQL_DATABASE"]) { $missingVars += "DB_NAME" }
if (-not $mysqlSecretData["MYSQL_USER"]) { $missingVars += "DB_USER" }

if ($missingVars.Count -gt 0) {
    Write-Host "ERREUR: Variables manquantes dans le .env: $($missingVars -join ', ')" -ForegroundColor Red
    exit 1
}

# Supprimer le secret existant s'il existe
kubectl delete secret mysql-secret -n $Namespace --ignore-not-found=true | Out-Null

# Creer le secret
kubectl create secret generic mysql-secret `
    -n $Namespace `
    --from-literal=MYSQL_ROOT_PASSWORD="$($mysqlSecretData['MYSQL_ROOT_PASSWORD'])" `
    --from-literal=MYSQL_DATABASE="$($mysqlSecretData['MYSQL_DATABASE'])" `
    --from-literal=MYSQL_USER="$($mysqlSecretData['MYSQL_USER'])" `
    --from-literal=MYSQL_PASSWORD="$($mysqlSecretData['MYSQL_PASSWORD'])" | Out-Null

Write-Host "Secret 'mysql-secret' cree avec succes" -ForegroundColor Green

# Creer le secret Backend
Write-Host "`nCreation du secret 'backend-secret'..." -ForegroundColor Green

$backendSecretData = @{
    "DB_HOST"      = "mysql.$Namespace.svc.cluster.local"
    "DB_PORT"      = "3306"
    "DB_USER"      = $envVars["DB_USER"]
    "DB_PASSWORD"  = $envVars["DB_PASSWORD"]
    "DB_NAME"      = $envVars["DB_NAME"]
    "BACKEND_PORT" = $envVars["BACKEND_PORT"]
}

# Supprimer le secret existant s'il existe
kubectl delete secret backend-secret -n $Namespace --ignore-not-found=true | Out-Null

# Creer le secret
kubectl create secret generic backend-secret `
    -n $Namespace `
    --from-literal=DB_HOST="$($backendSecretData['DB_HOST'])" `
    --from-literal=DB_PORT="$($backendSecretData['DB_PORT'])" `
    --from-literal=DB_USER="$($backendSecretData['DB_USER'])" `
    --from-literal=DB_PASSWORD="$($backendSecretData['DB_PASSWORD'])" `
    --from-literal=DB_NAME="$($backendSecretData['DB_NAME'])" `
    --from-literal=BACKEND_PORT="$($backendSecretData['BACKEND_PORT'])" | Out-Null

Write-Host "Secret 'backend-secret' cree avec succes" -ForegroundColor Green

# Afficher les secrets crees
Write-Host "`nSecrets crees:" -ForegroundColor Cyan
kubectl get secrets -n $Namespace | Select-String -Pattern "(mysql-secret|backend-secret)"

Write-Host "`nTous les secrets ont ete crees avec succes!" -ForegroundColor Green
Write-Host "Vous pouvez maintenant deployer les pods." -ForegroundColor Green
