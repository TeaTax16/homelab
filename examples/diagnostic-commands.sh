#!/usr/bin/env bash
set -euo pipefail

echo '== Running containers =='
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'

echo
echo '== Storage usage =='
du -sh /srv/appdata /srv/data /srv/backups /srv/system 2>/dev/null || true

echo
echo '== Mount mappings =='
for c in $(docker ps --format '{{.Names}}'); do
  echo "===== $c ====="
  docker inspect --format '{{range .Mounts}}{{println .Source " -> " .Destination}}{{end}}' "$c"
done
