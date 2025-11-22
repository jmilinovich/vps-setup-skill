# VPS Setup Skill for Claude Code

A Claude Code skill that helps set up fresh Ubuntu VPS servers for web development. Includes automated scripts and step-by-step guides for installing Node.js, Python, Nginx, PM2, Docker, SSL certificates, and security tools.

## Installation

Clone this repository to your Claude Code skills directory:

```bash
git clone git@github.com:jmilinovich/vps-setup-skill.git ~/.claude/skills/vps-setup
```

Then restart Claude Code for the skill to take effect.

## What's Included

| File | Description |
|------|-------------|
| `SKILL.md` | Skill definition - tells Claude when/how to use this |
| `reference.md` | Complete manual setup guide |
| `scripts/setup.sh` | Automated installation script |
| `scripts/add-site.sh` | Helper to add nginx sites + SSL |
| `templates/nginx-site.conf` | Nginx configuration templates |
| `templates/CLAUDE.md.template` | AI assistant documentation template |

## Usage

Once installed, Claude Code will automatically use this skill when you ask questions like:

- "Help me set up a new VPS"
- "Configure nginx for my app"
- "Deploy my project to a server"
- "Set up SSL certificates"

## Automated Setup Script

On a fresh Ubuntu VPS, you can run the full setup with:

```bash
bash ~/.claude/skills/vps-setup/scripts/setup.sh
```

This installs:
- Node.js 20 LTS + npm
- PM2 process manager
- Python 3 + pip
- Nginx web server
- Docker (optional)
- UFW firewall
- fail2ban
- Certbot (Let's Encrypt)

## What Gets Configured

### Firewall Ports
| Port | Service |
|------|---------|
| 22 | SSH |
| 80 | HTTP |
| 443 | HTTPS |
| 3000-3010 | Development apps |

### Directory Structure
```
/home/projects/          # All projects go here
/etc/nginx/sites-available/  # Nginx configs
~/.pm2/logs/             # PM2 app logs
```

## Quick Reference

```bash
# PM2 Commands
pm2 list                 # View running apps
pm2 logs [app]          # View logs
pm2 restart [app]       # Restart app

# Nginx
nginx -t                # Test config
systemctl reload nginx  # Apply changes

# Firewall
ufw status              # View rules
ufw allow 3011/tcp      # Open port

# SSL
certbot --nginx -d domain.com  # Get certificate
```

## Adding a New Site

Use the helper script:

```bash
bash ~/.claude/skills/vps-setup/scripts/add-site.sh
```

This will prompt for domain and port, create nginx config, and optionally get an SSL certificate.

## Requirements

- Ubuntu 22.04 or 24.04
- Root or sudo access
- Claude Code installed

## License

MIT
