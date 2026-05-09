# Komut Akışı ve Kontroller

NetSatBench komutları `nsb.py` wrapper'ı üzerinden çalışır.

## Yaşam Döngüsü Komutları

| Aşama | Komut | Etki |
|---|---|---|
| Worker hazırlığı | `system-init-docker` | Docker bridge, route, iptables, `/config/workers/` |
| Senaryo hazırlığı | `init` | Node merge, placement, CIDR atama, `/config/nodes/` |
| Container deploy | `deploy` | `docker run`, `sat-agent`, `eth0_ip` bekleme |
| Runtime | `run` | Epoch dosyalarını Etcd'ye link/run event olarak yazar |
| Node komutu | `exec`, `exectype` | Node içinde komut çalıştırır |
| Dosya kopyalama | `cp`, `cptype` | Node'a dosya/dizin gönderir |
| Runtime reset | `reset` | `/config/links/` ve `/config/run/` temizliği |
| Node kaldırma | `rm` | Node containerları ve ilgili durum |
| Worker temizliği | `system-clean-docker` | Docker bridge ve iptables route kalıntıları |

Gerçek cleanup komutu `system-clean-docker` şeklindedir.

## Tek VM Komut Sırası

```bash
export HOST_IP=$(ip -4 route get 1.1.1.1 | awk '{print $7; exit}')
export ETCD_HOST="$HOST_IP"
export ETCD_PORT=2379
export NODE_ETCD_HOST="$HOST_IP"
export NODE_ETCD_PORT=2379

python3 ./nsb.py system-init-docker --config ./examples/10nodes/worker-config.json
python3 ./nsb.py init --config ./examples/10nodes/sat-config.json --write-full-config
python3 ./nsb.py deploy -t 8
python3 ./nsb.py run
```

## Smoke Testler

Etcd:

```bash
curl -s "http://$ETCD_HOST:$ETCD_PORT/version"
ETCDCTL_API=3 etcdctl --endpoints="http://$ETCD_HOST:$ETCD_PORT" endpoint health
```

Worker kaydı:

```bash
ETCDCTL_API=3 etcdctl --endpoints="http://$ETCD_HOST:$ETCD_PORT" \
  get /config/workers/ --prefix
```

Node kaydı:

```bash
ETCDCTL_API=3 etcdctl --endpoints="http://$ETCD_HOST:$ETCD_PORT" \
  get /config/nodes/sat1 --print-value-only | jq .
```

Docker bridge:

```bash
docker network inspect sat-vnet | jq '.[0].IPAM.Config'
```

Deploy sonrası:

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'
ETCDCTL_API=3 etcdctl --endpoints="http://$ETCD_HOST:$ETCD_PORT" \
  get /config/nodes/sat1 --print-value-only | jq .eth0_ip
```

Node içinden Etcd:

```bash
docker exec sat1 curl -sS --max-time 3 "http://$NODE_ETCD_HOST:$NODE_ETCD_PORT/version"
docker exec sat1 ip -4 addr show eth0
docker exec sat1 ip route
```

Runtime:

```bash
python3 ./nsb.py exec usr1 ip route show
python3 ./nsb.py exec usr1 ping -c 3 grd1
python3 ./nsb.py exec grd1 iperf3 -s
python3 ./nsb.py exec usr1 iperf3 -c grd1 -t 10 -i 1
```

## Başarı Kriterleri

| Kontrol | Beklenen |
|---|---|
| `curl /version` | Etcd version JSON |
| `endpoint health` | healthy |
| `docker network inspect sat-vnet` | Beklenen subnet ve gateway |
| `/config/workers/` | En az `host-1` |
| `/config/nodes/sat1` | JSON node config |
| `.eth0_ip` | `172.20.0.x` benzeri underlay IP |
| `docker ps` | `sat*`, `grd1`, `usr1` up |
| `nsb.py run` | Epoch dosyalarını işlemeye başlar |

