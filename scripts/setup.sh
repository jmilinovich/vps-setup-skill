#!/bin/bash
#
# VPS Setup Script
# Sets up a fresh Ubuntu VPS for web development
#
# Usage: curl -fsSL [url]/setup.sh | bash
#    or: bash setup.sh
#
# Tested on: Ubuntu 22.04, 24.04
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Detect OS
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
        log_info "Detected OS: $OS $VERSION"
    else
        log_error "Cannot detect OS"
        exit 1
    fi

    if [[ "$OS" != "ubuntu" ]]; then
        log_warn "This script is designed for Ubuntu. Proceeding anyway..."
    fi
}

# Update system packages
update_system() {
    log_info "Updating system packages..."
    apt update && apt upgrade -y
    apt install -y curl wget git build-essential software-properties-common
    log_success "System packages updated"
}

# Install Node.js via NodeSource
install_nodejs() {
    log_info "Installing Node.js 20 LTS..."

    if command -v node &> /dev/null; then
        log_warn "Node.js already installed: $(node --version)"
        read -p "Reinstall? (y/N): " reinstall
        if [[ "$reinstall" != "y" && "$reinstall" != "Y" ]]; then
            return
        fi
    fi

    # Install Node.js 20.x from NodeSource
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt install -y nodejs

    log_success "Node.js installed: $(node --version)"
    log_success "npm installed: $(npm --version)"
}

# Install PM2 process manager
install_pm2() {
    log_info "Installing PM2..."

    if command -v pm2 &> /dev/null; then
        log_warn "PM2 already installed"
        return
    fi

    npm install -g pm2

    # Setup PM2 to start on boot
    pm2 startup systemd -u root --hp /root

    log_success "PM2 installed and configured for startup"
}

# Install Python and pip
install_python() {
    log_info "Installing Python..."

    apt install -y python3 python3-pip python3-venv

    log_success "Python installed: $(python3 --version)"
}

# Install and configure Nginx
install_nginx() {
    log_info "Installing Nginx..."

    apt install -y nginx

    # Enable and start nginx
    systemctl enable nginx
    systemctl start nginx

    log_success "Nginx installed and running"
}

# Install Docker (optional)
install_docker() {
    log_info "Installing Docker..."

    if command -v docker &> /dev/null; then
        log_warn "Docker already installed"
        return
    fi

    # Install Docker using official script
    curl -fsSL https://get.docker.com | bash

    # Enable and start Docker
    systemctl enable docker
    systemctl start docker

    log_success "Docker installed: $(docker --version)"
}

# Install and configure UFW firewall
configure_firewall() {
    log_info "Configuring UFW firewall..."

    apt install -y ufw

    # Reset to defaults
    ufw --force reset

    # Set default policies
    ufw default deny incoming
    ufw default allow outgoing

    # Allow essential ports
    ufw allow 22/tcp      # SSH
    ufw allow 80/tcp      # HTTP
    ufw allow 443/tcp     # HTTPS
    ufw allow 3000:3010/tcp  # Development apps

    # Enable firewall
    ufw --force enable

    log_success "Firewall configured and enabled"
    ufw status numbered
}

# Install and configure fail2ban
install_fail2ban() {
    log_info "Installing fail2ban..."

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

    # Enable and start fail2ban
    systemctl enable fail2ban
    systemctl restart fail2ban

    log_success "fail2ban installed and configured"
}

# Install Certbot for SSL
install_certbot() {
    log_info "Installing Certbot..."

    apt install -y certbot python3-certbot-nginx

    log_success "Certbot installed"
    log_info "To get SSL certificate, run: certbot --nginx -d yourdomain.com"
}

# Create project directory structure
create_project_structure() {
    log_info "Creating project directory structure..."

    mkdir -p /home/projects
    cd /home/projects

    # Create README.md
    cat > /home/projects/README.md << 'EOF'
# Dev Playground Server

Personal development server for testing and running projects.

## Server Details

- **OS**: Ubuntu (see /etc/os-release)
- **Projects**: /home/projects/
- **Process Manager**: PM2

## Quick Commands

```bash
pm2 list                 # See running apps
pm2 logs [app]          # View logs
pm2 restart [app]       # Restart app
```

## Deploy a Project

```bash
cd /home/projects
git clone <your-repo>
cd <project>
npm install
pm2 start index.js --name <app-name>
```

## Ports

- 22: SSH
- 80: HTTP
- 443: HTTPS
- 3000-3010: Development apps

## Firewall

```bash
ufw status              # View rules
ufw allow <port>/tcp    # Open port
```
EOF

    # Create CLAUDE.md
    cat > /home/projects/CLAUDE.md << 'EOF'
# Claude Assistant Guide

This document is for AI assistants helping with this server.

## Context

- **Purpose**: Personal development playground
- **Skill Level**: Learning server management
- **Approach**: Explain things simply

## Pre-Flight Checklist

```bash
pm2 list              # What's running?
df -h                 # Disk space
free -h               # Memory
systemctl status nginx
```

## Common Tasks

### Deploy Node.js App
```bash
cd /home/projects
git clone <repo>
cd <project>
npm install
pm2 start index.js --name <app-name>
```

### Check Logs
```bash
pm2 logs <app-name>
```

### Troubleshooting
1. Check if running: pm2 list
2. Check logs: pm2 logs <app>
3. Check port: lsof -i :<port>
4. Check firewall: ufw status

## Key Directories

- /home/projects/ - All projects
- /etc/nginx/sites-available/ - Nginx configs
- ~/.pm2/logs/ - PM2 logs
EOF

    # Create QUICKSTART.md
    cat > /home/projects/QUICKSTART.md << 'EOF'
# Quick Start

## Deploy in 60 Seconds

```bash
cd /home/projects
git clone <your-repo>
cd <project>
npm install
pm2 start index.js --name my-app
```

## Essential Commands

```bash
pm2 list          # What's running?
pm2 logs          # See logs
pm2 restart all   # Restart everything
```

## Open a Port

```bash
ufw allow 3011/tcp
```
EOF

    log_success "Project structure created at /home/projects/"
}

