#!/usr/bin/env bash
set -e

cd /var/www/html

APP_TZ="${TZ:-Europe/Berlin}"
echo "date.timezone=${APP_TZ}" > /usr/local/etc/php/conf.d/99-timezone.ini
export TZ="${APP_TZ}"

echo "== Git safe.directory setzen =="
git config --global --add safe.directory /var/www/html || true

if [ ! -f /var/www/html/vendor/autoload.php ]; then
    echo "== Composer bootstrap =="
    composer install --no-dev --prefer-dist --no-interaction || true
    composer dump-autoload -o --no-interaction || true
else
    echo "== Composer bootstrap uebersprungen (vendor vorhanden) =="
fi

echo "== Running DB migrations =="
php /var/www/html/bin/migrate.php || {
    echo "Migration failed!" >&2
    exit 1
}

echo "== Starting PHP-FPM =="
exec php-fpm
