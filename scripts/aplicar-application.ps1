param(
  [Parameter(Mandatory = $true)]
  [string]$RepoUrl
)
$ErrorActionPreference = "Stop"
if ($RepoUrl -notmatch '^https://github\.com/[^/]+/[^/]+(\.git)?$') {
  throw "Usa la URL HTTPS del repositorio, por ejemplo: https://github.com/usuario/repositorio.git"
}
$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $root "argocd\application.yaml"
$dest = Join-Path $root "argocd\application-local.yaml"
$manifest = (Get-Content -Raw -Encoding UTF8 $src).Replace('URL_REPOSITORIO_GITHUB', $RepoUrl)
[System.IO.File]::WriteAllText($dest, $manifest, (New-Object System.Text.UTF8Encoding($false)))
kubectl apply -f $dest
if ($LASTEXITCODE -ne 0) { throw "No se pudo crear la Application. Comprueba el cluster y Argo CD." }
Write-Host "Application creada. Confirma sincronizacion en Argo CD y kubectl get deploy,svc -n demo-gitops"
