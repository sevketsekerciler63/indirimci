import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/deal.dart';
import '../models/coupon.dart';
import '../models/category.dart';
import '../services/mock_data_service.dart';
import '../services/ai_service.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/search_matcher.dart';
import '../services/scraper_service.dart';
import '../config/env.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService.fromEnv();
});

// ==================== Deals ====================

final dealsProvider = StateNotifierProvider<DealsNotifier, List<Deal>>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return DealsNotifier(apiService);
});

final dealsLoadingProvider = StateProvider<bool>((ref) => true);

class DealsNotifier extends StateNotifier<List<Deal>> {
  final ApiService _apiService;
  List<Deal> _allDeals = [];

  DealsNotifier(this._apiService) : super([]) {
    _loadDeals();
  }

  Future<void> _loadDeals() async {
    try {
      // Önce API'den dene
      final rawDeals = await _apiService.fetchRealDeals();
      if (rawDeals.isNotEmpty) {
        _allDeals = rawDeals.where((deal) => deal.isTrusted).toList();
      }
    } catch (e) {
      debugPrint('DealsNotifier _loadDeals API error: $e');
    }

    // API boş döndüyse mock data kullan (uygulama boş açılmasın)
    if (_allDeals.isEmpty && Env.enableUntrustedData) {
      _allDeals = MockDataService.getDailyDeals();
      debugPrint(
        'DealsNotifier: API boş, mock data yüklendi (${_allDeals.length} ürün)',
      );
    }

    if (mounted) {
      state = _allDeals;
    }
  }

  Future<void> refresh() async {
    try {
      final freshDeals = await _apiService.fetchRealDeals();
      if (freshDeals.isNotEmpty) {
        _allDeals = freshDeals;
      } else {
        // Yenileme boş döndüyse mock güncelle
        _allDeals = Env.enableUntrustedData
            ? MockDataService.getDailyDeals()
            : [];
      }
    } catch (e) {
      debugPrint('DealsNotifier refresh error: $e');
    }
    if (mounted) {
      state = _allDeals;
    }
  }

  void filterByCategory(String categoryId) {
    if (categoryId == 'all') {
      state = _allDeals;
    } else {
      state = _allDeals.where((d) => d.category == categoryId).toList();
    }
  }

  void filterByPlatform(String platform) {
    state = _allDeals.where((d) => d.platform == platform).toList();
  }
}

// ==================== Coupons ====================

final couponsProvider = StateNotifierProvider<CouponsNotifier, List<Coupon>>((
  ref,
) {
  final apiService = ref.read(apiServiceProvider);
  final aiService = ref.read(aiServiceProvider);
  return CouponsNotifier(apiService, aiService);
});

class CouponsNotifier extends StateNotifier<List<Coupon>> {
  final ApiService _apiService;
  final AIService _aiService;
  List<Coupon> _allCoupons = [];

  CouponsNotifier(this._apiService, this._aiService) : super([]) {
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    // Kullanıcının kendi eklediği kuponlar API doğrulaması gerektirmez.
    // Uygulama yeniden açıldığında da kaybolmamaları için önce yerelden al.
    final savedCoupons = StorageService.getCoupons()
        .where((coupon) => coupon.source == DataSourceType.manual)
        .toList();
    _allCoupons = savedCoupons;
    try {
      // Önce API'den dene
      final rawCoupons = await _apiService.fetchCoupons();
      if (rawCoupons.isNotEmpty) {
        final trusted = rawCoupons
            .where((coupon) => coupon.isTrusted())
            .toList();
        for (final coupon in trusted) {
          if (!_allCoupons.any(
            (saved) =>
                saved.platform == coupon.platform && saved.code == coupon.code,
          )) {
            _allCoupons.add(coupon);
          }
        }
      }
    } catch (e) {
      debugPrint('CouponsNotifier _loadCoupons error: $e');
    }

    // API boş döndüyse mock data + AI
    if (_allCoupons.isEmpty && Env.enableUntrustedData) {
      _allCoupons = MockDataService.getCoupons();
      debugPrint('CouponsNotifier: API boş, mock kuponlar yüklendi');

      // Arka planda AI'dan da kupon bulmaya çalış
      _loadAICoupons();
    }

    if (mounted) {
      state = _allCoupons;
    }
  }

  Future<void> _loadAICoupons() async {
    try {
      final platforms = ['Trendyol', 'Yemeksepeti', 'Hepsiburada', 'Getir'];
      for (var platform in platforms) {
        final aiCoupons = await _aiService.findCouponsWithAI(platform);
        if (aiCoupons.isNotEmpty) {
          // Mevcut kodlarla çakışanları filtrele
          final newCoupons = aiCoupons
              .where(
                (c) => !_allCoupons.any((existing) => existing.code == c.code),
              )
              .toList();
          _allCoupons.addAll(newCoupons);
        }
      }
      if (mounted) {
        state = List.from(_allCoupons);
      }
    } catch (e) {
      debugPrint('CouponsNotifier AI coupons error: $e');
    }
  }

  void filterByPlatform(String platform) {
    if (platform == 'all') {
      state = _allCoupons;
    } else {
      state = _allCoupons.where((c) => c.platform == platform).toList();
    }
  }

  Future<void> updateStatus(Coupon coupon, CouponStatus status) async {
    final updated = coupon.copyWithCheckedStatus(status);
    _allCoupons = _allCoupons
        .map((item) => item.id == coupon.id ? updated : item)
        .toList();
    if (mounted) state = List.from(_allCoupons);
    await StorageService.saveCoupon(updated);
  }

