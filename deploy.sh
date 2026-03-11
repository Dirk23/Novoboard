#!/bin/bash
set -e

# Usage: ./deploy.sh <version>
# Example: ./deploy.sh beta1
#          ./deploy.sh v1.0.0
#          ./deploy.sh v0.9.0-rc.1

if [ -z "$1" ]; then
    echo "ERROR: Version missing!"
    echo "Usage: ./deploy.sh <version>"
    exit 1
fi

VERSION="$1"
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="${REPO_DIR:-$ROOT_DIR/projekt}"
VERSION_FILE="${VERSION_FILE:-$REPO_DIR/storage/version.txt}"

# ---------------------------------------------------------------------------
# UI-Version automatisch erzeugen (ohne .env)
# Die UI liest /storage/version.txt
# ---------------------------------------------------------------------------
mkdir -p "$(dirname "$VERSION_FILE")"

if command -v git >/dev/null 2>&1 && [ -d "$REPO_DIR/.git" ]; then
    DESC=$(git -C "$REPO_DIR" describe --tags --always 2>/dev/null || true)
    SHA=$(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || true)
    BRANCH=$(git -C "$REPO_DIR" branch --show-current 2>/dev/null || true)

    if [ -n "$DESC" ]; then
        echo "$DESC" > "$VERSION_FILE"
    else
        echo "$VERSION" > "$VERSION_FILE"
    fi

    if [ -n "$SHA" ]; then
        echo "Commit $SHA" >> "$VERSION_FILE"
    fi

    if [ -n "$BRANCH" ]; then
        echo "Branch $BRANCH" >> "$VERSION_FILE"
    fi
else
    echo "$VERSION" > "$VERSION_FILE"
fi

echo "[deploy] UI version set to:"
cat "$VERSION_FILE"
echo "----------------------------------------"

# ---------------------------------------------------------------------------
# Image-Namen auf Docker Hub
# ---------------------------------------------------------------------------
IMAGE_DB="hildebrandit/novoboard-db"
IMAGE_APP="hildebrandit/novoboard"
IMAGE_NGINX="hildebrandit/novoboard-nginx"
IMAGE_CRON="hildebrandit/novoboard-cron"

# ---------------------------------------------------------------------------
# Dockerfiles
# ---------------------------------------------------------------------------
DB_DOCKERFILE="docker/db/Dockerfile.prod"
PHP_DOCKERFILE="docker/php/Dockerfile.prod"
NGINX_DOCKERFILE="docker/nginx/Dockerfile.prod"
CRON_DOCKERFILE="docker/cron/Dockerfile.prod"

# Build-Kontext
CONTEXT_DIR="."

# ---------------------------------------------------------------------------
# BUILD
# ---------------------------------------------------------------------------
echo "----------------------------------------"
echo "Building Novoboard DB image"
echo "  Image:   $IMAGE_DB"
echo "  Version: $VERSION"
echo "----------------------------------------"

docker build \
  -f "$DB_DOCKERFILE" \
  -t "$IMAGE_DB:$VERSION" \
  -t "$IMAGE_DB:latest" \
  "$CONTEXT_DIR"

echo "----------------------------------------"
echo "Building Novoboard APP (PHP) image"
echo "  Image:   $IMAGE_APP"
echo "  Version: $VERSION"
echo "----------------------------------------"

docker build \
  -f "$PHP_DOCKERFILE" \
  -t "$IMAGE_APP:$VERSION" \
  -t "$IMAGE_APP:latest" \
  "$CONTEXT_DIR"

echo "----------------------------------------"
echo "Building Novoboard NGINX image"
echo "  Image:   $IMAGE_NGINX"
echo "  Version: $VERSION"
echo "----------------------------------------"

docker build \
  -f "$NGINX_DOCKERFILE" \
  -t "$IMAGE_NGINX:$VERSION" \
  -t "$IMAGE_NGINX:latest" \
  "$CONTEXT_DIR"

echo "----------------------------------------"
echo "Building Novoboard CRON image"
echo "  Image:   $IMAGE_CRON"
echo "  Version: $VERSION"
echo "----------------------------------------"

docker build \
  -f "$CRON_DOCKERFILE" \
  -t "$IMAGE_CRON:$VERSION" \
  -t "$IMAGE_CRON:latest" \
  "$CONTEXT_DIR"

# ---------------------------------------------------------------------------
# PUSH
# ---------------------------------------------------------------------------
echo "----------------------------------------"
echo "Login to Docker Hub"
echo "----------------------------------------"
if [ -n "${DOCKERHUB_USERNAME:-}" ] && [ -n "${DOCKERHUB_TOKEN:-}" ]; then
  printf '%s\n' "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin
elif [ -f "${HOME}/.docker/config.json" ] && grep -q '"https://index.docker.io/v1/"' "${HOME}/.docker/config.json"; then
  echo "Docker Hub credentials found in ${HOME}/.docker/config.json, skipping interactive login."
else
  docker login
fi

echo "----------------------------------------"
echo "Pushing DB image"
echo "----------------------------------------"
docker push "$IMAGE_DB:$VERSION"
docker push "$IMAGE_DB:latest"

echo "----------------------------------------"
echo "Pushing APP (PHP) image"
echo "----------------------------------------"
docker push "$IMAGE_APP:$VERSION"
docker push "$IMAGE_APP:latest"

echo "----------------------------------------"
echo "Pushing NGINX image"
echo "----------------------------------------"
docker push "$IMAGE_NGINX:$VERSION"
docker push "$IMAGE_NGINX:latest"

echo "----------------------------------------"
echo "Pushing CRON image"
echo "----------------------------------------"
docker push "$IMAGE_CRON:$VERSION"
docker push "$IMAGE_CRON:latest"

# ---------------------------------------------------------------------------
# DONE
# ---------------------------------------------------------------------------
echo "----------------------------------------"
echo "DONE. Images pushed as:"
echo "  $IMAGE_DB:$VERSION"
echo "  $IMAGE_DB:latest"
echo "  $IMAGE_APP:$VERSION"
echo "  $IMAGE_APP:latest"
echo "  $IMAGE_NGINX:$VERSION"
echo "  $IMAGE_NGINX:latest"
echo "  $IMAGE_CRON:$VERSION"
echo "  $IMAGE_CRON:latest"
echo "----------------------------------------"
