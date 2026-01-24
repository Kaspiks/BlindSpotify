#!/bin/bash
set -e

if [ -f /tmp/server.pid ]; then
  rm /tmp/server.pid
fi

if [ -f /app/tmp/pids/server.pid ]; then
  rm /app/tmp/pids/server.pid
fi

wait_for_db() {
  echo "Waiting for database..."
  while ! pg_isready -h "$DATABASE_HOST" -p "${DATABASE_PORT:-5432}" -U "$DATABASE_USERNAME" -q; do
    echo "Database is unavailable - sleeping"
    sleep 2
  done
  echo "Database is ready!"
}

case "$1" in
  rails|rake|bundle)
    if [ -n "$DATABASE_HOST" ]; then
      wait_for_db

      echo "Running db:prepare..."
      bundle exec rails db:prepare
    fi
    ;;
esac

exec "$@"
