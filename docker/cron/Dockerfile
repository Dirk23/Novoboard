# docker/cron/Dockerfile
FROM php:8.3-cli-alpine

# Pakete für Cron + Mail + Build-Abhängigkeiten für PHP-Extensions
RUN apk add --no-cache \
      bash tzdata ca-certificates \
      cronie msmtp busybox-extras git \
      openldap-dev icu-dev libzip-dev oniguruma-dev \
    && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS

# PHP-Extensions (analog zu deinem FPM-Image; GD nicht nötig im Cron)
RUN docker-php-ext-install \
      pdo \
      pdo_mysql \
      ldap \
      intl \
      mbstring \
      zip

# Build-Deps wieder entsorgen
RUN apk del .build-deps

WORKDIR /var/www/html

# Crontab & Startscript ins Image
COPY crontab /etc/crontabs/root
COPY start-cron.sh /usr/local/bin/start-cron.sh
RUN sed -i 's/\r$//' /etc/crontabs/root /usr/local/bin/start-cron.sh \
 && chmod 600 /etc/crontabs/root \
 && chmod +x /usr/local/bin/start-cron.sh
