#!/bin/bash

# ==============================================================================
# Script de Sauvegarde Automatique - Écosystème Moodle
# Ce script est piloté par Ofelia pour sauvegarder les bases de données et fichiers.
# ==============================================================================

# Configuration des couleurs pour la sortie console
GREEN='\033[0;32m'
NC='\033[0m' # Pas de couleur (Reset)

# Génération de la date pour l'horodatage des fichiers
DATE=$(date +%Y-%m-%d_%Hh%M)
BACKUP_DIR="./backups/$DATE"

# Création du dossier temporaire pour la sauvegarde du jour
mkdir -p "$BACKUP_DIR"

echo -e "${GREEN}Démarrage de la sauvegarde complète...${NC}"

# 1. Sauvegarde de la Base de données du Backend (FastAPI)
# Note: Ce conteneur doit être nommé 'postgres' dans le réseau Docker
echo "Sauvegarde de la base Backend (lafaom_db)..."
docker exec postgres pg_dump -U afrolancer lafaom_mao > "$BACKUP_DIR/backend_db.sql"

# 2. Sauvegarde de la Base de données de Moodle
# Utilise l'utilitaire pg_dump sur le conteneur 'moodle_postgres'
echo "Sauvegarde de la base Moodle (moodle_db)..."
docker exec moodle_postgres pg_dump -U moodle_user moodle_db > "$BACKUP_DIR/moodle_db.sql"

# 3. Sauvegarde des fichiers physiques de Moodle
# Sauvegarde le volume Docker contenant les documents et fichiers uploadés (moodledata)
echo "Sauvegarde des fichiers Moodle (volumes)..."
tar -czf "$BACKUP_DIR/moodle_data.tar.gz" -C /var/lib/docker/volumes/moodle_lfm_moodle_data/_data . 2>/dev/null || echo "Attention: Le chemin des volumes Docker peut varier selon l'installation."

# 4. Compression finale et Nettoyage
# On compresse tout le dossier du jour en une archive unique
tar -czf "./backups/backup_$DATE.tar.gz" "$BACKUP_DIR"
# Suppression du dossier temporaire non compressé
rm -rf "$BACKUP_DIR"

echo -e "${GREEN}Sauvegarde terminée avec succès : ./backups/backup_$DATE.tar.gz${NC}"
