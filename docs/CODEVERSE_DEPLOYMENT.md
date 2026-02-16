# Deployment Guide untuk codeverse.id

## 📋 Overview

Guide ini khusus untuk deployment E-Procurement microservices ke VPS dengan konfigurasi subdomain codeverse.id.

### VPS Information

- **IP Address:** 103.123.45.67
- **Domain:** codeverse.id

### Subdomain Mapping

| Service     | Subdomain                | Container Port | Description                      |
| ----------- | ------------------------ | -------------- | -------------------------------- |
| Frontend    | evox.codeverse.id        | 80             | Vue.js Application               |
| Account API | account-api.codeverse.id | 8001           | Authentication & User Management |
| General API | api.codeverse.id         | 8002           | General Operations               |
| Vendor API  | vendor-api.codeverse.id  | 8004           | Vendor Management                |
| Invoice API | invoice-api.codeverse.id | 8003           | Invoice Processing               |

---

## 🚀 Step-by-Step Deployment

### Phase 1: DNS Configuration

**1. Login ke Domain Registrar Anda**

**2. Tambahkan DNS A Records:**

```
Type  Name                  Value          TTL
A     evox                  103.123.45.67  3600
A     account-api           103.123.45.67  3600
A     api                   103.123.45.67  3600
A     vendor-api            103.123.45.67  3600
A     invoice-api           103.123.45.67  3600
```

**3. Verifikasi DNS (tunggu 5-60 menit untuk propagasi):**

```bash
# Check semua subdomain
nslookup evox.codeverse.id
nslookup account-api.codeverse.id
nslookup api.codeverse.id
nslookup vendor-api.codeverse.id
nslookup invoice-api.codeverse.id

# Atau gunakan dig
dig evox.codeverse.id
```

**Expected output:** Semua harus return IP 103.123.45.67

---

### Phase 2: VPS Preparation

**1. Login ke VPS:**

```bash
ssh root@103.123.45.67
# atau
ssh user@103.123.45.67
```

**2. Update System:**

```bash
sudo apt update
sudo apt upgrade -y
```

**3. Install Docker:**

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version
```

**4. Add user to docker group (optional):**

```bash
sudo usermod -aG docker $USER
# Logout and login again
```

---

### Phase 3: Clone Repositories

**1. Clone Config Repository:**

```bash
cd ~
git clone https://github.com/yourusername/eprocurement-deployment.git
cd eprocurement-deployment
```

**2. Run Multi-Repo Setup Script:**

```bash
chmod +x scripts/setup-multi-repo.sh
./scripts/setup-multi-repo.sh
```

Script akan clone:

```
~/eprocurement/
├── tugas_akhir-eprocurement-backend-account/
├── tugas_akhir-eprocurement-backend-general/
├── tugas_akhir-eprocurement-backend-invoice/
├── tugas_akhir-eprocurement-backend-vendor/
├── tugas_akhir-eprocurement-frontend/
└── config/  (deployment config)
```

---

### Phase 4: Configuration

**1. Setup Environment:**

```bash
cd ~/eprocurement/config

# Copy codeverse configuration
cp .env.codeverse .env

# Verify configuration
nano .env
```

**IMPORTANT:** Di `.env`, pastikan:

- ✅ `DB_PASSWORD` sudah benar
- ✅ `JWT_KEY` sudah di-generate baru (untuk production)
- ✅ Semua domain sudah `codeverse.id`

**Generate JWT Key baru:**

```bash
openssl rand -base64 32
# Copy output dan replace JWT_KEY di .env
```

**2. Update NGINX Configuration:**

```bash
# Replace default NGINX config dengan subdomain version
cd ~/eprocurement/config
rm nginx/conf.d/default.conf
cp nginx/conf.d/default.subdomain.conf nginx/conf.d/default.conf
```

**3. Verify NGINX Config:**

```bash
cat nginx/conf.d/default.conf | grep server_name
```

Should show:

```
server_name evox.codeverse.id;
server_name account-api.codeverse.id;
server_name api.codeverse.id;
server_name vendor-api.codeverse.id;
server_name invoice-api.codeverse.id;
```

---

### Phase 5: Build & Deploy

**1. Build All Services:**

```bash
cd ~/eprocurement/config

# Build images (this takes 10-15 minutes)
docker-compose -f docker-compose.multi-repo.yml build --no-cache

