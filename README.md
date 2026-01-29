# Projet : Gestion Collection — Déploiement Docker & Kubernetes

**Remplacez ce bloc par les Nom(s) et Prénom(s) des membre(s) du groupe**
- Deumeni Ngaleu Cécile-Audrée

---

## 1. Présentation
Ce dépôt contient l'infrastructure (Docker Compose + manifests Kubernetes) pour une application de gestion de collection (frontend + backend) avec une base de données MySQL, un outil d'administration et un tunnel Cloudflare pour exposition HTTPS publique.

L'objectif de ce dépôt est de servir de livrable pour un projet DevOps — conteneurisation, orchestration, persistance et exposition sécurisée.

## 2. Architecture technique
- Frontend : service web (Vite/Static)
- Backend : API Node.js
- BDD : MySQL (PVC)
- Admin : Dockge (ou interface d'administration)
- Reverse Proxy : Caddy (point d'entrée)
- Tunnel public : cloudflared (Cloudflare Tunnel)

Schéma (simplifié) :

Frontend <---> Caddy <---> Backend <---> MySQL (PVC)
                         |
                         +--> cloudflared -> Internet (HTTPS)

## 3. Contenu du dépôt
- `compose/compose.yml` : fichier Docker Compose principal
- `compose/.env` : variables d'environnement (local)
- `kubernete/` : manifests Kubernetes + scripts
  - `0-namespace.yml`, `1-configmap.yml`, `2-networkpolicy.yml`
  - `mysql/`, `backend/`, `frontend/` : manifests respectifs
  - `create-secrets.ps1` : script PowerShell pour créer les secrets depuis `compose/.env`
  - `3-secrets.yml` : template (ne contient pas de secrets en clair)

## 4. Lancer le projet (Docker Compose)
1. Placer vos variables dans `compose/.env`.
2. Démarrer Docker Desktop (Windows) ou avoir Docker Engine actif.
3. Depuis le répertoire `compose` :

```bash
# Lancer tous les services
docker compose up -d --build

# Voir les logs
docker compose logs -f

# Arrêter
docker compose down
```

Important : `compose/compose.yml` utilise des réseaux externes (`app_network`, `public`, `private`). Créez-les si besoin :

```bash
docker network create app_network
docker network create public
docker network create private
```

## 5. Lancer le projet (Minikube / Kubernetes)
### Pré-requis
- `minikube`, `kubectl`, Docker CLI
- Démarrer Minikube : `minikube start --driver=docker`
- Pointer Docker sur Minikube pour builder les images :

```powershell
minikube docker-env | Invoke-Expression
docker build -t collection-backend:latest ./compose/app/backend
docker build -t collection-frontend:latest ./compose/app/frontend
```

### Déployer
```bash
cd kubernete
# Créer namespace et configmaps
kubectl apply -f 0-namespace.yml
kubectl apply -f 1-configmap.yml
kubectl apply -f 2-networkpolicy.yml

# Créer les secrets depuis le .env (Windows PowerShell)
./create-secrets.ps1

# Déployer les composants
kubectl apply -f mysql/
kubectl apply -f backend/
kubectl apply -f frontend/
# (Optionnel) kubectl apply -f cloudflared/  # si vous voulez exposer via Cloudflare
```

## 6. Secrets & sécurité
- Les secrets ne sont PAS stockés en clair dans le repo. Utilisez `compose/.env` localement et `kubernete/create-secrets.ps1` pour créer `mysql-secret` et `backend-secret`.
- `3-secrets.yml` est un template et ne doit pas contenir de données sensibles.

## 7. Commandes utiles
- Vérifier les pods : `kubectl get pods -n app`
- Vérifier les services : `kubectl get svc -n app`
- Vérifier les PVC : `kubectl get pvc -n app`
- Logs : `kubectl logs -n app -l app=backend -f`
- Port-forward : `kubectl port-forward -n app svc/frontend 5173:5173`

## 8. Transparence IA
Outils d'IA utilisés pour ce dépôt :
- ChatGPT / Copilot : aide à la génération des manifests, scripts PowerShell et rédaction du README (revues & ajustements réalisés manuellement).

## Méthodologie

Organisation et répartition des tâches :
- Gestion de projet : 1 responsable (coordination, validation des livrables).
- Infra & CI : 1 ingénieur (manifests Kubernetes, Dockerfiles, scripts de déploiement).
- Application (frontend/backend) : 1 développeur (API et UI minimales, points d'entrée).

Outils utilisés :
- Développement : VS Code, Git
- Conteneurisation : Docker, Docker Compose
- Orchestration : Minikube, kubectl
- Automatisation : Makefile, PowerShell (script de création de secrets)
- Diagrammes : PlantUML

Workflow proposé :
1. Branching : `main` pour la livraison, `feature/*` pour le développement.
2. Développement local : builder et tester via `docker compose up --build`.
3. Test en cluster local : démarrer Minikube, builder les images dans l'environnement Minikube, puis `make k8s-apply`.
4. Secrets : garder les secrets hors du dépôt (fichier local `.env`) et utiliser `kubernete/create-secrets.ps1` pour les injecter dans Kubernetes.
5. Revue & validation : vérifier que les pods sont `Running`, exécuter les tests manuels via `port-forward`.

Bonnes pratiques recommandées :
- Ne jamais committer de secrets ni `.env` dans le dépôt.
- Définir `imagePullPolicy` et tags d'image explicites pour la reproductibilité.
- Ajouter des probes (`liveness`/`readiness`) et limites de ressources pour chaque déploiement.
- Documenter toute étape manuelle dans le `README.md`.

## 9. Problèmes courants à l'installation et résolutions
### 9.1 Docker command not found / daemon not running
- Symptom: `docker build` échoue avec connexion pipe error.
- Solution: démarrer Docker Desktop (ou WSL2), ou exécuter `minikube start` et `minikube docker-env | Invoke-Expression` avant de builder.

### 9.2 `path not found` lors du build
- Symptom: `unable to prepare context: path "./app/backend" not found`
- Solution: lancer la commande depuis le bon répertoire ou corriger le chemin vers `compose/app/backend`.

### 9.3 ImagePullBackOff
- Symptom: Pods en échec avec `ImagePullBackOff`.
- Cause: l'image n'est pas présente dans le registry du cluster.
- Solution: builder l'image dans l'environnement Docker de Minikube ou pousser vers un registry accessible. Pour Minikube :

```powershell
minikube docker-env | Invoke-Expression
# puis docker build -t collection-backend:latest ./compose/app/backend
```

### 9.4 PVC Pending / StorageClass manquante
- Symptom: PVC reste `Pending`.
- Cause: pas de StorageClass disponible ou ressources insuffisantes.
- Solution: configurer `minikube start --driver=docker --memory=8192 --cpus=4` ou ajouter un StorageClass adapté.

### 9.5 Pods en CrashLoopBackOff
- Vérifier les logs du pod : `kubectl logs -n app <pod>`
- Vérifier les probes `liveness`/`readiness` si elles échouent; augmenter `initialDelaySeconds` si nécessaire.

### 9.6 Erreur lors de la création des secrets (Windows PowerShell)
- Symptom: erreurs liées à `grep` ou options non supportées.
- Solution: utilisez le script PowerShell fourni `kubernete/create-secrets.ps1` (corrige les commandes Unix vs PowerShell).

### 9.7 Cloudflared / Tunnel
- Pour exposer via Cloudflare, vous devez configurer un tunnel côté Cloudflare (compte + credentials). Le manifeste `cloudflared/deployment.yml` utilise l'image `cloudflare/cloudflared` mais nécessite des credentials/secret pour fonctionner en production.
- Pour tests locaux via Minikube, vous pouvez éviter cloudflared et utiliser `minikube service` ou `kubectl port-forward`.

## 10. Checklist pour la remise
- [ ] `README.md` à la racine avec noms/prénoms inclus
- [ ] `docker-compose.yml` fonctionnel et testé
- [ ] Images buildables et déployables (Docker / Minikube)
- [ ] Manifest Kubernetes et script de création des secrets
- [ ] Rapport (README) expliquant architecture, déploiement et outils IA utilisés

---

Si vous voulez, j'ajoute maintenant :
- Le schéma UML en SVG/PNG dans le repo
- Un `Makefile` pour automatiser build/deploy
- Un guide rapide pour configurer Cloudflare Tunnel (création des credentials)

Dites-moi ce que je dois faire ensuite.

## Diagramme UML

Le schéma d'architecture PlantUML est disponible dans `docs/architecture.puml`.

Pour générer une image depuis le `.puml` :

```bash
# Avec PlantUML (jar)
java -jar plantuml.jar docs/architecture.puml

# Ou via l'extension PlantUML de VSCode (prévisualisation / export)
```

## Makefile d'automatisation

Un `Makefile` a été ajouté à la racine pour automatiser les tâches courantes : build d'images, déploiement en Compose et Kubernetes, création des secrets et accès aux logs.

Utilisation rapide :

```bash
# Builder les images
make build-backend
make build-frontend

# Déployer en Minikube (création des secrets via PowerShell)
make k8s-apply

# Lancer via Docker Compose
make compose-up

# Supprimer namespace Kubernetes
make k8s-delete
```

IA: Copilot