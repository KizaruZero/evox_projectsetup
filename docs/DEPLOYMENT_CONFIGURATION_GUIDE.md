# Panduan Deployment dengan Domain Custom

## 📋 Jawaban untuk Pertanyaan Anda

### 1️⃣ Perubahan yang Diperlukan Sebelum Deploy

#### A. Environment Variables Frontend

**SAAT INI** (di `.env` dan `.env.development`):

```env
VITE_API_BASE_URL=https://account-management-dev.azurewebsites.net/api
VITE_API_GENERAL_BASE_URL=https://general-management-dev.azurewebsites.net/
VITE_API_VENDOR_BASE_URL=https://vendor-management-dev.azurewebsites.net/
VITE_API_INVOICE_BASE_URL=https://invoice-management-dev.azurewebsites.net/api
```

**HARUS DIUBAH KE** (untuk deployment Docker dengan domain Anda):

```env
# Gunakan domain Anda dengan routing NGINX
VITE_API_BASE_URL=https://yourdomain.com/api/account
VITE_API_GENERAL_BASE_URL=https://yourdomain.com/api/general
VITE_API_VENDOR_BASE_URL=https://yourdomain.com/api/vendor
VITE_API_INVOICE_BASE_URL=https://yourdomain.com/api/invoice
```

**ATAU untuk testing lokal:**

```env
VITE_API_BASE_URL=http://localhost/api/account
VITE_API_GENERAL_BASE_URL=http://localhost/api/general
VITE_API_VENDOR_BASE_URL=http://localhost/api/vendor
VITE_API_INVOICE_BASE_URL=http://localhost/api/invoice
```

#### B. File yang Perlu Dibuat/Diubah

**1. Frontend: `.env.production`** (baru - untuk build production)

```env
VITE_API_BASE_URL=https://yourdomain.com/api/account
VITE_API_GENERAL_BASE_URL=https://yourdomain.com/api/general
VITE_API_VENDOR_BASE_URL=https://yourdomain.com/api/vendor
VITE_API_INVOICE_BASE_URL=https://yourdomain.com/api/invoice
```

**2. Deployment Config: `.env`** (di config repo)

```env
# Database
DB_CONNECTION_STRING=Server=tcp:datasea-dev.database.windows.net,1433;Initial Catalog=eProcGeneralDB;Persist Security Info=False;User ID=sqladminrole;Password=@dmin123!@321;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;

# JWT
JWT_KEY=Xy7aB9cKp2mR4vL8nJ1hD5gS3fW6tZ0qE2rU4iO9lM1=
JWT_ISSUER=https://yourdomain.com/api/account
JWT_AUDIENCE_ACCOUNT=https://yourdomain.com/api/account
JWT_AUDIENCE_GENERAL=https://yourdomain.com/api/general
JWT_AUDIENCE_INVOICE=https://yourdomain.com/api/invoice
JWT_AUDIENCE_VENDOR=https://yourdomain.com/api/vendor

# Internal Container URLs (Docker network)
ACCOUNT_API_URL=http://account-api:8001
GENERAL_API_URL=http://general-api:8002
INVOICE_API_URL=http://invoice-api:8003
VENDOR_API_URL=http://vendor-api:8004

# NGINX Ports
NGINX_HTTP_PORT=80
NGINX_HTTPS_PORT=443

# Environment
ASPNETCORE_ENVIRONMENT=Production
```

**3. NGINX Config: Update domain di `nginx/conf.d/default.conf`**

```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;  # UBAH INI!

    # ... rest of config
}
```

---

### 2️⃣ URL Domain Custom vs Localhost

#### Penjelasan

**Q: Apakah URL localhost?**  
A: Localhost **HANYA untuk development lokal**. Untuk production dengan domain, Anda harus ubah!

**Q: Frontend sudah bisa consume backend?**  
A: **YA**, TAPI perlu perubahan URL di frontend `.env`:

#### Skenario Deployment

##### Skenario 1: VPS dengan Domain Custom (PRODUCTION)

**Domain Anda:** `yourdomain.com`

**Setup:**

1. **NGINX** listen di port 80/443
2. **Routing:**
   - `https://yourdomain.com/` → Frontend
   - `https://yourdomain.com/api/account/` → Account API
   - `https://yourdomain.com/api/general/` → General API
   - `https://yourdomain.com/api/invoice/` → Invoice API
   - `https://yourdomain.com/api/vendor/` → Vendor API

**Frontend `.env.production`:**

```env
VITE_API_BASE_URL=https://yourdomain.com/api/account
VITE_API_GENERAL_BASE_URL=https://yourdomain.com/api/general
VITE_API_VENDOR_BASE_URL=https://yourdomain.com/api/vendor
VITE_API_INVOICE_BASE_URL=https://yourdomain.com/api/invoice
```

