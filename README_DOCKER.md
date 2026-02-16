# E-Procurement Microservices - Docker Setup

Complete Docker containerization for the E-Procurement system with 4 backend microservices, 1 frontend, and NGINX reverse proxy.

## 🚀 Quick Start

### Prerequisites

- Docker Desktop (Windows) or Docker Engine + Docker Compose (Linux/VPS)
- 8GB RAM minimum
- 10GB free disk space

### Local Development

```bash
# 1. Clone the repository (if not already done)
cd "e:\Datasea Project\final_project"

# 2. Create environment file
copy .env.example .env
# Edit .env with your configuration

# 3. Start all services
docker-compose up -d

# 4. Access the application
# Frontend: http://localhost
# APIs: http://localhost/api/account, /api/general, /api/invoice, /api/vendor
```

### VPS Production Deployment

```bash
# 1. Install Docker on your VPS
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 2. Clone and configure
git clone <your-repo> eprocurement
cd eprocurement
cp .env.example .env
nano .env  # Configure for production

# 3. Deploy
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

## 📁 Project Structure

```
final_project/
├── tugas_akhir-eprocurement-backend-account/    # Account Management API
│   ├── Dockerfile                                # .NET 8.0 container
│   └── .dockerignore
├── tugas_akhir-eprocurement-backend-general/     # General Management API
│   ├── Dockerfile
│   └── .dockerignore
├── tugas_akhir-eprocurement-backend-invoice/     # Invoice Management API
│   ├── Dockerfile
│   └── .dockerignore
├── tugas_akhir-eprocurement-backend-vendor/      # Vendor Management API
│   ├── Dockerfile
│   └── .dockerignore
├── tugas_akhir-eprocurement-frontend/            # Vue.js Frontend
│   ├── Dockerfile                                # Multi-stage: Build + NGINX
│   ├── nginx.conf                                # SPA routing
│   └── .dockerignore
├── nginx/                                        # Reverse Proxy
│   ├── Dockerfile
│   ├── nginx.conf                                # Main config
│   ├── conf.d/
│   │   └── default.conf                          # Routing rules
│   └── ssl/                                      # SSL certificates
├── docs/
│   ├── DOCKER_SETUP.md                           # Comprehensive setup guide
│   └── DEPLOYMENT_VPS.md                         # VPS deployment guide
├── scripts/
│   ├── deploy.sh                                 # Automated deployment
│   └── backup.sh                                 # Backup script
├── docker-compose.yml                            # Main orchestration
├── docker-compose.prod.yml                       # Production overrides
├── .env.example                                  # Environment template
└── README.md                                     # This file
```

## 🏗️ Architecture

```
┌──────────────────────────────────────────┐
│            Client Browser                │
└─────────────────┬────────────────────────┘
                  │
                  ▼
      ┌───────────────────────┐
      │   NGINX (Port 80/443) │
      │   Reverse Proxy       │
      └───────────┬───────────┘
                  │
      ┌───────────┴────────────────────┬─────────┐
      │                                │         │
      ▼                                ▼         ▼
┌──────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐
│ Frontend │  │ Account    │  │ General    │  │ Invoice    │  ┌────────────┐
│ Vue.js   │  │ API (.NET) │  │ API (.NET) │  │ API (.NET) │  │ Vendor API │
│ :3000    │  │ :8001      │  │ :8002      │  │ :8003      │  │ :8004      │
└──────────┘  └────────────┘  └────────────┘  └────────────┘  └────────────┘
                                       │
                                       ▼
                              ┌─────────────────┐
                              │  Azure SQL DB   │
                              └─────────────────┘
```

## 🔧 Services

| Service         | Description                   | Port    | Technology         |
| --------------- | ----------------------------- | ------- | ------------------ |
| **nginx**       | Reverse proxy & load balancer | 80, 443 | NGINX Alpine       |
| **frontend**    | Vue.js web application        | 3000    | Node.js 20 + NGINX |
| **account-api** | Account management service    | 8001    | .NET 8.0           |
| **general-api** | General operations service    | 8002    | .NET 8.0           |
| **invoice-api** | Invoice management service    | 8003    | .NET 8.0           |
| **vendor-api**  | Vendor management service     | 8004    | .NET 8.0           |

## 🌐 API Routing

Through NGINX reverse proxy:

- `http://localhost/` → Frontend
- `http://localhost/api/account/` → Account API (8001)
- `http://localhost/api/general/` → General API (8002)
- `http://localhost/api/invoice/` → Invoice API (8003)
- `http://localhost/api/vendor/` → Vendor API (8004)

