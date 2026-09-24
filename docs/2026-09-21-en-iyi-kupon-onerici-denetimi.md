# Indirimci – En İyi Kupon Önerici Denetimi

**Tarih:** 21 Eylül 2026  
**Kapsam:** Çalışma ağacındaki kupon durum takibi, kaynak durumu ve doğruluk korumaları; gelecekteki “platform + sepet tutarına göre en iyi kupon” önerisi.

## Doğrulanmış sonuçlar

- `flutter analyze`: başarılı, sorun yok.
- `flutter test`: başarılı, 22 test geçti.
- `flutter build apk --debug`: başarılı. APK: `build/app/outputs/flutter-apk/app-debug.apk`.
- Yeni ve değişmiş kod henüz commit edilmemiş. Çalışma ağacında 7 değişmiş Dart dosyası; 1 strateji belgesi ve 7 yeni test dosyası var.
- Android manifestinde yedekleme davranışını açıkça sınırlayan bir `allowBackup`, `dataExtractionRules` veya `fullBackupContent` ayarı yok.
- Varsayılan Obsidian kasası bulunamadığı için kayıt proje içindeki `docs/` klasörüne yazıldı.

## Güçlü noktalar

1. Doğrulanmamış mock/AI verisi normal akışta kapalı (`Env.enableUntrustedData = false`).
2. Arama sonucu artık kaynak başına durum taşıyor; boş sonuç ile hata ayrımı için doğru yön.
3. Ürün fiyat geçmişi doğrulanmış, ürün-kimliğine bağlı veri yokken gösterilmiyor.
4. Kupon hesaplama ekranı sonucu “tahmin” olarak tanımlıyor ve minimum sepet şartını hesaplıyor.
5. Gizli dosya/anahtar taramasında izlenen bir sır dosyası veya değişikliklerde açık anahtar bulunmadı.

## Kritik riskler

### 1. “Çalıştı” işareti, kullanıcıya genel doğrulama gibi gösteriliyor

- **Kanıt:** `Coupon.copyWithCheckedStatus` bir `worked` bildirimiyle `isVerified=true` yapıyor; `CouponCard` bunu `Doğrulanmış` rozeti olarak gösteriyor. Aynı kart ayrıca deneme ve başarı yüzdesini gösteriyor.
- **Sonuç:** Tek cihazdaki, tek hesap/konum/sepet koşulundaki sonuç; tüm kullanıcılar için doğrulanmış/geçerli ve istatistiksel başarı oranı gibi algılanabilir. Bu, proje ilkesindeki “kişisel deneme” ayrımıyla çelişir.
- **Önerici ön şartı:** `officialVerified`, `localWorked`, `localFailed` durumlarını ayır. Yerel sonuçta “Bu cihazda son deneme: çalıştı” de; genel `Doğrulanmış` rozeti ve yüzde başarı oranı kullanma.

### 2. Gizli kişisel kodlar fiilen gizlenmiyor ve şifrelenmeden saklanıyor

- **Kanıt:** Manuel kupon formu `isHidden` alanını sormuyor ve varsayılan değer `false`. `CouponCard` kodu doğrudan ekranda gösteriyor, dokununca panoya kopyalıyor ve Snackbar’da tekrar açıkça yazıyor. Hive kutusuna `Coupon.toMap()` ham `code` alanını kaydediyor.
- **Sonuç:** Ekran görüntüsü, omuz sörfü, pano geçmişi, cihazın yerel veri erişimi veya Android yedekleri yoluyla hesaba özel kod açığa çıkabilir. “Gizli” rozeti tek başına koruma değildir.
- **Önerici ön şartı:** Kişisel kodları varsayılan gizli tut; göster/kopyala için bilinçli kullanıcı eylemi ve mümkünse biyometrik/ekran kilidi koruması kullan. Kodun kendisini telemetri, log, paylaşım, dışa aktarma ve kaynak durumlarına hiç yazma. Android yedekleme/taşıma politikasını açıkça belirle; Hive verisinin şifreli saklanması için anahtarın güvenli anahtar deposunda tutulmasını değerlendir.

