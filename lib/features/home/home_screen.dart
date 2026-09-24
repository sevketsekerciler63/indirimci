import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme/app_colors.dart';
import '../../core/providers/providers.dart';
import '../product_detail/product_detail_screen.dart';
import 'widgets/deal_card.dart';
import 'widgets/category_chip.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deals = ref.watch(dealsProvider);
    final dealsLoadState = ref.watch(dealsLoadStateProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final categories = ref.watch(categoriesProvider);
    final favorites = ref.watch(favoritesProvider);
    final totalSavings = ref.watch(totalSavingsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.cardDark,
        onRefresh: () async {
          await ref.read(dealsProvider.notifier).refresh();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            _buildAppBar(ref, totalSavings),
            _buildSearchBar(ref),
            _buildCategories(ref, categories, selectedCategory),
            _buildSectionTitle(deals.length, dealsLoadState),
            _buildDealsList(
              deals,
              favorites,
              ref,
              dealsLoadState,
              selectedCategory,
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(WidgetRef ref, double totalSavings) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.bgDark,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.bgDarkTertiary, AppColors.bgDark],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              AppColors.primaryGradient.createShader(bounds),
                          child: const Text(
                            'IndirimCI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ).animate().fadeIn(duration: 600.ms),
                        const Text(
                          'En iyi firsatlar, AI destekli',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.savingsGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Iconsax.money_recive,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${totalSavings.toStringAsFixed(0)} TL',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(WidgetRef ref) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: GestureDetector(
          onTap: () => ref.read(selectedTabProvider.notifier).state = 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Row(
              children: [
                ShaderMask(
                  shaderCallback: (b) =>
                      AppColors.primaryGradient.createShader(b),
                  child: const Icon(
                    Iconsax.search_normal_1,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Indirim ara... "Bebek mamasi?"',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Iconsax.microphone,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 300.ms),
      ),
    );
  }

  Widget _buildCategories(WidgetRef ref, List categories, String selected) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const BouncingScrollPhysics(),
          children: [
            AllCategoryChip(
              isSelected: selected == 'all',
              onTap: () {
                ref.read(selectedCategoryProvider.notifier).state = 'all';
                ref.read(dealsProvider.notifier).filterByCategory('all');
              },
            ),
            ...categories.map(
              (cat) => CategoryChip(
                category: cat,
                isSelected: selected == cat.id,
                onTap: () {
                  ref.read(selectedCategoryProvider.notifier).state = cat.id;
                  ref.read(dealsProvider.notifier).filterByCategory(cat.id);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(int count, DealsLoadState loadState) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Row(
          children: [
            const Icon(
              Icons.local_fire_department,
              color: AppColors.accent,
              size: 22,
            ),
            const SizedBox(width: 8),
            const Text(
              'Günün Doğrulanmış Fırsatları',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color:
                    (loadState.isLoading ? AppColors.warning : AppColors.accent)
                        .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: loadState.isLoading
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      '$count',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ).animate().fadeIn(delay: 500.ms),
      ),
    );
  }

  Widget _buildDealsList(
    List deals,
    List favorites,
    WidgetRef ref,
    DealsLoadState loadState,
    String selectedCategory,
  ) {
    if (deals.isEmpty) {
      final isCategoryEmpty = selectedCategory != 'all' && loadState.hasLoaded;
      final message = loadState.isLoading
          ? loadState.message
          : isCategoryEmpty
          ? 'Bu kategoride güncel ve doğrulanmış fırsat yok.'
          : loadState.message;
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                if (loadState.isLoading)
                  const CircularProgressIndicator(color: AppColors.primary)
                else
                  const Icon(
                    Iconsax.search_status,
                    color: AppColors.textTertiary,
                    size: 48,
                  ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
                if (!loadState.isLoading && selectedCategory == 'all') ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Sahte veya kaynağı belirsiz fiyat gösterilmiyor. Arama sekmesinde kaynakların durumunu ayrı ayrı görebilirsin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final deal = deals[index];
          return DealCard(
            deal: deal,
            isFavorite: favorites.any((d) => d.id == deal.id),
            onFavoriteTap: () =>
                ref.read(favoritesProvider.notifier).toggleFavorite(deal),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(deal: deal),
                ),
              );
            },
          );
        }, childCount: deals.length),
      ),
    );
  }
}
