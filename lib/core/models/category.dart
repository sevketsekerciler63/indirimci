import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class DealCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final int dealCount;

  const DealCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.dealCount = 0,
  });

  static List<DealCategory> get allCategories => [
        const DealCategory(
          id: 'food',
          name: 'Yemek',
          icon: Iconsax.cake,
          color: Color(0xFFEF4444),
          dealCount: 42,
        ),
        const DealCategory(
          id: 'market',
          name: 'Market',
          icon: Iconsax.shop,
          color: Color(0xFF10B981),
          dealCount: 67,
        ),
        const DealCategory(
          id: 'baby',
          name: 'Bebek',
          icon: Iconsax.heart,
          color: Color(0xFFF472B6),
          dealCount: 28,
        ),
        const DealCategory(
          id: 'electronics',
          name: 'Elektronik',
          icon: Iconsax.cpu,
          color: Color(0xFF3B82F6),
          dealCount: 54,
        ),
        const DealCategory(
          id: 'fashion',
          name: 'Moda',
          icon: Iconsax.bag_2,
          color: Color(0xFF8B5CF6),
          dealCount: 89,
        ),
        const DealCategory(
          id: 'beauty',
          name: 'Kozmetik',
          icon: Iconsax.brush_1,
          color: Color(0xFFEC4899),
          dealCount: 35,
        ),
        const DealCategory(
          id: 'home',
          name: 'Ev & Yaşam',
          icon: Iconsax.home_2,
          color: Color(0xFFF97316),
          dealCount: 46,
        ),
        const DealCategory(
          id: 'sports',
          name: 'Spor',
          icon: Iconsax.weight,
          color: Color(0xFF06B6D4),
          dealCount: 31,
        ),
      ];
}