# Check built images
docker images
```

**Expected images:**

- `config_account-api`
- `config_general-api`
- `config_invoice-api`
- `config_vendor-api`
- `config_frontend`
- `config_nginx`

**2. Start Services:**

```bash
# Start in production mode
docker-compose -f docker-compose.multi-repo.yml -f docker-compose.prod.yml up -d

# Check status
docker-compose ps
```

**All services should be "Up" and "healthy"**

**3. View Logs:**

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f account-api
docker-compose logs -f frontend
docker-compose logs -f nginx
```

---

### Phase 6: Testing (HTTP)

**1. Test Health Endpoints (dari VPS):**

```bash
# Test each API
curl http://localhost/health  # Account API via NGINX
curl http://account-api.codeverse.id/health

curl http://api.codeverse.id/health
curl http://vendor-api.codeverse.id/health
curl http://invoice-api.codeverse.id/health
```

**2. Test from Browser:**

- Frontend: http://evox.codeverse.id
- Account API: http://account-api.codeverse.id/health
- General API: http://api.codeverse.id/health

**⚠️ Note:** HTTP only works initially. Setup SSL for HTTPS!

---

### Phase 7: SSL Setup (HTTPS)

**1. Stop NGINX temporarily:**

```bash
cd ~/eprocurement/config
docker-compose stop nginx
```

**2. Install Certbot:**

```bash
sudo apt install certbot -y
```

**3. Generate SSL Certificates:**

```bash
# Get certificates for all subdomains
sudo certbot certonly --standalone \
  -d evox.codeverse.id \
  -d account-api.codeverse.id \
  -d api.codeverse.id \
  -d vendor-api.codeverse.id \
  -d invoice-api.codeverse.id \
  --email your-email@example.com \
  --agree-tos
```

**4. Copy Certificates to NGINX:**

```bash
# Create SSL directory if not exists
mkdir -p ~/eprocurement/config/nginx/ssl

# Copy certificates (adjust path based on certbot output)
sudo cp /etc/letsencrypt/live/evox.codeverse.id/fullchain.pem \
  ~/eprocurement/config/nginx/ssl/cert.pem

sudo cp /etc/letsencrypt/live/evox.codeverse.id/privkey.pem \
  ~/eprocurement/config/nginx/ssl/key.pem

# Fix permissions
sudo chown $USER:$USER ~/eprocurement/config/nginx/ssl/*.pem
```

**5. Update NGINX Config untuk SSL:**

```bash
nano ~/eprocurement/config/nginx/conf.d/default.conf
```

Uncomment semua SSL server blocks (yang ada `listen 443 ssl http2`)

**6. Restart NGINX:**

```bash
cd ~/eprocurement/config
docker-compose up -d nginx
```

**7. Enable HTTPS Redirect:**

Uncomment baris ini di setiap HTTP server block:

```nginx
# return 301 https://$server_name$request_uri;
```

Menjadi:

```nginx
return 301 https://$server_name$request_uri;
```

Restart: `docker-compose restart nginx`

---

### Phase 8: Firewall Setup

**1. Install UFW:**

```bash
sudo apt install ufw -y
```

**2. Configure Firewall:**

```bash
# Allow SSH
sudo ufw allow 22/tcp

# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

---

## ✅ Verification Checklist

### DNS Check

- [ ] `evox.codeverse.id` resolves to 103.123.45.67
- [ ] `account-api.codeverse.id` resolves to 103.123.45.67
- [ ] `api.codeverse.id` resolves to 103.123.45.67
- [ ] `vendor-api.codeverse.id` resolves to 103.123.45.67
- [ ] `invoice-api.codeverse.id` resolves to 103.123.45.67

### Docker Check

- [ ] All containers are running: `docker-compose ps`
- [ ] All containers are healthy
- [ ] No error in logs: `docker-compose logs`

### HTTP Check

- [ ] Frontend accessible: http://evox.codeverse.id
- [ ] All API health endpoints return 200 OK

### HTTPS Check (after SSL setup)

- [ ] Frontend: https://evox.codeverse.id
- [ ] All APIs accessible via HTTPS
- [ ] HTTP redirects to HTTPS
- [ ] SSL certificate valid (no browser warning)

### Application Check

- [ ] Login works
- [ ] API calls from frontend succeed
- [ ] No CORS errors in browser console

---

## 🔧 Docker Build vs Manual Publish

### ❓ Pertanyaan: "Apakah perlu build/publish manual setelah docker-compose?"

**TIDAK! Docker build = publish yang otomatis.**

### Manual Publish (.NET):

```bash
dotnet publish -c Release -o ./publish
# Copy files to server
# Configure IIS/Kestrel
```

### Docker Build (Otomatis di Dockerfile):

```dockerfile
# Dockerfile sudah handle publish
RUN dotnet publish -c Release -o /app/publish

