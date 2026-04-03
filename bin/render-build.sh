set -euo pipefail

bundle install
npm ci
npm run build:prod
bundle exec rails assets:precompile
bundle exec rails assets:clean
