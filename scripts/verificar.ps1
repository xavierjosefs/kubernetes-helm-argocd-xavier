$ErrorActionPreference = "Stop"
Write-Host "--- Nodos Kubernetes ---" -ForegroundColor Cyan
kubectl get nodes
Write-Host "--- Estado de la aplicacion GitOps ---" -ForegroundColor Cyan
kubectl -n argocd get applications.argoproj.io xavier-web -o wide
Write-Host "--- Deployment, Service y Pods ---" -ForegroundColor Cyan
kubectl get deploy,svc,pods -n demo-gitops
Write-Host "--- Replicas deseadas / actualizadas / disponibles ---" -ForegroundColor Cyan
kubectl get deploy xavier-xavier-web -n demo-gitops -o jsonpath='{.spec.replicas}{" / "}{.status.updatedReplicas}{" / "}{.status.availableReplicas}'
Write-Host ""
