# NetSatBench Lab Guide

Bu dokümantasyon, [mSvcBench/NetSatBench](https://github.com/mSvcBench/NetSatBench) ile tek VM veya küçük çok-worker lab ortamı kurmak için hazırlanmış Türkçe bir rehberdir.

## Okuma Sırası

1. [Mimari ve adresleme modeli](00-mimari-ve-adresleme.md)
2. [Temiz Ubuntu kurulum akışı](01-temiz-ubuntu-kurulum.md)
3. [Konfigürasyon dosyaları](02-konfigurasyon-dosyalari.md)
4. [Komut akışı ve kontroller](03-komut-akisi-ve-kontroller.md)
5. [Troubleshooting](04-troubleshooting.md)
6. [Reset ve temizlik](05-reset-ve-temizlik.md)
7. [Kaynaklar ve upstream notları](06-kaynaklar-ve-upstream-notlari.md)

## Kısa Hatırlatma

Tek VM'de en kritik ayar `ETCD_HOST` ve `NODE_ETCD_HOST` değerlerinin containerlardan erişilebilir olmasıdır. Başarılı deploy sonunda her node Etcd'deki kendi config kaydına `eth0_ip` alanını yazmalıdır.

