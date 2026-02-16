# Config Repository Structure

This repository contains deployment configuration for E-Procurement microservices.

## 📁 Repository Contents

```
eprocurement-deployment/
├── README.md                          # This file
├── .gitignore                         # Git ignore (includes .env)
├── .env.example                       # Environment template
│
├── docker-compose.multi-repo.yml      # Multi-repository orchestration
├── docker-compose.prod.yml            # Production overrides
│
├── nginx/                             # NGINX reverse proxy
│   ├── Dockerfile
│   ├── nginx.conf                     # Main NGINX config
│   ├── conf.d/
│   │   └── default.conf               # Routing rules
│   └── ssl/                           # SSL certificates directory
│       └── README.md
│
├── docs/                              # Documentation
│   ├── DOCKER_SETUP.md
│   ├── DEPLOYMENT_VPS.md
│   ├── MULTI_REPOSITORY_DEPLOYMENT.md
│   └── DEPLOYMENT_CONFIGURATION_GUIDE.md
│
└── scripts/                           # Automation scripts
    ├── deploy.sh                      # Deployment script
    ├── backup.sh                      # Backup script
    └── setup-multi-repo.sh            # Multi-repo setup
```

## 🚀 Quick Start

### 1. Setup on VPS

```bash
# Clone this config repository
git clone https://github.com/yourusername/eprocurement-deployment.git
cd eprocurement-deployment

# Run setup script (will clone all 5 service repositories)
chmod +x scripts/setup-multi-repo.sh
./scripts/setup-multi-repo.sh
```

This will create:

```
~/eprocurement/
├── tugas_akhir-eprocurement-backend-account/    (cloned)
├── tugas_akhir-eprocurement-backend-general/    (cloned)
├── tugas_akhir-eprocurement-backend-invoice/    (cloned)
├── tugas_akhir-eprocurement-backend-vendor/     (cloned)
├── tugas_akhir-eprocurement-frontend/           (cloned)
└── config/                                       (this repo)
```

### 2. Configure

```bash
cd ~/eprocurement/config

# Create .env from template
cp .env.example .env

# Edit with your configuration
nano .env
```

**IMPORTANT:** Update these values:

- `DOMAIN=yourdomain.com`
- `JWT_KEY=` (generate new: `openssl rand -base64 32`)
- `DB_PASSWORD=` (if needed)
- All `VITE_API_*` URLs to use your domain

### 3. Deploy

```bash
# Build all services
docker-compose -f docker-compose.multi-repo.yml build

# Start in production mode
docker-compose -f docker-compose.multi-repo.yml -f docker-compose.prod.yml up -d

# Check status
docker-compose ps
```

### 4. Setup SSL (Production)

```bash
# Install certbot
sudo apt install certbot

# Generate certificate
sudo certbot certonly --standalone -d yourdomain.com -d www.yourdomain.com

# Copy to nginx directory
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem nginx/ssl/cert.pem
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem nginx/ssl/key.pem

# Update nginx/conf.d/default.conf with SSL config
# Then restart nginx
docker-compose restart nginx
```

## 📖 Documentation

- **[DEPLOYMENT_CONFIGURATION_GUIDE.md](docs/DEPLOYMENT_CONFIGURATION_GUIDE.md)** - Complete configuration guide
- **[MULTI_REPOSITORY_DEPLOYMENT.md](docs/MULTI_REPOSITORY_DEPLOYMENT.md)** - Multi-repo deployment methods
- **[DEPLOYMENT_VPS.md](docs/DEPLOYMENT_VPS.md)** - VPS deployment guide
- **[DOCKER_SETUP.md](docs/DOCKER_SETUP.md)** - Docker setup guide

## ⚙️ What This Repository Contains

### ✅ Configuration Files

- Docker Compose orchestration
- NGINX reverse proxy configuration
- Environment variable templates
- SSL certificate directory

### ✅ Documentation

- Setup guides
- Deployment procedures
- Troubleshooting

### ✅ Automation Scripts

- Multi-repository setup
- Deployment automation
- Backup procedures

### ❌ What's NOT Included

- Source code (services are in separate repositories)
- Actual `.env` file (use `.env.example` as template)
- SSL certificates (generated on VPS)

## 🔧 Service Repositories

This deployment config works with these repositories:

1. **Account API:** https://github.com/luthfan1234/tugas_akhir-eprocurement-backend-account
2. **General API:** https://github.com/luthfan1234/tugas_akhir-eprocurement-backend-general
3. **Invoice API:** https://github.com/luthfan1234/tugas_akhir-eprocurement-backend-invoice
4. **Vendor API:** https://github.com/luthfan1234/tugas_akhir-eprocurement-backend-vendor
5. **Frontend:** https://github.com/FIGRIHANS/tugas_akhir-eprocurement-frontend

## 🌐 Architecture

```
          ┌──────────────┐
          │   Internet   │
          └───────┬──────┘
                  │
          ┌───────▼────────┐
          │  NGINX :80/443 │
          │  (yourdomain)  │
          └────────┬───────┘
                   │
    ┌──────────────┼─────────────────┬─────────┐
    │              │                 │         │
    ▼              ▼                 ▼         ▼
┤Frontend│  │Account API│  │General API│  │Invoice│  │Vendor│
│ :3000  │  │  :8001    │  │  :8002    │  │ :8003 │  │:8004 │
└────────┘  └───────────┘  └───────────┘  └───────┘  └──────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  Azure SQL DB    │
                    └──────────────────┘
```

## 🔒 Security Checklist

Before deploying to production:

- [ ] Update `JWT_KEY` to new secure random value
- [ ] Change default database password
- [ ] Configure SSL certificates
- [ ] Update `DOMAIN` in .env
- [ ] Setup firewall (UFW)
- [ ] Limit SSH access
- [ ] Enable automatic security updates
- [ ] Setup backup automation

## 📞 Support

For issues:

1. Check logs: `docker-compose logs -f`
2. Review documentation in `docs/`
3. Check service status: `docker-compose ps`

## 📝 License

[Your License]
