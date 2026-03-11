# docker/php/Dockerfile
FROM php:8.3-fpm

# System Packages
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    libldap2-dev \
    libonig-dev \
    libxml2-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    && rm -rf /var/lib/apt/lists/*

# PHP Extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
        zip \
        pdo \
        pdo_mysql \
        ldap \
        gd

# Arbeitsverzeichnis
WORKDIR /var/www/html

# mPDF + PDF-Assets: Verzeichnisse anlegen und Rechte setzen
RUN mkdir -p /var/www/html/storage/tmp/mpdf \
    /var/www/html/public/storage/tenant_assets \
    && chown -R www-data:www-data /var/www/html/storage /var/www/html/public/storage \
    && chmod -R 775 /var/www/html/storage /var/www/html/public/storage

# Composer installieren (global)
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
 && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
 && rm composer-setup.php

# Hinweis:
# Der eigentliche Projekt-Code wird als Volume gemountet (siehe docker-compose.yml),
# damit du live entwickeln kannst. Hier drin kein COPY.

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]
CMD ["php-fpm"]
