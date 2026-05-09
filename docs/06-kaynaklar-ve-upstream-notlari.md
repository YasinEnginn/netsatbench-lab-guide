# Kaynaklar ve Upstream Notları

Bu repo hazırlanırken resmi NetSatBench deposu hem GitHub üzerinden hem de geçici yerel clone ile incelendi.

## İncelenen Upstream

- Resmi repo: <https://github.com/mSvcBench/NetSatBench>
- İncelenen branch: `main`
- İncelenen commit: `cb36a81f35b66a79f84643e1e41799632bbedc20`
- Commit tarihi: `2026-05-08`

## Resmi Doküman ve Kod Eşleşmeleri

| Konu | Kaynak |
|---|---|
| Mimari, VXLAN, Etcd, `nsb.py` yaşam döngüsü | NetSatBench `README.md` |
| Worker config, sat config, epoch config | `docs/configuration.md` |
| Etcd keyspace | `docs/etcd.md` |
| CLI komutları | `docs/control-commands.md`, `nsb.py` |
| Deploy env ayrımı | `control/nsb-deploy.py` |
| `eth0_ip` yazımı | `sat-container/sat-agent.py` |
| Docker bridge ve iptables setup | `control/system-init-docker.py` |
| Healthcheck | `sat-container/Dockerfile` |

## Dış Resmi Kaynaklar

- Docker Engine Ubuntu kurulumu: <https://docs.docker.com/engine/install/ubuntu/>
- Docker Engine genel kurulum sayfası: <https://docs.docker.com/engine/install/>
- etcd configuration options: <https://etcd.io/docs/v3.5/op-guide/configuration/>
- etcd container çalıştırma notları: <https://etcd.io/docs/v3.6/op-guide/container/>
- etcd FAQ, listen/advertise farkı: <https://etcd.io/docs/v3.7/faq/>

## Upstream Notları

Resmi README'de lab kurarken dikkat edilmesi gereken birkaç küçük fark görüldü:

- README quick start içinde `examples/10nodes/workers-config.json` yazıyor; repoda dosya `worker-config.json`.
- README cleanup örneğinde `system-cleanup-docker` yazıyor; `nsb.py` içindeki gerçek komut `system-clean-docker`.
- README sonunda `docs/contro-commands.md` linki var; gerçek dosya `docs/control-commands.md`.

Bu kılavuzda gerçek kaynak kod ve dosya adları esas alınmıştır.