### 3. Kaynak başarısızlığı “Sonuç yok” diye yanlış etiketlenebilir

- **Kanıt:** `searchTrendyolApi` ve `searchCimri` kendi içlerinde hatayı yakalayıp boş liste dönüyor. Üstteki `_safeScrapeWithStatus` bunu başarılı çağrı kabul edip `ok: true, “Sonuç yok”` durumunu üretiyor. Kaynak durumu testi yapay servis ile 403 bilgisini geçiriyor; gerçek adaptör hata zincirini test etmiyor.
- **Sonuç:** Kullanıcı, kaynak erişilemediği veya ayrıştırıcı bozulduğu halde kampanya/ürün bulunmadığını sanabilir. Kupon önericisi boş/verisiz kaynak üzerinden “en iyi” seçimi yapmamalıdır.
- **Önerici ön şartı:** Adaptörler sonuç ile hata durumunu ayrı bir sonuç tipinde dönsün. HTTP 403/429, zaman aşımı, DNS, şema/parse hatası, geçersiz yanıt ve gerçek sıfır sonuç ayrı durumlar olsun. En iyi öneri yalnızca veri setinin kapsamı kullanıcıya açıkken verilsin.

### 4. Eski, süresi geçmiş veya “çalışmadı” kuponlar manuel kayıt olarak listede kalıyor

- **Kanıt:** `CouponsNotifier._loadCoupons`, yerel manuel kuponları tazelik, bitiş tarihi ve `failed` durumuna göre filtrelemeden ekliyor. `Coupon.isExpired` bitiş tarihi yoksa her zaman `false`; manuel kupon formunda bitiş tarihi alanı yok. Manuel kayıtlar resmî kayıtlar için kullanılan `isTrusted()` filtresini de atlıyor.
- **Sonuç:** Eski ya da son denemede başarısız olmuş bir kişisel kod, önerici tarafından yanlışlıkla en yüksek parasal indirime sahipmiş gibi seçilebilir.
- **Önerici ön şartı:** Öneri adaylarında bitiş tarihi veya kontrollü “son deneme” süresi zorunlu olsun. `failed` sonucun öneriden çıkarılması, `unknown` sonucun “denenmemiş” etiketiyle ikincil gösterimi ve zaman aşımında yeniden doğrulama akışı tanımlansın. Bitiş tarihi bilinmeyen kayıt otomatik “güvenilir” sayılmasın.

## Önemli riskler

### 5. Başarı oranı geri kazanılamaz biçimde türetiliyor

- **Kanıt:** Çalışan deneme adedi yalnız `usageCount * successRate / 100` üzerinden yuvarlanarak tekrar üretiliyor; gerçek worked/failed sayaçları tutulmuyor.
- **Sonuç:** Yuvarlama zamanla oranı bozabilir. Ayrıca import edilmiş sayıların hangi popülasyona ait olduğu belli değildir.
- **Önerici ön şartı:** Yüzde yerine ayrı yerel `workedCount`, `failedCount`, `lastOutcomeAt` ve kapsam (cihaz/hesap/konum) tut. Varsayılan MVP’de oran yerine son sonuç ve tarih göster.

### 6. Platform, ürün/kategori, kullanıcı uygunluğu ve kupon şartları modelde yetersiz

- **Kanıt:** Kupon platformu serbest metin; eşleme tam metin karşılaştırmasına dayanıyor. Modelde kullanıcı/konum/yeni kullanıcı/üyelik/kategori/kargo/ödeme yöntemi/tekil kullanım/istifleme şartları, kaynak URL’si ve kanıt tipi yok.
- **Sonuç:** Salt sepet tutarına göre hesaplanan en büyük indirim, gerçekte o platformda veya o sepette uygulanamayabilir.
- **Önerici ön şartı:** Kanonik platform kimliği; koşul alanları; `requiresAccountCheck`; kategori ve ürün uygunluğu; istifleme kuralı; kaynak URL’si; gözlem/kontrol/bitiş zamanı; açıkça “bilinmiyor” değerleri olmadan öneri verme kuralı gerekir.

