#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROD_DIR="${PROD_DIR:-/opt/containers/novoboard-github}"
PROD_ENV_FILE="${PROD_ENV_FILE:-$PROD_DIR/.env}"
DEV_ENV_FILE="${DEV_ENV_FILE:-$ROOT_DIR/.env}"
DUMP_DIR="${DUMP_DIR:-$ROOT_DIR/storage/db-sync}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
DUMP_FILE="$DUMP_DIR/prod-to-dev-$TIMESTAMP.sql"

read_env_var() {
  local env_file="$1"
  local key="$2"

  bash -lc "set -a; source \"$env_file\" >/dev/null 2>&1; printf '%s' \"\${$key}\""
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Fehlendes Kommando: $cmd" >&2
    exit 1
  fi
}

require_cmd docker
require_cmd mysqldump
require_cmd mysql

if [[ ! -f "$PROD_ENV_FILE" ]]; then
  echo "PROD .env nicht gefunden: $PROD_ENV_FILE" >&2
  exit 1
fi

if [[ ! -f "$DEV_ENV_FILE" ]]; then
  echo "DEV .env nicht gefunden: $DEV_ENV_FILE" >&2
  exit 1
fi

mkdir -p "$DUMP_DIR"

PROD_DB_NAME="$(read_env_var "$PROD_ENV_FILE" DB_NAME)"
PROD_DB_ROOT_PASS="$(read_env_var "$PROD_ENV_FILE" DB_ROOT_PASS)"
PROD_DB_PORT="${PROD_DB_PORT:-63307}"

DEV_DB_NAME="$(read_env_var "$DEV_ENV_FILE" DB_NAME)"
DEV_DB_ROOT_PASS="$(read_env_var "$DEV_ENV_FILE" DB_ROOT_PASS)"
DEV_DB_PORT="$(read_env_var "$DEV_ENV_FILE" DB_PUBLISHED_PORT)"
DEV_PROJECT_NAME="$(read_env_var "$DEV_ENV_FILE" COMPOSE_PROJECT_NAME)"

echo "Starte/aktualisiere DEV-Datenbankcontainer ..."
docker compose up -d db >/dev/null

echo "Warte auf DEV-Datenbank auf Port $DEV_DB_PORT ..."
until mysql -h 127.0.0.1 -P "$DEV_DB_PORT" -u root "-p$DEV_DB_ROOT_PASS" -e "SELECT 1" >/dev/null 2>&1; do
  sleep 2
done

echo "Erzeuge Dump aus PROD-Datenbank '$PROD_DB_NAME' ..."
mysqldump \
  -h 127.0.0.1 \
  -P "$PROD_DB_PORT" \
  -u root \
  "-p$PROD_DB_ROOT_PASS" \
  --column-statistics=0 \
  --single-transaction \
  --routines \
  --triggers \
  "$PROD_DB_NAME" > "$DUMP_FILE"

echo "Setze DEV-Datenbank '$DEV_DB_NAME' zurück ..."
mysql \
  -h 127.0.0.1 \
  -P "$DEV_DB_PORT" \
  -u root \
  "-p$DEV_DB_ROOT_PASS" \
  -e "DROP DATABASE IF EXISTS \`$DEV_DB_NAME\`; CREATE DATABASE \`$DEV_DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

echo "Importiere Dump nach DEV ..."
mysql \
  -h 127.0.0.1 \
  -P "$DEV_DB_PORT" \
  -u root \
  "-p$DEV_DB_ROOT_PASS" \
  "$DEV_DB_NAME" < "$DUMP_FILE"

echo "Fertig."
echo "Compose-Projekt: $DEV_PROJECT_NAME"
echo "Dump-Datei: $DUMP_FILE"
