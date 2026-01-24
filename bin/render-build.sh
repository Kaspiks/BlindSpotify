#!/usr/bin/env bash
# exit on error
set -o errexit

echo "Installing dependencies..."
bundle install

echo "Building assets..."
bundle exec rails assets:precompile

echo "Running database migrations..."
bundle exec rails db:migrate

echo "Build complete!"
