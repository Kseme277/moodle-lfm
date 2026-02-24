# 🏗️ Architecture Complète : Moodle & Backend (Stack lafaom-mao)

Ce document fournit une vision détaillée de l'écosystème technique déployé sur votre serveur VPS. L'architecture est conçue pour être **isolée, sécurisée et auto-maintenable**.

---

## 🗺️ Schéma du Flux de Données

1.  **Utilisateur** → HTTPS (Port 443) → **Caddy (Reverse Proxy)**
2.  **Caddy** → Route vers :
    *   `api.lafaom-mao.org` → **FastAPI Backend (8000)**
    *   `moodle.lafaom-mao.org` → **Moodle App (8080)**
    *   `admin.lafaom-mao.org` → **Portainer (9000)**
    *   `monitor.lafaom-mao.org` → **Grafana (3000)**

---

## 🛠️ Détail des Composants

### 1. Frontal & Proxy (Caddy)
*   **Fonction** : Point d'entrée unique.
*   **Pourquoi ?** : Il gère les certificats SSL automatiquement et protège les ports internes.
*   **Configuration** : Il redirige le trafic externe vers les ports Docker (8000, 8081, etc.).

### 2. Plateforme d'Apprentissage (Moodle) - Port 8080
*   **Version** : Bitnami Moodle 5.
*   **Exposition** : Port interne `8080`, exposé sur l'hôte au port **`8080`**.
*   **Authentification (SSO)** : Utilise le plugin `auth_jwtsso`. Moodle valide les tokens envoyés par le backend FastAPI en récupérant la clé publique sur l'endpoint `/api/v1/auth/jwks.json`.

### 3. Logique Applicative (Backend FastAPI) - Port 8000
*   **Fonction** : Gestion du métier, des inscriptions et émission de tokens JWT.
*   **Base de données** : PostgreSQL 15 (`lafaom_db`).

### 4. Automatisation des Tâches (Ofelia) - Le Cerveau CRON
*   **Rôle** : Remplace le `crontab` du serveur pour tout gérer à l'intérieur de Docker.
*   **Fonctionnement** : Il surveille les "labels" Docker. 
*   **Tâches configurées** : 
    *   Sauvegarde complète (BD + Fichiers) tous les jours à 2h00 du matin.
*   **Avantage** : Si vous déplacez le projet sur un autre serveur, les tâches planifiées suivent automatiquement le code.

### 5. Monitoring & Performance (Prometheus + Grafana)
*   **Prometheus** : Base de données de métriques "time-series". Il interroge périodiquement chaque service pour savoir s'il est en ligne et combien de RAM il utilise.
*   **Grafana (Port 3000)** : Votre cockpit visuel. Il affiche des graphiques sur l'usage du processeur, le nombre de requêtes HTTP et l'état de santé global.
*   **cAdvisor** : Un agent léger qui analyse les performances de chaque conteneur Docker.

### 6. Persistance & Cache (PostgreSQL & Redis)
*   **PostgreSQL 16 (Moodle)** : Base de données isolée pour le LMS.
*   **Redis** : Utilisé en commun par le Backend (pour Celery) et Moodle (pour le cache MUC). Cela réduit la consommation RAM globale du serveur.

---

## 💾 Stratégie de Sauvegarde (Backup)
Les sauvegardes sont pilotées par **Ofelia** qui appelle le script `./scripts/backup.sh`.
*   **Destination** : `/home/kseme/Documents/INGE 4/Virtualisation/moodle-lfm/backups/`.
*   **Contenu** : SQL Dump du backend, SQL Dump de Moodle et archive des documents Moodle.

---

## 🚦 Commandes de Gestion Rapide

| Action | Commande |
| :--- | :--- |
| **Lancer tout** | `docker compose up -d` |
| **Voir les logs Ofelia** | `docker logs cron_scheduler` |
| **Checker le monitoring** | Accéder à `IP_SERVEUR:3000` (Grafana) |
| **Vérifier Moodle** | Accéder à `IP_SERVEUR:8080` |
| **Manuel Backup** | `./scripts/backup.sh` |
