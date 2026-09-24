# Indirimci: Çok Kaynaklı Kupon ve Fırsat Stratejisi

**Karar tarihi:** 21 Eylül 2026

## Ürün ilkesi

Indirimci kişisel karar desteği verir; "fırsat bulundu" ile "bu kupon senin hesabında çalışır" iddiasını ayırır. Veri yoksa boş durum ve kaynak hatası gösterilir; fiyat, indirim veya kupon üretilmez.

Hesaba özel kuponlar yalnızca kullanıcı tarafından elle eklenir ve cihazda kalır. Uygulama giriş bilgisi istemez, hesap içindeki kuponları çekmez, özel uç noktaları çağırmaz, CAPTCHA/bot korumasını aşmaya çalışmaz.

## Kaynak türleri ve öncelik

| Sıra | Kaynak türü | Kapsam | Uygulamadaki etiket | Otomasyon kararı |
|---|---|---|---|---|
| 1 | Kullanıcının elle eklediği kişisel kod | Hesaba/kişiye özel olabilecek kodlar | `Kişisel • doğrulama bekliyor` | Yerel Hive; varsayılan gizli; sunucuya gönderilmez |
| 2 | Resmî, herkese açık kampanya/kupon sayfası | Trendyol kupon havuzu, kampanya sayfası; Yemeksepeti’nin açık kampanya duyuruları; platformun açık şartları | `Resmî açık kampanya` | Sayfa/izinli feed koşulları uygunsa düşük sıklıkta alım; aksi halde uygulama içi bağlantı + kullanıcı doğrulaması |
| 3 | Resmî iş ortağı / affiliate feed veya yazılı izinli API | Ürün, fiyat, kampanya | `İzinli feed` | Küçük backend üzerinden; ham yanıt ve kontrol zamanı saklanır |
| 4 | Satıcı/marka tarafından yayımlanan açık kampanya | Marka veya restoran fırsatları | `Satıcı beyanı` | URL, şart ve son kontrol zamanı zorunlu; otomatik kesin-kupon iddiası yok |
| 5 | Kullanıcı doğrulaması | Kullanıcının kendi sepetinde "çalıştı/çalışmadı" geri bildirimi | `Kişisel deneme` | Sadece yerel varsayılan; kodu değil sonucu saklamak tercih edilir |
| 6 | Üçüncü taraf kupon siteleri / arama sonuçları | Keşif ipucu | `Doğrulanmamış ipucu` | MVP dışında; resmî sayfa ve koşul ile çapraz doğrulanmadan normal listede gösterilmez |

**Platform kararı:** Trendyol, açık kupon/kampanya ekranları sayesinde ilk resmî-açık kaynak adayıdır. Yemeksepeti ve Getir’de kampanyaların kullanıcı, konum, sepet ve üyelik koşullarına göre değişebileceği kabul edilir; açık kampanya kaydı "hesabımda geçerli" anlamına gelmez. Resmî sayfanın bilgisi kampanya olarak saklanır; kod alanı yalnızca açıkça yayımlanmışsa doldurulur.

## Veri sözleşmesi

Mevcut `Coupon` ve `Deal` modelleri korunur; feed katmanına aşağıdaki alanlar eklenir veya yan tabloda tutulur:

- `sourceUrl`, `sourceKind` (`officialPublic`, `partnerFeed`, `manual`, `merchantPublic`), `sourceId`
- `observedAt`, `checkedAt`, `expiresAt`, `availability` (`active`, `expired`, `unknown`)
- `termsText`, `termsHash`, `locationScope`, `newUserOnly`, `membershipRequired`, `minBasket`, `eligibleCategories`
- `requiresAccountCheck` ve `stackingRule` (`unknown`, `notStackable`, `stackable`)
- `evidenceType` (`page`, `feed`, `userReceipt`) ve `parseVersion`

Kod yoksa kayıt `Deal/Campaign` olarak kalır; sahte `couponCode` oluşturulmaz. Her kaydın kaynak URL’si, son kontrol zamanı, şart özeti ve "mağazada kontrol et" bağlantısı gösterilir.

## Güven puanı ve yayın eşiği

Puan 0–100 arasında hesaplanır. Amaç kuponun herkes için geçerli olduğunu tahmin etmek değil, kaydın kanıt ve tazelik kalitesini görünür kılmaktır.

```
source:  resmî açık sayfa 40 | izinli feed 45 | kullanıcı manuel 25 | satıcı açık sayfa 30 | üçüncü taraf 10
freshness: <= 6s 25 | <= 24s 18 | <= 72s 8 | daha eski 0
terms:    son/geçerlilik + koşullar tam 20 | kısmi 8 | yok 0
integrity: kaynak URL + benzersiz kayıt + tutarlı alanlar 10 | kısmi 4 | yok 0
local outcome: bu cihazda yakın zamanda çalıştı 5 | çalışmadı -20 | bilinmiyor 0
```

Kurallar:

- **80–100:** `Yüksek kanıt`; yalnızca resmî/izinli kaynaktan, taze ve koşulları açık kayıt.
- **60–79:** `Kontrol et`; listeye girer fakat kesin geçerlilik etiketi almaz.
- **40–59:** Sadece "İpuçları" sekmesinde; varsayılan ana listede gizli.
- **0–39:** Gösterilmez, kaynak günlüklerinde hata/eskime olarak kalır.
- Süresi geçmiş, `failed` işaretli veya kaynak URL’siz kupon ana listede asla gösterilmez.
- `worked`/`failed` yalnızca bu kullanıcının kendi denemesini ifade eder; global başarı oranı gibi sunulmaz.