### 7. Hesaplama motoru tüm indirimi toplayabiliyor

- **Kanıt:** `CouponCalculator` yüzde indirim ile sabit tutarı topluyor; üst indirim limiti, kategori/kargo/vergiler, istifleme ve mağazanın yuvarlama kuralını modellemiyor.
- **Sonuç:** Önerilen net fiyat, mağaza sepetindeki gerçek net fiyatı aşırı iyimser gösterebilir.
- **Önerici ön şartı:** Her kupon için tek hesaplama türü ve varsa resmî üst limit; bilinmeyen istifleme/vergiler için “tahmini” ve belirsizlik açıklaması. Aynı anda birden çok kuponu otomatik birleştirme varsayılanı kapalı olmalı.

### 8. Yerel yazma hataları kullanıcıya güvenilir biçimde yansıtılmıyor

- **Kanıt:** `saveCoupon` ve `getCoupons` hata koruması sınırlı; durum güncellemesi önce ekrana uygulanıyor, sonra Hive’a yazılıyor ve yazma başarısız olursa geri alma/bildirim yok.
- **Sonuç:** Kullanıcı kuponu veya deneme sonucunu kaydedildi sanabilir; uygulama açılınca kayıt kaybolabilir.
- **Önerici ön şartı:** Kalıcı yazma tamamlanmadan “kaydedildi” sonucu verme; hata halinde eski duruma dönme ve tekrar dene seçeneği; bozuk tek kaydı atlayıp diğer kayıtları okumaya devam etme.

## En iyi kupon önerici: güvenilirlik ve UX kontrol listesi

### A. Aday seçimi ve veri doğruluğu

- [ ] Öneri yalnız seçilmiş/tespit edilmiş kanonik platformdaki kuponlardan yapılır.
- [ ] Sepet tutarı geçerli, pozitif ve para birimi açık; kuponun minimum sepet şartı sağlanır.
- [ ] Kuponun bitiş tarihi geçmiş değildir; bilinmeyen bitiş zamanı için politika açıkça uygulanır.
- [ ] Son kaynak kontrolü, veri türüne göre tazelik eşiğini geçmez; cihaz saati anomalisinde “yeniden kontrol et” gösterilir.
- [ ] `failed` durumundaki kişisel kod önerilmez; `unknown` kod “denenmemiş” olarak ikincil sunulur.
- [ ] `worked` sonucu yalnız bu cihazdaki son deneme olarak sunulur; genel geçerlilik veya topluluk başarısı iddia edilmez.
- [ ] Kaynak, kaynak URL’si/kanıt türü, kontrol zamanı ve koşul özeti olmayan otomatik kayıt önerilmez.
- [ ] Kampanya kaydı ile gerçek kupon kodu ayrıdır; kod yoksa uydurulmaz ve “kampanyayı mağazada kontrol et” akışı kullanılır.
- [ ] Aynı kodun yinelenen kayıtları kanonik platform + kod + koşul/farklı sürüm anahtarıyla birleştirilir.

### B. Hesaplama ve sıralama

- [ ] Uygun olmayan adaylar elenir; kullanıcıya en yüksek teorik oran değil en düşük **tahmini net sepet** ile sıralama yapılır.
- [ ] Sabit/yüzde indirim, kupon üst limiti ve minimum sepet doğru uygulanır.
- [ ] İstifleme kuralı bilinmiyorsa kuponlar birleştirilmez.
- [ ] Kargo, teslimat, servis, vergi, ödeme yöntemi ve üyelik etkisi bilinmiyorsa net fiyat “tahmini” kalır ve nedenleri listelenir.
- [ ] Eşit net fiyatlarda daha taze ve daha güçlü kanıtlı kayıt üstte olur.
- [ ] Geçersiz, negatif, fiyatı aşan ve sayı dönüşümü hatalı değerler aday havuzundan çıkarılır.
- [ ] En iyi aday yoksa “kupon yok” değil, “bu sepet için doğrulanabilir öneri yok” denir; kaynak hata durumları ayrıca gösterilir.

