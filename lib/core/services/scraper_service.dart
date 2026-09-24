import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as parser;
import '../models/deal.dart';
import '../models/coupon.dart';

/// Tek bir arama kaynağının (mağaza/sitening) bu aramadaki durumu.
class SearchSourceStatus {
  const SearchSourceStatus({
    required this.name,
    required this.count,
    required this.ok,
    required this.message,
  });

  final String name;
  final int count;
  final bool ok;
  final String message;
}

/// Arama sonucu + hangi kaynağın ne döndürdüğü.
class SearchResultBundle {
  const SearchResultBundle({required this.deals, required this.statuses});
  final List<Deal> deals;
  final List<SearchSourceStatus> statuses;
}

class ScraperService {
  final Dio _dio;

  ScraperService() : _dio = _createDefaultDio();

  ScraperService.withDio(Dio dio) : _dio = dio;

  static Dio _createDefaultDio() {
    return Dio(
      BaseOptions(
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 13; SM-G991B) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          'Accept': 'application/json, text/html, */*;q=0.8',
          'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
        },
        validateStatus: (status) => true,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  ANA FONKSİYON: Birden fazla kaynaktan veri çek
  // ─────────────────────────────────────────────────────────
  Future<List<Deal>> getMultiSiteDeals(String query) async {
    return (await getMultiSiteDealBundle(query)).deals;
  }

  Future<SearchResultBundle> getMultiSiteDealBundle(String query) async {
    if (query.trim().isEmpty) {
      return const SearchResultBundle(deals: [], statuses: []);
    }

    final results = await Future.wait([
      _safeScrapeWithStatus('Trendyol', () => searchTrendyolApi(query)),
      _safeScrapeWithStatus('Cimri', () => searchCimri(query)),
    ]);

    final allDeals = <Deal>[];
    final statuses = <SearchSourceStatus>[];
    for (final result in results) {
      allDeals.addAll(result.deals);
      statuses.addAll(result.statuses);
    }
    return SearchResultBundle(deals: allDeals, statuses: statuses);
  }

  Future<SearchResultBundle> _safeScrapeWithStatus(
    String sourceName,
    Future<List<Deal>> Function() scraper,
  ) async {
    try {
      final deals = await scraper().timeout(
        const Duration(seconds: 12),
        onTimeout: () => throw TimeoutException('Kaynak zaman aşımına uğradı'),
      );
      return SearchResultBundle(
        deals: deals,
        statuses: [
          SearchSourceStatus(
            name: sourceName,
            count: deals.length,
            ok: true,
            message: deals.isEmpty ? 'Sonuç yok' : '${deals.length} sonuç',
          ),
        ],
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final blocked = statusCode == 403 || statusCode == 429;
      return SearchResultBundle(
        deals: const [],
        statuses: [
          SearchSourceStatus(
            name: sourceName,
            count: 0,
            ok: false,
            message: blocked
                ? '$statusCode engellendi'
                : 'Bağlantı hatası: ${e.message ?? 'bilinmiyor'}',
          ),
        ],
      );
    } on TimeoutException {
      return SearchResultBundle(
        deals: const [],
        statuses: [
          SearchSourceStatus(
            name: sourceName,
            count: 0,
            ok: false,
            message: 'Zaman aşımı',
          ),
        ],
      );
    } catch (e) {
      debugPrint('ScraperService _safeScrapeWithStatus error: $e');
      return SearchResultBundle(
        deals: const [],
        statuses: [
          SearchSourceStatus(
            name: sourceName,
            count: 0,
            ok: false,
            message: 'Hata: $e',
          ),
        ],
      );
    }
  }

  // ─────────────────────────────────────────────────────────
  //  TRENDYOL - Public JSON API (en güvenilir)
  // ─────────────────────────────────────────────────────────
  Future<List<Deal>> searchTrendyolApi(String query) async {
    final deals = <Deal>[];
    try {
      final response = await _dio.get(
        'https://public.trendyol.com/discovery-web-searchgw-service/v2/api/infinite-scroll/sr',
        queryParameters: {
          'q': query,
          'pi': 0,
          'culture': 'tr-TR',
          'userGenderId': 1,
          'pId': 0,
          'scoringAlgorithmId': 2,
          'categoryRelevancyEnabled': false,
          'isLegalRequirementConfirmed': false,
          'searchStrategyType': 'DEFAULT',
          'productStampType': 'TypeA',
        },
      );

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
      if (response.data == null) return deals;

      final data = response.data;
      if (data is! Map<String, dynamic>) return deals;

      final result = data['result'] as Map<String, dynamic>?;
      if (result == null) return deals;

      final products = result['products'] as List? ?? [];

      for (var i = 0; i < products.length && i < 10; i++) {
        try {
          final p = products[i] as Map<String, dynamic>;
          final price = p['price'] as Map<String, dynamic>?;
          if (price == null) continue;

          final selling = _toDouble(
            price['sellingPrice'] ?? price['discountedPrice'],
          );
          final original = _toDouble(price['originalPrice']);
          if (selling <= 0) continue;

          final brand =
              (p['brand'] as Map<String, dynamic>?)?['name']?.toString() ?? '';
          final name = p['name']?.toString() ?? '';
          final title = brand.isNotEmpty ? '$brand $name' : name;

          // Resim URL
          String imageUrl = '';
          if (p['imageUrl'] != null) {
            final img = p['imageUrl'].toString();
            imageUrl = img.startsWith('http')
                ? img
                : 'https://cdn.dsmcdn.com/mnresize/200/200/$img';
          } else {
            final images = p['images'] as List?;
            if (images != null && images.isNotEmpty) {
              final img = images[0].toString();
              imageUrl = img.startsWith('http')
                  ? img
                  : 'https://cdn.dsmcdn.com/mnresize/200/200/$img';
            }
          }

          final productUrl = p['url']?.toString() ?? '';
          final fullUrl = productUrl.startsWith('http')
              ? productUrl
              : 'https://www.trendyol.com$productUrl';

          final disc = original > selling
              ? ((original - selling) / original * 100).roundToDouble()
              : 0.0;

          deals.add(
            Deal(
              id: 'ty_${p['id'] ?? i}',
              title: title.trim(),
              description: disc > 0
                  ? 'Trendyol\'da %${disc.toInt()} indirimli!'
                  : 'Trendyol\'da uygun fiyat',
              imageUrl: imageUrl,
              platform: 'Trendyol',
              category: _mapCategory(p['categoryName']?.toString() ?? ''),
              originalPrice: original > 0 ? original : selling,
              discountedPrice: selling,
              discountPercent: disc,
              url: fullUrl,
              createdAt: DateTime.now(),
              source: DataSourceType.scraper,
              fetchedAt: DateTime.now(),
            ),
          );
        } catch (e) {
          continue;
        }
      }
    } on DioException {
      rethrow;
    } catch (e) {
      debugPrint('ScraperService Trendyol API error: $e');
    }
    return deals;
  }

  // ─────────────────────────────────────────────────────────
  //  CİMRİ - Fiyat karşılaştırma sitesi (HTML)
  // ─────────────────────────────────────────────────────────
  Future<List<Deal>> searchCimri(String query) async {
    final deals = <Deal>[];
    try {
      final response = await _dio.get(
        'https://www.cimri.com/arama',
        queryParameters: {'q': query},
      );

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
      if (response.data is! String) {
        return deals;
      }

      final document = parser.parse(response.data as String);
      final items = document.querySelectorAll('[class*="ProductCard"]');

      for (var item in items) {
        try {
          final titleEl = item.querySelector('[class*="ProductName"], h3, a');
          final priceEl = item.querySelector(
            '[class*="Price"], [class*="price"]',
          );
          final imgEl = item.querySelector('img');
          final linkEl = item.querySelector('a');

          if (titleEl == null || priceEl == null) continue;

          final title = titleEl.text.trim();
          if (title.isEmpty) continue;

          String priceText = priceEl.text
              .replaceAll('TL', '')
              .replaceAll('.', '')
              .replaceAll(',', '.')
              .replaceAll(RegExp(r'[^\d.]'), '')
              .trim();
          final price = double.tryParse(priceText) ?? 0.0;
          if (price <= 0) continue;

          final imgUrl =
              imgEl?.attributes['src'] ?? imgEl?.attributes['data-src'] ?? '';
          final href = linkEl?.attributes['href'] ?? '';
          final link = href.startsWith('http')
              ? href
              : 'https://www.cimri.com$href';

          if (deals.length < 5) {
            deals.add(
              Deal(
                id: 'cimri_${link.hashCode}',
                title: title,
                description: 'Cimri fiyat karşılaştırması',
                imageUrl: imgUrl.startsWith('http') ? imgUrl : 'https:$imgUrl',
                platform: 'Cimri',
                category: 'search',
                originalPrice: price,
                discountedPrice: price,
                discountPercent: 0,
                url: link,
                createdAt: DateTime.now(),
                source: DataSourceType.scraper,
                fetchedAt: DateTime.now(),
              ),
            );
          }
        } catch (e) {
          continue;
        }
      }
    } on DioException {
      rethrow;
    } catch (e) {
      debugPrint('ScraperService Cimri error: $e');
    }
    return deals;
  }

  // ─────────────────────────────────────────────────────────
  //  Yardımcılar
  // ─────────────────────────────────────────────────────────
  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  String _mapCategory(String cat) {
    final l = cat.toLowerCase();
    if (l.contains('elektron') ||
        l.contains('telefon') ||
        l.contains('bilgi')) {
      return 'electronics';
    }
    if (l.contains('giyim') || l.contains('ayakkab') || l.contains('moda')) {
      return 'fashion';
    }
    if (l.contains('kozmetik') || l.contains('bakım') || l.contains('parfüm')) {
      return 'beauty';
    }
    if (l.contains('bebek') || l.contains('mama') || l.contains('çocuk')) {
      return 'baby';
    }
    if (l.contains('ev') || l.contains('mutfak') || l.contains('bahçe')) {
      return 'home';
    }
    if (l.contains('market') || l.contains('gıda') || l.contains('süt')) {
      return 'market';
    }
    if (l.contains('yemek') || l.contains('food') || l.contains('restoran')) {
      return 'food';
    }
    return 'genel';
  }
}
