#!/usr/bin/env bash
set -euo pipefail

ETCD_HOST="${ETCD_HOST:-${HOST_IP:-127.0.0.1}}"
ETCD_PORT="${ETCD_PORT:-2379}"
NODE="${NODE:-sat1}"

echo "== Etcd version =="
curl -sS --max-time 3 "http://${ETCD_HOST}:${ETCD_PORT}/version"
echo

if command -v etcdctl >/dev/null 2>&1; then
  echo "== Etcd health =="
  ETCDCTL_API=3 etcdctl --endpoints="http://${ETCD_HOST}:${ETCD_PORT}" endpoint health

  echo "== Workers =="
  ETCDCTL_API=3 etcdctl --endpoints="http://${ETCD_HOST}:${ETCD_PORT}" get /config/workers/ --prefix || true

  echo "== Node $NODE =="
  ETCDCTL_API=3 etcdctl --endpoints="http://${ETCD_HOST}:${ETCD_PORT}" \
    get "/config/nodes/${NODE}" --print-value-only | jq . || true
else
  echo "etcdctl not found; skipping etcdctl checks."
fi

if docker network inspect sat-vnet >/dev/null 2>&1; then
  echo "== sat-vnet =="
  docker network inspect sat-vnet | jq '.[0].IPAM.Config'
fi

if docker ps --format '{{.Names}}' | grep -qx "$NODE"; then
  echo "== Container $NODE =="
  docker exec "$NODE" ip -4 addr show eth0
  docker exec "$NODE" printenv | grep -E 'NODE_NAME|ETCD' || true
fi