### C. Kişisel kod gizliliği

- [ ] Manuel/hesaba özel kod varsayılan gizlidir; liste ve öneri kartında maskelenir.
- [ ] Kodu gösterme/kopyalama açık kullanıcı eylemi gerektirir; Snackbar, hata, analitik ve paylaşım metni kodu tekrar etmez.
- [ ] Kodlar uygulama günlüklerine, kaynak durumlarına, URL’lere, crash raporlarına veya telemetriye gitmez.
- [ ] Yerel saklama şifreleme ve anahtar yönetimi değerlendirilir; Android yedekleme/cihaz taşıma davranışı kullanıcıya açıklanır.
- [ ] Kod silme, düzenleme ve yerel veriyi temizleme için görünür kontrol vardır.

### D. UX metinleri ve güven sınırları

- [ ] Başlık “Önerilen kupon (tahmini)” olur; “kesin çalışır/en iyi fırsat” gibi kesin dil kullanılmaz.
- [ ] Kartta indirim, minimum sepet, bitiş zamanı, kaynak/son kontrol ve uygulanamama nedenleri görünür.
- [ ] Hesap/konum/yeni kullanıcı/üyelik kontrolü gerekiyorsa kullanıcı işlem öncesinde açıkça uyarılır.
- [ ] “Çalıştı / çalışmadı” geri bildirimi tek dokunuşla verilir; geri alma veya düzeltme yolu vardır.
- [ ] Kaynak erişilemediğinde bunu “sonuç yok”tan ayıran okunabilir durum kartı gösterilir.
- [ ] Kullanıcıya, mağazaya yönlendirilmeden önce en az bir kez koşulları kontrol etmesi söylenir.

### E. Test ve yayın kapısı

- [ ] Saf öneri motoru için birim testleri: platform eşleşmesi, min sepet sınırı, yüzde/sabit/üst limit, eşitlik, geçersiz değer, zaman aşımı, stale/expired/failed/unknown durumları.
- [ ] Kupon modelinin eski Hive kayıtlarıyla geriye uyum ve bozuk kayıt toleransı test edilir.
- [ ] Hive yazma hatasında UI geri alma ve kullanıcı bildirimi test edilir.
- [ ] Gizli kodun UI’da maskelendiği, pano/Snackbar/paylaşım/telemetri yoluna girmediği widget/entegrasyon testleri eklenir.
- [ ] Gerçek adaptör testleri HTTP 200 sıfır sonuç, 403, 429, timeout, DNS/bağlantı hatası ve parse şema değişikliğini ayırır.
- [ ] Saat ileri/geri alındığında tazelik ve bitiş hesapları test edilir.
- [ ] Küçük ve büyük ekranlarda öneri kartı, uzun platform/koşul metni ve erişilebilirlik test edilir.
- [ ] En az bir gerçek cihazda, uygulama kapalıyken yeniden açma ve Hive kalıcılığı doğrulanır.
- [ ] Yayın öncesi `flutter analyze`, `flutter test` ve `flutter build apk --debug` tekrar çalışır; canlı kaynak sonuçları yalnız izleme kanıtı olarak ayrıca kayda alınır.

## Önerilen en küçük güvenli kapsam

Önce yalnızca kullanıcının **manuel eklediği**, seçili platformla eşleşen, bitiş tarihi ve minimum sepet şartı bilinen tek kuponu hesaplayıp “tahmini en iyi aday” olarak gösterin. Otomatik kaynaklardan kupon seçimini; kaynak URL’si, koşullar, tazelik, hata ayrımı ve kişisel/hesap koşulları modellemesi tamamlanmadan eklemeyin.
