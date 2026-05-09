#!/usr/bin/env bash
set -euo pipefail

if [[ "${YES:-0}" != "1" ]]; then
  echo "This removes NetSatBench lab containers, sat-vnet, and /config keys in Etcd."
  echo "Run with YES=1 to continue."
  exit 1
fi

ETCD_HOST="${ETCD_HOST:-127.0.0.1}"
ETCD_PORT="${ETCD_PORT:-2379}"

if [[ -f ./nsb.py ]]; then
  python3 ./nsb.py rm -t "${THREADS:-8}" || true
  python3 ./nsb.py system-clean-docker || true
fi

if command -v etcdctl >/dev/null 2>&1; then
  ETCDCTL_API=3 etcdctl --endpoints="http://${ETCD_HOST}:${ETCD_PORT}" del /config --prefix || true
fi

docker ps -a --format '{{.Names}}' | grep -E '^(sat|grd|usr)' | xargs -r docker rm -f
docker network rm sat-vnet 2>/dev/null || true

echo "Lab reset complete."

