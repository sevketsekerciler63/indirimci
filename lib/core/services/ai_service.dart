import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/deal.dart';
import '../models/coupon.dart';
import '../config/env.dart';
import 'scraper_service.dart';

final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});

class AIService {
  final ScraperService _scraperService = ScraperService();
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.groq.com/openai/v1',
    headers: {'Content-Type': 'application/json'},
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  bool get _hasApiKey => Env.groqApiKey.trim().isNotEmpty;

  /// Groq API'ye chat completion isteği gönder
  Future<String?> _chatCompletion(String systemPrompt, String userMessage,
      {double temperature = 0.7, int maxTokens = 1024}) async {
    if (!_hasApiKey) return null;

    try {
      final response = await _dio.post(
        '/chat/completions',
        options: Options(
          headers: {'Authorization': 'Bearer ${Env.groqApiKey}'},
        ),
        data: {
          'model': Env.groqModel,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'temperature': temperature,
          'max_tokens': maxTokens,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final choices = response.data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          return choices[0]['message']?['content']?.toString();
        }
      }
      return null;
    } on DioException catch (e) {
      debugPrint('AIService: Groq API DioException: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('AIService: Groq API error: $e');
      return null;
    }
  }

  /// AI sohbet yanıtı
  Future<String> askAI(String query) async {
    if (_hasApiKey) {
      try {
        final result = await _chatCompletion(
          'Sen "IndirimCI" uygulamasının yapay zeka asistanısın. '
          'Türkiye\'deki e-ticaret ve yemek platformlarını iyi bilirsin. '
          'Kullanıcı bir ürün veya indirim arıyor. Kısa ve öz yanıt ver (max 2-3 cümle). '
          'Ürünün genel piyasa fiyat aralığını, nerelerden indirimli bulunabileceğini '
          've varsa bildiğin kupon kodu önerilerini belirt.',
          query,
          maxTokens: 256,
        );
        if (result != null && result.isNotEmpty) return result;
      } catch (e) {
        debugPrint('AIService askAI error: $e');
      }
    }
    return _generateLocalSmartResponse(query);
  }

  String _generateLocalSmartResponse(String query) {
    final lowerQuery = query.toLowerCase();
    final platforms = ['Trendyol', 'Amazon TR', 'Hepsiburada', 'N11', 'Migros'];
    final random = Random();
    final p1 = platforms[random.nextInt(platforms.length)];
    var p2 = platforms[random.nextInt(platforms.length)];
    while (p2 == p1) {
      p2 = platforms[random.nextInt(platforms.length)];
    }

    if (lowerQuery.contains('yemek') || lowerQuery.contains('burger') ||
        lowerQuery.contains('pizza') || lowerQuery.contains('döner')) {
      return '🍔 Yemek siparişlerinde Yemeksepeti ve Getir uygulamalarını karşılaştırın. '
          'İlk sipariş kodları ve platform özel kuponları ile %20-40 tasarruf mümkün.';
    }
    if (lowerQuery.contains('bebek') || lowerQuery.contains('mama')) {
      return '🍼 Bebek ürünlerinde $p1 ve $p2 genellikle en iyi fırsatları sunar. '
          'Haftalık kampanyaları takip etmenizi öneririz.';
    }
    if (lowerQuery.contains('elektron') || lowerQuery.contains('telefon') ||
        lowerQuery.contains('laptop')) {
      return '💻 Elektronik ürünlerde $p1 ve $p2 karşılaştırın. '
          'Sezon sonu indirimleri genellikle %15-30 tasarruf sağlar.';
    }
    if (lowerQuery.contains('ayakkab') || lowerQuery.contains('giyim')) {
      return '👟 Giyim ve ayakkabıda $p1 ve $p2 sık sık kampanya düzenler. '
          'Sezon geçişlerinde %40\'a varan indirimler bulabilirsiniz.';
    }
    return '🔍 "$query" için $p1 ve $p2 üzerindeki fırsatları listeliyoruz. '
        'En iyi fiyat için birden fazla platformu karşılaştırmanızı öneririz.';
  }

  // ─────────────────────────────────────────────────────────
  //  ANA ARAMA: Scraping + AI Fallback
  // ─────────────────────────────────────────────────────────
  Future<List<Deal>> searchDealsSmart(String query) async {
    debugPrint('AIService: searchDealsSmart başladı, query="$query"');
    List<Deal> allResults = [];

    // ADIM 1: Scraper ile gerçek sitelerden çek
    try {
      final scrapedDeals = await _scraperService
          .getMultiSiteDeals(query)
          .timeout(const Duration(seconds: 12), onTimeout: () => <Deal>[]);
      allResults.addAll(scrapedDeals);
      debugPrint('AIService: Scraper ${scrapedDeals.length} sonuç döndü');
    } catch (e) {
      debugPrint('AIService: Scraper hata: $e');
    }

    // ADIM 2: Scraper az sonuç döndüyse AI ile tamamla
    if (allResults.length < 3 && _hasApiKey && Env.enableUntrustedData) {
      debugPrint('AIService: Sonuç az, Groq AI devreye giriyor...');
      try {
        final aiDeals = await _generateDealsWithAI(query);
        // Mevcut ID'lerle çakışmayanları ekle
        for (var d in aiDeals) {
          if (!allResults.any((r) => r.title == d.title)) {
            allResults.add(d);
          }
        }
        debugPrint('AIService: AI ${aiDeals.length} sonuç üretti');
      } catch (e) {
        debugPrint('AIService: AI üretim hatası: $e');
      }
    }

    debugPrint('AIService: Toplam ${allResults.length} sonuç');
    return allResults;
  }

  // ─────────────────────────────────────────────────────────
  //  AI İLE KUPON BULMA
  // ─────────────────────────────────────────────────────────
  Future<List<Coupon>> findCouponsWithAI(String platform) async {
    if (!_hasApiKey) return [];

    try {
      final result = await _chatCompletion(
        '''Sen Türkiye'deki e-ticaret kupon uzmanısın. "$platform" platformu için güncel, bilinen ve yaygın kullanılan kupon kodlarını listele.

KURALLAR:
1. SADECE geçerli JSON array döndür
2. Hiçbir açıklama veya markdown YAZMA
3. Gerçekçi ve bilinen kampanya kodları üret
4. Her kupon farklı kategoride olsun

JSON formatı:
[{"code":"KOD123","description":"Açıklama","discountPercent":20,"discountAmount":null,"minOrderAmount":100,"category":"food","isVerified":false}]''',
        'platform: $platform',
        temperature: 0.6,
        maxTokens: 512,
      );

      if (result == null || result.isEmpty) return [];

      String text = result
          .replaceAll('```json', '')
          .replaceAll('```JSON', '')
          .replaceAll('```', '')
          .trim();

      final start = text.indexOf('[');
      final end = text.lastIndexOf(']');
      if (start == -1 || end == -1 || end <= start) return [];
      text = text.substring(start, end + 1);

      final List<dynamic> jsonList = jsonDecode(text);
      return jsonList.map((item) {
        final m = item as Map<String, dynamic>;
        return Coupon(
          id: 'ai_coupon_${DateTime.now().millisecondsSinceEpoch}_${m['code']}',
          code: (m['code'] ?? '').toString(),
          platform: platform,
          description: (m['description'] ?? '').toString(),
          discountPercent: _safeDouble(m['discountPercent']),
          discountAmount: _safeDouble(m['discountAmount']),
          minOrderAmount: _safeDouble(m['minOrderAmount']),
          category: m['category']?.toString(),
          expiryDate: DateTime.now().add(const Duration(days: 7)),
          isVerified: false,
          usageCount: Random().nextInt(5000) + 100,
          successRate: Random().nextInt(30) + 60,
        );
      }).where((c) => c.code.trim().isNotEmpty).toList();
    } catch (e) {
      debugPrint('AIService findCouponsWithAI error: $e');
      return [];
    }
  }

  /// Groq AI ile ürün fırsatları üret
  Future<List<Deal>> _generateDealsWithAI(String query) async {
    final result = await _chatCompletion(
      '''Sen bir e-ticaret uzmanısın. Kullanıcı "$query" arıyor.
Türkiye'deki e-ticaret sitelerinde (Trendyol, Amazon TR, Hepsiburada, Yemeksepeti, Getir) bu ürünle ilgili 5 gerçekçi fırsat üret.

KURALLAR:
1. SADECE geçerli JSON array döndür, başka hiçbir şey yazma
2. Fiyatlar TL cinsinden ve GÜNCEL piyasa fiyatlarına uygun olsun
3. Her ürün farklı platformdan olsun
4. Yemek aramasıysa yemek platformlarını kullan

JSON formatı:
[{"title":"Ürün Adı","description":"Kısa açıklama","platform":"Trendyol","category":"elektronik","originalPrice":1500.0,"discountedPrice":1200.0,"discountPercent":20.0,"url":"https://www.trendyol.com"}]''',
      query,
      temperature: 0.8,
      maxTokens: 1024,
    );

    if (result == null || result.isEmpty) return [];

    String text = result
        .replaceAll('```json', '')
        .replaceAll('```JSON', '')
        .replaceAll('```', '')
        .trim();

    final start = text.indexOf('[');
    final end = text.lastIndexOf(']');
    if (start == -1 || end == -1 || end <= start) return [];
    text = text.substring(start, end + 1);

    final List<dynamic> jsonList = jsonDecode(text);
    final List<Deal> deals = [];

    for (var i = 0; i < jsonList.length; i++) {
      try {
        final item = jsonList[i] as Map<String, dynamic>;
        deals.add(Deal(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}_$i',
          title: (item['title'] ?? query).toString(),
          description: (item['description'] ?? 'AI önerisi').toString(),
          imageUrl: '',
          platform: (item['platform'] ?? 'İnternet').toString(),
          category: (item['category'] ?? 'genel').toString(),
          originalPrice: _safeDouble(item['originalPrice']),
          discountedPrice: _safeDouble(item['discountedPrice']),
          discountPercent: _safeDouble(item['discountPercent']),
          url: (item['url'] ??
                  'https://www.google.com/search?q=${Uri.encodeComponent(query)}')
              .toString(),
          createdAt: DateTime.now(),
        ));
      } catch (e) {
        continue;
      }
    }
    return deals;
  }

  static double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
