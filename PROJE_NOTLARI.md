# Indirimci – Proje Notları

Bu uygulama kişisel alışverişlerde ürün arayıp farklı mağazalardaki fiyatları karşılaştırmak için geliştiriliyor.

## Son yapılanlar

- Gerçekliği doğrulanmamış sahte ürün, fiyat ve kuponların normal modda gösterilmesi kapatıldı.
- Ürünlerde veri kaynağı ve son kontrol zamanı gösteriliyor.
- Kuponlar için `Bilinmiyor`, `Çalıştı` ve `Çalışmadı` durumları eklendi.
- Kullanıcı tarafından manuel kupon ekleme özelliği eklendi.
- Manuel kuponlar Hive ile cihazda saklanıyor.
- Kupon indirimi ve minimum sepet tutarı hesaplama ekranı eklendi.
- Kupon kartlarındaki bazı piksel taşmaları düzeltildi.
- Analiz başarılı, 12 test başarılı ve debug APK oluşturuldu.

## Telefon testinde kalan sorunlar

- Kullanıcı bazı sorunların hâlâ devam ettiğini bildirdi; ayrıntıları yarın birlikte netleştireceğiz.
- Kuponların otomatik gelmesi için henüz güvenilir bir canlı kupon kaynağı bağlı değil.
- Arama, benzer ürün bulma ve mağaza sonuçları gerçek cihazda yeniden kontrol edilecek.

## Sonraki adımlar

1. Kullanıcının telefonda gördüğü her hatayı ekran görüntüsü ve mümkünse hata metniyle kaydetmek.
2. Piksel taşması olan ekranları tek tek düzeltmek.
3. “Faber-Castell kalem” gibi aramalarda tam, marka ve benzer kategori eşleşmelerini iyileştirmek.
4. Gerçek veri kaynaklarını güvenilirlik ve kullanım şartları açısından değerlendirmek.
5. Testlerden sonra yeni APK oluşturmak.
6. Projeyi GitHub’a göndermeden önce gizli anahtarları ve gereksiz dosyaları kontrol etmek.

## Önemli kararlar

- Uygulama sadece kullanıcı tarafından kullanılacak; karmaşık kullanıcı hesabı sistemi şimdilik gerekmiyor.
- Veri doğruluğu, mağaza sayısından daha önemli.
- Sistem gerçek kaynağı olmayan kupon veya fiyat uydurmamalı.
- `C:\\Users\\PC\\Desktop\\veri` aktif projedir.
- `akkayasoftOnlineOtomasyonProjesi` ve `claude-scholar` bu çalışmanın dışındadır.

## Çalıştırma

```bash
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug
```
