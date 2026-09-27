# Indirimci

[![Flutter CI](https://github.com/sevketsekerciler63/indirimci/actions/workflows/ci.yml/badge.svg)](https://github.com/sevketsekerciler63/indirimci/actions/workflows/ci.yml)

Flutter ile geliştirilmiş, alışveriş kararlarını destekleyen kişisel indirim ve kupon takip uygulamasıdır. Ürün arama sonuçlarını kaynak bilgisiyle gösterir, favori ürünleri takip eder ve kullanıcı tarafından girilen kupon indiriminin tahmini son fiyatını hesaplar.

> Proje şu anda kişisel kullanım ve portföy geliştirme aşamasındadır. Gerçek mağaza verisi yalnızca doğrulanabilir kaynak bulunduğunda kullanılmalıdır.

## Problem

İndirim ve kupon sonuçları çoğu zaman kaynağı, güncelliği veya güvenilirliği belirtilmeden gösterilir. Indirimci, sonuçları kaynak/provenance bilgisiyle birlikte ele alır ve doğrulanmamış veriyi kesin gerçekmiş gibi göstermemeyi amaçlar.

## Özellikler

- Ürün ve fırsat arama akışı
- Kaynak ve son kontrol zamanı bilgisi taşıyan sonuçlar
- Güvenilirliği doğrulanmamış sonuçları filtreleme
- Favori ürünleri yerel olarak takip etme
- Kupon indirimi ve tahmini son fiyat hesaplama
- Kuponların geçerliliğini kesinmiş gibi göstermeyen durum takibi
- Fiyat düşüşleri için yerel bildirim altyapısı
- Arka planda periyodik fiyat kontrolü için Workmanager entegrasyonu
- Opsiyonel AI destekli öneriler; API anahtarı `--dart-define` ile verilir

## Teknolojiler

- Flutter ve Dart
- Riverpod — durum yönetimi
- Dio — HTTP istemcisi
- Hive ve Flutter Secure Storage — yerel veri saklama
- Workmanager — arka plan görevleri
- Flutter Local Notifications — yerel bildirimler
- Flutter Test ve Flutter Lints — doğrulama

## Mimari genel bakış

Kod, `lib` altında sorumluluklara göre ayrılmıştır:

- `lib/core/models` — fırsat ve kupon veri modelleri
- `lib/core/services` — API, scraper, depolama, hesaplama ve bildirim servisleri
- `lib/core/providers` — Riverpod sağlayıcıları ve iş akışları
- `lib/features` — ana ekran, arama, favoriler, kuponlar ve ürün detay ekranları
- `lib/config` — uygulama teması ve ortam ayarları

Sonuçların güvenilirlik kuralları model/provider katmanlarında uygulanır; UI katmanı bu doğrulanmış sonuçları sunar.

## Kurulum ve çalıştırma

Gereksinimler: Flutter stable ve Dart SDK.

```bash
git clone https://github.com/sevketsekerciler63/indirimci.git
cd indirimci
flutter pub get
flutter run
```

Opsiyonel AI önerileri için anahtarı kaynak koda yazmadan geçin:

```bash
flutter run --dart-define=GROQ_API_KEY=YOUR_GROQ_API_KEY
```

API anahtarlarını kaynak koda, commit geçmişine veya GitHub deposuna eklemeyin.

## Test ve statik analiz

```bash
flutter analyze
flutter test
```

GitHub Actions aynı iki doğrulamayı her push ve pull request sonrasında çalıştırır.

## Veri doğruluğu yaklaşımı

- Gerçek mağaza verisi ile demo verisi birbirine karıştırılmaz.
- Doğrulanmamış AI ürün, fiyat veya kuponları normal akışta gösterilmez.
- Scraper sonuçları kaynak ve son kontrol zamanı ile işaretlenir.
- Kuponlar mağazada denenmeden kesin geçerli kabul edilmez.
- Uygulama bulunamayan veriyi uydurmaz.
- Kaynak hataları, boş sonuç ile aynı durum gibi gizlenmez.

## Bilinen sınırlamalar

- Gerçek mağaza kaynaklarının erişilebilirliği ve sürekliliği dış servislere bağlıdır.
- Kupon geçerliliği mağaza koşullarına göre değişebilir; uygulama bunu garanti etmez.
- AI önerileri opsiyoneldir ve kullanılan harici API'nin erişilebilirliğine bağlıdır.
- Uygulama şu aşamada kişisel kullanım odaklıdır; üretim ölçeğinde çok kullanıcılı bir servis olarak sunulmamaktadır.

## Ekran görüntüleri

Portföy ekran görüntüleri doğrulanmış son arayüz akışları hazırlandıktan sonra eklenecektir.

## Lisans

Bu depoya henüz lisans eklenmemiştir. Kullanım ve dağıtım koşulları netleştirilmeden kodu başka projelerde yeniden kullanmayın.
