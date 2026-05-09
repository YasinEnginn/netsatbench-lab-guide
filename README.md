# NetSatBench Lab Guide

Bu repo, [mSvcBench/NetSatBench](https://github.com/mSvcBench/NetSatBench) ile tek VM veya küçük çok-worker lab ortamı kurmak isteyenler için hazırlanmış pratik, açıklayıcı ve tekrar edilebilir bir kurulum kılavuzudur.

NetSatBench; uydu, gateway ve user düğümlerini Linux container olarak çalıştırır. Düğümler arası bağlantılar VXLAN overlay ile kurulur, link gecikmesi/kaybı/hızı Linux `tc` ve `netem` ile uygulanır, zamanla değişen topoloji ise Etcd üstünden `sat-agent` süreçlerine dağıtılır.

> Bu repo resmi NetSatBench deposu değildir. Resmi kaynak: <https://github.com/mSvcBench/NetSatBench>. Atıf ve lisans notları için [NOTICE.md](NOTICE.md) dosyasına bakın.

## Ne Var?

- Temiz Ubuntu VM üstünde Docker, SSH, Python venv ve Etcd kurulumu
- Tek VM için çalışan `10nodes` lab akışı
- `worker-config.json`, `sat-config.json` ve Etcd keyspace mantığının açıklaması
- Host IP, Docker bridge underlay CIDR ve overlay CIDR ayrımı
- `eth0_ip` gelmiyor, Etcd erişilemiyor, image çekilemiyor, overcommit oluyor gibi hatalar için teşhis reçeteleri
- Güvenli reset ve temizlik akışları
- Tekrar edilebilir shell scriptleri ve örnek config dosyaları

## Hızlı Başlangıç

Bu bölüm, lab VM'in Ubuntu olduğunu varsayar. Kılavuz reposu ile resmi NetSatBench kaynak kodunu ayrı tutmak için örnekte resmi kaynak `upstream/NetSatBench` altına klonlanır.

```bash
# 0) Bu kılavuz reposunun kökü
export GUIDE_DIR="$(pwd)"

# 1) NetSatBench kaynak kodunu alın
mkdir -p upstream
git clone https://github.com/mSvcBench/NetSatBench.git upstream/NetSatBench
cd upstream/NetSatBench
git submodule update --init --recursive

# 2) Python ortamı
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -U pip setuptools wheel
pip install -r requirements.txt

# 3) Etcd endpoint değerleri
export HOST_IP=$(ip -4 route get 1.1.1.1 | awk '{print $7; exit}')
export ETCD_HOST="$HOST_IP"
export ETCD_PORT=2379
export NODE_ETCD_HOST="$HOST_IP"
export NODE_ETCD_PORT=2379

# 4) Etcd başlatma
"$GUIDE_DIR/scripts/01-start-etcd.sh"

# 5) Tek VM worker config üretme
SSH_USER="$USER" SSH_KEY="$HOME/.ssh/id_rsa" CPU=4 MEM=8GiB \
  "$GUIDE_DIR/scripts/02-render-worker-config.sh"

# 6) Worker, senaryo, deploy
python3 ./nsb.py system-init-docker --config ./examples/10nodes/worker-config.json
python3 ./nsb.py init --config ./examples/10nodes/sat-config.json --write-full-config
python3 ./nsb.py deploy -t 8

# 7) Epoch akışı
"$GUIDE_DIR/scripts/03-smoke-check.sh"
python3 ./nsb.py run
```

> NetSatBench kaynak deposunu zaten başka bir yerde tutuyorsanız `GUIDE_DIR` değişkenini bu kılavuz reposuna, terminal konumunuzu da resmi NetSatBench repo köküne ayarlamanız yeterli.

## Önce Okunacaklar

1. [Mimari ve adresleme modeli](docs/00-mimari-ve-adresleme.md)
2. [Temiz Ubuntu kurulum akışı](docs/01-temiz-ubuntu-kurulum.md)
3. [Konfigürasyon dosyaları](docs/02-konfigurasyon-dosyalari.md)
4. [Komut akışı ve kontroller](docs/03-komut-akisi-ve-kontroller.md)
5. [Troubleshooting](docs/04-troubleshooting.md)
6. [Reset ve temizlik](docs/05-reset-ve-temizlik.md)
7. [Kaynaklar ve upstream notları](docs/06-kaynaklar-ve-upstream-notlari.md)

## Lab İçin En Önemli Kural

Üç IP alanını karıştırmayın:

| Alan | Örnek | Kullanım |
|---|---:|---|
| Host/worker yönetim IP'si | `10.0.1.215` | SSH, Etcd client erişimi, control host |
| Docker bridge underlay | `172.20.0.0/24` | Container `eth0` IP'leri |
| Overlay node CIDR'leri | `172.100.0.0/16` | VXLAN/L3 emülasyon adresleri |

Tek VM lab için pratik başlangıç: `ETCD_HOST` ve `NODE_ETCD_HOST` değerlerini host'un gerçek yönetim IP'si yapın. Yalnız container içinden host IP'ye erişilemiyorsa `NODE_ETCD_HOST` için Docker bridge gateway değerini deneyin.

Bridge gateway fallback'inde `docker exec sat1 curl http://172.20.0.1:2379/version` timeout oluyorsa host firewall'u `172.20.0.0/24` kaynaklı Etcd trafiğini engelliyor olabilir. Hızlı lab teşhisi için [troubleshooting firewall bölümüne](docs/04-troubleshooting.md) bakın.

## Resmi Repoda Doğrulanan Küçük Tuzaklar

Bu kılavuz hazırlanırken resmi NetSatBench deposu incelendi. Şu farklar özellikle lab kurulumunda önemlidir:

- Resmi README bazı yerlerde `examples/10nodes/workers-config.json` diyor; gerçek örnek dosya adı `examples/10nodes/worker-config.json`.
- Resmi README cleanup için `system-cleanup-docker` yazıyor; gerçek CLI komutu `system-clean-docker`.
- Docker healthcheck yalnız `sat-agent.py` sürecini denetliyor. Container `healthy` olsa bile Etcd bağlantısı, `eth0_ip` yazımı ve VXLAN linkleri ayrıca kontrol edilmelidir.
- `deploy` node containerlarını `--pull=always` ile başlatıyor. Worker host registry'ye çıkamıyorsa deploy aşaması kırılır.

## Repo Yapısı

```text
.
├── docs/       # Ayrıntılı Türkçe kılavuz
├── examples/   # Tek VM env ve worker config örnekleri
├── scripts/    # Kurulum, Etcd, smoke-check ve reset yardımcıları
├── assets/     # Mermaid diyagramları
└── README.md
```

## Hedef Ortam

Bu kılavuz özellikle şu başlangıç senaryosu için tasarlanmıştır:

- Ubuntu 22.04 LTS, 24.04 LTS veya güncel resmi Docker destekli Ubuntu sürümü
- Tek VM üzerinde control host, worker ve Etcd
- `examples/10nodes/sat-config.json` ile ilk doğrulama
- Plain HTTP Etcd ile hızlı lab doğrulaması

Çok-worker veya bulut ortamında aynı mantık geçerlidir; ek olarak container subnet route'ları, anti-spoofing kuralları, security group/firewall ve VXLAN UDP 4789 trafiği doğrulanmalıdır.
