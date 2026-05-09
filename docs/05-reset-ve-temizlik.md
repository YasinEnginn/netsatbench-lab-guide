# Reset ve Temizlik

NetSatBench lab'ında temizlik iki seviyelidir: runtime state temizliği ve worker/Docker altyapı temizliği.

## Hafif Runtime Reset

Link ve runtime komut durumunu temizler; containerları kaldırmaz.

```bash
python3 ./nsb.py reset
```

Bunu yeni bir `run` denemesi öncesinde kullanabilirsiniz.

## Node Containerlarını Kaldırma

```bash
python3 ./nsb.py rm -t 8
```

Ardından tekrar deploy:

```bash
python3 ./nsb.py deploy -t 8
```

## Worker Altyapısını Temizleme

Gerçek komut adı:

```bash
python3 ./nsb.py system-clean-docker
```

Bu komut worker config bilgisini Etcd'den okuyarak Docker bridge ve ilgili iptables/route kurallarını temizlemeye çalışır.

## Etcd `/config` Temizliği

```bash
ETCDCTL_API=3 etcdctl --endpoints="http://$ETCD_HOST:$ETCD_PORT" \
  del /config --prefix
```

Bu işlem NetSatBench durumunu siler, Etcd containerını veya volume'ünü silmez.

## Hedefli Lab Temizliği

```bash
docker ps -a --format '{{.Names}}' | grep -E '^(sat|grd|usr)' | xargs -r docker rm -f
docker network rm sat-vnet 2>/dev/null || true
```

Bu dokümantasyon reposundaki `scripts/90-reset-lab.sh` aynı işleri prompt ile yapar.

## Etcd'yi Baştan Başlatma

Sadece lab Etcd'nizi silmek istediğinizden eminseniz:

```bash
docker rm -f etcd
docker volume rm etcd-data
```

Sonra tekrar:

```bash
scripts/01-start-etcd.sh
```

## Son Çare: Docker State Reset

Bu işlem tüm Docker container, image ve volume durumunu siler. Sadece bu VM lab için ayrılmışsa düşünün.

```bash
sudo systemctl stop docker
sudo rm -rf /var/lib/docker /var/lib/containerd
sudo systemctl start docker
```

