#!/bin/bash

# =====================================================
# Multi-Repository Setup Script (SSH Version)
# =====================================================
# This script clones all microservice repositories using SSH
# Make sure your SSH key is added to GitHub

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================"
echo "E-Procurement Multi-Repo Setup (SSH)"
echo -e "======================================${NC}"

# Configuration - SSH URLs
ACCOUNT_REPO="git@github.com:luthfan1234/tugas_akhir-eprocurement-backend-account.git"
GENERAL_REPO="git@github.com:luthfan1234/tugas_akhir-eprocurement-backend-general.git"
INVOICE_REPO="git@github.com:luthfan1234/tugas_akhir-eprocurement-backend-invoice.git"
VENDOR_REPO="git@github.com:luthfan1234/tugas_akhir-eprocurement-backend-vendor.git"
FRONTEND_REPO="git@github.com:FIGRIHANS/tugas_akhir-eprocurement-frontend.git"
CONFIG_REPO="git@github.com:KizaruZero/evox_projectsetup.git"

# Working directory
WORK_DIR="$HOME/eprocurement"

echo -e "${YELLOW}Working directory: $WORK_DIR${NC}"

# Create working directory
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Clone repositories
echo -e "${GREEN}Cloning repositories via SSH...${NC}"

clone_or_pull () {
    REPO_URL=$1
    DIR_NAME=$2
    LABEL=$3

    if [ ! -d "$DIR_NAME" ]; then
        echo "Cloning $LABEL..."
        git clone "$REPO_URL" "$DIR_NAME"
    else
        echo "$LABEL already exists, pulling latest..."
        cd "$DIR_NAME"
        git pull origin main || git pull origin master
        cd ..
    fi
}

clone_or_pull "$ACCOUNT_REPO" "tugas_akhir-eprocurement-backend-account" "Account API"
clone_or_pull "$GENERAL_REPO" "tugas_akhir-eprocurement-backend-general" "General API"
clone_or_pull "$INVOICE_REPO" "tugas_akhir-eprocurement-backend-invoice" "Invoice API"
clone_or_pull "$VENDOR_REPO" "tugas_akhir-eprocurement-backend-vendor" "Vendor API"
clone_or_pull "$FRONTEND_REPO" "tugas_akhir-eprocurement-frontend" "Frontend"
clone_or_pull "$CONFIG_REPO" "config" "Deployment Config"

# Setup environment
echo -e "${GREEN}Setting up environment...${NC}"
cd config

if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo -e "${YELLOW}Created .env file from .env.example${NC}"
        echo -e "${YELLOW}IMPORTANT: Edit .env file with your configuration!${NC}"
    else
        echo -e "${YELLOW}Warning: .env.example not found${NC}"
    fi
else
    echo ".env file already exists"
fi

# Display structure
echo -e "${GREEN}Repository structure:${NC}"
ls -la "$WORK_DIR"

echo ""
echo -e "${BLUE}======================================"
echo "Setup Complete!"
echo -e "======================================${NC}"
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "1. cd $WORK_DIR/config"
echo "2. nano .env"
echo "3. docker-compose build"
echo "4. docker-compose up -d"
echo ""
echo -e "${YELLOW}To update a service:${NC}"
echo "cd $WORK_DIR/<service-folder>"
echo "git pull"
echo "cd $WORK_DIR/config"
echo "docker-compose up -d --build <service-name>"

exit 0