Tazelik varsayılanları: kupon/kampanya 12 saat, yemek/market fırsatı 2 saat, ürün fiyatı 6 saat. Süre veya koşul yoksa 24 saati aşan açık-kampanya kaydı otomatik olarak `unknown` olur.

## İlk MVP: iki dikey dilim

### Dilim A — Kişisel kupon kasası (önce)

1. Mevcut manuel kupon formuna kaynak türü, URL/ekran notu, şartlar, bitiş tarihi ve gizlilik varsayılanı eklenir.
2. `Kişisel`, `Resmî açık kampanya` ve `Doğrulanmamış ipucu` sekmeleri ayrılır.
3. Kullanıcı sepet tutarını girer; sadece açık koşulları olan kuponlar için tahmini indirim hesaplanır.
4. Kullanıcı "çalıştı/çalışmadı" seçer; sonuç sadece cihazda güncellenir.
5. Testler: Hive geriye uyumluluğu, gizli kodun dışa aktarılmaması, süresi geçmiş kayıt gizleme, minimum sepet hesaplama, puan eşiği.

**Kabul ölçütü:** Elle girilen kişisel kodlar güvenle saklanır; uygulama hiçbir otomatik kupon uydurmaz; her kayıt neden gösterildiğini açıklar.

### Dilim B — Resmî açık kampanya toplayıcısı (sonra)

1. Tek platformla başlanır: Trendyol’un açık kampanya/kupon sayfaları; yalnızca erişilebilir ve şartları okunabilir kayıtlar.
2. Küçük backend veya kontrollü feed adaptörü yalnızca izinli/halka açık yüzeyden kampanya başlığı, şart, URL ve kontrol zamanını normalize eder. Mobil uygulamaya API anahtarı gömülmez.
3. Backend kayıtları kaynağa göre cache’ler, değişiklikte `termsHash` üretir, hata ve HTTP durumlarını tutar; 403/429/DNS hatasında geri çekilir ve istemciye `kaynak erişilemedi` döner.
4. Uygulama kaynak-bazlı durum kartını gösterir: başarılı kayıt sayısı, son başarılı kontrol, hata nedeni; diğer kaynakların sonucu engellenmez.
5. Kullanıcı platforma giderek son kontrolü yapar; uygulama hesap bağlama veya oturum cookie’si toplamaz.

**Kabul ölçütü:** En az bir açık resmî kampanya kaydı URL, şart, tazelik ve güven puanıyla görünür; kaynak erişilemezse sahte boş olmayan sonuç üretilmez.

## Sonraki sıra

1. Yemeksepeti açık kampanya duyurularını kampanya (kod değil) olarak eklemek.
2. Getir için yalnızca resmî, herkese açık kampanya sayfası veya yazılı izinli feed bulunursa adaptör eklemek.
3. Affiliate/iş ortağı anlaşması varsa ürün-fiyat feed’ini backend’e eklemek; yoksa doğrudan mobil scraping’i büyütmemek.
4. Fiyat geçmişi için yalnızca doğrulanmış feed/URL’den alınan fiyat gözlemlerini saklamak; "en düşük" etiketi için en az iki zaman damgalı gözlem ve aynı ürün eşlemesi istemek.

## Riskler ve önlemler

| Risk | Etki | Önlem |
|---|---|---|
| Hesaba, konuma veya yeni kullanıcı segmentine özel kampanya | Yanıltıcı tasarruf | `requiresAccountCheck`, koşul rozeti, kesin-geçerli etiketi yok |
| Bot koruması, 403/429 veya DNS hatası | Veri kesintisi | Aşma denememek; backoff, cache, kaynak durum kartı ve boş durum |
| HTML/endpoint değişimi | Bozuk ayrıştırma | Adaptör başına sözleşme testi, parse sürümü, hata alarmı; başarısız kaydı yayımlamamak |
| Üçüncü taraf kodların bayat/yanlış olması | Güven kaybı | MVP dışında tutmak; resmî koşul yoksa `ipucu` olarak ayırmak |
| Kişisel kuponun sızması | Gizlilik | Yerel saklama, varsayılan gizleme, analitik/telemetriye kod göndermemek |
| Mobil uygulamadaki API anahtarı | Kötüye kullanım | Anahtarı backend’de tutmak; istemcide yalnızca sınırlı feed endpoint’i |
| Kaynak kullanım şartları | Hukuki/operasyonel risk | Resmî API/affiliate/izin önceliği; robots/şartlara uyum; erişim engelini aşmamak |

## Ölçümleme

MVP’de yalnızca yerel ve anonimleştirilmiş ölçümler: kaynak başarı oranı, son başarılı kontrol yaşı, gösterilen kayıtların puan dağılımı, kullanıcının işaretlediği çalıştı/çalışmadı sayısı. Kupon metni, sepet içeriği, hesap kimliği veya oturum verisi telemetriye yazılmaz.

## Resmî kaynak örnekleri

- Trendyol Mega Kuponlar: `https://www.trendyol.com/s/mega-kuponlar`
- Trendyol Kampanya Detayları: `https://www.trendyol.com/s/kampanya-detaylari`
- Yemeksepeti Ypro duyurusu ve koşulları: `https://kurumsal.yemeksepeti.com/newsroom/yemeksepetinden-sektorde-bir-ilk-ucretsiz-teslimat-ve-tasarruf-ekosistemi-ypro-kullanicilarla-bulusuyor/`
- Getir/Bitaksi kullanım koşulları: `https://static.getir.com/bitaksi/term_of_use_tr`

Bu bağlantılar, yalnızca herkese açık kampanya ve koşul bilgisini değerlendirme başlangıç noktasıdır; kullanıcının hesabındaki kuponlara erişim yetkisi vermez.
