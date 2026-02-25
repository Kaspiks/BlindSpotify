#!/usr/bin/env bash
# Set up SSL certificates for blindjam.com on the production server.
# Caddy will automatically obtain Let's Encrypt certificates.
#
# Prerequisites:
#   1. DNS: blindjam.com and www.blindjam.com must point to your server IP (89.167.37.194)
#   2. Ports 80 and 443 must be open on the server
#
# On the server, ensure deploy/.env.production has:
#   APP_HOST=blindjam.com
#   FORCE_SSL=true
#
set -euo pipefail

APP_DIR="/opt/beatdrop"
SSH_HOST="beatdrop"

echo "==> Syncing updated Caddyfile to ${SSH_HOST}..."
rsync -avz deploy/Caddyfile "${SSH_HOST}:${APP_DIR}/deploy/"

echo "==> Restarting Caddy to apply new config and obtain certificates..."
ssh "${SSH_HOST}" "cd ${APP_DIR} && docker compose -f docker-compose.prod.yml restart caddy"

echo ""
echo "==> SSL setup initiated! Caddy will obtain Let's Encrypt certificates."
echo "    Check Caddy logs: ssh ${SSH_HOST} 'cd ${APP_DIR} && docker compose -f docker-compose.prod.yml logs -f caddy'"
echo ""
echo "    Your site should be live at: https://blindjam.com"
echo "    (First request may take 10–30 seconds while Caddy obtains the certificate)"
