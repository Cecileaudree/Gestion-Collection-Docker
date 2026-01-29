# Kubernetes Configuration

Migration de Docker Compose vers Kubernetes.

## Structure

```
kubernete/
├── 0-namespace.yml          # Namespace "app"
├── 1-configmap.yml          # ConfigMaps globales
├── 2-networkpolicy.yml      # Politiques réseau
├── 3-secrets.yml            # Template (secrets générés via script)
├── create-secrets.ps1       # Script pour créer les secrets depuis .env
├── mysql/
│   ├── pvc.yml              # PersistentVolumeClaim
│   ├── deployment.yml       # Deployment
│   └── service.yml          # Service ClusterIP
├── backend/
│   ├── deployment.yml       # Deployment avec init container
│   └── service.yml          # Service ClusterIP
└── frontend/
    ├── deployment.yml       # Deployment
    └── service.yml          # Service ClusterIP
```

## Installation

### 1. Créer les secrets depuis le .env
```powershell
cd kubernete
./create-secrets.ps1
```

Le script va lire `../compose/.env` et créer les secrets Kubernetes de manière sécurisée.

### 2. Déployer dans l'ordre

```bash
# Namespace et configurations globales
kubectl apply -f 0-namespace.yml
kubectl apply -f 1-configmap.yml
kubectl apply -f 2-networkpolicy.yml

# MySQL
kubectl apply -f mysql/

# Backend (attendra que MySQL soit prêt)
kubectl apply -f backend/

# Frontend
kubectl apply -f frontend/
```

Ou en une seule commande (après création des secrets) :
```bash
kubectl apply -f .
```

## Vérification

```bash
# Vérifier les pods
kubectl get pods -n app

# Vérifier les services
kubectl get svc -n app

# Vérifier les PVC
kubectl get pvc -n app

# Vérifier les secrets
kubectl get secrets -n app

# Logs
kubectl logs -n app -l app=mysql
kubectl logs -n app -l app=backend
kubectl logs -n app -l app=frontend
```

## Accès aux services

### ClusterIP (interne)
- MySQL: `mysql.app.svc.cluster.local:3306`
- Backend: `backend.app.svc.cluster.local:5000`
- Frontend: `frontend.app.svc.cluster.local:5173`

### Port-forwarding (local)
```bash
# Frontend
kubectl port-forward -n app svc/frontend 5173:5173

# Backend
kubectl port-forward -n app svc/backend 5000:5000

# MySQL
kubectl port-forward -n app svc/mysql 3306:3306
```

## Notes importantes

1. **Secrets sécurisés**: Les secrets sont créés via script PowerShell depuis le `.env`. Les données sensibles ne sont jamais en clair dans le contrôle de version.

2. **ImagePullPolicy**: Les déploiements backend/frontend utilisent `Always` pour tirer la dernière image. Changez à `IfNotPresent` si vous utilisez un registry privé ou des images locales.

3. **Replicas**: Backend et Frontend ont 2 replicas. Ajustez selon vos besoins.

4. **Resources**: Les requêtes et limites sont définies. Ajustez selon votre infrastructure.

5. **Health Checks**: Probes configurées. Assurez-vous que vos endpoints `/health` sont implémentés.

6. **Persistent Data**: MySQL utilise un PVC. Vérifiez que le `storageClass` `standard` existe dans votre cluster.

## Différences avec Docker Compose

| Docker Compose | Kubernetes |
|---|---|
| Networks externes | Services + DNS Kubernetes |
| env_file | Secret (créé via script) |
| volumes | PersistentVolumeClaim |
| depends_on | initContainers + readinessProbe |
| ports exposés | Service type (ClusterIP) |
| replicas | Deployment replicas |
| resource limits | resources requests/limits |

## Sécurité

### Gestion des secrets
- **Jamais en clair** dans YAML ou git
- Créés dynamiquement via `create-secrets.ps1`
- Source unique : `../compose/.env`
- Stockés dans Kubernetes Secret

### Fichiers à ignorer
- `3-secrets.yml` est un template - ne pas commiter de vraies données
- `.env` doit rester en dehors du contrôle de version

## Troubleshooting

### Pod ne démarre pas
```bash
kubectl describe pod -n app <pod-name>
```

### MySQL ne démarre pas
```bash
kubectl logs -n app -l app=mysql
```

### Backend ne peut pas se connecter à MySQL
Vérifier :
1. MySQL est running : `kubectl get pods -n app -l app=mysql`
2. Service MySQL existe : `kubectl get svc -n app mysql`
3. Variables d'environnement : `kubectl describe pod -n app -l app=backend`

### Port forwarding pour accéder localement
```bash
# Frontend
kubectl port-forward -n app svc/frontend 5173:5173

# Backend
kubectl port-forward -n app svc/backend 5000:5000

# MySQL
kubectl port-forward -n app svc/mysql 3306:3306
```
