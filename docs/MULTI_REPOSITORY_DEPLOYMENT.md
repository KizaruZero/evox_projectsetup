# Multi-Repository Microservices Deployment Guide

## Skenario: Setiap Microservice di Repository Terpisah

Guide ini menjelaskan cara deploy microservices yang berada di repository berbeda-beda ke VPS.

---

## 📋 Table of Contents

1. [Arsitektur Multi-Repository](#arsitektur-multi-repository)
2. [Metode Deployment](#metode-deployment)
3. [Opsi 1: Docker Registry (Recommended)](#opsi-1-docker-registry-recommended)
4. [Opsi 2: Git Submodules](#opsi-2-git-submodules)
5. [Opsi 3: Separate Clone](#opsi-3-separate-clone)
6. [Opsi 4: CI/CD Pipeline](#opsi-4-cicd-pipeline)
7. [Best Practices](#best-practices)

---

## Arsitektur Multi-Repository

### Struktur Repository Anda (Asumsi)

```
Repository 1: tugas_akhir-eprocurement-backend-account (GitHub/GitLab)
Repository 2: tugas_akhir-eprocurement-backend-general (GitHub/GitLab)
Repository 3: tugas_akhir-eprocurement-backend-invoice (GitHub/GitLab)
Repository 4: tugas_akhir-eprocurement-backend-vendor (GitHub/GitLab)
Repository 5: tugas_akhir-eprocurement-frontend (GitHub/GitLab)
Repository 6: eprocurement-deployment (Repository ini - berisi docker-compose)
```

### Pertanyaan Umum

**Q: Apakah Docker hanya bisa untuk 1 repository?**  
**A: TIDAK!** Docker dan Docker Compose sangat cocok untuk multi-repository microservices.

---

## Metode Deployment

Ada 4 metode utama untuk deploy multi-repo microservices:

| Metode          | Complexity | Production Ready | Build Location | Recommended For     |
| --------------- | ---------- | ---------------- | -------------- | ------------------- |
| Docker Registry | Medium     | ✅ Yes           | CI/CD or Local | **Production**      |
| Git Submodules  | Easy       | ✅ Yes           | VPS            | Development/Staging |
| Separate Clone  | Easy       | ⚠️ Manual        | VPS            | Quick Testing       |
| CI/CD Pipeline  | High       | ✅✅ Yes         | CI/CD Server   | **Large Teams**     |

---

## Opsi 1: Docker Registry (RECOMMENDED)

### Konsep

Build Docker images di local/CI, push ke registry, pull di VPS. **Tidak perlu source code di VPS!**

### Keuntungan

✅ **Paling aman** - Source code tidak perlu ada di VPS  
✅ **Fast deployment** - Hanya download image, tidak build  
✅ **Version control** - Setiap image punya tag/version  
✅ **Easy rollback** - Ganti tag untuk rollback  
✅ **Production standard** - Digunakan di Google, Netflix, dll

### Setup Docker Registry

#### Option A: Docker Hub (Free, Public/Private)

**1. Buat Account di Docker Hub**

- https://hub.docker.com
- Create repositories untuk setiap service

**2. Build & Tag Images**

```bash
# Login ke Docker Hub
docker login

# Account Service
cd tugas_akhir-eprocurement-backend-account
docker build -t yourusername/eprocurement-account:latest .
docker push yourusername/eprocurement-account:latest

# General Service
cd ../tugas_akhir-eprocurement-backend-general
docker build -t yourusername/eprocurement-general:latest .
docker push yourusername/eprocurement-general:latest

# Invoice Service
cd ../tugas_akhir-eprocurement-backend-invoice
docker build -t yourusername/eprocurement-invoice:latest .
docker push yourusername/eprocurement-invoice:latest

# Vendor Service
cd ../tugas_akhir-eprocurement-backend-vendor
docker build -t yourusername/eprocurement-vendor:latest .
docker push yourusername/eprocurement-vendor:latest

# Frontend
cd ../tugas_akhir-eprocurement-frontend
docker build -t yourusername/eprocurement-frontend:latest .
docker push yourusername/eprocurement-frontend:latest
```

**3. Update docker-compose.yml di VPS**

```yaml
services:
  account-api:
    image: yourusername/eprocurement-account:latest
    # Remove 'build' section
    container_name: eprocurement-account-api
    environment:
      # ... environment variables
    ports:
      - "8001:8001"
    # ... rest of config

  general-api:
    image: yourusername/eprocurement-general:latest
    # ... config

  invoice-api:
    image: yourusername/eprocurement-invoice:latest
    # ... config

  vendor-api:
    image: yourusername/eprocurement-vendor:latest
    # ... config

  frontend:
    image: yourusername/eprocurement-frontend:latest
    # ... config
```

**4. Deploy di VPS**

```bash
# Di VPS, clone repository deployment
git clone https://github.com/yourusername/eprocurement-deployment.git
cd eprocurement-deployment

# Buat .env file
cp .env.example .env
nano .env  # Configure

# Login Docker Hub (jika private repo)
docker login

# Pull & Run
docker-compose pull
docker-compose up -d
```

**5. Update aplikasi**

```bash
# Build image baru
docker build -t yourusername/eprocurement-account:v1.1 .
docker push yourusername/eprocurement-account:v1.1

# Di VPS, update tag dan pull
docker-compose pull
docker-compose up -d
```

#### Option B: GitHub Container Registry (Free)

```bash
# Login ke GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Build & Push
docker build -t ghcr.io/yourusername/eprocurement-account:latest .
docker push ghcr.io/yourusername/eprocurement-account:latest

# Update docker-compose.yml
# image: ghcr.io/yourusername/eprocurement-account:latest
```

#### Option C: Private Registry (Self-hosted)

```bash
# Setup registry di VPS lain atau cloud
docker run -d -p 5000:5000 --name registry registry:2

# Push ke private registry
docker tag myimage localhost:5000/myimage
docker push localhost:5000/myimage
```

---

## Opsi 2: Git Submodules

### Konsep

Buat 1 repository "deployment" yang berisi semua repository service sebagai submodules.

### Setup

**1. Buat Repository Deployment**

```bash
# Buat repo baru untuk deployment
mkdir eprocurement-deployment
cd eprocurement-deployment
git init

# Tambahkan setiap service sebagai submodule
git submodule add https://github.com/your/tugas_akhir-eprocurement-backend-account.git backend-account
git submodule add https://github.com/your/tugas_akhir-eprocurement-backend-general.git backend-general
git submodule add https://github.com/your/tugas_akhir-eprocurement-backend-invoice.git backend-invoice
git submodule add https://github.com/your/tugas_akhir-eprocurement-backend-vendor.git backend-vendor
git submodule add https://github.com/your/tugas_akhir-eprocurement-frontend.git frontend
```

**2. Update docker-compose.yml**

```yaml
services:
  account-api:
    build:
      context: ./backend-account # Path ke submodule
      dockerfile: Dockerfile
    # ... rest of config

  general-api:
    build:
      context: ./backend-general
      dockerfile: Dockerfile
    # ... rest of config
```

**3. Deploy di VPS**

```bash
# Clone dengan submodules
git clone --recurse-submodules https://github.com/your/eprocurement-deployment.git
cd eprocurement-deployment

# Setup environment
cp .env.example .env
nano .env

# Build & Run
docker-compose build
docker-compose up -d
```

**4. Update Service**

```bash
# Update submodule tertentu
cd backend-account
git pull origin main
cd ..

# Rebuild service
docker-compose build account-api
docker-compose up -d account-api

# Atau update semua submodules
git submodule update --remote --merge
docker-compose build
docker-compose up -d
```

### Structure dengan Submodules

```
eprocurement-deployment/
├── .gitmodules
├── docker-compose.yml
├── .env.example
├── nginx/
│   └── conf.d/
├── backend-account/          (submodule)
│   ├── Dockerfile
│   └── [.NET project files]
├── backend-general/          (submodule)
│   └── ...
├── backend-invoice/          (submodule)
│   └── ...
├── backend-vendor/           (submodule)
│   └── ...
└── frontend/                 (submodule)
    └── ...
```

---

## Opsi 3: Separate Clone

### Konsep

Clone setiap repository secara terpisah di VPS, lebih manual tapi fleksibel.

### Setup di VPS

```bash
# Buat direktori project
mkdir ~/eprocurement
cd ~/eprocurement

# Clone semua repository
git clone https://github.com/your/tugas_akhir-eprocurement-backend-account.git
git clone https://github.com/your/tugas_akhir-eprocurement-backend-general.git
git clone https://github.com/your/tugas_akhir-eprocurement-backend-invoice.git
git clone https://github.com/your/tugas_akhir-eprocurement-backend-vendor.git
git clone https://github.com/your/tugas_akhir-eprocurement-frontend.git

# Clone deployment config
git clone https://github.com/your/eprocurement-deployment.git config
```

**Structure:**

```
~/eprocurement/
├── tugas_akhir-eprocurement-backend-account/
├── tugas_akhir-eprocurement-backend-general/
├── tugas_akhir-eprocurement-backend-invoice/
├── tugas_akhir-eprocurement-backend-vendor/
├── tugas_akhir-eprocurement-frontend/
└── config/
    ├── docker-compose.yml
    ├── nginx/
    └── .env
```

**docker-compose.yml** (di folder config):

```yaml
services:
  account-api:
    build:
      context: ../tugas_akhir-eprocurement-backend-account
      dockerfile: Dockerfile
    # ... config

  general-api:
    build:
      context: ../tugas_akhir-eprocurement-backend-general
      dockerfile: Dockerfile
    # ... config
```

**Deploy:**

```bash
cd ~/eprocurement/config
cp .env.example .env
nano .env
docker-compose build
docker-compose up -d
```

**Update service tertentu:**

```bash
cd ~/eprocurement/tugas_akhir-eprocurement-backend-account
git pull
cd ~/eprocurement/config
docker-compose build account-api
docker-compose up -d account-api
```

---

## Opsi 4: CI/CD Pipeline (BEST for Teams)

### Konsep

Automated build & deployment menggunakan GitHub Actions, GitLab CI, atau Jenkins.

### GitHub Actions Example

**File: `.github/workflows/deploy.yml` di setiap repository**

```yaml
name: Build and Deploy

on:
  push:
    branches: [main]

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Login to Docker Hub
        uses: docker/login-action@v1
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build and push
        uses: docker/build-push-action@v2
        with:
          context: .
          push: true
          tags: yourusername/eprocurement-account:latest

  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to VPS
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USERNAME }}
          key: ${{ secrets.VPS_SSH_KEY }}
          script: |
            cd ~/eprocurement
            docker-compose pull account-api
            docker-compose up -d account-api
```

### Workflow

1. Push code ke repository → Trigger CI/CD
2. CI/CD build Docker image
3. Push image ke registry
4. SSH ke VPS dan pull image baru
5. Restart service

---

## Best Practices

### 1. Version Tagging

```bash
# Gunakan semantic versioning
docker tag myimage yourusername/eprocurement-account:1.0.0
docker tag myimage yourusername/eprocurement-account:latest

# Deploy version spesifik
docker-compose.yml:
  account-api:
    image: yourusername/eprocurement-account:1.0.0
```

### 2. Environment Management

Buat `.env` terpisah untuk setiap environment:

```
.env.development
.env.staging
.env.production
```

### 3. Health Checks

Pastikan setiap service punya health check endpoint.

### 4. Rollback Strategy

```bash
# Jika ada masalah, rollback ke versi sebelumnya
docker-compose stop account-api
docker-compose rm account-api

# Edit docker-compose.yml, ganti tag
# image: yourusername/eprocurement-account:1.0.0  # previous version

docker-compose up -d account-api
```

### 5. Security

- **Jangan** simpan `.env` di git
- Gunakan secrets management
- Update images secara regular
- Scan images untuk vulnerabilities

---

## Recommended Setup untuk Anda

Berdasarkan struktur project Anda, saya rekomendasikan:

### Phase 1: Development (Sekarang)

**Gunakan Opsi 3 (Separate Clone)** - Paling cepat untuk mulai

### Phase 2: Staging/Testing

**Gunakan Opsi 2 (Git Submodules)** - Lebih terorganisir

### Phase 3: Production

**Gunakan Opsi 1 (Docker Registry)** - Production standard

---

## Quick Setup Script

Saya akan buatkan script untuk setup multi-repo di VPS:

**File: `setup-multi-repo.sh`**

```bash
#!/bin/bash

# Setup E-Procurement Multi-Repository Deployment

REPOS=(
    "https://github.com/your/tugas_akhir-eprocurement-backend-account.git"
    "https://github.com/your/tugas_akhir-eprocurement-backend-general.git"
    "https://github.com/your/tugas_akhir-eprocurement-backend-invoice.git"
    "https://github.com/your/tugas_akhir-eprocurement-backend-vendor.git"
    "https://github.com/your/tugas_akhir-eprocurement-frontend.git"
)

CONFIG_REPO="https://github.com/your/eprocurement-deployment.git"

# Clone all repositories
echo "Cloning all repositories..."
mkdir -p ~/eprocurement
cd ~/eprocurement

for repo in "${REPOS[@]}"; do
    git clone "$repo"
done

# Clone deployment config
git clone "$CONFIG_REPO" config

# Setup environment
cd config
cp .env.example .env
echo "Please edit .env file with your configuration"

# Build and run
docker-compose build
docker-compose up -d

echo "Deployment complete!"
```

---

## Kesimpulan

✅ **Multi-repository microservices SANGAT MUNGKIN untuk di-deploy**  
✅ **Ada banyak pilihan metode**, pilih sesuai kebutuhan  
✅ **Docker Registry adalah best practice untuk production**  
✅ **Git Submodules cocok untuk development/staging**  
✅ **Setup awal memang lebih kompleks, tapi maintenance lebih mudah**

Pertanyaan? Silakan bertanya! 😊
