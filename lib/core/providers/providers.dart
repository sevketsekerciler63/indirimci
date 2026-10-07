import 'dart:async';

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

final storageServiceProvider = Provider<StorageRepository>((ref) {
  return StorageService.shared;
});

// ==================== Deals ====================

class DealsLoadState {
  const DealsLoadState({
    required this.isLoading,
    required this.hasLoaded,
    required this.message,
  });

  const DealsLoadState.loading()
    : isLoading = true,
      hasLoaded = false,
      message = 'Doğrulanmış fırsatlar kontrol ediliyor.';

  final bool isLoading;
  final bool hasLoaded;
  final String message;
}

final dealsLoadStateProvider = StateProvider<DealsLoadState>(
  (ref) => const DealsLoadState.loading(),
);

final dealsProvider = StateNotifierProvider<DealsNotifier, List<Deal>>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return DealsNotifier(apiService, ref);
});

class DealsNotifier extends StateNotifier<List<Deal>> {
  final ApiService _apiService;
  final Ref _ref;
  List<Deal> _allDeals = [];

  DealsNotifier(this._apiService, this._ref) : super([]) {
    _loadDeals();
  }

  List<Deal> _trustedDeals(Iterable<Deal> deals) {
    return deals.where((deal) => deal.isTrusted).toList();
  }

  void _publishLoadState({required bool sourceReturnedRows}) {
    _ref.read(dealsLoadStateProvider.notifier).state = DealsLoadState(
      isLoading: false,
      hasLoaded: true,
      message: _allDeals.isNotEmpty
          ? '${_allDeals.length} güncel ve doğrulanmış fırsat gösteriliyor.'
          : sourceReturnedRows
          ? 'Kaynak yanıt verdi ancak güncel ve doğrulanmış fırsat bulunamadı.'
          : 'Bağlı ve doğrulanmış fırsat kaynağı henüz yok.',
    );
  }

  Future<void> _loadDeals() async {
    _ref.read(dealsLoadStateProvider.notifier).state =
        const DealsLoadState.loading();
    var sourceReturnedRows = false;
    try {
      final rawDeals = await _apiService.fetchRealDeals();
      sourceReturnedRows = rawDeals.isNotEmpty;
      _allDeals = _trustedDeals(rawDeals);
    } catch (e) {
      debugPrint('DealsNotifier _loadDeals API error: $e');
      _allDeals = [];
    }

    if (_allDeals.isEmpty && Env.enableUntrustedData) {
      _allDeals = MockDataService.getDailyDeals();
      debugPrint(
        'DealsNotifier: API boş, mock data yüklendi (${_allDeals.length} ürün)',
      );
    }

    if (mounted) {
      state = _allDeals;
      _publishLoadState(sourceReturnedRows: sourceReturnedRows);
    }
  }

  Future<void> refresh() async {
    _ref.read(dealsLoadStateProvider.notifier).state =
        const DealsLoadState.loading();
    var sourceReturnedRows = false;
    try {
      final freshDeals = await _apiService.fetchRealDeals();
      sourceReturnedRows = freshDeals.isNotEmpty;
      _allDeals = _trustedDeals(freshDeals);
      if (_allDeals.isEmpty && Env.enableUntrustedData) {
        _allDeals = MockDataService.getDailyDeals();
      }
    } catch (e) {
      debugPrint('DealsNotifier refresh error: $e');
      _allDeals = [];
    }
    if (mounted) {
      state = _allDeals;
      _publishLoadState(sourceReturnedRows: sourceReturnedRows);
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
  final storage = ref.read(storageServiceProvider);
  return CouponsNotifier(apiService, aiService, storage: storage);
});

class CouponsNotifier extends StateNotifier<List<Coupon>> {
  final ApiService _apiService;
  final AIService _aiService;
  final StorageRepository _storage;
  List<Coupon> _allCoupons = [];

  CouponsNotifier(
    this._apiService,
    this._aiService, {
    StorageRepository? storage,
  }) : _storage = storage ?? StorageService.shared,
       super([]) {
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    // Kullanıcının kendi eklediği kuponlar API doğrulaması gerektirmez.
    // Uygulama yeniden açıldığında da kaybolmamaları için önce yerelden al.
    try {
      _allCoupons = (await _storage.loadCoupons())
          .where((coupon) => coupon.source == DataSourceType.manual)
          .toList();
    } catch (e) {
      debugPrint('CouponsNotifier yerel kupon okuma hatası: $e');
    }
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
    final next = _allCoupons
        .map((item) => item.id == coupon.id ? updated : item)
        .toList();
    await _storage.saveCoupon(updated);
    _allCoupons = next;
    if (mounted) state = List.from(_allCoupons);
  }

  Future<void> addManualCoupon(Coupon coupon) async {
    final next = [coupon, ..._allCoupons.where((item) => item.id != coupon.id)];
    await _storage.saveCoupon(coupon);
    _allCoupons = next;
    if (mounted) state = List.from(_allCoupons);
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
  return FavoritesNotifier(storage: ref.read(storageServiceProvider));
});

class FavoritesNotifier extends StateNotifier<List<Deal>> {
  FavoritesNotifier({StorageRepository? storage})
    : _storage = storage ?? StorageService.shared,
      super([]) {
    _operations = _loadFromStorage();
  }

  final StorageRepository _storage;
  late Future<void> _operations;

  Future<void> _loadFromStorage() async {
    try {
      final saved = await _storage.loadFavorites();
      if (mounted) {
        state = saved;
      }
    } catch (e) {
      debugPrint('FavoritesNotifier: Storage okuma hatası: $e');
    }
  }

  Future<void> toggleFavorite(Deal deal) async {
    final completer = Completer<void>();
    _operations = _operations.then((_) async {
      try {
        final next = state.any((d) => d.id == deal.id)
            ? state.where((d) => d.id != deal.id).toList()
            : [...state, deal];
        await _storage.saveFavorites(next);
        if (mounted) state = next;
        completer.complete();
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
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
