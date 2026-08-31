# Official Feed JSON Schema

Bu dokuman, tum platformlarin ayni formatta veri vermesi icin referans semadir.
Uygulama yalnizca guvenilir ve dogrulanmis veriyi gosterir.

## Genel Yanit Formatlari

Asagidaki 3 form da desteklenir:

1) Dogrudan liste
```json
[ ... ]
```

2) Ust seviyede anahtar
```json
{
  "coupons": [ ... ],
  "deals": [ ... ]
}
```

3) Data envelope
```json
{
  "data": {
    "coupons": [ ... ],
    "deals": [ ... ]
  }
}
```

Not: `items` veya `offers` anahtari da fallback olarak desteklenir.

## Coupon Item Alani

```json
{
  "id": "ys_123",
  "code": "YEMEK50",
  "platform": "Yemeksepeti",
  "description": "250 TL uzeri sipariste 50 TL indirim",
  "discountAmount": 50.0,
  "discountPercent": null,
  "minOrderAmount": 250.0,
  "category": "food",
  "expiryDate": "2026-05-06T20:00:00Z",
  "isVerified": true,
  "usageCount": 4200,
  "successRate": 94,
  "isHidden": false,
  "verifiedAt": "2026-05-04T12:00:00Z",
  "lastCheckedAt": "2026-05-04T14:55:00Z"
}
```

Zorunluya yakin alanlar:
- `code`
- `isVerified`
- `expiryDate`
- `lastCheckedAt`

## Deal Item Alani

```json
{
  "id": "ys_deal_1",
  "title": "Burger menu kampanyasi",
  "description": "Belirli restoranda ozel fiyat",
  "imageUrl": "https://cdn.example.com/deal.png",
  "platform": "Yemeksepeti",
  "category": "food",
  "originalPrice": 260.0,
  "discountedPrice": 199.0,
  "discountPercent": 23.46,
  "couponCode": "YEMEK50",
  "url": "https://www.yemeksepeti.com/...",
  "expiryDate": "2026-05-06T20:00:00Z",
  "createdAt": "2026-05-04T12:00:00Z",
  "fetchedAt": "2026-05-04T14:55:00Z",
  "isFlashDeal": true,
  "isHot": true
}
```

Zorunluya yakin alanlar:
- `title`
- `url`
- `originalPrice`
- `discountedPrice`
- `fetchedAt`

## Guvenilirlik Kurallari (Uygulama Tarafi)

Kuponun listelenmesi icin:
- `isVerified == true`
- `expiryDate` gecmemis olmali
- `lastCheckedAt` guncel olmali (varsayilan tazelik: 12 saat)

Deal'in listelenmesi icin:
- `source != unknown`
- `fetchedAt` guncel olmali (varsayilan tazelik: 6 saat)

## Platform Bazli Endpoint Onerisi

- `/feeds/yemeksepeti/coupons`
- `/feeds/yemeksepeti/deals`
- `/feeds/getir/coupons`
- `/feeds/getir/deals`
- `/feeds/trendyol/coupons`
- `/feeds/trendyol/deals`
- `/feeds/hepsiburada/coupons`
- `/feeds/hepsiburada/deals`
- `/feeds/amazontr/coupons`
- `/feeds/amazontr/deals`
- `/feeds/migros/coupons`
- `/feeds/migros/deals`
