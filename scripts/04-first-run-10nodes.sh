#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f ./nsb.py || ! -d ./examples/10nodes ]]; then
  echo "Run this script from the NetSatBench source repo root." >&2
  exit 1
fi

export HOST_IP="${HOST_IP:-$(ip -4 route get 1.1.1.1 | awk '{print $7; exit}')}"
export ETCD_HOST="${ETCD_HOST:-$HOST_IP}"
export ETCD_PORT="${ETCD_PORT:-2379}"
export NODE_ETCD_HOST="${NODE_ETCD_HOST:-$HOST_IP}"
export NODE_ETCD_PORT="${NODE_ETCD_PORT:-2379}"

python3 ./nsb.py system-init-docker --config ./examples/10nodes/worker-config.json
python3 ./nsb.py init --config ./examples/10nodes/sat-config.json --write-full-config
python3 ./nsb.py deploy -t "${THREADS:-8}"

echo "Deploy finished. Start epochs with:"
echo "  python3 ./nsb.py run"

