# Kubernetes avec Minikube

Guide d'installation et déploiement avec Minikube.

## Prérequis

- **Minikube** installé
- **kubectl** installé
- **Docker** (ou Podman/autre driver Minikube)
- **Git Bash** ou **PowerShell** avec WSL2

## Installation de Minikube (si pas encore fait)

### Windows avec WSL2

```powershell
# Installer Minikube avec Chocolatey
choco install minikube

# Ou télécharger manuellement depuis https://minikube.sigs.k8s.io/docs/start/

# Démarrer Minikube avec WSL2
minikube start --driver=docker

# Ou avec Hyper-V
minikube start --driver=hyperv
```

## Démarrer Minikube

```powershell
# Démarrer le cluster
minikube start

# Vérifier le statut
minikube status

# Obtenir les informations
kubectl cluster-info
```

## Builder les images Docker

### Option 1 : Utiliser le Docker de Minikube (Recommandé)

```powershell
# Pointer vers le Docker de Minikube
minikube docker-env | Invoke-Expression

# Vérifier que vous utilisez le Docker de Minikube
docker ps

# Builder les images
docker build -t collection-backend:latest ./app/backend
docker build -t collection-frontend:latest ./app/frontend

# Vérifier les images
docker images
```

### Option 2 : Builder localement et pusher vers registry

```powershell
# Builder localement
docker build -t localhost:5000/collection-backend:latest ./app/backend
docker build -t localhost:5000/collection-frontend:latest ./app/frontend

# Pousser vers un registry local (nécessite setup supplémentaire)
docker push localhost:5000/collection-backend:latest
docker push localhost:5000/collection-frontend:latest
```

## Adapter les manifests pour Minikube

Les fichiers Kubernetes sont déjà compatibles ! Quelques ajustements optionnels :

### 1. ImagePullPolicy - Déploiements backend/frontend

Pour utiliser les images du Docker de Minikube, modifier les déploiements :

```yaml
containers:
  - name: backend
    image: collection-backend:latest
    imagePullPolicy: Never  # ← Ajouter ceci si images locales
```

