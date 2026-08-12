#!/bin/sh
set -eu

log() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }

APP_TZ="${TZ:-Europe/Berlin}"
echo "date.timezone=${APP_TZ}" > /usr/local/etc/php/conf.d/99-timezone.ini
export TZ="${APP_TZ}"

# --------------------------------------------------------
#  .env ins Environment exportieren
# --------------------------------------------------------
if [ -f /var/www/html/.env ]; then
  set -a
  . /var/www/html/.env
  set +a
fi

# --------------------------------------------------------
#  Mail: nur einrichten, wenn SMTP_HOST gesetzt ist
# --------------------------------------------------------
SMTP_HOST="${SMTP_HOST:-}"
SMTP_PORT="${SMTP_PORT:-587}"
SMTP_USER="${SMTP_USER:-}"
SMTP_PASS="${SMTP_PASS:-}"
SMTP_FROM="${SMTP_FROM:-noreply@example.com}"

if [ -n "${SMTP_HOST}" ]; then
  cat > /etc/msmtprc <<EOF
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        /proc/1/fd/1

account        default
host           ${SMTP_HOST}
port           ${SMTP_PORT}
user           ${SMTP_USER}
password       ${SMTP_PASS}
from           ${SMTP_FROM}
EOF
  chmod 600 /etc/msmtprc
  echo 'sendmail_path = "/usr/bin/msmtp -t"' > /usr/local/etc/php/conf.d/sendmail.ini
  mkdir -p /usr/sbin && ln -sf /usr/bin/msmtp /usr/sbin/sendmail
  log "[cron] msmtp configured for host ${SMTP_HOST}:${SMTP_PORT}"
else
  echo 'sendmail_path = "/bin/true"' > /usr/local/etc/php/conf.d/sendmail.ini
  rm -f /usr/sbin/sendmail >/dev/null 2>&1 || true
  log "[cron] no SMTP_HOST set – mailing disabled"
fi

# --------------------------------------------------------
#  Zeitzone (optional)
# --------------------------------------------------------
if [ -n "${TZ:-}" ]; then
  echo "${TZ}" > /etc/timezone || true
fi

# --------------------------------------------------------
#  Auf Datenbank warten
# --------------------------------------------------------
DB_HOST="${DB_HOST:-db}"
DB_PORT="${DB_PORT:-3306}"
log "[cron] waiting for database ${DB_HOST}:${DB_PORT} ..."
i=0
while ! nc -z "${DB_HOST}" "${DB_PORT}"; do
  i=$((i+1))
  if [ $i -gt 120 ]; then
    log "[cron] DB not reachable after 120s – giving up."
    exit 1
  fi
  sleep 1
done
log "[cron] DB reachable."

# --------------------------------------------------------
#  Crontab installieren (MAILTO unterdrücken)
# --------------------------------------------------------
SRC="/etc/crontabs/root"
if [ -f "$SRC" ]; then
  if ! grep -q '^MAILTO=""' "$SRC"; then
    sed -i '1i MAILTO=""' "$SRC"
  fi
  chmod 600 "$SRC" || true
  crontab "$SRC"
  log "[cron] crontab installed for root"
else
  log "[cron] WARN: $SRC not found, no jobs will run."
fi

# --------------------------------------------------------
#  Environment für Cronjobs exportieren (nur sichere Keys)
#    -> verhindert Fehler wie "export: -pie: bad variable name"
# --------------------------------------------------------
{
  echo '#!/bin/sh'
  # Nur diese Präfixe/Keys erlauben:
  env | while IFS='=' read -r k v; do
    case "$k" in
      DB_*|SMTP_*|APP_*|PW_*|SESSION_*|AUTH_*|TZ|PATH)
        # Key ist gültiger Shell-Bezeichner?
        if echo "$k" | grep -Eq '^[A-Za-z_][A-Za-z0-9_]*$'; then
          # Singlequotes im Wert escapen
          esc=$(printf "%s" "$v" | sed "s/'/'\"'\"'/g")
          printf "export %s='%s'\n" "$k" "$esc"
        fi
      ;;
    esac
  done
} > /etc/profile.d/00-env.sh
chmod 644 /etc/profile.d/00-env.sh

# --------------------------------------------------------
#  Diagnose: aktive Crontab einmal ins Log
# --------------------------------------------------------
log "[cron] current crontab:"
crontab -l || log "[cron] no crontab"

# --------------------------------------------------------
#  Cron starten (Foreground, Logs -> stdout)
# --------------------------------------------------------
log "[cron] starting crond"
exec crond -f
