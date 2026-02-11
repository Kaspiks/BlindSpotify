# Production Dockerfile for Kamal deploy
FROM ruby:3.3.0-slim-bookworm AS base

ENV RAILS_ENV=production
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV APP_WORKDIR /app

RUN set -eux; \
  sed -i 's|http://deb.debian.org|https://deb.debian.org|g; s|http://security.debian.org|https://security.debian.org|g' /etc/apt/sources.list.d/debian.sources 2>/dev/null || true; \
  sed -i 's|http://deb.debian.org|https://deb.debian.org|g; s|http://security.debian.org|https://security.debian.org|g' /etc/apt/sources.list 2>/dev/null || true;

RUN set -eux; \
  apt-get update -qq; \
  apt-get install -y --no-install-recommends --fix-missing \
    ca-certificates \
    curl \
    gnupg2 \
    gcc \
    g++ \
    patch \
    make \
    git \
    libpq-dev \
    libpq5 \
    postgresql-client \
    imagemagick \
    libmagickwand-dev \
    python3 \
    python3-pip \
    python3-venv \
    libgl1 \
    libglib2.0-0 \
    nodejs \
    npm; \
  update-ca-certificates 2>/dev/null || true; \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR $APP_WORKDIR

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment true && \
    bundle config set --local without "development test" && \
    bundle install --jobs 4 --retry 5 && \
    rm -rf "$GEM_HOME/cache"

# Install app and Python deps (for aruco scripts if needed)
COPY . .
RUN pip3 install --no-cache-dir --break-system-packages -r scripts/aruco/requirements.txt 2>/dev/null || true

# Precompile assets
RUN SECRET_KEY_BASE=placeholder bundle exec rails assets:precompile && \
    bundle exec rails assets:clean

# Entrypoint: wait for DB and run migrations when running rails/rake
COPY docker/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 3000

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
