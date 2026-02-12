#!/usr/bin/env bash
# Deploy BeatDrop to the Hetzner server (beatdrop).
#
# Usage:
#   ./scripts/deploy.sh          # Full deploy (sync + build + restart)
#   ./scripts/deploy.sh quick     # Quick deploy (sync + restart, skip rebuild)
#
set -euo pipefail

APP_DIR="/opt/beatdrop"
SSH_HOST="beatdrop"

echo "==> Syncing project to ${SSH_HOST}:${APP_DIR}..."
rsync -avz --delete \
  --exclude '.git' \
  --exclude 'tmp' \
  --exclude 'log' \
  --exclude 'node_modules' \
  --exclude 'storage' \
  --exclude '.DS_Store' \
  --exclude 'beatdrop-images.tar' \
  --exclude '.env' \
  . "${SSH_HOST}:${APP_DIR}/"

# Copy .env if it doesn't exist on the server yet
ssh "${SSH_HOST}" "test -f ${APP_DIR}/.env || cp ${APP_DIR}/deploy/.env.production ${APP_DIR}/.env"

if [ "${1:-}" = "quick" ]; then
  echo "==> Quick deploy: restarting web service..."
  ssh "${SSH_HOST}" "cd ${APP_DIR} && docker compose -f docker-compose.prod.yml up -d --no-build web"
else
  echo "==> Building and starting services on server..."
  ssh "${SSH_HOST}" "cd ${APP_DIR} && docker compose -f docker-compose.prod.yml build --no-cache web && docker compose -f docker-compose.prod.yml up -d"
fi

echo "==> Running database migrations..."
ssh "${SSH_HOST}" "cd ${APP_DIR} && docker compose -f docker-compose.prod.yml exec -T web bundle exec rails db:prepare"

echo ""
echo "==> Deploy complete! App should be running at http://89.167.37.194"
echo "    Check logs: ssh ${SSH_HOST} 'cd ${APP_DIR} && docker compose -f docker-compose.prod.yml logs -f web'"