## ⚙️ Configuration

### Environment Variables

Copy `.env.example` to `.env` and configure:

```env
# Database
DB_SERVER=your-server.database.windows.net
DB_NAME=eProcGeneralDB
DB_USER=yourusername
DB_PASSWORD=yourpassword

# JWT (CHANGE IN PRODUCTION!)
JWT_KEY=your-secure-random-key

# Ports
ACCOUNT_API_PORT=8001
GENERAL_API_PORT=8002
INVOICE_API_PORT=8003
VENDOR_API_PORT=8004
```

**⚠️ Security**: Never commit `.env` to version control!

## 📚 Documentation

- **[Docker Setup Guide](docs/DOCKER_SETUP.md)** - Complete guide for local development
  - Prerequisites and installation
  - Architecture overview
  - Configuration details
  - Common commands
  - Troubleshooting

- **[VPS Deployment Guide](docs/DEPLOYMENT_VPS.md)** - Production deployment
  - Server setup
  - Docker installation
  - SSL/HTTPS configuration
  - Firewall setup
  - Monitoring and backups

## 🛠️ Common Commands

### Development

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Rebuild after code changes
docker-compose up -d --build

# Check status
docker-compose ps
```

### Production

```bash
# Deploy with production settings
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# View production logs
docker-compose logs -f --tail=100

# Restart specific service
docker-compose restart account-api
```

### Maintenance

```bash
# Backup configuration
./scripts/backup.sh

# Deploy updates
./scripts/deploy.sh

# Clean up unused images
docker image prune -a
```

## 🔍 Health Checks

All services include health checks:

```bash
# NGINX
curl http://localhost/health

# Backend APIs
curl http://localhost/api/account/health
curl http://localhost/api/general/health
curl http://localhost/api/invoice/health
curl http://localhost/api/vendor/health
```

## 🐛 Troubleshooting

### Services won't start

```bash
# Check logs for errors
docker-compose logs <service-name>

# Common issues:
# - Port already in use (change in .env)
# - Missing .env file (copy from .env.example)
# - Database connection failed (check credentials)
```

### Database connection errors

1. Verify connection string in `.env`
2. Check if Azure SQL allows connections from your IP
3. Ensure firewall rules permit outbound connections

### NGINX 502 errors

Backend service is not responding:

```bash
# Check if backend is running
docker-compose ps

# View backend logs
docker-compose logs account-api
```

See [DOCKER_SETUP.md](docs/DOCKER_SETUP.md#troubleshooting) for more details.

## 🔒 Security Best Practices

✅ **Implemented:**

- Multi-stage Docker builds (minimal final images)
- Non-root container users
- Environment variable configuration (no secrets in code)
- Health checks for all services
- Resource limits (production)
- SSL/HTTPS support (NGINX)

⚠️ **Production Checklist:**

- [ ] Change `JWT_KEY` to secure random value
- [ ] Use strong database password
- [ ] Configure SSL certificates
- [ ] Enable firewall (UFW)
- [ ] Set up automated backups
- [ ] Configure log rotation
- [ ] Limit SSH access
- [ ] Keep Docker updated

## 📊 Monitoring

### Resource Usage

```bash
# Real-time stats
docker stats

# Container details
docker-compose top
```

### Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f account-api

# Last 100 lines
docker-compose logs --tail=100
```

## 🔄 Updates and Deployment

### Automated Deployment (VPS)

```bash
# Run deployment script
./scripts/deploy.sh
```

This script:

1. Creates backup
2. Pulls latest code
3. Rebuilds images
4. Restarts services
5. Verifies health
6. Cleans up old images

### Manual Update

```bash
# Pull latest changes
git pull

# Rebuild and restart
docker-compose down
docker-compose build
docker-compose up -d

# Verify
docker-compose ps
```

## 🆘 Support

For issues or questions:

1. Check the logs: `docker-compose logs -f`
2. Review documentation in `docs/`
3. Check [Troubleshooting](docs/DOCKER_SETUP.md#troubleshooting)
4. Contact development team

## 📝 License

[Your License Here]

## 👥 Contributors

[Your Team/Contributors Here]

---

**Built with Docker** 🐳 | **Powered by .NET 8.0 & Vue.js** ⚡
