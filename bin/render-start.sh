#!/usr/bin/env bash
set -euo pipefail

bundle exec rails db:migrate
bundle exec rails db:seed

exec bundle exec puma -C config/puma.rb
