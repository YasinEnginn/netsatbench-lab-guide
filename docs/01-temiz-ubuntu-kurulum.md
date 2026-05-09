# Temiz Ubuntu Kurulum Akışı

Bu akış tek VM lab içindir. Control host, worker ve Etcd aynı VM üzerindedir. Çok-worker ortamında worker hazırlığı her host için tekrarlanır.

## 1. Sistem Paketleri

```bash
sudo apt update
sudo apt install -y \
  git curl jq ca-certificates gnupg lsb-release \
  openssh-server python3 python3-venv python3-pip \
  build-essential iproute2 net-tools
sudo systemctl enable --now ssh
```

## 2. Docker Engine

Docker için Ubuntu'nun rastgele `docker.io` paketine değil, Docker'ın resmi apt deposuna yaslanmak daha temizdir.

```bash
sudo apt update
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker "$USER"
newgrp docker
docker version
```

## 3. SSH ve Sudo

NetSatBench worker hostlara SSH ile bağlanır ve Docker/network işlemleri için passwordless `sudo` bekler.

```bash
ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/90-netsatbench
sudo chmod 440 /etc/sudoers.d/90-netsatbench
```

Self-SSH testi:

```bash
export HOST_IP=$(ip -4 route get 1.1.1.1 | awk '{print $7; exit}')
ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa "$USER@$HOST_IP" 'hostname && docker ps >/dev/null'
```

## 4. NetSatBench Kaynak Kodu

```bash
git clone https://github.com/mSvcBench/NetSatBench.git
cd NetSatBench
git submodule update --init --recursive

python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -U pip setuptools wheel
pip install -r requirements.txt
```

## 5. Etcd

Tek VM lab için host network ile çalışan tek düğüm Etcd pratik ve nettir.

```bash
export HOST_IP=$(ip -4 route get 1.1.1.1 | awk '{print $7; exit}')
docker volume create etcd-data

docker run -d \
  --name etcd \
  --restart unless-stopped \
  --network host \
  -v etcd-data:/etcd-data \
  quay.io/coreos/etcd:v3.5.17 \
  /usr/local/bin/etcd \
  --name netsat-etcd \
  --data-dir /etcd-data \
  --listen-client-urls "http://0.0.0.0:2379" \
  --advertise-client-urls "http://${HOST_IP}:2379" \
  --listen-peer-urls "http://0.0.0.0:2380" \
  --initial-advertise-peer-urls "http://${HOST_IP}:2380" \
  --initial-cluster "netsat-etcd=http://${HOST_IP}:2380" \
  --initial-cluster-state new
```

Doğrulama:

```bash
curl -s "http://127.0.0.1:2379/version"
ETCDCTL_API=3 etcdctl --endpoints="http://127.0.0.1:2379" endpoint health
```

`etcdctl` yoksa:

```bash
sudo apt install -y etcd-client || true
```

## 6. Environment

```bash
export ETCD_HOST="$HOST_IP"
export ETCD_PORT=2379
export NODE_ETCD_HOST="$HOST_IP"
export NODE_ETCD_PORT=2379
```

Bu dört değişkeni shell profilinize yazmadan önce lab'ın çalıştığını doğrulamak daha sağlıklıdır.

## 7. Worker Config

Resmi örnek dosya adı:

```text
examples/10nodes/worker-config.json
```

Tek VM için şu değerlerle başlayın:

```json
{
  "workers-common": {
    "ssh-user": "ubuntu",
    "ssh-key": "/home/ubuntu/.ssh/id_rsa",
    "sat-vnet": "sat-vnet",
    "sat-vnet-super-cidr": "172.20.0.0/16"
  },
  "workers": {
    "host-1": {
      "ip": "10.0.1.215",
      "sat-vnet-cidr": "172.20.0.0/24",
      "cpu": "4",
      "mem": "8GiB"
    }
  }
}
```

Bu dokümantasyon reposundaki script ile de üretebilirsiniz:

```bash
SSH_USER="$USER" SSH_KEY="$HOME/.ssh/id_rsa" CPU=4 MEM=8GiB \
  /path/to/NetSatBench-Lab-Guide/scripts/02-render-worker-config.sh
```

## 8. Worker Init

```bash
python3 ./nsb.py system-init-docker --config ./examples/10nodes/worker-config.json
```

Beklenen etkiler:

- `/config/workers/host-1` Etcd'ye yazılır.
- `sat-vnet` Docker bridge network oluşur.
- `DOCKER-USER` zincirinde supernet forward kuralı hazırlanır.
- Containerların dışarı çıkışı için NAT kuralı eklenir.

Doğrulama:

```bash
docker network inspect sat-vnet | jq '.[0].IPAM.Config'
ETCDCTL_API=3 etcdctl --endpoints="http://$ETCD_HOST:$ETCD_PORT" \
  get /config/workers/ --prefix
```

## 9. Scenario Init

```bash
python3 ./nsb.py init \
  --config ./examples/10nodes/sat-config.json \
  --write-full-config
```

Doğrulama:

```bash
ETCDCTL_API=3 etcdctl --endpoints="http://$ETCD_HOST:$ETCD_PORT" \
  get /config/nodes/sat1 --print-value-only | jq .
```

## 10. Deploy

```bash
python3 ./nsb.py deploy -t 8
```

Başarılı deploy sonunda `eth0_ip` uyarısı görmemeniz gerekir.

```bash
ETCDCTL_API=3 etcdctl --endpoints="http://$ETCD_HOST:$ETCD_PORT" \
  get /config/nodes/sat1 --print-value-only | jq .eth0_ip
```

Eğer `eth0_ip` gelmiyorsa:

```bash
export NODE_ETCD_HOST=$(docker network inspect sat-vnet | jq -r '.[0].IPAM.Config[0].Gateway')
python3 ./nsb.py deploy --fix -t 8
```

## 11. Run

```bash
python3 ./nsb.py run
```

Node içine girip test:

```bash
python3 ./nsb.py exec usr1 ip route show
python3 ./nsb.py exec usr1 ping -c 3 grd1
```

