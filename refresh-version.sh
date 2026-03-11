#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${REPO_DIR:-$ROOT_DIR/projekt}"
OUT_FILE="${OUT_FILE:-$REPO_DIR/storage/version.txt}"

mkdir -p "$(dirname "$OUT_FILE")"

if ! command -v git >/dev/null 2>&1; then
  echo "git ist nicht installiert." >&2
  exit 1
fi

if [[ ! -d "$REPO_DIR/.git" ]]; then
  echo "Git-Repository nicht gefunden: $REPO_DIR" >&2
  exit 1
fi

DESC="$(git -C "$REPO_DIR" describe --tags --always 2>/dev/null || true)"
SHA="$(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || true)"
BRANCH="$(git -C "$REPO_DIR" branch --show-current 2>/dev/null || true)"

if [[ -z "$DESC" ]]; then
  DESC="${SHA:-dev}"
fi

{
  printf '%s\n' "$DESC"
  [[ -n "$SHA" ]] && printf 'Commit %s\n' "$SHA"
  [[ -n "$BRANCH" ]] && printf 'Branch %s\n' "$BRANCH"
} > "$OUT_FILE"

echo "[version] wrote $OUT_FILE"
cat "$OUT_FILE"
