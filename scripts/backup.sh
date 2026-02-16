#!/bin/bash

# =====================================================
# Backup Script for E-Procurement Microservices
# =====================================================
# This script backs up configuration and important files
# Usage: ./backup.sh

set -e

# Configuration
PROJECT_DIR="$HOME/eprocurement"
BACKUP_DIR="$HOME/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/eprocurement_backup_$DATE.tar.gz"
MAX_BACKUPS=7  # Keep last 7 backups

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo -e "${GREEN}Starting backup process...${NC}"

# Navigate to project directory
cd "$PROJECT_DIR" || exit 1

# Create compressed backup
tar -czf "$BACKUP_FILE" \
    .env \
    nginx/ \
    docker-compose.yml \
    docker-compose.prod.yml \
    docs/ \
    scripts/ \
    2>/dev/null

echo -e "${GREEN}Backup created: $BACKUP_FILE${NC}"

# Get backup size
SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo -e "${GREEN}Backup size: $SIZE${NC}"

# Clean up old backups
echo -e "${YELLOW}Cleaning up old backups (keeping last $MAX_BACKUPS)...${NC}"
ls -t "$BACKUP_DIR"/eprocurement_backup_*.tar.gz | tail -n +$((MAX_BACKUPS + 1)) | xargs rm -f 2>/dev/null || true

# List current backups
echo -e "${GREEN}Current backups:${NC}"
ls -lh "$BACKUP_DIR"/eprocurement_backup_*.tar.gz 2>/dev/null || echo "No backups found"

echo -e "${GREEN}Backup completed successfully!${NC}"
echo ""
echo "To restore from this backup:"
echo "1. cd ~/eprocurement"
echo "2. tar -xzf $BACKUP_FILE"
echo "3. docker compose down && docker compose up -d"

exit 0
