# Novoboard Infrastructure

Dieses Repository versioniert nur die Host-/Deploy-Infrastruktur fuer Novoboard.

Enthalten:
- `docker-compose.yml`
- `.dockerignore`
- `docker/`
- `deploy.sh`
- `refresh-version.sh`
- `sync-prod-db.sh`

Nicht enthalten:
- `projekt/` (eigenes Anwendungs-Repository)
- `.env` (enthaelt Secrets)
- `storage/` (Laufzeitdaten, Dumps, temporaere Dateien)
