#!/usr/bin/env bash
# Build images locally and save to a tarball for transfer to the server.
# Run from project root: ./scripts/deploy-build-and-save.sh

set -e

echo "Building images with docker compose..."
docker compose build

echo "Saving images to beatdrop-images.tar..."
docker save -o beatdrop-images.tar \
  beatdrop-web:latest \
  beatdrop-db:latest \
  beatdrop-test:latest \
  redis:7-alpine \
  node:20-alpine

echo "Done. beatdrop-images.tar is ready."
echo ""
echo "Next steps:"
echo "  1. Copy project and tarball to server:"
echo "     rsync -avz --exclude '.git' --exclude 'tmp' --exclude 'log' --exclude 'node_modules' . beatdrop:/opt/hitster-2.0/"
echo "     scp beatdrop-images.tar beatdrop:/opt/hitster-2.0/"
echo "  2. On the server:"
echo "     cd /opt/hitster-2.0"
echo "     docker load -i beatdrop-images.tar"
echo "     docker compose up -d --no-build"
