# 🎓 Projet Moodle-LFM (Stack lafaom-mao)

Ce projet orchestre l'infrastructure Docker de la plateforme **Moodle**, son système de **Backups** et son **Monitoring**, le tout intégré à l'écosystème **Lafaom-Mao**.

---

## 🏗️ Explication des Composants (Pourquoi chaque truc ?)

### 🚪 1. Reverse Proxy (Caddy)

_Non présent dans ce docker-compose mais essentiel en amont._

- **C'est quoi ?** Le point d'entrée unique de votre serveur.
- **Pourquoi ?** Il reçoit les connexions sécurisées (HTTPS) et les distribue intelligemment :
  - Si vous demandez `moodle.lafaom-mao.org`, il envoie vers ce projet (port 8080).
  - Si vous demandez `api.lafaom-mao.org`, il envoie vers le backend FastAPI.
- **Le plus :** Il gère les certificats SSL (cadenas vert) automatiquement.

### 🏫 2. Moodle App (`moodle_app`)

- **C'est quoi ?** L'application web Moodle (PHP/Apache).
- **Pourquoi ?** C'est ici que les professeurs déposent les cours et que les étudiants se connectent. Nous utilisons l'image **Bitnami** car elle est pré-configurée pour être sécurisée et performante.
- **Optimisation :** Nous avons augmenté les limites PHP (512Mo RAM, 500Mo d'upload) pour que la plateforme ne sature pas lors de l'ajout de vidéos.

### 🗄️ 3. Moodle DB (`moodle_postgres`)

- **C'est quoi ?** Base de données PostgreSQL 16.
- **Pourquoi ?** C'est le "cerveau" de Moodle. Elle stocke les notes, les comptes utilisateurs, et la structure des cours. Elle est **isolée** pour qu'un problème sur le backend principal ne bloque pas Moodle.

### ⏰ 4. Scheduler (`cron_scheduler`) via Ofelia

- **C'est quoi ?** Un planificateur de tâches intégré à Docker.
- **Pourquoi ?** Moodle a besoin de nettoyer ses caches et de lancer des sauvegardes. Ofelia remplace le "crontab" classique du serveur. Si vous déplacez le dossier du projet sur un autre serveur, les sauvegardes continuent de fonctionner sans rien configurer sur le serveur hôte.

### 🕵️‍♂️ 5. cAdvisor (`cadvisor`)

- **C'est quoi ?** Un "espion" de ressources Docker.
- **Pourquoi ?** Il analyse en temps réel combien de CPU et de RAM consomme chaque container. C'est lui qui fournit les données de base pour voir si le serveur va exploser ou s'il est à l'aise.

### 📊 6. Prometheus (`prometheus`)

- **C'est quoi ?** Une base de données spécialisée dans les chiffres (métriques).
- **Pourquoi ?** Il va interroger cAdvisor et Moodle toutes les 15 secondes pour enregistrer l'historique des performances.

### 📈 7. Grafana (`grafana`)

- **C'est quoi ?** Votre tableau de bord visuel.
- **Pourquoi ?** C'est la "vitrine" du monitoring. Il transforme les chiffres compliqués de Prometheus en beaux graphiques (Dashboard inclu dans `/monitoring/grafana`).

---

## ❓ Pourquoi avoir enlevé le job `backend (lfm-back)` de Prometheus ?

Vous avez remarqué que j'ai supprimé la ligne qui cherchait les métriques du backend FastAPI directement dans `prometheus.yml`. Voici pourquoi :

1. **Isolation & Modularité** : Ce dépôt est dédié à Moodle. Le backend `lfm-back` vit dans son propre dossier et son propre cycle de vie. Mélanger les configurations rendrait le projet "moodle" dépendant du projet "backend" pour démarrer sans erreur.
2. **cAdvisor fait déjà le travail** : C'est le point le plus important ! **cAdvisor voit tous les containers du serveur**. Dans votre Dashboard Grafana, vous verrez quand même l'utilisation CPU/RAM du container du backend car cAdvisor le détecte automatiquement.
3. **Éviter les erreurs de résolution** : Le container backend (`app`) n'est pas défini dans ce `docker-compose.yaml`. Si on laisse le job dans Prometheus, il afficherait une erreur "Down" en permanence dans les logs car il ne trouverait pas l'hôte `app`.
4. **Clean Code** : Chaque projet doit être capable de tourner seul. Si vous voulez des métriques spécifiques (internes) au Python du backend, il vaudra mieux avoir un Prometheus central ou ajouter ce job uniquement sur le serveur de production.

---

## 🚦 Comment tout fonctionne ensemble ?

1. **Lancement** : `docker compose up -d`.
2. **Sauvegarde** : Chaque nuit à 2h, Ofelia lance le script `backup.sh`. Ce script "entre" dans les bases de données, fait un export SQL, et compresse le tout dans le dossier `backups/`.
3. **Monitoring** :
   - cAdvisor analyse les containers.
   - Prometheus stocke les analyses.
   - Vous consultez les résultats sur `IP_SERVEUR:3000` (Grafana).
4. **Utilisateur** : Passe par Caddy -> Moodle. Si Moodle a besoin de savoir qui est l'utilisateur, il demande au Backend (SSO) via les tokens JWT.

---

_Ce document explique la structure actuelle pour l'équipe de développement lafaom-mao._
