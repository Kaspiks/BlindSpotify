#!/usr/bin/env bash
#
# Builds a Docker image, tags it with a version number consisting of the
# current date and pushes it to the specified registry.
#
# Be sure to log in the Docker Registry first.
#
# Usage:
#
#   $ ./release.sh <registry url>
#
# Examples:
#
#   $ ./release.sh "registry.mysite.com:5443"
#
set -euo pipefail

main () {
  local registry_url="${1:?Usage: ./release.sh <registry url>}"
  local tag="$(date +v%Y%m%d%H%M%S)"

  echo "[RELEASE] Starting release..."

  echo "[RELEASE] Building image 'ipvd/app:$tag'..."
  docker build --target app --tag "ipvd/app:$tag" --file docker/production.Dockerfile .

  echo "[RELEASE] Building image 'ipvd/web:$tag'..."
  docker build --target web --tag "ipvd/web:$tag" --file docker/production.Dockerfile .

  echo "[RELEASE] Tagging and pushing 'ipvd/app:$tag' image to registry '$registry_url'..."
  docker tag "ipvd/app:$tag" "$registry_url/ipvd/app:$tag"
  docker push "$registry_url/ipvd/app:$tag"

  echo "[RELEASE] Tagging and pushing 'ipvd/web:$tag' image to registry '$registry_url'..."
  docker tag "ipvd/web:$tag" "$registry_url/ipvd/web:$tag"
  docker push "$registry_url/ipvd/web:$tag"

  echo "[RELEASE] Done!"
}

main "$@"
