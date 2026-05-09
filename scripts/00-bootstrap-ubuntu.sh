#!/usr/bin/env bash
set -euo pipefail

sudo apt update
sudo apt install -y \
  git curl jq ca-certificates gnupg lsb-release \
  openssh-server python3 python3-venv python3-pip \
  build-essential iproute2 net-tools
sudo systemctl enable --now ssh

sudo install -m 0755 -d /etc/apt/keyrings
if [[ ! -s /etc/apt/keyrings/docker.asc ]]; then
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
fi

if [[ ! -s /etc/apt/sources.list.d/docker.list ]]; then
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
fi

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker "$USER"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
if [[ ! -f "$HOME/.ssh/id_rsa" ]]; then
  ssh-keygen -t rsa -b 4096 -N "" -f "$HOME/.ssh/id_rsa"
fi
grep -qxF "$(cat "$HOME/.ssh/id_rsa.pub")" "$HOME/.ssh/authorized_keys" 2>/dev/null || \
  cat "$HOME/.ssh/id_rsa.pub" >> "$HOME/.ssh/authorized_keys"
chmod 600 "$HOME/.ssh/authorized_keys"

if [[ "${NSB_ENABLE_PASSWORDLESS_SUDO:-0}" == "1" ]]; then
  echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/90-netsatbench > /dev/null
  sudo chmod 440 /etc/sudoers.d/90-netsatbench
  echo "Passwordless sudo enabled for $USER."
else
  echo "Passwordless sudo was not changed."
  echo "For NetSatBench worker setup, run again with NSB_ENABLE_PASSWORDLESS_SUDO=1 or configure sudo manually."
fi

echo "Docker installed. Re-login or run: newgrp docker"