##### Skenario 2: Testing Lokal (DEVELOPMENT)

**Frontend `.env.development`:**

```env
VITE_API_BASE_URL=http://localhost/api/account
VITE_API_GENERAL_BASE_URL=http://localhost/api/general
VITE_API_VENDOR_BASE_URL=http://localhost/api/vendor
VITE_API_INVOICE_BASE_URL=http://localhost/api/invoice
```

#### ⚠️ PENTING: NGINX Routing

Frontend Anda menggunakan URL terpisah untuk setiap service. NGINX config sudah benar untuk ini:

```nginx
# Account API
location /api/account/ {
    proxy_pass http://account-api:8001/;  # Perhatikan trailing slash!
}

# General API (HATI-HATI: Frontend tidak pakai /api prefix!)
location /api/general/ {
    proxy_pass http://general-api:8002/;
}

# Invoice API
location /api/invoice/ {
    proxy_pass http://invoice-api:8003/;
}

# Vendor API
location /api/vendor/ {
    proxy_pass http://vendor-api:8004/;
}
```

**ISSUE DETECTED!** Frontend Anda saat ini menggunakan:

- `VITE_API_BASE_URL` → Account (sudah ada `/api` suffix di Azure URL)
- `VITE_API_GENERAL_BASE_URL` → General (TIDAK ada `/api` prefix!)
- dll

Ini **HARUS DISESUAIKAN** dengan routing NGINX kita!

---

### 3️⃣ Isi Config Repository

Config repository berisi **semua file konfigurasi deployment**, TIDAK berisi source code services.

#### Structure Config Repository

```
eprocurement-deployment/
├── README.md                          # Quick start guide
├── .gitignore                         # Ignore .env file
├── .env.example                       # Template environment
├── .env                               # ACTUAL config (tidak di-commit!)
│
├── docker-compose.yml                 # Main orchestration
├── docker-compose.multi-repo.yml      # Multi-repo version
├── docker-compose.prod.yml            # Production overrides
│
├── nginx/                             # NGINX reverse proxy
│   ├── Dockerfile
│   ├── nginx.conf
│   ├── conf.d/
│   │   └── default.conf               # Routing rules
│   └── ssl/                           # SSL certificates
│       └── README.md
│
├── docs/                              # Documentation
│   ├── DOCKER_SETUP.md
│   ├── DEPLOYMENT_VPS.md
│   └── MULTI_REPOSITORY_DEPLOYMENT.md
│
└── scripts/                           # Automation scripts
    ├── deploy.sh
    ├── backup.sh
    └── setup-multi-repo.sh
```

#### File-file yang HARUS Ada

| File                            | Required    | Description                    |
| ------------------------------- | ----------- | ------------------------------ |
| `docker-compose.multi-repo.yml` | ✅ YES      | Orchestration untuk multi-repo |
| `.env.example`                  | ✅ YES      | Template configuration         |
| `nginx/` folder                 | ✅ YES      | Reverse proxy config           |
| `docs/` folder                  | ⚠️ OPTIONAL | Documentation                  |
| `scripts/setup-multi-repo.sh`   | ✅ YES      | Clone semua repo               |

#### File yang TIDAK Boleh Di-commit

```gitignore
# .gitignore untuk config repo
.env
.env.local
.env.*.local
*.log
```

---

## 🚀 Step-by-Step Deployment

### Preparation (Di Local)

#### 1. Buat Config Repository Baru

```bash
# Di GitHub, buat repository baru: eprocurement-deployment

# Di local
cd ~/projects
mkdir eprocurement-deployment
cd eprocurement-deployment
git init
```

#### 2. Copy File Konfigurasi

```bash
# Copy file dari final_project ke config repo
cp "e:/Datasea Project/final_project/docker-compose.multi-repo.yml" ./
cp "e:/Datasea Project/final_project/.env.example" ./
cp -r "e:/Datasea Project/final_project/nginx" ./
cp -r "e:/Datasea Project/final_project/docs" ./
cp -r "e:/Datasea Project/final_project/scripts" ./
```

#### 3. Update `scripts/setup-multi-repo.sh`

```bash
# Sudah di-update dengan URL Anda:
ACCOUNT_REPO="https://github.com/luthfan1234/tugas_akhir-eprocurement-backend-account.git"
GENERAL_REPO="https://github.com/luthfan1234/tugas_akhir-eprocurement-backend-general.git"
INVOICE_REPO="https://github.com/luthfan1234/tugas_akhir-eprocurement-backend-invoice.git"
VENDOR_REPO="https://github.com/luthfan1234/tugas_akhir-eprocurement-backend-vendor.git"
FRONTEND_REPO="https://github.com/FIGRIHANS/tugas_akhir-eprocurement-frontend.git"
CONFIG_REPO="https://github.com/yourusername/eprocurement-deployment.git"  # UBAH INI
```

