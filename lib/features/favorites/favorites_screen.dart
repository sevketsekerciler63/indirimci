import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme/app_colors.dart';
import '../../core/providers/providers.dart';
import '../product_detail/product_detail_screen.dart';
import '../home/widgets/deal_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        title: Row(
          children: [
            const Icon(Iconsax.heart, color: AppColors.error, size: 24),
            const SizedBox(width: 10),
            const Text('Favorilerim'),
          ],
        ),
        centerTitle: false,
        actions: [
          if (favorites.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${favorites.length} urun',
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: const Icon(Iconsax.heart, color: AppColors.textTertiary, size: 48),
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 20),
                  const Text(
                    'Henuz favori yok',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 8),
                  const Text(
                    'Begendigniz firsatlari kalbine dokunarak\nfavorilere ekleyin!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ).animate().fadeIn(delay: 300.ms),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final deal = favorites[index];
                return DealCard(
                  deal: deal,
                  isFavorite: true,
                  onFavoriteTap: () => ref.read(favoritesProvider.notifier).toggleFavorite(deal),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProductDetailScreen(deal: deal)),
                    );
                  },
                );
              },
            ),
    );
  }
}
