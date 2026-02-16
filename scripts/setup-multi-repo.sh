#!/bin/bash

# =====================================================
# Multi-Repository Setup Script
# =====================================================
# This script clones all microservice repositories and
# sets up the deployment configuration

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================"
echo "E-Procurement Multi-Repo Setup"
echo -e "======================================${NC}"

# Configuration - UPDATE THESE WITH YOUR REPOSITORIES
ACCOUNT_REPO="https://github.com/luthfan1234/tugas_akhir-eprocurement-backend-account.git"
GENERAL_REPO="https://github.com/luthfan1234/tugas_akhir-eprocurement-backend-general.git"
INVOICE_REPO="https://github.com/luthfan1234/tugas_akhir-eprocurement-backend-invoice.git"
VENDOR_REPO="https://github.com/luthfan1234/tugas_akhir-eprocurement-backend-vendor.git"
FRONTEND_REPO="https://github.com/FIGRIHANS/tugas_akhir-eprocurement-frontend.git"
CONFIG_REPO="https://github.com/KizaruZero/evox_projectsetup.git"
# Working directory
WORK_DIR="$HOME/eprocurement"

echo -e "${YELLOW}Working directory: $WORK_DIR${NC}"

# Create working directory
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Clone repositories
echo -e "${GREEN}Cloning repositories...${NC}"

if [ ! -d "tugas_akhir-eprocurement-backend-account" ]; then
    echo "Cloning Account API..."
    git clone "$ACCOUNT_REPO"
else
    echo "Account API already exists, pulling latest..."
    cd tugas_akhir-eprocurement-backend-account && git pull && cd ..
fi

if [ ! -d "tugas_akhir-eprocurement-backend-general" ]; then
    echo "Cloning General API..."
    git clone "$GENERAL_REPO"
else
    echo "General API already exists, pulling latest..."
    cd tugas_akhir-eprocurement-backend-general && git pull && cd ..
fi

if [ ! -d "tugas_akhir-eprocurement-backend-invoice" ]; then
    echo "Cloning Invoice API..."
    git clone "$INVOICE_REPO"
else
    echo "Invoice API already exists, pulling latest..."
    cd tugas_akhir-eprocurement-backend-invoice && git pull && cd ..
fi

if [ ! -d "tugas_akhir-eprocurement-backend-vendor" ]; then
    echo "Cloning Vendor API..."
    git clone "$VENDOR_REPO"
else
    echo "Vendor API already exists, pulling latest..."
    cd tugas_akhir-eprocurement-backend-vendor && git pull && cd ..
fi

if [ ! -d "tugas_akhir-eprocurement-frontend" ]; then
    echo "Cloning Frontend..."
    git clone "$FRONTEND_REPO"
else
    echo "Frontend already exists, pulling latest..."
    cd tugas_akhir-eprocurement-frontend && git pull && cd ..
fi

if [ ! -d "config" ]; then
    echo "Cloning deployment config..."
    git clone "$CONFIG_REPO" config
else
    echo "Config already exists, pulling latest..."
    cd config && git pull && cd ..
fi

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
echo "2. nano .env (configure your environment)"
echo "3. docker-compose build"
echo "4. docker-compose up -d"
echo ""
echo -e "${YELLOW}To update a specific service:${NC}"
echo "cd $WORK_DIR/tugas_akhir-eprocurement-backend-account"
echo "git pull"
echo "cd $WORK_DIR/config"
echo "docker-compose build account-api"
echo "docker-compose up -d account-api"

exit 0
