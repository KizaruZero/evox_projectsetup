# Docker Setup Guide - E-Procurement Microservices

Complete guide for setting up and running the E-Procurement system using Docker.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [Quick Start](#quick-start)
4. [Configuration](#configuration)
5. [Local Development](#local-development)
6. [Production Deployment](#production-deployment)
7. [Common Commands](#common-commands)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Software

**Docker Desktop (Recommended for Windows)**

- Download from: https://www.docker.com/products/docker-desktop
- Version: 20.10 or later
- Includes Docker Engine and Docker Compose

**OR Docker Engine + Docker Compose (for Linux/VPS)**

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo apt-get install docker-compose-plugin
```

### System Requirements

- **RAM**: Minimum 8GB (16GB recommended)
- **Disk Space**: 10GB free space
- **CPU**: 4 cores minimum

### Verify Installation

```bash
docker --version
docker-compose --version
```

---

## Architecture Overview

### System Diagram

```
┌─────────────────────────────────────────────────┐
│              Internet / Client                  │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
        ┌────────────────────────┐
        │   NGINX (Port 80/443)  │
        │   Reverse Proxy        │
        └────────────┬───────────┘
                     │
        ┌────────────┴────────────────────┬───────────┬──────────┐
        │                                 │           │          │
        ▼                                 ▼           ▼          ▼
┌──────────────┐  ┌──────────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐
│  Frontend    │  │ Account API  │  │ General  │  │ Invoice  │  │  Vendor API  │
│  (Vue.js)    │  │  (Port 8001) │  │   API    │  │   API    │  │ (Port 8004)  │
│  (Port 3000) │  │              │  │ (8002)   │  │ (8003)   │  │              │
└──────────────┘  └──────────────┘  └──────────┘  └──────────┘  └──────────────┘
                          │                │            │              │
                          └────────────────┴────────────┴──────────────┘
                                              │
                                              ▼
                                    ┌──────────────────┐
                                    │  Azure SQL DB    │
                                    │  (External)      │
                                    └──────────────────┘
```

### Container Details

| Service     | Container Name           | Port    | Image Base                          | Purpose                       |
| ----------- | ------------------------ | ------- | ----------------------------------- | ----------------------------- |
| NGINX       | eprocurement-nginx       | 80, 443 | nginx:alpine                        | Reverse proxy & load balancer |
| Frontend    | eprocurement-frontend    | 3000    | node:20-alpine                      | Vue.js web interface          |
| Account API | eprocurement-account-api | 8001    | mcr.microsoft.com/dotnet/aspnet:8.0 | Account management            |
| General API | eprocurement-general-api | 8002    | mcr.microsoft.com/dotnet/aspnet:8.0 | General operations            |
| Invoice API | eprocurement-invoice-api | 8003    | mcr.microsoft.com/dotnet/aspnet:8.0 | Invoice management            |
| Vendor API  | eprocurement-vendor-api  | 8004    | mcr.microsoft.com/dotnet/aspnet:8.0 | Vendor management             |

### Network

All containers communicate through a Docker bridge network named `eprocurement-network`.

### Routing (NGINX Reverse Proxy)

- `http://localhost/` → Frontend
- `http://localhost/api/account/` → Account API
- `http://localhost/api/general/` → General API
- `http://localhost/api/invoice/` → Invoice API
- `http://localhost/api/vendor/` → Vendor API

---

## Quick Start

### 1. Clone the Repository

```bash
cd e:\Datasea Project\final_project
```

### 2. Create Environment File

```bash
# Copy the example environment file
copy .env.example .env

# Edit .env with your actual values
notepad .env
```

**Important**: Update these values in `.env`:

- Database connection string
- JWT secret key (for production)
- API URLs

### 3. Build and Start All Services

```bash
# Build all Docker images
docker-compose build

# Start all services in detached mode
docker-compose up -d
```

### 4. Verify All Services Are Running

```bash
# Check container status
docker-compose ps

# All services should show "Up" status with "healthy" state
```

### 5. Access the Application

Open your browser and navigate to:

- **Frontend**: http://localhost
- **API Health Checks**:
  - http://localhost/api/account/health
  - http://localhost/api/general/health
  - http://localhost/api/invoice/health
  - http://localhost/api/vendor/health

---

## Configuration

### Environment Variables

The `.env` file contains all configuration. Key sections:

#### Database Configuration

```env
DB_SERVER=your-server.database.windows.net
DB_NAME=eProcGeneralDB
DB_USER=sqladminrole
DB_PASSWORD=YourSecurePassword
```

#### API Ports (Internal)

```env
ACCOUNT_API_PORT=8001
GENERAL_API_PORT=8002
INVOICE_API_PORT=8003
VENDOR_API_PORT=8004
```

#### JWT Configuration

```env
JWT_KEY=<YourSecureRandomKey>
JWT_ISSUER=http://localhost/api/account
```

> **Security Note**: Always use strong, unique values for `DB_PASSWORD` and `JWT_KEY` in production!

### Service Configuration

Each backend service reads configuration from:

1. `appsettings.json` (default values)
2. Environment variables (override defaults)

---

## Local Development

### Starting Services

```bash
# Start all services
docker-compose up

# Start specific service
docker-compose up account-api

# Start in background
docker-compose up -d
```

### Stopping Services

```bash
# Stop all services (keeps containers)
docker-compose stop

# Stop and remove containers
docker-compose down

# Stop and remove containers + volumes + networks
docker-compose down -v
```

### Viewing Logs

```bash
# View logs from all services
docker-compose logs

# Follow logs in real-time
docker-compose logs -f

# View logs for specific service
docker-compose logs -f account-api

# View last 100 lines
docker-compose logs --tail=100 frontend
```

### Rebuilding After Code Changes

```bash
# Rebuild all services
docker-compose build

# Rebuild specific service
docker-compose build account-api

# Rebuild and restart
docker-compose up -d --build
```

### Accessing Container Shell

```bash
# Access backend container
docker exec -it eprocurement-account-api /bin/bash

# Access frontend container
docker exec -it eprocurement-frontend /bin/sh

# Access NGINX container
docker exec -it eprocurement-nginx /bin/sh
```

### Database Migrations

If your .NET services have Entity Framework migrations:

```bash
# Run migrations inside the container
docker exec -it eprocurement-account-api dotnet ef database update
```

---

## Production Deployment

See [DEPLOYMENT_VPS.md](./DEPLOYMENT_VPS.md) for detailed VPS deployment guide.

### Quick Production Deploy

```bash
# Use production override file
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# View production logs
docker-compose -f docker-compose.yml -f docker-compose.prod.yml logs -f
```

### Production Checklist

- [ ] Update `.env` with production values
- [ ] Change `JWT_KEY` to a secure random key
- [ ] Update database connection string
- [ ] Configure SSL certificates in `nginx/ssl/`
- [ ] Update NGINX config for your domain
- [ ] Set resource limits (already in `docker-compose.prod.yml`)
- [ ] Configure firewall on VPS
- [ ] Set up automatic backups

---

## Common Commands

### Container Management

```bash
# View running containers
docker-compose ps

# View container resource usage
docker stats

# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart account-api
```

### Image Management

```bash
# List images
docker images

# Remove unused images
docker image prune

# Remove all stopped containers
docker container prune
```

### Network Management

```bash
# View networks
docker network ls

# Inspect network
docker network inspect eprocurement-network
```

### Clean Up Everything

```bash
# Stop and remove everything (CAUTION!)
docker-compose down -v --rmi all

# Remove all unused Docker resources
docker system prune -a
```

---

## Troubleshooting

### Services Not Starting

**Check logs:**

```bash
docker-compose logs <service-name>
```

**Common issues:**

- Port already in use
- Missing environment variables
- Database connection failed

### Database Connection Errors

1. Verify connection string in `.env`
2. Check if database allows connections from your IP
3. Verify credentials are correct

```bash
# Test from inside container
docker exec -it eprocurement-account-api /bin/bash
# Then try to connect manually
```

### NGINX 502 Bad Gateway

Means backend service is not responding:

```bash
# Check if backend is healthy
docker-compose ps

# View backend logs
docker-compose logs account-api
```

### Port Conflicts

If ports are already in use:

1. Stop conflicting services
2. OR change ports in `.env`:
   ```env
   NGINX_HTTP_PORT=8080  # Instead of 80
   ```

### Rebuilding from Scratch

```bash
# Remove everything and start fresh
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
```

### Memory Issues

If containers are running out of memory:

```bash
# Increase Docker Desktop memory limit (Windows)
# Settings → Resources → Memory → Increase

# OR limit individual service memory in docker-compose.prod.yml
```

### Health Check Failing

If health checks keep failing but service works:

1. Increase health check timeout
2. Check if `/health` endpoint exists in your API
3. Verify health check command in Dockerfile

---

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [.NET Docker Images](https://hub.docker.com/_/microsoft-dotnet)

---

## Support

For issues or questions:

1. Check the logs: `docker-compose logs -f`
2. Review this documentation
3. Check the [Troubleshooting](#troubleshooting) section
4. Contact your development team
