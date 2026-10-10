# Evidencias requeridas para el informe

**No incluir pruebas inventadas.** Registrar las siguientes capturas cuando se ejecute el proyecto en tu PC:

1. `01-nodo-ready.png`: salida de `kubectl get nodes` con estado `Ready`.
2. `02-helm-install.png`: salida de `helm install prueba-web ...` y `kubectl get deploy,svc,pods -n demo-helm`.
3. `03-argocd-synced-healthy.png`: UI de Argo CD con `xavier-web`, estado Synced y Healthy.
4. `04-replicas-iniciales-2.png`: `kubectl get deploy,svc,pods -n demo-gitops` con dos replicas.
5. `05-git-commit-cambio.png`: GitHub mostrando cambio de replicaCount: 2 a 3 (o el terminal `git log`).
6. `06-replicas-3.png`: salida de Kubernetes con tres replicas disponibles y UI de Argo CD sincronizada.
7. `07-rollback-a-2.png`: GitHub con revert y Kubernetes retornando a dos replicas; opcional incluir segunda captura de Argo CD.

Evitar capturar contrasenas de Argo CD o tokens de GitHub.
