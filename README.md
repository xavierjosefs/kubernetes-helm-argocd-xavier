# Kubernetes + Helm + Argo CD (GitOps)

**Estudiante:** Xavier Fernandez  
**ID:** 1122340  
**Actividad:** Cluster local, Helm Chart, repositorio Git, Argo CD y GitOps.

## Estructura

```text
kind-config.yaml
helm/xavier-web/Chart.yaml
helm/xavier-web/values.yaml
helm/xavier-web/templates/_helpers.tpl
helm/xavier-web/templates/configmap.yaml
helm/xavier-web/templates/deployment.yaml
helm/xavier-web/templates/service.yaml
helm/xavier-web/templates/NOTES.txt
argocd/application.yaml
scripts/aplicar-application.ps1
scripts/verificar.ps1
evidencias/INSTRUCCIONES.md
```

## 1. Preparar herramientas (Windows / PowerShell)

Tener **Docker Desktop abierto** y funcionando, con el motor Linux. Instalar (si aun faltan):

```powershell
winget install -e --id Kubernetes.kind
winget install -e --id Kubernetes.kubectl
winget install -e --id Helm.Helm
```

Cerrar y volver a abrir VS Code/PowerShell tras instalar. Confirmar versiones:

```powershell
docker version
kind version
kubectl version --client
helm version
git --version
```

## 2. Crear el cluster local con Kind

Desde la **raiz** de esta carpeta:

```powershell
kind create cluster --name xavier-gitops --config .\kind-config.yaml --wait 5m
kubectl config use-context kind-xavier-gitops
kubectl get nodes
```

El nodo debe mostrar `Ready`. Si hay poca memoria disponible en Docker Desktop, incrementar los recursos asignados al motor (Argo CD despliega varios pods).

## 3. Validar el Helm Chart e instalarlo manualmente

```powershell
helm lint .\helm\xavier-web
helm template prueba-web .\helm\xavier-web
helm install prueba-web .\helm\xavier-web -n demo-helm --create-namespace
kubectl get deploy,svc,pods -n demo-helm
kubectl rollout status deployment/prueba-web-xavier-web -n demo-helm --timeout=180s
helm uninstall prueba-web -n demo-helm
```

Esto prueba `helm install` en `demo-helm`, distinto del namespace `demo-gitops` que administrara Argo CD. **No usar `helm upgrade` manualmente para la aplicacion de Argo CD**: los cambios deben venir de Git.

## 4. Publicar este proyecto en GitHub

Crear desde la web un **repositorio publico vacio**, por ejemplo `kubernetes-helm-argocd-xavier`, **sin crear README, licencia ni .gitignore** (ya existen localmente). Desde esta carpeta:

```powershell
git status
git remote add origin https://github.com/TU_USUARIO/kubernetes-helm-argocd-xavier.git
git push -u origin main
```

El ZIP ya contiene un commit local en la rama `main`, asi que no es necesario repetir `git init`. Si al extraer el ZIP Windows no conserva el directorio oculto `.git`, usar antes de `git remote add`:

```powershell
git init
git branch -M main
git add .
git commit -m "feat: helm chart inicial y application GitOps"
```

**IMPORTANTE:** sustituir `TU_USUARIO` por el usuario de GitHub real; no escribir un link ficticio en la entrega. Un repositorio publico permite a Argo CD clonar sin credenciales.

## 5. Instalar Argo CD con Helm

```powershell
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd --namespace argocd --create-namespace --wait --timeout 10m
kubectl get pods -n argocd
kubectl rollout status deployment/argocd-server -n argocd --timeout=300s
```

Abrir **otra terminal** y mantenerla corriendo:

```powershell
kubectl -n argocd port-forward svc/argocd-server 8081:443
```

Navegar a <https://localhost:8081> (el certificado es autofirmado en este entorno local). Usuario: `admin`. Leer la contrasena inicial **solo en tu terminal**:

```powershell
$b64 = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}'
[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($b64))
```

No incluir contrasenas en capturas ni publicar el secreto en GitHub.

## 6. Conectar la Application con GitHub

Despues de hacer `git push`, ejecutar (cambia la URL):

```powershell
.\scripts\aplicar-application.ps1 -RepoUrl "https://github.com/TU_USUARIO/kubernetes-helm-argocd-xavier.git"
kubectl -n argocd get applications.argoproj.io xavier-web -o wide
kubectl get deploy,svc,pods -n demo-gitops
```

El script crea un archivo **local, excluido de Git**, con el repositorio correcto y crea el recurso `Application`. Argo CD usa `main`, lee `helm/xavier-web` y sincroniza en `demo-gitops` con `prune` y `selfHeal` activados.

Revisar Argo CD UI: la aplicacion debe mostrar **Healthy** y **Synced** (cuando termine el despliegue). Si no aparece de inmediato, esperar el sondeo o pulsar Refresh.

Para ver la aplicacion web (otra terminal distinta a la del port-forward de Argo CD):

```powershell
kubectl -n demo-gitops port-forward svc/xavier-xavier-web 8080:80
```

Abrir <http://localhost:8080>.

## 7. Demostracion del cambio GitOps (2 --> 3 replicas)

1. Abrir `helm/xavier-web/values.yaml` y cambiar `replicaCount: 2` por `replicaCount: 3`.
2. Opcional: cambiar `page.version` a `"v2 - Cambio sincronizado por Argo CD"`.
3. Guardar, realizar commit y push:

```powershell
git add helm/xavier-web/values.yaml
git commit -m "feat: escalar web a 3 replicas con GitOps"
git push origin main
```

4. Esperar un momento (Argo CD sondea Git periodicamente), observar la UI y verificar:

```powershell
kubectl get deploy,svc,pods -n demo-gitops
kubectl rollout status deployment/xavier-xavier-web -n demo-gitops --timeout=180s
kubectl get deploy xavier-xavier-web -n demo-gitops -o jsonpath='{.spec.replicas}'
```

El valor esperado de `.spec.replicas` es `3`.

## 8. Rollback desde Git (3 --> 2 replicas)

Si el ultimo commit fue el cambio del paso 7:

```powershell
git revert --no-edit HEAD
git push origin main
```

Esperar la nueva sincronizacion. Comprobar que el Deployment tiene nuevamente `2` replicas y que Argo CD esta `Synced` y `Healthy`:

```powershell
kubectl get deploy,svc,pods -n demo-gitops
kubectl get deploy xavier-xavier-web -n demo-gitops -o jsonpath='{.spec.replicas}'
kubectl -n argocd get applications.argoproj.io xavier-web -o wide
```

Tambien puedes ejecutar `powershell -ExecutionPolicy Bypass -File .\scripts\verificar.ps1` si tu politica local impide ejecutar scripts `.ps1`.

## 9. Capturas requeridas y entrega

En `evidencias/INSTRUCCIONES.md` hay una lista de capturas: nodo Ready, helm install, Argo CD Synced/Healthy, replicacion inicial (2), cambio a 3, rollback a 2 y commits Git. **Las capturas no se han fabricado; deben hacerse sobre tu propia ejecucion**.

Adjuntar: link publico del repo + capturas + informe PDF. El link solo es valido cuando el repositorio se publica efectivamente.

## Fuentes de consulta

- Kind: https://kind.sigs.k8s.io/docs/user/quick-start/
- Helm Charts: https://helm.sh/docs/topics/charts/
- Argo CD instalacion: https://argo-cd.readthedocs.io/en/stable/operator-manual/installation/
- Argo CD auto-sync: https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/
- Argo CD Helm: https://argo-cd.readthedocs.io/en/stable/user-guide/helm/