# Output langsung ready untuk production!
```

### Alur Docker:

```
Step 1: docker-compose build
├─→ Backend: dotnet restore → dotnet build → dotnet publish
├─→ Frontend: npm install → npm run build
└─→ NGINX: copy configs

Step 2: docker-compose up
├─→ Start containers dengan hasil publish
└─→ Services langsung ready!

✅ BISA LANGSUNG TESTING API!
```

### Kapan Perlu Rebuild?

**Perlu rebuild jika:**

- ✅ Source code berubah (git pull)
- ✅ Environment variables berubah (frontend .env)
- ✅ Dependencies berubah (package.json, .csproj)

**Tidak perlu rebuild jika:**

- ❌ Hanya config .env berubah (backend)
- ❌ Hanya NGINX config berubah
- ❌ Hanya database data berubah

**Command untuk rebuild:**

```bash
# Rebuild specific service
docker-compose build account-api
docker-compose up -d account-api

# Rebuild all
docker-compose build
docker-compose up -d
```

---

## 📊 Testing API Setelah Deployment

### 1. Test Health Endpoints

```bash
# Account API
curl https://account-api.codeverse.id/health

# General API
curl https://api.codeverse.id/health

# Vendor API
curl https://vendor-api.codeverse.id/health

# Invoice API
curl https://invoice-api.codeverse.id/health
```

### 2. Test Login (Account API)

```bash
curl -X POST https://account-api.codeverse.id/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "password"
  }'
```

### 3. Test dari Browser Console

```javascript
// Open browser console di https://evox.codeverse.id
fetch("https://account-api.codeverse.id/health")
  .then((r) => r.text())
  .then(console.log);
```

### 4. Check Logs

```bash
# Real-time logs
docker-compose logs -f account-api

# Last 100 lines
docker-compose logs --tail=100 account-api
```

---

## 🔥 Troubleshooting

### Problem: "DNS not resolving"

**Check:**

```bash
nslookup evox.codeverse.id
# If fails, DNS belum propagasi. Wait 5-60 minutes.
```

### Problem: "502 Bad Gateway"

**Cause:** Backend container not responding

**Fix:**

```bash
# Check container status
docker-compose ps

# Check logs
docker-compose logs account-api

# Restart service
docker-compose restart account-api
```

### Problem: "CORS error di browser"

**Check NGINX headers:**

```bash
docker exec -it eprocurement-nginx cat /etc/nginx/conf.d/default.conf | grep -A5 CORS
```

### Problem: "Frontend tidak bisa akses API"

**Check:**

1. Frontend .env.production sudah benar?
2. NGINX routing sudah benar?
3. Check browser Network tab untuk error details

---

## 📝 Maintenance

### Update Service

```bash
# Pull latest code
cd ~/eprocurement/tugas_akhir-eprocurement-backend-account
git pull

# Rebuild & restart
cd ~/eprocurement/config
docker-compose build account-api
docker-compose up -d account-api
```

### View Logs

```bash
docker-compose logs -f --tail=100
```

### Backup

```bash
# Backup .env dan configs
./scripts/backup.sh
```

### Auto SSL Renewal

```bash
# Setup cron for certbot renewal
sudo crontab -e

# Add this line:
0 0 1 * * certbot renew --quiet && docker-compose restart nginx
```

---

## 🎯 Summary

✅ **DNS Setup:** 5 A records → 103.123.45.67  
✅ **Docker Build:** Otomatis build & publish, tidak perlu manual!  
✅ **Setelah `docker-compose up`:** Langsung bisa testing API!  
✅ **Subdomain Routing:** NGINX handle berdasarkan server_name  
✅ **SSL:** Let's Encrypt untuk semua subdomain

**Total waktu deployment:** ~30-60 menit (termasuk DNS propagation)

Ada pertanyaan? 😊
