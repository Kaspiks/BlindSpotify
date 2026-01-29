FROM ruby:3.3.0-slim-bookworm

ARG UID=1000
ARG GID=1000

ENV LANG='C.UTF-8' LC_ALL='C.UTF-8'

ENV APP_WORKDIR /app
ENV APP_USER_HOME /home/rails


RUN set -eux; \
  sed -i 's|http://deb.debian.org|https://deb.debian.org|g; s|http://security.debian.org|https://security.debian.org|g' /etc/apt/sources.list.d/debian.sources 2>/dev/null || true; \
  sed -i 's|http://deb.debian.org|https://deb.debian.org|g; s|http://security.debian.org|https://security.debian.org|g' /etc/apt/sources.list 2>/dev/null || true; \
  printf 'Acquire::Retries "5";\nAcquire::https::Timeout "30";\nAcquire::http::Timeout "30";\n' > /etc/apt/apt.conf.d/80-retries

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
    libmagickwand-dev; \
  update-ca-certificates 2>/dev/null || true; \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN set -eux; \
  groupadd --gid "$GID" --system rails; \
  useradd --gid rails --uid "$UID" --home "$APP_USER_HOME" --no-log-init --system rails

RUN set -eux; \
  mkdir -p "$APP_USER_HOME" "$APP_WORKDIR"; \
  chown -R rails:rails "$APP_USER_HOME" "$APP_WORKDIR"

WORKDIR $APP_WORKDIR

COPY --chown=rails:rails Gemfile Gemfile.lock $APP_WORKDIR/

RUN set -eux; \
  bundle install --jobs 4 --retry 5; \
  rm -rf "$GEM_HOME/cache"; \
  chown -R rails:rails "$GEM_HOME"

COPY --chown=rails:rails . $APP_WORKDIR

COPY docker/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]

USER rails

EXPOSE 3024

CMD ["rails", "server", "-b", "0.0.0.0", "-p", "3024", "-P", "/tmp/server.pid"]