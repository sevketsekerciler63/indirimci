import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../core/models/deal.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalSavings = ref.watch(totalSavingsProvider);
    final deals = ref.watch(dealsProvider);
    final coupons = ref.watch(couponsProvider);
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        title: Row(
          children: [
            const Icon(Iconsax.chart_2, color: AppColors.primaryLight, size: 24),
            const SizedBox(width: 10),
            const Text('Tasarruf Paneli'),
          ],
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Total savings card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.savingsGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('Toplam Tasarruf',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    '${totalSavings.toStringAsFixed(0)} TL',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.trending_up, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(favorites.isEmpty ? 'Firsat ekle' : '${favorites.length} favori urun',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95)),

            const SizedBox(height: 20),

            // Stats row
            Row(
              children: [
                _buildStatCard(
                  icon: Iconsax.shopping_bag,
                  label: 'Firsatlar',
                  value: '${deals.length}',
                  color: AppColors.accent,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Iconsax.ticket_discount,
                  label: 'Kuponlar',
                  value: '${coupons.length}',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Iconsax.heart,
                  label: 'Favoriler',
                  value: '${favorites.length}',
                  color: AppColors.error,
                ),
              ],
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 24),

            // Chart title
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Kategori Dagilimi',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),

            // Pie chart
            if (favorites.isEmpty)
              Container(
                height: 200,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: const Text('Henüz favori ürününüz yok.', style: TextStyle(color: AppColors.textSecondary)),
              ).animate().fadeIn(delay: 400.ms)
            else
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: _generatePieChartData(favorites),
                    sectionsSpace: 3,
                    centerSpaceRadius: 40,
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 24),

            // Recent activity
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Son Aktiviteler (Favoriler)',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),

            if (favorites.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Aktivite bulunamadı.', style: TextStyle(color: AppColors.textSecondary)),
              )
            else
              ...favorites.take(5).map((deal) => _buildActivityItem(
                icon: Iconsax.heart,
                title: 'Favorilere eklendi',
                subtitle: deal.title,
                color: AppColors.error,
                time: '${deal.savingsAmount.toStringAsFixed(0)} TL Tasarruf',
              )),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _generatePieChartData(List<Deal> favorites) {
    if (favorites.isEmpty) return [];

    final categoryCounts = <String, int>{};
    for (var deal in favorites) {
      categoryCounts[deal.category] = (categoryCounts[deal.category] ?? 0) + 1;
    }

    final colors = [
      const Color(0xFFEF4444),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFFF97316),
    ];

    final sections = <PieChartSectionData>[];
    int colorIndex = 0;

    categoryCounts.forEach((category, count) {
      final percentage = (count / favorites.length) * 100;
      sections.add(
        PieChartSectionData(
          value: percentage,
          color: colors[colorIndex % colors.length],
          title: category.toUpperCase(),
          radius: 60,
          titleStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
        ),
      );
      colorIndex++;
    });

    return sections;
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(time,
                style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.05);
  }
}
