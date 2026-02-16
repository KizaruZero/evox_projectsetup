# VPS Deployment Guide

Step-by-step guide to deploy the E-Procurement microservices system to a VPS (Virtual Private Server).

---

## Table of Contents

1. [VPS Requirements](#vps-requirements)
2. [Initial Server Setup](#initial-server-setup)
3. [Install Docker](#install-docker)
4. [Deploy Application](#deploy-application)
5. [Configure SSL/HTTPS](#configure-ssl-https)
6. [Configure Firewall](#configure-firewall)
7. [Setup Monitoring](#setup-monitoring)
8. [Backup Strategy](#backup-strategy)

---

## VPS Requirements

### Minimum Specifications

- **OS**: Ubuntu 20.04 LTS or later (recommended)
- **RAM**: 4GB minimum (8GB recommended)
- **CPU**: 2 cores minimum (4 cores recommended)
- **Storage**: 40GB SSD minimum
- **Network**: Public IP address

### Recommended VPS Providers

- DigitalOcean
- Linode
- AWS Lightsail
- Vultr
- Azure VM

---

## Initial Server Setup

### 1. Connect to Your VPS

```bash
ssh root@your-server-ip
```

### 2. Update System

```bash
# Update package list
apt update

# Upgrade all packages
apt upgrade -y

# Install essential tools
apt install -y curl git wget nano ufw
```

### 3. Create Non-Root User (Recommended)

```bash
# Create new user
adduser deployer

# Add to sudo group
usermod -aG sudo deployer

# Switch to new user
su - deployer
```

### 4. Setup SSH Key Authentication (Optional but Recommended)

```bash
# On your local machine, generate SSH key
ssh-keygen -t rsa -b 4096

# Copy public key to server
ssh-copy-id deployer@your-server-ip
```

---

## Install Docker

### Docker Engine Installation

```bash
# Remove old versions
sudo apt remove docker docker-engine docker.io containerd runc

# Install prerequisites
sudo apt update
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Setup repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Verify installation
docker --version
docker compose version
```

### Add User to Docker Group

```bash
# Add current user to docker group
sudo usermod -aG docker $USER

# Apply group changes
newgrp docker

# Verify (no sudo needed)
docker ps
```

### Enable Docker on Boot

```bash
sudo systemctl enable docker
sudo systemctl start docker
```

---

## Deploy Application

### 1. Clone Repository

```bash
# Navigate to home directory
cd ~

# Clone your repository
git clone <your-repository-url> eprocurement
cd eprocurement
```

**OR** Upload files via SFTP/SCP:

```bash
# From your local machine
scp -r "e:\Datasea Project\final_project" deployer@your-server-ip:~/eprocurement
```

### 2. Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit environment file
nano .env
```

**Update these critical values:**

```env
# Database - Use your production database
DB_SERVER=your-production-db.database.windows.net
DB_NAME=eProcGeneralDB
DB_USER=produser
DB_PASSWORD=<strong-password>

# JWT - MUST be changed for production!
JWT_KEY=<generate-new-secure-key>

# API URLs - Use your domain
JWT_ISSUER=https://yourdomain.com/api/account
PUBLIC_ACCOUNT_API_URL=https://yourdomain.com/api/account
# ... update all URLs

# Environment
ASPNETCORE_ENVIRONMENT=Production
```

**Generate secure JWT key:**

```bash
# Generate random 256-bit key (base64)
openssl rand -base64 32
```

### 3. Build Docker Images

```bash
# Build all images (this may take 5-10 minutes)
docker compose build

# Verify images are built
docker images | grep eprocurement
```

### 4. Start Services

```bash
# Start in production mode
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Check all containers are running
docker compose ps

# Verify all services are healthy
docker compose ps | grep healthy
```

### 5. Verify Deployment

```bash
# Check logs
docker compose logs -f

# Test health endpoints
curl http://localhost/health
curl http://localhost/api/account/health
curl http://localhost/api/general/health
curl http://localhost/api/invoice/health
curl http://localhost/api/vendor/health
```

---

## Configure SSL/HTTPS

### Option 1: Let's Encrypt (Free, Recommended)

#### Install Certbot

```bash
sudo apt install -y certbot
```

#### Stop NGINX Temporarily

```bash
docker compose stop nginx
```

#### Generate Certificate

```bash
# Replace with your domain
sudo certbot certonly --standalone -d yourdomain.com -d www.yourdomain.com

# Follow prompts, certificates will be in:
# /etc/letsencrypt/live/yourdomain.com/
```

#### Copy Certificates to Project

```bash
# Copy to nginx/ssl directory
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem \
    ~/eprocurement/nginx/ssl/cert.pem

sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem \
    ~/eprocurement/nginx/ssl/key.pem

# Set permissions
sudo chown $USER:$USER ~/eprocurement/nginx/ssl/*.pem
chmod 600 ~/eprocurement/nginx/ssl/*.pem
```

#### Update NGINX Configuration

Edit `nginx/conf.d/default.conf`:

```nginx
# Add HTTPS server block (uncomment and modify)
server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;

    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Include all locations from HTTP block
    # ... (copy from HTTP server block)
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    return 301 https://$server_name$request_uri;
}
```

#### Update docker-compose.yml

Mount SSL certificates:

```yaml
nginx:
  volumes:
    - ./nginx/ssl:/etc/nginx/ssl:ro
```

#### Restart NGINX

```bash
docker compose up -d nginx
```

#### Setup Auto-Renewal

```bash
# Create renewal script
sudo nano /etc/cron.monthly/renew-ssl.sh
```

Add:

```bash
#!/bin/bash
certbot renew --quiet
docker compose -f /home/deployer/eprocurement/docker-compose.yml restart nginx
```

Make executable:

```bash
sudo chmod +x /etc/cron.monthly/renew-ssl.sh
```

### Option 2: Custom SSL Certificate

If you have your own SSL certificate:

```bash
# Copy your certificate files
cp your-cert.pem ~/eprocurement/nginx/ssl/cert.pem
cp your-key.pem ~/eprocurement/nginx/ssl/key.pem
chmod 600 ~/eprocurement/nginx/ssl/*.pem
```

Then follow the NGINX configuration steps above.

---

## Configure Firewall

### Setup UFW (Uncomplicated Firewall)

```bash
# Reset firewall
sudo ufw --force reset

# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (IMPORTANT! Do this first)
sudo ufw allow 22/tcp

# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status verbose
```

### Additional Security (Optional)

```bash
# Rate limit SSH to prevent brute force
sudo ufw limit 22/tcp

# Allow from specific IP only (if you have static IP)
sudo ufw allow from YOUR_IP_ADDRESS to any port 22
```

---

## Setup Monitoring

### 1. Container Health Monitoring

Create monitoring script:

```bash
nano ~/monitor-containers.sh
```

Add:

```bash
#!/bin/bash
cd ~/eprocurement
docker compose ps
docker compose top
docker stats --no-stream
```

Make executable:

```bash
chmod +x ~/monitor-containers.sh
```

### 2. Setup Log Rotation

Docker handles log rotation, but verify:

```bash
# Check Docker daemon.json
sudo nano /etc/docker/daemon.json
```

Add if not present:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

Restart Docker:

```bash
sudo systemctl restart docker
```

### 3. System Monitoring

```bash
# Install monitoring tools
sudo apt install -y htop iotop

# Check system resources
htop
docker stats
```

---

## Backup Strategy

### 1. Application Backup Script

Create backup script:

```bash
nano ~/backup.sh
```

Add:

```bash
#!/bin/bash
BACKUP_DIR=~/backups
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup configuration
tar -czf $BACKUP_DIR/config_$DATE.tar.gz \
    ~/eprocurement/.env \
    ~/eprocurement/nginx/ \
    ~/eprocurement/docker-compose*.yml

# Keep only last 7 backups
ls -t $BACKUP_DIR/config_*.tar.gz | tail -n +8 | xargs rm -f

echo "Backup completed: config_$DATE.tar.gz"
```

Make executable:

```bash
chmod +x ~/backup.sh
```

### 2. Schedule Automated Backups

```bash
# Add to crontab
crontab -e
```

Add line:

```
0 2 * * * /home/deployer/backup.sh >> /home/deployer/backup.log 2>&1
```

This runs backup daily at 2 AM.

### 3. Database Backups

Your Azure SQL Database should have automated backups. Verify in Azure Portal.

---

## Maintenance Tasks

### Update Application

```bash
cd ~/eprocurement

# Pull latest code
git pull origin main

# Rebuild and restart
docker compose down
docker compose build
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Verify
docker compose ps
```

### View Logs

```bash
# Real-time logs
docker compose logs -f

# Specific service
docker compose logs -f account-api

# Last 100 lines
docker compose logs --tail=100
```

### Restart Services

```bash
# Restart all
docker compose restart

# Restart specific service
docker compose restart account-api
```

### Clean Up Disk Space

```bash
# Remove unused images
docker image prune -a

# Remove unused containers
docker container prune

# Remove unused volumes
docker volume prune

# Clean everything (careful!)
docker system prune -a
```

---

## Troubleshooting

### Containers Not Starting

```bash
# Check logs
docker compose logs

# Check individual container
docker logs eprocurement-account-api
```

### Out of Memory

```bash
# Check memory usage
free -h
docker stats

# Restart specific service
docker compose restart <service>
```

### Database Connection Issues

1. Verify firewall allows outbound connections
2. Check if Azure SQL allows your VPS IP
3. Verify connection string in `.env`

### SSL Certificate Issues

```bash
# Check certificate expiry
openssl x509 -in nginx/ssl/cert.pem -noout -dates

# Renew Let's Encrypt
sudo certbot renew
docker compose restart nginx
```

---

## Security Best Practices

1. **Keep system updated**: `sudo apt update && sudo apt upgrade`
2. **Use strong passwords**: For database, JWT keys
3. **Enable firewall**: UFW configuration
4. **Regular backups**: Automated daily backups
5. **Monitor logs**: Check for suspicious activity
6. **Use HTTPS**: Always in production
7. **Limit SSH access**: Use key-based authentication
8. **Update Docker**: Keep Docker engine updated

---

## Quick Reference

### Essential Commands

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f

# Restart
docker compose restart

# Update and restart
git pull && docker compose up -d --build

# Backup
~/backup.sh

# Check health
docker compose ps
```

---

## Support

For issues contact your development team with:

- Output of `docker compose ps`
- Output of `docker compose logs`
- Contents of `.env` (remove sensitive data!)
