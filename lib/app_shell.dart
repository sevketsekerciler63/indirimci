import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iconsax/iconsax.dart';
import 'config/theme/app_colors.dart';
import 'core/providers/providers.dart';
import 'features/home/home_screen.dart';
import 'features/search/search_screen.dart';
import 'features/coupons/coupons_screen.dart';
import 'features/favorites/favorites_screen.dart';
import 'features/dashboard/dashboard_screen.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedTabProvider);

    final screens = [
      const HomeScreen(),
      const SearchScreen(),
      const CouponsScreen(),
      const FavoritesScreen(),
      const DashboardScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.bgDarkSecondary,
          border: const Border(
            top: BorderSide(color: AppColors.borderDark, width: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                _buildNavItem(
                  ref: ref,
                  index: 0,
                  selectedIndex: selectedIndex,
                  icon: Iconsax.home_2,
                  activeIcon: Iconsax.home_15,
                  label: 'Ana Sayfa',
                ),
                _buildNavItem(
                  ref: ref,
                  index: 1,
                  selectedIndex: selectedIndex,
                  icon: Iconsax.search_normal_1,
                  activeIcon: Iconsax.search_normal,
                  label: 'Arama',
                ),
                _buildNavItem(
                  ref: ref,
                  index: 2,
                  selectedIndex: selectedIndex,
                  icon: Iconsax.ticket_discount,
                  activeIcon: Iconsax.ticket_discount,
                  label: 'Kuponlar',
                  showBadge: true,
                ),
                _buildNavItem(
                  ref: ref,
                  index: 3,
                  selectedIndex: selectedIndex,
                  icon: Iconsax.heart,
                  activeIcon: Iconsax.heart,
                  label: 'Favoriler',
                ),
                _buildNavItem(
                  ref: ref,
                  index: 4,
                  selectedIndex: selectedIndex,
                  icon: Iconsax.chart_2,
                  activeIcon: Iconsax.chart_21,
                  label: 'Panel',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required WidgetRef ref,
    required int index,
    required int selectedIndex,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    bool showBadge = false,
  }) {
    final isSelected = index == selectedIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(selectedTabProvider.notifier).state = index,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? activeIcon : icon,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textTertiary,
                    size: 24,
                  ),
                  if (showBadge)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textTertiary,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
