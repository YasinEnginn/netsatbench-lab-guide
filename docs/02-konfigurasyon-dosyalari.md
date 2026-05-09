# Konfigürasyon Dosyaları

NetSatBench lab'ında iki ana JSON dosyası vardır:

- `worker-config.json`: worker hostlar, SSH, Docker underlay ağı ve kapasite
- `sat-config.json`: emüle edilecek node'lar, ortak node ayarları, overlay IP ataması ve epoch dosyaları

## Worker Config

Minimal tek VM dosyası:

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

| Alan | Anlamı | Lab notu |
|---|---|---|
| `ssh-user` | Worker'a bağlanacak Linux kullanıcısı | Passwordless sudo ve Docker yetkisi olmalı |
| `ssh-key` | Private key path | Control host tarafından okunabilir olmalı |
| `ip` | Worker yönetim IP'si | SSH ile erişilebilir gerçek host IP |
| `sat-vnet` | Docker bridge adı | Genelde `sat-vnet` |
| `sat-vnet-cidr` | O worker container subneti | Tek VM'de `172.20.0.0/24` yeterli |
| `sat-vnet-super-cidr` | Tüm worker subnetlerinin üst bloğu | Fiziksel ağ ve overlay ile çakışmamalı |
| `cpu`, `mem` | Scheduler kapasitesi | 10 node denemesi için `4`, `8GiB` rahat başlar |

## Satellite Config

`sat-config.json` üç ana bölüm taşır:

```json
{
  "node-config-common": [],
  "epoch-config": {},
  "nodes": {}
}
```

### `node-config-common`

Node tipine veya metadata alanına göre ortak ayarları merge eder. Resmi `10nodes` örneğinde `satellite`, `gateway` ve `user` için ayrı kurallar bulunur.

Kritik alanlar:

| Alan | Anlamı |
|---|---|
| `image` | Node container imajı, varsayılan örnek `msvcbench/sat-container:latest` |
| `cpu-request`, `mem-request` | Scheduler talebi |
| `cpu-limit`, `mem-limit` | Runtime limitleri |
| `L3-config.enable-netem` | Link delay/loss/rate uygulanacak mı? |
| `L3-config.enable-routing` | Overlay üzerinde routing modülü çalışacak mı? |
| `L3-config.routing-module` | Örnek: `extra.routing.isis`, `extra.routing.isisv6` |
| `auto-assign-ips` | Overlay CIDR otomatik atanacak mı? |
| `auto-assign-super-cidr` | Node tipine göre overlay super block |

> `sidecars` alanı dokümantasyonda geçer, fakat incelenen control CLI akışında pratik olarak desteklenen bir deploy yüzeyi değildir. İlk lab için boş bırakın.

### `epoch-config`

Epoch dosyalarının nereden okunacağını belirler:

```json
{
  "epoch-dir": "examples/10nodes/epochs",
  "file-pattern": "NetSatBench-epoch*.json"
}
```

`nsb.py run`, bu dosyaları sıralı şekilde okuyup Etcd'ye link ve run eventleri yazar.

### `nodes`

Her node adı 8 karakterden kısa tutulmalıdır. `sat1`, `grd1`, `usr1` gibi isimler güvenlidir.

Per-node override örneği:

```json
{
  "grd1": {
    "type": "gateway",
    "cpu-request": "200m",
    "mem-request": "400MiB",
    "cpu-limit": "400m",
    "mem-limit": "800MiB",
    "metadata": {
      "location": {
        "latitude": 37.4275,
        "longitude": -122.1697,
        "altitude": 30
      },
      "L3-config": {
        "routing-metadata": {
          "advertize-default-route": true
        }
      }
    }
  }
}
```

## CIDR Çakışma Kontrolü

Kaçınılması gereken durum:

```text
Host LAN:             172.20.10.0/24
sat-vnet-super-cidr:  172.20.0.0/16
```

Bu durumda Docker underlay ile fiziksel ağ çakışır. Alternatif bir blok seçin:

```text
sat-vnet-super-cidr:  10.250.0.0/16
sat-vnet-cidr:        10.250.0.0/24
overlay satellite:    172.100.0.0/16
overlay gateway:      172.101.0.0/16
overlay user:         172.102.0.0/16
```

## İlk Lab İçin Önerilen Değerler

| Parametre | Değer |
|---|---|
| Worker sayısı | 1 |
| Worker CPU | `4` |
| Worker MEM | `8GiB` |
| Node image | `msvcbench/sat-container:latest` |
| Underlay supernet | `172.20.0.0/16` |
| Tek worker subnet | `172.20.0.0/24` |
| Etcd | Plain HTTP, host network |
| Senaryo | `examples/10nodes/sat-config.json` |