Fichiers à modifier :
- [backend/deployment.yml](backend/deployment.yml#L17)
- [frontend/deployment.yml](frontend/deployment.yml#L17)

### 2. Accès aux services

Avec Minikube, utiliser `NodePort` pour accéder aux services :

```powershell
# Accéder au service caddy-private
minikube service caddy-private -n app

# Accéder au backend (port-forward)
kubectl port-forward -n app svc/backend 5000:5000

# Accéder au frontend
kubectl port-forward -n app svc/frontend 5173:5173
```

## Déploiement étape par étape

### 1. Préparer les images

```powershell
# Pointer vers Docker de Minikube
minikube docker-env | Invoke-Expression

# Builder
docker build -t collection-backend:latest ./app/backend
docker build -t collection-frontend:latest ./app/frontend

# Vérifier
docker images | grep collection
```

### 2. Configurer les secrets

Éditer [3-secrets.yml](3-secrets.yml) (déjà fait ✅)

### 3. Déployer dans l'ordre

```powershell
# Aller au dossier kubernete
cd kubernete

# Appliquer les manifests (ordre conseillé)
kubectl apply -f 0-namespace.yml
kubectl apply -f 1-configmap.yml
kubectl apply -f 2-networkpolicy.yml
kubectl apply -f 3-secrets.yml

# MySQL
kubectl apply -f mysql/

# Attendre que MySQL soit prêt
kubectl wait --for=condition=ready pod -l app=mysql -n app --timeout=300s

# Backend
kubectl apply -f backend/

# Frontend
kubectl apply -f frontend/

# Caddy
kubectl apply -f caddy/

# Cloudflared
kubectl apply -f cloudflared/
```

Ou en une seule commande (une fois tout prêt) :
```powershell
kubectl apply -f .
```

### 4. Vérifier le déploiement

```powershell
# Voir tous les pods
kubectl get pods -n app

# Voir les services
kubectl get svc -n app

# Voir les PVC
kubectl get pvc -n app

# Voir les détails
kubectl describe pod -n app -l app=mysql
kubectl describe pod -n app -l app=backend
```

## Accéder à l'application

### Frontend

```powershell
# Méthode 1 : Port-forward
kubectl port-forward -n app svc/frontend 5173:5173
# Accéder à http://localhost:5173

# Méthode 2 : NodePort (modifier service-private.yml pour frontend)
minikube service frontend -n app
```

### Backend

```powershell
# Port-forward
kubectl port-forward -n app svc/backend 5000:5000
# Accéder à http://localhost:5000
```

### MySQL

```powershell
# Port-forward
kubectl port-forward -n app svc/mysql 3306:3306
# Se connecter : mysql -h localhost -u collection_user -p
```

### Dockge (Caddy Private)

```powershell
# Obtenir le NodePort
kubectl get svc caddy-private -n app

# Accéder via Minikube
minikube service caddy-private -n app

# Ou accéder directement à l'IP Minikube
$MINIKUBE_IP = minikube ip
# http://$MINIKUBE_IP:30080
```

## Commandes utiles

```powershell
# Logs d'un service
kubectl logs -n app -l app=mysql
kubectl logs -n app -l app=backend -f  # -f pour follow

# Exécuter une commande dans un pod
kubectl exec -n app -it <pod-name> -- sh

# Copier fichiers
kubectl cp -n app <pod-name>:/etc/caddy ./config

# Dashboard Minikube
minikube dashboard

# Arrêter Minikube
minikube stop

# Supprimer Minikube
minikube delete
```

## Troubleshooting

### ImagePullBackOff

**Problème** : Pod ne démarre pas avec erreur ImagePullBackOff

**Solution** :
```powershell
# Vérifier les images dans Minikube
minikube docker-env | Invoke-Expression
docker images

# Vérifier imagePullPolicy dans les deployments
kubectl get deployment -n app backend -o yaml | grep -i imagepull
```

### MySQL ne démarre pas

```powershell
# Vérifier les logs
kubectl logs -n app -l app=mysql

# Vérifier le PVC
kubectl get pvc -n app
kubectl describe pvc mysql-data-pvc -n app

# Vérifier les ressources
minikube ssh
mount | grep mysql
```

### Backend ne peut pas se connecter à MySQL

```powershell
# Tester la connectivité
kubectl exec -n app -it <backend-pod> -- sh
# Dans le container :
nc -zv mysql.app.svc.cluster.local 3306

# Vérifier les services
kubectl get svc -n app
kubectl describe svc mysql -n app
```

### Pods restent en Pending

```powershell
# Vérifier les ressources du cluster
kubectl top nodes
kubectl top pods -n app

# Augmenter les ressources Minikube
minikube stop
minikube start --cpus=4 --memory=8192

# Ou via config
minikube config set cpus 4
minikube config set memory 8192
minikube start
```

## Configuration Minikube avancée

```powershell
# Vérifier la config actuelle
minikube config view

# Définir les ressources par défaut
minikube config set cpus 4
minikube config set memory 8192

# Utiliser un driver spécifique
minikube start --driver=hyperv

# Activer addons
minikube addons list
minikube addons enable metrics-server
minikube addons enable ingress

# Pour Ingress (optionnel - si vous voulez l'utiliser à la place de Caddy)
minikube addons enable ingress
```

## Migration de Compose vers Minikube

### Résumé des changements

1. **Namespace** : Tous les services dans `app`
2. **Networking** : Services Kubernetes à la place des réseaux Docker
3. **Storage** : PVC à la place des volumes nommés Docker
4. **Images** : Buildées dans/avec Minikube
5. **Secrets** : ConfigMap + Secret Kubernetes

### Vérification complète

```powershell
# Tous les pods running
kubectl get pods -n app

# Tous les services
kubectl get svc -n app

# Tous les PVC
kubectl get pvc -n app

# Tous les secrets et configmaps
kubectl get secrets,cm -n app
```

## Nettoyage

```powershell
# Supprimer le namespace (tout ce qu'il contient)
kubectl delete namespace app

# Supprimer tous les pods
kubectl delete pods --all -n app

# Arrêter Minikube (garde les données)
minikube stop

# Supprimer le cluster Minikube
minikube delete
```
