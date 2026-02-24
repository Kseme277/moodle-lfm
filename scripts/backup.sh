#!/bin/bash

# Configuration des couleurs
GREEN='\033[0;32m'
NC='\033[0m'

# Date pour le nom du fichier
DATE=$(date +%Y-%m-%d_%Hh%M)
BACKUP_DIR="./backups/$DATE"

mkdir -p "$BACKUP_DIR"

echo -e "${GREEN}Démarrage de la sauvegarde complète...${NC}"

# 1. Sauvegarde Base de données Backend
echo "Sauvegarde de la base Backend (lafaom_db)..."
docker exec postgres pg_dump -U afrolancer lafaom_mao > "$BACKUP_DIR/backend_db.sql"

# 2. Sauvegarde Base de données Moodle
echo "Sauvegarde de la base Moodle (moodle_db)..."
docker exec moodle_postgres pg_dump -U moodle_user moodle_db > "$BACKUP_DIR/moodle_db.sql"

# 3. Sauvegarde des fichiers Moodle (Data)
echo "Sauvegarde des fichiers Moodle (volumes)..."
tar -czf "$BACKUP_DIR/moodle_data.tar.gz" -C /var/lib/docker/volumes/moodle_lfm_moodle_data/_data . 2>/dev/null || echo "Note: Chemins de volumes peuvent varier selon l'install."

# Compression finale
tar -czf "./backups/backup_$DATE.tar.gz" "$BACKUP_DIR"
rm -rf "$BACKUP_DIR"

echo -e "${GREEN}Sauvegarde terminée : ./backups/backup_$DATE.tar.gz${NC}"
