import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/models/coupon.dart';

class CouponCard extends StatelessWidget {
  final Coupon coupon;
  final VoidCallback? onTap;
  final ValueChanged<CouponStatus>? onStatusChanged;

  const CouponCard({
    super.key,
    required this.coupon,
    this.onTap,
    this.onStatusChanged,
  });

  Color _getPlatformColor() {
    switch (coupon.platform.toLowerCase()) {
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

  String _getRemainingTimeText() {
    final remaining = coupon.remainingTime;
    if (remaining == null) return 'Süresi dolmuş';
    if (remaining.inDays > 0) return '${remaining.inDays} gün kaldı';
    if (remaining.inHours > 0) return '${remaining.inHours} saat kaldı';
    return '${remaining.inMinutes} dakika kaldı';
  }

  @override
  Widget build(BuildContext context) {
    final platformColor = _getPlatformColor();

    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: coupon.code));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('${coupon.code} kopyalandı!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left colored bar
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: platformColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: platform + badge
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: platformColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              coupon.platform,
                              style: TextStyle(
                                color: platformColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (coupon.isVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified,
                                    color: AppColors.success,
                                    size: 12,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Doğrulanmış',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (coupon.isHidden) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.visibility_off,
                                    color: AppColors.warning,
                                    size: 12,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Gizli',
                                    style: TextStyle(
                                      color: AppColors.warning,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          Text(
                            coupon.status == CouponStatus.worked
                                ? 'Çalıştı'
                                : coupon.status == CouponStatus.failed
                                ? 'Çalışmadı'
                                : 'Durum bilinmiyor',
                            style: TextStyle(
                              color: coupon.status == CouponStatus.worked
                                  ? AppColors.success
                                  : AppColors.warning,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Discount text
                      Text(
                        coupon.discountText,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        coupon.description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      if (coupon.minOrderAmount != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Min. sipariş: ${coupon.minOrderAmount!.toStringAsFixed(0)}₺',
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (onStatusChanged != null)
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          runSpacing: 8,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  onStatusChanged!(CouponStatus.worked),
                              child: const Text('Çalıştı'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  onStatusChanged!(CouponStatus.failed),
                              child: const Text('Çalışmadı'),
                            ),
                          ],
                        ),
                      // Bottom row: code + expiry
                      Row(
                        children: [
                          // Code
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bgDark,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  coupon.code,
                                  style: const TextStyle(
                                    color: AppColors.primaryLight,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.content_copy,
                                  color: AppColors.primaryLight,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                          // Expiry
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color:
                                    coupon.remainingTime != null &&
                                        coupon.remainingTime!.inHours < 24
                                    ? AppColors.error
                                    : AppColors.textTertiary,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getRemainingTimeText(),
                                style: TextStyle(
                                  color:
                                      coupon.remainingTime != null &&
                                          coupon.remainingTime!.inHours < 24
                                      ? AppColors.error
                                      : AppColors.textTertiary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0);
  }
}
