import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/models/deal.dart';
import '../../../core/models/coupon.dart';

class DealCard extends StatelessWidget {
  final Deal deal;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;

  const DealCard({
    super.key,
    required this.deal,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteTap,
  });

  Color _getPlatformColor() {
    switch (deal.platform.toLowerCase()) {
      case 'trendyol':
        return AppColors.trendyol;
      case 'hepsiburada':
        return AppColors.hepsiburada;
      case 'amazon tr':
        return AppColors.amazonTR;
      case 'migros':
        return AppColors.migros;
      case 'yemeksepeti':
        return AppColors.yemeksepeti;
      case 'getir':
        return AppColors.getir;
      default:
        return AppColors.primary;
    }
  }

  String _sourceLabel() {
    switch (deal.source) {
      case DataSourceType.officialApi:
        return 'Resmî kaynak';
      case DataSourceType.affiliateFeed:
        return 'Affiliate feed';
      case DataSourceType.scraper:
        return 'Scraper';
      case DataSourceType.manual:
        return 'Manuel';
      case DataSourceType.mock:
        return 'Demo veri';
      case DataSourceType.unknown:
        return 'Kaynak belirtilmedi';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderDark, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    color: AppColors.bgDarkSecondary,
                    child: deal.imageUrl.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  color: AppColors.textTertiary,
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  deal.platform,
                                  style: TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Image.network(
                            deal.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: AppColors.textTertiary,
                                size: 40,
                              ),
                            ),
                          ),
                  ),
                ),
                // Discount badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppColors.fireGradient,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.error.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '%${deal.discountPercent.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Platform badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _getPlatformColor(),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      deal.platform,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Share button
                Positioned(
                  bottom: 12,
                  right: 52,
                  child: GestureDetector(
                    onTap: () {
                      final shareText = 
                          '🔥 İndirim Yakaladım!\n\n'
                          '📦 ${deal.title}\n'
                          '💰 ${deal.discountedPrice.toStringAsFixed(2)} TL (Piyasa: ${deal.originalPrice.toStringAsFixed(2)} TL)\n\n'
                          'Link: ${deal.url}\n\n'
                          'İndirimci App ile bulundu.';
                      Share.share(shareText);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.bgDark.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: const Icon(
                        Icons.share,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                // Favorite button
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: onFavoriteTap,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.bgDark.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? AppColors.error : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                // Flash deal indicator
                if (deal.isFlashDeal)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flash_on, color: Colors.white, size: 12),
                          SizedBox(width: 2),
                          Text(
                            'Flash',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            // Info Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deal.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    deal.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_sourceLabel()}${deal.fetchedAt == null ? '' : ' • Son kontrol: ${deal.fetchedAt!.day.toString().padLeft(2, '0')}.${deal.fetchedAt!.month.toString().padLeft(2, '0')} ${deal.fetchedAt!.hour.toString().padLeft(2, '0')}:${deal.fetchedAt!.minute.toString().padLeft(2, '0')}'}',
                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 10),
                  ),
                  const SizedBox(height: 12),
                  // Price row
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Text(
                          '${deal.discountedPrice.toStringAsFixed(2)}₺',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${deal.originalPrice.toStringAsFixed(2)}₺',
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 14,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${deal.savingsAmount.toStringAsFixed(0)}₺ kazanç',
                            style: const TextStyle(
                              color: AppColors.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Coupon code row
                  if (deal.couponCode != null) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: deal.couponCode!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${deal.couponCode} kopyalandı!'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.content_copy, color: AppColors.primaryLight, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              deal.couponCode!,
                              style: const TextStyle(
                                color: AppColors.primaryLight,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'KOPYALA',
                                style: TextStyle(
                                  color: AppColors.primaryLight,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}