#### 4. Update `.env.example` dengan Domain

```env
# UBAH semua localhost ke domain Anda
JWT_ISSUER=https://yourdomain.com/api/account
# ... dst
```

#### 5. Commit & Push Config Repository

```bash
git add .
git commit -m "Initial deployment config"
git remote add origin https://github.com/yourusername/eprocurement-deployment.git
git push -u origin main
```

### Deployment di VPS

#### 1. Clone Config Repo & Setup

```bash
# Login ke VPS
ssh user@your-vps-ip

# Install Docker (jika belum)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Clone config repo
cd ~
git clone https://github.com/yourusername/eprocurement-deployment.git
cd eprocurement-deployment
```

#### 2. Jalankan Setup Script

```bash
# Script akan clone semua 5 repository
chmod +x scripts/setup-multi-repo.sh
./scripts/setup-multi-repo.sh
```

**Script akan membuat struktur:**

```
~/eprocurement/
├── tugas_akhir-eprocurement-backend-account/
├── tugas_akhir-eprocurement-backend-general/
├── tugas_akhir-eprocurement-backend-invoice/
├── tugas_akhir-eprocurement-backend-vendor/
├── tugas_akhir-eprocurement-frontend/
└── config/  (eprocurement-deployment repo)
```

#### 3. Configure Environment

```bash
cd ~/eprocurement/config
cp .env.example .env
nano .env
```

**Edit `.env` dengan:**

- Database connection (sudah benar!)
- JWT key (generate baru untuk production!)
- Domain Anda: `yourdomain.com`

#### 4. Update NGINX Config

```bash
nano nginx/conf.d/default.conf
```

Ubah:

```nginx
server_name yourdomain.com www.yourdomain.com;  # Sebelumnya: localhost
```

#### 5. Build & Deploy

```bash
docker-compose -f docker-compose.multi-repo.yml build
docker-compose -f docker-compose.multi-repo.yml -f docker-compose.prod.yml up -d
```

#### 6. Setup SSL (Let's Encrypt)

```bash
# Stop NGINX temporarily
docker-compose stop nginx

# Generate certificate
sudo certbot certonly --standalone -d yourdomain.com -d www.yourdomain.com

# Copy certificates
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem nginx/ssl/cert.pem
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem nginx/ssl/key.pem

# Restart NGINX
docker-compose up -d nginx
```

---

## ✅ Checklist Deployment

### Frontend Changes

- [ ] Buat `.env.production` dengan URL domain
- [ ] Update semua `VITE_API_*_BASE_URL` ke routing NGINX
- [ ] Rebuild frontend image setelah env berubah

### Backend Changes

- [ ] Pastikan semua Dockerfile sudah ada (✅ sudah dibuat)
- [ ] Update CORS settings jika perlu

### Config Repository

- [ ] Buat repository baru di GitHub
- [ ] Upload semua file konfigurasi
- [ ] Update `setup-multi-repo.sh` dengan URL repo Anda
- [ ] Commit & push

### VPS Setup

- [ ] Install Docker & Docker Compose
- [ ] Clone config repository
- [ ] Jalankan `setup-multi-repo.sh`
- [ ] Configure `.env` dengan production values
- [ ] Update NGINX config dengan domain
- [ ] Build & deploy containers
- [ ] Setup SSL certificates
- [ ] Configure firewall (port 80, 443)
- [ ] Setup domain DNS ke IP VPS

### Testing

- [ ] Test health endpoints: `https://yourdomain.com/api/account/health`
- [ ] Test frontend: `https://yourdomain.com`
- [ ] Test login & authentication
- [ ] Check logs: `docker-compose logs -f`

---

## 🔧 Troubleshooting Frontend → Backend Connection

### Issue: Frontend tidak bisa akses backend

**Check 1: NGINX routing**

```bash
docker logs eprocurement-nginx
```

**Check 2: Backend health**

```bash
curl http://localhost/api/account/health
curl http://localhost/api/general/health
```

**Check 3: Frontend env vars**

```bash
# Di container frontend, check env
docker exec -it eprocurement-frontend env | grep VITE
```

**Check 4: CORS settings** (jika 401/403)
Backend harus allow domain Anda di CORS settings

---

## 📝 Summary

1. **Frontend ENV:** Harus diubah dari Azure URLs ke domain Anda dengan routing NGINX
2. **Domain:** Ubah semua `localhost` ke `yourdomain.com`
3. **Config Repo:** Berisi deployment config, scripts, NGINX, docs - BUKAN source code
4. **Deployment:** Clone config → Run script → Build → Deploy
5. **SSL:** Setup Let's Encrypt untuk HTTPS

Sudah jelas? Ada pertanyaan lain? 😊