# Create hello-world test app
create_test_app() {
    log_info "Creating hello-world test app..."

    mkdir -p /home/projects/hello-world
    cd /home/projects/hello-world

    # Create package.json
    cat > package.json << 'EOF'
{
  "name": "hello-world",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
EOF

    # Create server.js
    cat > server.js << 'EOF'
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
    res.send(`
        <html>
        <head>
            <title>Server Setup Complete</title>
            <style>
                body {
                    font-family: -apple-system, sans-serif;
                    max-width: 600px;
                    margin: 50px auto;
                    padding: 20px;
                    background: #1a1a2e;
                    color: #eee;
                }
                h1 { color: #00d9ff; }
                .success { color: #00ff88; }
                code {
                    background: #16213e;
                    padding: 2px 8px;
                    border-radius: 4px;
                }
            </style>
        </head>
        <body>
            <h1>Server Setup Complete!</h1>
            <p class="success">Your VPS is ready for development.</p>
            <h3>Next Steps:</h3>
            <ul>
                <li>Deploy your projects to <code>/home/projects/</code></li>
                <li>Use <code>pm2</code> to manage processes</li>
                <li>Configure nginx for custom domains</li>
                <li>Run <code>certbot --nginx</code> for SSL</li>
            </ul>
            <p>Server time: ${new Date().toISOString()}</p>
        </body>
        </html>
    `);
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
EOF

    # Install dependencies and start with PM2
    npm install
    pm2 start server.js --name hello-world
    pm2 save

    log_success "Test app created and running on port 3000"
}

# Print summary
print_summary() {
    echo ""
    echo "=============================================="
    echo -e "${GREEN}VPS SETUP COMPLETE${NC}"
    echo "=============================================="
    echo ""
    echo "Installed Components:"
    echo "  - Node.js $(node --version)"
    echo "  - npm $(npm --version)"
    echo "  - Python $(python3 --version | cut -d' ' -f2)"
    echo "  - PM2 $(pm2 --version)"
    echo "  - Nginx $(nginx -v 2>&1 | cut -d'/' -f2)"
    echo "  - Docker $(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',' || echo 'Not installed')"
    echo "  - UFW Firewall (enabled)"
    echo "  - fail2ban (enabled)"
    echo "  - Certbot (ready)"
    echo ""
    echo "Open Ports:"
    echo "  - 22 (SSH)"
    echo "  - 80 (HTTP)"
    echo "  - 443 (HTTPS)"
    echo "  - 3000-3010 (Dev apps)"
    echo ""
    echo "Test App:"
    echo "  - http://$(curl -s ifconfig.me):3000"
    echo ""
    echo "Project Directory:"
    echo "  - /home/projects/"
    echo ""
    echo "Next Steps:"
    echo "  1. Point your domain to this server's IP"
    echo "  2. Run: certbot --nginx -d yourdomain.com"
    echo "  3. Deploy your projects!"
    echo ""
    echo "=============================================="
}

# Main installation flow
main() {
    echo ""
    echo "=============================================="
    echo "       VPS SETUP SCRIPT"
    echo "=============================================="
    echo ""

    check_root
    detect_os

    echo ""
    echo "This script will install:"
    echo "  - Node.js 20 LTS + npm"
    echo "  - PM2 process manager"
    echo "  - Python 3 + pip"
    echo "  - Nginx web server"
    echo "  - Docker (optional)"
    echo "  - UFW firewall"
    echo "  - fail2ban"
    echo "  - Certbot (Let's Encrypt)"
    echo ""

    read -p "Continue? (Y/n): " confirm
    if [[ "$confirm" == "n" || "$confirm" == "N" ]]; then
        log_info "Setup cancelled"
        exit 0
    fi

    echo ""
    read -p "Install Docker? (y/N): " install_docker_confirm

    update_system
    install_nodejs
    install_pm2
    install_python
    install_nginx

    if [[ "$install_docker_confirm" == "y" || "$install_docker_confirm" == "Y" ]]; then
        install_docker
    fi

    configure_firewall
    install_fail2ban
    install_certbot
    create_project_structure
    create_test_app

    print_summary
}

# Run main function
main "$@"
