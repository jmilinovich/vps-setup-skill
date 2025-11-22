# VPS Setup Reference Guide

Complete step-by-step guide for manually setting up an Ubuntu VPS for web development.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Server Access](#initial-server-access)
3. [System Updates](#system-updates)
4. [Install Node.js](#install-nodejs)
5. [Install PM2](#install-pm2)
6. [Install Python](#install-python)
7. [Install Nginx](#install-nginx)
8. [Configure Firewall](#configure-firewall)
9. [Install fail2ban](#install-fail2ban)
10. [Install Docker](#install-docker-optional)
11. [SSL Certificates](#ssl-certificates)
12. [Nginx Reverse Proxy](#nginx-reverse-proxy)
13. [Deploy First App](#deploy-first-app)
14. [Maintenance](#maintenance)

---

## Prerequisites

- Fresh Ubuntu 22.04 or 24.04 VPS
- Root or sudo access
- SSH access to the server
- Domain name (optional, for SSL)

## Initial Server Access

```bash
# Connect to your server
ssh root@your-server-ip

# Or with a key file
ssh -i ~/.ssh/your-key.pem root@your-server-ip
```

## System Updates

Always start by updating the system:

```bash
# Update package lists
apt update

# Upgrade installed packages
apt upgrade -y

# Install essential tools
apt install -y curl wget git build-essential software-properties-common htop
```

## Install Node.js

Install Node.js 20 LTS via NodeSource:

```bash
# Download and run NodeSource setup script
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -

# Install Node.js
apt install -y nodejs

# Verify installation
node --version   # Should show v20.x.x
npm --version    # Should show 10.x.x
```

## Install PM2

PM2 is a process manager for Node.js applications:

```bash
# Install PM2 globally
npm install -g pm2

# Verify installation
pm2 --version

# Configure PM2 to start on boot
pm2 startup systemd -u root --hp /root
```

### PM2 Essential Commands

```bash
pm2 start app.js --name my-app    # Start an app
pm2 list                          # List all apps
pm2 logs [app-name]               # View logs
pm2 restart [app-name]            # Restart app
pm2 stop [app-name]               # Stop app
pm2 delete [app-name]             # Remove app
pm2 save                          # Save current app list
pm2 resurrect                     # Restore saved apps
```

## Install Python

Python 3 is usually pre-installed, but ensure pip is available:

```bash
# Install Python and pip
apt install -y python3 python3-pip python3-venv

# Verify installation
python3 --version
pip3 --version
```

## Install Nginx

Nginx serves as a reverse proxy and web server:

```bash
# Install Nginx
apt install -y nginx

# Enable and start Nginx
systemctl enable nginx
systemctl start nginx

# Verify it's running
systemctl status nginx

# Test by visiting http://your-server-ip in a browser
```

### Nginx Key Directories

- `/etc/nginx/nginx.conf` - Main config
- `/etc/nginx/sites-available/` - Site configs
- `/etc/nginx/sites-enabled/` - Enabled sites (symlinks)
- `/var/log/nginx/` - Access and error logs

## Configure Firewall

UFW (Uncomplicated Firewall) provides simple firewall management:

```bash
# Install UFW (usually pre-installed)
apt install -y ufw

# Set default policies
ufw default deny incoming
ufw default allow outgoing

# Allow essential ports
ufw allow 22/tcp        # SSH
ufw allow 80/tcp        # HTTP
ufw allow 443/tcp       # HTTPS
ufw allow 3000:3010/tcp # Development apps

# Enable firewall
ufw enable

# Check status
ufw status numbered
```

### Firewall Commands Reference

```bash
ufw status                    # View current rules
ufw allow [port]/tcp         # Open a port
ufw delete allow [port]/tcp  # Close a port
ufw allow from [ip]          # Allow specific IP
ufw deny from [ip]           # Block specific IP
ufw reset                    # Reset all rules
```

## Install fail2ban

fail2ban protects against brute-force attacks:

```bash
# Install fail2ban
apt install -y fail2ban

# Create local config
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 24h
EOF

# Restart fail2ban
systemctl restart fail2ban

# Check status
fail2ban-client status
fail2ban-client status sshd
```

## Install Docker (Optional)

Docker enables containerized applications:

```bash
# Install Docker using official script
curl -fsSL https://get.docker.com | bash

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Verify installation
docker --version
docker run hello-world

# Install Docker Compose (included in modern Docker)
docker compose version
```

## SSL Certificates

Use Certbot to get free SSL certificates from Let's Encrypt:

```bash
# Install Certbot
apt install -y certbot python3-certbot-nginx

# Get certificate (replace with your domain)
certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Test auto-renewal
certbot renew --dry-run
```

### Certificate Management

```bash
certbot certificates              # List all certs
certbot renew                    # Renew all certs
certbot delete --cert-name name  # Delete a cert
```

Certificates auto-renew via systemd timer. Check with:
```bash
systemctl status certbot.timer
```

## Nginx Reverse Proxy

### Basic Site Configuration

Create a new site config:

```bash
nano /etc/nginx/sites-available/myapp
```

Basic reverse proxy config:

```nginx
server {
    listen 80;
    server_name myapp.yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable the site:

```bash
# Create symlink
ln -s /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/

# Test config
nginx -t

# Reload nginx
systemctl reload nginx
```

### Multiple Apps on One Domain

```nginx
server {
    listen 80;
    server_name yourdomain.com;

    # Main app
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }

    # API
    location /api/ {
        proxy_pass http://localhost:5000/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }

    # Dashboard
    location /dashboard {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }
}
```

## Deploy First App

### Create Project Directory

```bash
mkdir -p /home/projects
cd /home/projects
```

### Clone and Deploy a Node.js App

```bash
# Clone repository
git clone https://github.com/username/myproject.git
cd myproject

# Install dependencies
npm install

# Start with PM2
pm2 start index.js --name myproject

# Or with environment variables
PORT=3001 pm2 start index.js --name myproject

# Save PM2 state
pm2 save
```

### Deploy a Python App

```bash
# Clone repository
cd /home/projects
git clone https://github.com/username/python-app.git
cd python-app

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Start with PM2
pm2 start app.py --interpreter python3 --name python-app

pm2 save
```

## Maintenance

### Regular Updates

```bash
# Update system packages
apt update && apt upgrade -y

# Update npm packages globally
npm update -g

# Update PM2
npm install -g pm2@latest
pm2 update
```

### Check Disk Space

```bash
df -h                    # Overall disk usage
du -sh /home/projects/*  # Project sizes
ncdu /                   # Interactive disk analyzer (install with apt)
```

### Check Memory

```bash
free -h                  # Memory usage
htop                     # Interactive process viewer
```

### View Logs

```bash
# PM2 logs
pm2 logs                 # All apps
pm2 logs myapp           # Specific app
pm2 logs --lines 100     # Last 100 lines

# Nginx logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# System logs
journalctl -u nginx -n 50
journalctl -u fail2ban -n 50
```

### Backup Considerations

Important directories to backup:
- `/home/projects/` - Your applications
- `/etc/nginx/sites-available/` - Nginx configs
- `~/.pm2/` - PM2 configuration

```bash
# Example backup command
tar -czvf backup-$(date +%Y%m%d).tar.gz /home/projects /etc/nginx/sites-available
```

---

## Quick Reference Card

| Task | Command |
|------|---------|
| List running apps | `pm2 list` |
| View app logs | `pm2 logs [app]` |
| Restart app | `pm2 restart [app]` |
| Check firewall | `ufw status` |
| Open port | `ufw allow [port]/tcp` |
| Test nginx config | `nginx -t` |
| Reload nginx | `systemctl reload nginx` |
| Get SSL cert | `certbot --nginx -d domain` |
| Check disk | `df -h` |
| Check memory | `free -h` |

---

## Troubleshooting

### App not accessible externally

1. Check app is running: `pm2 list`
2. Check app logs: `pm2 logs [app]`
3. Test locally: `curl localhost:3000`
4. Check firewall: `ufw status`
5. Check nginx: `nginx -t && systemctl status nginx`

### Port already in use

```bash
# Find what's using the port
lsof -i :3000

# Kill the process
kill -9 [PID]

# Or use fuser
fuser -k 3000/tcp
```

### Nginx config errors

```bash
# Test configuration
nginx -t

# Check error log
tail -50 /var/log/nginx/error.log
```

### SSL certificate issues

```bash
# Check certificate status
certbot certificates

# Force renewal
certbot renew --force-renewal

# Check nginx SSL config
nginx -t
```

### Out of memory

```bash
# Check current usage
free -h

# Find memory-hungry processes
ps aux --sort=-%mem | head

# Add swap space (if needed)
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
```
