import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme/app_colors.dart';
import '../../core/providers/providers.dart';
import '../product_detail/product_detail_screen.dart';
import '../home/widgets/deal_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounceTimer;

  final _suggestions = [
    'Bebek mamasi',
    'Yemek indirimleri',
    'Elektronik',
    'Spor ayakkabi',
    'Kozmetik',
    'Market firsatlari',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    ref.read(searchQueryProvider.notifier).state = val;
    
    // Debounce: 800ms bekleyip sonra arama yap
    _debounceTimer?.cancel();
    if (val.trim().isEmpty) {
      ref.read(activeSearchQueryProvider.notifier).state = '';
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        ref.read(activeSearchQueryProvider.notifier).state = val.trim();
      }
    });
  }

  void _onSearchSubmitted(String val) {
    _debounceTimer?.cancel();
    if (val.trim().isNotEmpty) {
      ref.read(activeSearchQueryProvider.notifier).state = val.trim();
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        title: const Text('Akilli Arama'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search input
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Ne aramistiniz?',
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  prefixIcon: ShaderMask(
                    shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                    child: const Icon(Iconsax.search_normal_1, color: Colors.white),
                  ),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textTertiary),
                          onPressed: () {
                            _controller.clear();
                            _debounceTimer?.cancel();
                            ref.read(searchQueryProvider.notifier).state = '';
                            ref.read(activeSearchQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                onChanged: _onSearchChanged,
                onSubmitted: _onSearchSubmitted,
                textInputAction: TextInputAction.search,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),

          // AI suggestion chips
          if (query.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ShaderMask(
                        shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                        child: const Icon(Iconsax.magic_star, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Text('AI Onerileri',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _suggestions.asMap().entries.map((entry) {
                      return GestureDetector(
                        onTap: () {
                          _controller.text = entry.value;
                          ref.read(searchQueryProvider.notifier).state = entry.value;
                          ref.read(activeSearchQueryProvider.notifier).state = entry.value;
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.cardDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderDark),
                          ),
                          child: Text(entry.value,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ),
                      ).animate().fadeIn(delay: Duration(milliseconds: 100 * entry.key));
                    }).toList(),
                  ),
                ],
              ),
            ),

          // AI Chat Response
          if (query.isNotEmpty)
            Consumer(
              builder: (context, ref, child) {
                final aiResponse = ref.watch(aiChatResponseProvider);
                return aiResponse.when(
                  data: (text) {
                    if (text.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Iconsax.magic_star, color: AppColors.primaryLight, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                text,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                );
              },
            ),

          // Results
          if (query.isNotEmpty)
            Expanded(
              child: results.when(
                data: (deals) {
                  if (deals.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.search_status, color: AppColors.textTertiary, size: 48),
                          const SizedBox(height: 16),
                          Text('"$query" icin sonuc bulunamadi',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: deals.length,
                    itemBuilder: (context, index) {
                      final deal = deals[index];
                      return DealCard(
                        deal: deal,
                        isFavorite: favorites.any((d) => d.id == deal.id),
                        onFavoriteTap: () => ref.read(favoritesProvider.notifier).toggleFavorite(deal),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ProductDetailScreen(deal: deal)),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                      const SizedBox(height: 16),
                      Text('Arama hatası: $e',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
