#!/usr/bin/env bash
set -euo pipefail

HOST_IP="${HOST_IP:-$(ip -4 route get 1.1.1.1 | awk '{print $7; exit}')}"
ETCD_IMAGE="${ETCD_IMAGE:-quay.io/coreos/etcd:v3.5.17}"
ETCD_NAME="${ETCD_NAME:-etcd}"
ETCD_VOLUME="${ETCD_VOLUME:-etcd-data}"

if docker ps --format '{{.Names}}' | grep -qx "$ETCD_NAME"; then
  echo "$ETCD_NAME is already running."
  curl -sS "http://127.0.0.1:2379/version" || true
  exit 0
fi

if docker ps -a --format '{{.Names}}' | grep -qx "$ETCD_NAME"; then
  if [[ "${RECREATE_ETCD:-0}" != "1" ]]; then
    echo "$ETCD_NAME container exists but is not running."
    echo "Set RECREATE_ETCD=1 to remove and recreate it."
    exit 1
  fi
  docker rm -f "$ETCD_NAME"
fi

docker volume create "$ETCD_VOLUME" >/dev/null

docker run -d \
  --name "$ETCD_NAME" \
  --restart unless-stopped \
  --network host \
  -v "$ETCD_VOLUME:/etcd-data" \
  "$ETCD_IMAGE" \
  /usr/local/bin/etcd \
  --name netsat-etcd \
  --data-dir /etcd-data \
  --listen-client-urls "http://0.0.0.0:2379" \
  --advertise-client-urls "http://${HOST_IP}:2379" \
  --listen-peer-urls "http://0.0.0.0:2380" \
  --initial-advertise-peer-urls "http://${HOST_IP}:2380" \
  --initial-cluster "netsat-etcd=http://${HOST_IP}:2380" \
  --initial-cluster-state new

sleep 2
curl -sS "http://127.0.0.1:2379/version"
echo
echo "Etcd endpoint: http://${HOST_IP}:2379"

