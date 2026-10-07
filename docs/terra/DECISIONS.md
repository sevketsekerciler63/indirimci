# Terra kararları

## 2026-10-01 — Otonom çalışma başlangıcı

- Yol haritasındaki P1 önceliklidir: kayıt/migration başarısızlığı UI'da başarı gibi görünmemeli ve eski kupon kutusuna yazan kullanıcı verisi korunmalıdır.
- Başlangıçta `TERRA_YOL_HARITASI.md` izlenmeyen tek dosyaydı; kullanıcı yol haritasına göre devam edilmesini istediği için dosya korunacaktır.
- Android cihaz doğrulaması, yalnız gerçek AVD/cihaz bulunduğunda ve veri silmeden yapılacaktır. `adb.exe` Android SDK altında bulunuyor fakat PATH'te değil; mutlak yol kullanılacaktır.
- Canlı fiyat/kampanya bağlantısı yoksa fixture veya tahmini veri üretim listesine eklenmeyecek; bu durum ayrı harici engel olarak raporlanacaktır.

## 2026-10-07 — P1 depolama güvenliği

- Eski plaintext `couponsBox` silinmeden korunacak; doğrulanmış AES hedef `couponsBox.v2` aktif kasa olacaktır.
- Yarım migration tekrarında işaretsiz hedef temizlenip legacy kaynaktan yeniden kurulacak; artık kayıtlar kullanıcı kuponu gibi görünmeyecektir.
- Mevcut aynı adlı şifreli legacy kasa, kayıtlı doğru anahtarla açılabiliyorsa yerinde kullanılmaya devam edecektir.
- Favoriler tek snapshot anahtarında atomik yazılacak; eski satır biçimi okunup geçerli kayıtlar snapshot'a taşınacaktır.
- Depolama yazımı başarısızken notifier state'i başarı olarak yayımlanmayacak; UI açık hata mesajı gösterecektir.
