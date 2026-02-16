#!/bin/bash

# =====================================================
# Deployment Script for E-Procurement Microservices
# =====================================================
# This script automates the deployment process on VPS
# Usage: ./deploy.sh

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$HOME/eprocurement"
BACKUP_DIR="$HOME/backups"
LOG_FILE="$PROJECT_DIR/deploy.log"

# Functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Start deployment
log "======================================"
log "Starting deployment process..."
log "======================================"

# 1. Check if running as correct user
if [ "$EUID" -eq 0 ]; then
    error "Do not run this script as root!"
fi

# 2. Navigate to project directory
cd "$PROJECT_DIR" || error "Project directory not found: $PROJECT_DIR"
log "Project directory: $PROJECT_DIR"

# 3. Create backup
log "Creating backup..."
BACKUP_FILE="$BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S).tar.gz"
mkdir -p "$BACKUP_DIR"

tar -czf "$BACKUP_FILE" \
    .env \
    nginx/conf.d/ \
    docker-compose*.yml 2>/dev/null || warning "Some files not backed up"

log "Backup created: $BACKUP_FILE"

# 4. Pull latest changes
log "Pulling latest changes from repository..."
if [ -d ".git" ]; then
    git pull origin main || warning "Git pull failed, continuing anyway"
else
    warning "Not a git repository, skipping git pull"
fi

# 5. Check environment file
if [ ! -f ".env" ]; then
    error ".env file not found! Copy .env.example and configure it first."
fi
log "Environment file found"

# 6. Build Docker images
log "Building Docker images (this may take several minutes)..."
docker compose build || error "Docker build failed"
log "Docker images built successfully"

# 7. Stop old containers
log "Stopping old containers..."
docker compose down || warning "No containers to stop"

# 8. Start new containers
log "Starting new containers in production mode..."
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d || error "Failed to start containers"

# 9. Wait for services to be healthy
log "Waiting for services to become healthy..."
sleep 10

# 10. Check container health
log "Checking container status..."
UNHEALTHY=$(docker compose ps | grep -v "Up" | grep -v "Name" | wc -l)

if [ "$UNHEALTHY" -gt 0 ]; then
    error "Some containers are not running properly. Check with: docker compose ps"
fi

# 11. Verify health endpoints
log "Verifying health endpoints..."
sleep 5

curl -f http://localhost/health > /dev/null 2>&1 || warning "NGINX health check failed"
curl -f http://localhost/api/account/health > /dev/null 2>&1 || warning "Account API health check failed"
curl -f http://localhost/api/general/health > /dev/null 2>&1 || warning "General API health check failed"
curl -f http://localhost/api/invoice/health > /dev/null 2>&1 || warning "Invoice API health check failed"
curl -f http://localhost/api/vendor/health > /dev/null 2>&1 || warning "Vendor API health check failed"

# 12. Clean up old images
log "Cleaning up old Docker images..."
docker image prune -f || warning "Image cleanup failed"

# 13. Display running containers
log "Current running containers:"
docker compose ps

# 14. Show recent logs
log "Recent logs from all services:"
docker compose logs --tail=20

# Deployment complete
log "======================================"
log "Deployment completed successfully!"
log "======================================"
log "Backup file: $BACKUP_FILE"
log ""
log "Next steps:"
log "1. Verify application is working: http://your-domain.com"
log "2. Check logs: docker compose logs -f"
log "3. Monitor: docker stats"
log ""
log "To rollback, restore from backup and run:"
log "docker compose down && docker compose up -d"

exit 0