  Future<void> addManualCoupon(Coupon coupon) async {
    _allCoupons = [
      coupon,
      ..._allCoupons.where((item) => item.id != coupon.id),
    ];
    if (mounted) state = List.from(_allCoupons);
    await StorageService.saveCoupon(coupon);
  }

  void filterByCategory(String categoryId) {
    if (categoryId == 'all') {
      state = _allCoupons;
    } else {
      state = _allCoupons.where((c) => c.category == categoryId).toList();
    }
  }
}

// ==================== Categories ====================

final categoriesProvider = Provider<List<DealCategory>>((ref) {
  return DealCategory.allCategories;
});

// ==================== Selected Category ====================

final selectedCategoryProvider = StateProvider<String>((ref) => 'all');

// ==================== Search & AI ====================

final searchQueryProvider = StateProvider<String>((ref) => '');

/// Kullanıcının arama butonuna bastığında tetiklenen aktif sorgu
final activeSearchQueryProvider = StateProvider<String>((ref) => '');

final aiChatResponseProvider = FutureProvider<String>((ref) async {
  final query = ref.watch(activeSearchQueryProvider);
  if (query.isEmpty) return '';

  try {
    final aiService = ref.read(aiServiceProvider);
    return await aiService.askAI(query);
  } catch (e) {
    debugPrint('aiChatResponseProvider error: $e');
    return 'Bir hata oluştu, tekrar deneyin.';
  }
});

/// ARAMA: AI + Scraper birleşik sonuç ve kaynak durumları
final searchResultBundleProvider = FutureProvider<SearchResultBundle>((
  ref,
) async {
  final query = ref.watch(activeSearchQueryProvider);
  if (query.isEmpty) {
    return const SearchResultBundle(deals: [], statuses: []);
  }

  try {
    final aiService = ref.read(aiServiceProvider);
    final currentDeals = ref.read(dealsProvider);
    final smartBundle = await aiService.searchDealsSmartBundle(query);
    final smartResults = smartBundle.deals
        .where((deal) => deal.isTrusted)
        .toList();

    // Lokal deal'lerde de arama yap ve ekle
    final lowerQuery = query.toLowerCase();
    final localMatches = currentDeals.where((deal) {
      return deal.title.toLowerCase().contains(lowerQuery) ||
          deal.description.toLowerCase().contains(lowerQuery) ||
          deal.category.toLowerCase().contains(lowerQuery) ||
          deal.platform.toLowerCase().contains(lowerQuery);
    }).toList();

    // Birleştir (çakışma olmasın)
    final allResults = <Deal>[...smartResults];
    for (var local in localMatches) {
      if (!allResults.any((d) => d.id == local.id || d.title == local.title)) {
        allResults.add(local);
      }
    }

    return SearchResultBundle(
      deals: SearchMatcher.rank(query, allResults),
      statuses: smartBundle.statuses,
    );
  } catch (e) {
    debugPrint('searchResultBundleProvider error: $e');
    // Hata olursa sadece lokal arama
    final lowerQuery = query.toLowerCase();
    final currentDeals = ref.read(dealsProvider);
    final localMatches = currentDeals.where((deal) {
      return deal.title.toLowerCase().contains(lowerQuery) ||
          deal.description.toLowerCase().contains(lowerQuery);
    });
    return SearchResultBundle(
      deals: SearchMatcher.rank(query, localMatches),
      statuses: [
        SearchSourceStatus(
          name: 'Arama',
          count: 0,
          ok: false,
          message: 'Hata: $e',
        ),
      ],
    );
  }
});

final searchResultsProvider = FutureProvider<List<Deal>>((ref) async {
  return (await ref.watch(searchResultBundleProvider.future)).deals;
});

// ==================== Favorites ====================

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<Deal>>((
  ref,
) {
  return FavoritesNotifier();
});

class FavoritesNotifier extends StateNotifier<List<Deal>> {
  FavoritesNotifier() : super([]) {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    try {
      final saved = StorageService.getFavorites();
      if (mounted) {
        state = saved;
      }
    } catch (e) {
      debugPrint('FavoritesNotifier: Storage okuma hatası: $e');
    }
  }

  void toggleFavorite(Deal deal) {
    if (state.any((d) => d.id == deal.id)) {
      state = state.where((d) => d.id != deal.id).toList();
    } else {
      state = [...state, deal];
    }
    _saveToStorage();
  }

  Future<void> _saveToStorage() async {
    try {
      await StorageService.saveFavorites(state);
    } catch (e) {
      debugPrint('FavoritesNotifier: Storage yazma hatası: $e');
    }
  }

  bool isFavorite(String dealId) {
    return state.any((d) => d.id == dealId);
  }
}

// ==================== Savings ====================

final totalSavingsProvider = Provider<double>((ref) {
  final favorites = ref.watch(favoritesProvider);
  return favorites.fold(0.0, (sum, deal) => sum + deal.savingsAmount);
});

// ==================== Navigation ====================

final selectedTabProvider = StateProvider<int>((ref) => 0);

// ==================== Price History ====================

final priceHistoryProvider = Provider<List<PriceHistory>>((ref) {
  // Doğrulanmış, ürün kimliğine bağlı fiyat geçmişi eklenene kadar
  // mock geçmişi gerçek ürün ekranında göstermeyiz.
  return const [];
});
