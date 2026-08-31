# Bilinen Sorunlar

Bu sürüm bir geliştirme (WIP) sürümüdür.

## Veri çekme

- Arama şu an Trendyol ve Cimri uç noktalarını doğrudan telefondan deniyor.
- Bu siteler istekleri engelleyebilir veya yanıt biçimini değiştirebilir.
- Cimri otomatik isteği Cloudflare tarafından engellenebiliyor.
- Ana sayfanın resmî API katmanı henüz gerçek bir kaynakla bağlı değil.
- Kuponlar için izinli ve güncel bir canlı kaynak bağlı değil; uygulama kupon uydurmuyor.
- Güvenilir çözüm için resmî API/affiliate kaynağı veya küçük bir sunucu katmanı gerekiyor.

## Kullanıcı araması

- Tam ürün, marka + ürün ve kategori eşleşmeleri sıralanıyor.
- Sonuç bulunamadığında mağaza bazında ayrıntılı erişim nedeni henüz gösterilmiyor.
- Kaynaklardan biri çalışmazsa diğer kaynakların sonucu kullanılabiliyor.

## Arayüz

- Bazı küçük ekranlarda taşma ihtimali azaltıldı; farklı telefon boyutlarında yeniden test edilmeli.

## Güvenlik

- API anahtarları kaynak koda yazılmamalı; `--dart-define` kullanılmalı.
- `test_coupons.html` dışarıdan kaydedilmiş test çıktısı olduğu için repoya dahil edilmez.
