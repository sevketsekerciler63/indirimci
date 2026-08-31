import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme/app_colors.dart';
import '../../core/providers/providers.dart';
import 'widgets/coupon_card.dart';
import '../../core/models/coupon.dart';

class CouponsScreen extends ConsumerStatefulWidget {
  const CouponsScreen({super.key});

  @override
  ConsumerState<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends ConsumerState<CouponsScreen> {
  String _selectedPlatform = 'all';

  final _platforms = [
    'all',
    'Trendyol',
    'Yemeksepeti',
    'Getir',
    'Hepsiburada',
    'Migros',
    'Amazon TR',
  ];

  @override
  Widget build(BuildContext context) {
    final coupons = ref.watch(couponsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        title: Row(
          children: [
            const Icon(
              Iconsax.ticket_discount,
              color: AppColors.accent,
              size: 24,
            ),
            const SizedBox(width: 10),
            const Text('Kupon Kodlari'),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Platform filter
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              itemCount: _platforms.length,
              itemBuilder: (context, index) {
                final p = _platforms[index];
                final isSelected = _selectedPlatform == p;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedPlatform = p);
                    ref.read(couponsProvider.notifier).filterByPlatform(p);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.primaryGradient : null,
                      color: isSelected ? null : AppColors.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? null
                          : Border.all(color: AppColors.borderDark),
                    ),
                    child: Center(
                      child: Text(
                        p == 'all' ? 'Tumunu' : p,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 50 * index));
              },
            ),
          ),

          const SizedBox(height: 16),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Kuponlar mağazada denenmeden kesin geçerli kabul edilmez.',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
            ),
          ),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildStatChip(
                  icon: Iconsax.ticket_star,
                  label: '${coupons.length} Kupon',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                _buildStatChip(
                  icon: Iconsax.verify,
                  label:
                      '${coupons.where((c) => c.isVerified).length} Doğrulandı',
                  color: AppColors.warning,
                ),
                const SizedBox(width: 10),
                _buildStatChip(
                  icon: Iconsax.clock,
                  label:
                      '${coupons.where((c) => c.remainingTime != null).length} Güncel',
                  color: AppColors.success,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 16),

          // Coupons list
          Expanded(
            child: coupons.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.ticket_expired,
                          color: AppColors.textTertiary,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Dogrulanmis ve guncel kupon bulunamadi',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: coupons.length,
                    itemBuilder: (context, index) => CouponCard(
                      coupon: coupons[index],
                      onStatusChanged: (status) => ref
                          .read(couponsProvider.notifier)
                          .updateStatus(coupons[index], status),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCouponDialog,
        icon: const Icon(Iconsax.add),
        label: const Text('Kupon ekle'),
      ),
    );
  }

  Future<void> _showAddCouponDialog() async {
    final code = TextEditingController();
    final platform = TextEditingController(text: 'Manuel');
    final discount = TextEditingController();
    final minimum = TextEditingController();
    var isPercent = true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Kendi kuponunu ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Kupon kodu'),
                ),
                TextField(
                  controller: platform,
                  decoration: const InputDecoration(labelText: 'Mağaza'),
                ),
                DropdownButtonFormField<bool>(
                  initialValue: isPercent,
                  decoration: const InputDecoration(labelText: 'İndirim türü'),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Yüzde (%)')),
                    DropdownMenuItem(value: false, child: Text('Tutar (₺)')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => isPercent = value ?? true),
                ),
                TextField(
                  controller: discount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'İndirim değeri',
                  ),
                ),
                TextField(
                  controller: minimum,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Minimum sepet (isteğe bağlı)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
    if (result != true || code.text.trim().isEmpty) return;
    final value = double.tryParse(discount.text.replaceAll(',', '.'));
    if (value == null || value <= 0) return;
    final min = double.tryParse(minimum.text.replaceAll(',', '.'));
    final coupon = Coupon(
      id: 'manual_${DateTime.now().microsecondsSinceEpoch}',
      code: code.text.trim().toUpperCase(),
      platform: platform.text.trim().isEmpty ? 'Manuel' : platform.text.trim(),
      description: 'Kullanıcının eklediği kupon',
      discountPercent: isPercent ? value : null,
      discountAmount: isPercent ? null : value,
      minOrderAmount: min,
      source: DataSourceType.manual,
      lastCheckedAt: DateTime.now(),
    );
    await ref.read(couponsProvider.notifier).addManualCoupon(coupon);
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
