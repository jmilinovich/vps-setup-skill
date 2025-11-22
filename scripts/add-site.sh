#!/bin/bash
#
# Add New Site Helper Script
# Creates nginx config and optionally gets SSL certificate
#
# Usage: ./add-site.sh
#

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Add New Site ===${NC}"
echo ""

# Get site details
read -p "Domain name (e.g., app.example.com): " DOMAIN
read -p "Local port (e.g., 3000): " PORT

# Validate inputs
if [[ -z "$DOMAIN" || -z "$PORT" ]]; then
    echo "Error: Domain and port are required"
    exit 1
fi

# Check if port is in use
if lsof -i :$PORT > /dev/null 2>&1; then
    echo -e "${GREEN}Port $PORT is already in use (good - your app is running)${NC}"
else
    echo "Warning: Nothing is running on port $PORT yet"
fi

# Create nginx config
CONFIG_FILE="/etc/nginx/sites-available/$DOMAIN"

cat > "$CONFIG_FILE" << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://localhost:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

echo -e "${GREEN}Created nginx config: $CONFIG_FILE${NC}"

# Enable the site
ln -sf "$CONFIG_FILE" /etc/nginx/sites-enabled/

# Test nginx config
nginx -t

# Reload nginx
systemctl reload nginx

echo -e "${GREEN}Site enabled and nginx reloaded${NC}"

# Ask about SSL
echo ""
read -p "Get SSL certificate for $DOMAIN? (y/N): " GET_SSL

if [[ "$GET_SSL" == "y" || "$GET_SSL" == "Y" ]]; then
    echo "Running certbot..."
    certbot --nginx -d "$DOMAIN"
fi

echo ""
echo -e "${GREEN}=== Done! ===${NC}"
echo "Your site should now be accessible at:"
echo "  http://$DOMAIN"
if [[ "$GET_SSL" == "y" || "$GET_SSL" == "Y" ]]; then
    echo "  https://$DOMAIN"
fi
