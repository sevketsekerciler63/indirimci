# Indirimci

Kişisel alışveriş kararlarını destekleyen Flutter uygulaması. Ürün arama sonuçlarını kaynak bilgisiyle gösterir, favori ürünleri takip eder ve kullanıcı tarafından girilen kupon indiriminin tahmini son fiyatını hesaplar.

## Veri doğruluğu

- Gerçek mağaza verisi ile demo verisi birbirine karıştırılmaz.
- Doğrulanmamış AI ürün/fiyat/kuponları normal akışta gösterilmez.
- Scraper sonuçları kaynak ve son kontrol zamanı ile işaretlenir.
- Kuponlar mağazada denenmeden kesin geçerli kabul edilmez.
- Uygulama bulunamayan veriyi uydurmaz.

## Çalıştırma

```bash
flutter pub get
flutter run
```

İsteğe bağlı AI önerileri için:

```bash
flutter run --dart-define=GROQ_API_KEY=YOUR_GROQ_API_KEY
```

API anahtarlarını kaynak koda veya GitHub’a eklemeyin.

## Test

```bash
flutter analyze
flutter test
```

Uygulama kişisel kullanım odaklıdır. Yeni mağazalar ancak sürdürülebilir ve doğrulanabilir veri kaynağı bulunduğunda eklenmelidir.
