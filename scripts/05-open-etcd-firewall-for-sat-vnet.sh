#!/usr/bin/env bash
set -euo pipefail

SAT_VNET_CIDR="${SAT_VNET_CIDR:-172.20.0.0/24}"
SAT_VNET_NAME="${SAT_VNET_NAME:-sat-vnet}"
SAT_VNET_GATEWAY="${SAT_VNET_GATEWAY:-}"

for port in 2379 2380; do
  if sudo iptables -C INPUT -p tcp -s "$SAT_VNET_CIDR" --dport "$port" -j ACCEPT 2>/dev/null; then
    echo "INPUT rule already exists for $SAT_VNET_CIDR -> tcp/$port"
  else
    sudo iptables -I INPUT 1 -p tcp -s "$SAT_VNET_CIDR" --dport "$port" -j ACCEPT
    echo "Added INPUT rule for $SAT_VNET_CIDR -> tcp/$port"
  fi
done

if [[ -z "$SAT_VNET_GATEWAY" ]] && command -v docker >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  SAT_VNET_GATEWAY="$(docker network inspect "$SAT_VNET_NAME" 2>/dev/null | jq -r '.[0].IPAM.Config[0].Gateway // empty')"
fi

SAT_VNET_GATEWAY="${SAT_VNET_GATEWAY:-172.20.0.1}"

echo "Test from a running node with:"
echo "  docker exec sat1 sh -lc 'curl -v --max-time 3 http://${SAT_VNET_GATEWAY}:2379/version'"
