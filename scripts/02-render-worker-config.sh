#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f ./nsb.py || ! -d ./examples/10nodes ]]; then
  echo "Run this script from the NetSatBench source repo root." >&2
  exit 1
fi

HOST_IP="${HOST_IP:-$(ip -4 route get 1.1.1.1 | awk '{print $7; exit}')}"
SSH_USER="${SSH_USER:-$USER}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_rsa}"
CPU="${CPU:-4}"
MEM="${MEM:-8GiB}"
SAT_VNET_SUPER_CIDR="${SAT_VNET_SUPER_CIDR:-172.20.0.0/16}"
SAT_VNET_CIDR="${SAT_VNET_CIDR:-172.20.0.0/24}"
OUT="${OUT:-./examples/10nodes/worker-config.json}"

cat > "$OUT" <<JSON
{
  "workers-common": {
    "ssh-user": "$SSH_USER",
    "ssh-key": "$SSH_KEY",
    "sat-vnet": "sat-vnet",
    "sat-vnet-super-cidr": "$SAT_VNET_SUPER_CIDR"
  },
  "workers": {
    "host-1": {
      "ip": "$HOST_IP",
      "sat-vnet-cidr": "$SAT_VNET_CIDR",
      "cpu": "$CPU",
      "mem": "$MEM"
    }
  }
}
JSON

jq . "$OUT" >/dev/null
echo "Wrote $OUT"
jq . "$OUT"

