# Indirimci – Z Code / Yeni Codex Devir Notu

Bu dosya, başka bir Codex veya Z Code oturumunun projeye kaldığımız yerden devam etmesi içindir.

## Proje amacı

Flutter ile geliştirilmiş kişisel alışveriş yardımcısı. Kullanıcı “Faber-Castell kalem”, “kedi maması” gibi bir ürün yazar; uygulama mümkünse gerçek mağaza sonuçlarını getirir, uygun ürünleri sıralar ve kupon sonrası fiyatı hesaplar.

Kullanıcı tek kişi olduğu için hesap, üyelik ve karmaşık sunucu özellikleri şimdilik gerekmiyor. Veri doğruluğu, mağaza sayısından daha önemli. Gerçek olmayan fiyat veya kupon kesin bilgi gibi gösterilmemeli.

## Proje konumu

Bu dosyanın bulunduğu uygulama klasörü (proje kök dizini).

GitHub public repo:

`https://github.com/sevketsekerciler63/indirimci`

Git dalı: `main`

Son gönderilen commit: `1e54628 chore: initial Indirimci WIP snapshot`

GitHub hesabındaki `claude-scholar` reposuna ve `akkayasoftOnlineOtomasyonProjesi` projesine dokunma.

## Yapılan değişiklikler

- Doğrulanmamış mock/AI verileri normal akışta kapatıldı (`Env.enableUntrustedData = false`).
- Ürün kartlarında veri kaynağı ve son kontrol zamanı gösteriliyor.
- Deal güvenilirlik kontrolü eklendi.
- Kupon güvenilirlik, tazelik ve durum sistemi eklendi: bilinmiyor / çalıştı / çalışmadı.
- Kullanıcı manuel kupon ekleyebiliyor.
- Manuel kuponlar Hive ile cihazda saklanıyor.
- Kupon indirimi ve minimum sepet tutarı hesaplama ekranı eklendi.
- Arama sonuçlarını sıralamak için `lib/core/services/search_matcher.dart` eklendi.
- Arama sıralaması: tam eşleşme, tüm kelimeleri içeren ürün, marka/ürün eşleşmesi, daha genel eşleşme; eşit durumda düşük fiyat önce.
- Alt menü ve kupon istatistiklerindeki bazı küçük ekran taşmaları düzeltildi.
- `KNOWN_ISSUES.md` ve `PROJE_NOTLARI.md` oluşturuldu.
- Dış siteden kaydedilmiş `test_coupons.html` GitHub’a gönderilmiyor; `.gitignore` içine alındı.

## Test durumu

Son kontrolde:

- `flutter analyze --no-pub` başarılı.
- 14 test başarılı.
- `flutter build apk --debug` başarılı.

APK konumu:

`build/app/outputs/flutter-apk/app-debug.apk`

## En önemli mevcut sorun

Veri çekme sistemi henüz güvenilir değil:

- Arama doğrudan telefondan Trendyol ve Cimri uç noktalarını deniyor.
- Trendyol uç noktası her ağda/ortamda yanıt vermeyebiliyor.
- Cimri otomatik istekleri Cloudflare ile engelleyebiliyor.
- Cimri HTML seçicileri site tasarımı değişince bozulabilir.
- Ana sayfanın `ApiService.fromEnv()` katmanı şu an boş source ile başlıyor; ana sayfaya gerçek API bağlı değil.
- Kuponlar için izinli ve güncel canlı kaynak yok; sistem kupon uydurmuyor.
- Kullanıcı bu nedenle telefonda “veri gelmiyor” sorunu gördü.

Ayrıntılı liste: `KNOWN_ISSUES.md`

## Yeni oturumda yapılacaklar

Önce mevcut kodu ve bu dosyayı oku. Sonra aşağıdakileri sırayla ele al:

1. Veri çekme mimarisini düzelt: kaynakları tek tek izlenebilir hâle getir; hangi mağazanın başarılı/başarısız olduğunu kullanıcıya göster.
2. Doğrudan site scraping yaklaşımının sınırlarını koru; sahte fallback ekleme.
3. Resmî veya izinli veri kaynağı seçeneklerini araştır. API anahtarını Flutter uygulamasına gömme; gerekiyorsa küçük backend tasarla.
4. Ücretsiz ve kişisel kullanım için uygulanabilir çözümü kullanıcıya açıkça anlat. Ücretli servis önermeden önce onay al.
5. “Faber-Castell kalem” aramasını gerçek cihazda ve testlerle doğrula.
6. Telefon ekranı taşmalarını ekran görüntüsü veya hata mesajı üzerinden düzelt.
7. Her değişiklikten sonra şu komutları çalıştır:

```text
dart format .
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug
```

8. Temiz testten sonra commit oluştur ve GitHub’a push et. Push öncesi secret taraması yap.

## Çalışma kuralları

- Kullanıcıyı sadece onaylamak zorunda değilsin; yanlış veya riskli fikri açıkça söyle.
- Büyük kararlar (ücretli servis, backend, public/private değişikliği, veri kullanım şartları) için kullanıcıya sor.
- Rutin kod düzeltmelerini toplu yap; her küçük adımda kullanıcıyı bekletme.
- Gerçek veri yoksa bunu kullanıcıya söyle; ürün, fiyat veya kupon üretme.
- Mevcut kullanıcı değişikliklerini silme.
- `git reset --hard` veya geri dönüşü zor işlemler kullanma.
- Kullanıcı “bitirince haber ver” dediğinde test ve APK durumunu birlikte bildir.

## Yeni oturuma gönderilecek hazır mesaj

```text
Indirimci projesine kaldığımız yerden devam et. Önce proje kökündeki Z_CODE_DEVIR_NOTU.md, KNOWN_ISSUES.md ve PROJE_NOTLARI.md dosyalarını oku. Proje GitHub’da sevketsekerciler63/indirimci reposunda. claude-scholar ve akkayasoftOnlineOtomasyonProjesi projelerine dokunma. Önceliğimiz veri çekme zincirini incelemek ve telefonda veri gelmeme sorununu çözmek; sahte fiyat/kupon üretme. Rutin düzeltmeleri toplu yap, büyük maliyet veya backend kararı gerekirse bana sor. Sonunda analyze, test ve APK durumunu bildir.
```
