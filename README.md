Memebre : Deumeni Ngaleu Cécile-Audrée
# 📚 Outil de Gestion de Collection

## 📝 Description

L’**outil de gestion de collection** est une application web permettant aux utilisateurs de cataloguer, organiser et gérer différents types de collections (livres, films, jeux vidéo, objets de collection, etc.).

Ce projet a pour objectif de démontrer des compétences en **développement full-stack**, **architecture REST**, **gestion de bases de données NoSQL** et **déploiement via conteneurs Docker**.

---

## 🚀 Fonctionnalités

### 🔹 Gestion des objets

* Ajout d’éléments à la collection
* Modification des informations existantes
* Suppression d’éléments

### 🔍 Recherche et filtrage

* Recherche rapide par mot-clé
* Filtrage par catégorie, date d’acquisition, état, etc.

### 👁️ Visualisation

* Affichage sous forme de liste ou de grille
* Consultation des détails d’un élément

### 📊 Statistiques

* Nombre total d’éléments
* Répartition par catégorie
* Valeur totale estimée de la collection

---

## 🏗️ Architecture Technique

### Frontend

* **Framework** : React ou Vue.js
* **Fonctionnalités** :

  * Formulaires d’ajout et d’édition
  * Composants de visualisation
  * Communication avec l’API REST

### Backend

* **Technologie** : Node.js + Express
* **API RESTful** :

  * `POST /items` : Ajouter un élément
  * `GET /items` : Récupérer les éléments
  * `PUT /items/:id` : Modifier un élément
  * `DELETE /items/:id` : Supprimer un élément



## 🔄 Flux de Travail

1. L’utilisateur se connecte à l’application
2. Il ajoute un nouvel élément via un formulaire
3. Le frontend envoie une requête POST à l’API
4. Le backend enregistre les données dans MongoDB
5. L’utilisateur peut :

   * Visualiser sa collection
   * Rechercher et filtrer les éléments
   * Consulter les statistiques




