enum DataSourceType {
  officialApi,
  affiliateFeed,
  scraper,
  manual,
  mock,
  unknown,
}

enum CouponStatus { unknown, worked, failed }

class Coupon {
  final String id;
  final String code;
  final String platform;
  final String description;
  final double? discountAmount;
  final double? discountPercent;
  final double? minOrderAmount;
  final String? category;
  final DateTime? expiryDate;
  final bool isVerified;
  final int usageCount;
  final int successRate;
  final bool isHidden; // Gizli kupon kodu
  final DataSourceType source;
  final DateTime? verifiedAt;
  final DateTime? lastCheckedAt;
  final CouponStatus status;

  const Coupon({
    required this.id,
    required this.code,
    required this.platform,
    required this.description,
    this.discountAmount,
    this.discountPercent,
    this.minOrderAmount,
    this.category,
    this.expiryDate,
    this.isVerified = false,
    this.usageCount = 0,
    this.successRate = 0,
    this.isHidden = false,
    this.source = DataSourceType.unknown,
    this.verifiedAt,
    this.lastCheckedAt,
    this.status = CouponStatus.unknown,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'code': code,
    'platform': platform,
    'description': description,
    'discountAmount': discountAmount,
    'discountPercent': discountPercent,
    'minOrderAmount': minOrderAmount,
    'category': category,
    'expiryDate': expiryDate?.toIso8601String(),
    'isVerified': isVerified,
    'usageCount': usageCount,
    'successRate': successRate,
    'isHidden': isHidden,
    'source': source.name,
    'verifiedAt': verifiedAt?.toIso8601String(),
    'lastCheckedAt': lastCheckedAt?.toIso8601String(),
    'status': status.name,
  };

  factory Coupon.fromMap(Map<dynamic, dynamic> map) => Coupon(
    id: map['id']?.toString() ?? '',
    code: map['code']?.toString() ?? '',
    platform: map['platform']?.toString() ?? '',
    description: map['description']?.toString() ?? '',
    discountAmount: _double(map['discountAmount']),
    discountPercent: _double(map['discountPercent']),
    minOrderAmount: _double(map['minOrderAmount']),
    category: map['category']?.toString(),
    expiryDate: _date(map['expiryDate']),
    isVerified: map['isVerified'] == true,
    usageCount: map['usageCount'] is num
        ? (map['usageCount'] as num).toInt()
        : 0,
    successRate: map['successRate'] is num
        ? (map['successRate'] as num).toInt()
        : 0,
    isHidden: map['isHidden'] == true,
    source: DataSourceType.values.firstWhere(
      (e) => e.name == map['source'],
      orElse: () => DataSourceType.unknown,
    ),
    verifiedAt: _date(map['verifiedAt']),
    lastCheckedAt: _date(map['lastCheckedAt']),
    status: CouponStatus.values.firstWhere(
      (e) => e.name == map['status'],
      orElse: () => CouponStatus.unknown,
    ),
  );

  Coupon copyWith({
    CouponStatus? status,
    DateTime? lastCheckedAt,
    bool? isVerified,
    int? usageCount,
    int? successRate,
    DateTime? verifiedAt,
  }) => Coupon(
    id: id,
    code: code,
    platform: platform,
    description: description,
    discountAmount: discountAmount,
    discountPercent: discountPercent,
    minOrderAmount: minOrderAmount,
    category: category,
    expiryDate: expiryDate,
    isVerified: isVerified ?? this.isVerified,
    usageCount: usageCount ?? this.usageCount,
    successRate: successRate ?? this.successRate,
    isHidden: isHidden,
    source: source,
    verifiedAt: verifiedAt ?? this.verifiedAt,
    lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    status: status ?? this.status,
  );

  Coupon copyWithCheckedStatus(CouponStatus newStatus, {DateTime? checkedAt}) {
    final now = checkedAt ?? DateTime.now();
    final nextUsageCount = usageCount + 1;
    final previousWorkedCount = (usageCount * successRate / 100).round();
    final nextWorkedCount = newStatus == CouponStatus.worked
        ? previousWorkedCount + 1
        : previousWorkedCount;
    final nextSuccessRate = nextUsageCount == 0
        ? 0
        : ((nextWorkedCount / nextUsageCount) * 100).round();

    return copyWith(
      status: newStatus,
      lastCheckedAt: now,
      verifiedAt: newStatus == CouponStatus.worked ? now : verifiedAt,
      isVerified: newStatus == CouponStatus.worked,
      usageCount: nextUsageCount,
      successRate: nextSuccessRate,
    );
  }

  static double? _double(dynamic value) =>
      value == null ? null : double.tryParse(value.toString());
  static DateTime? _date(dynamic value) =>
      value == null ? null : DateTime.tryParse(value.toString());

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  String get maskedCode {
    if (!isHidden) return code;
    final trimmed = code.trim();
    if (trimmed.length <= 4) return '••••';
    final prefix = trimmed.substring(0, 3);
    final suffix = trimmed.substring(trimmed.length - 3);
    final hiddenLength = trimmed.length - prefix.length - suffix.length;
    return '$prefix${'*' * hiddenLength}$suffix';
  }

  String get discountText {
    if (discountPercent != null) {
      return '%${discountPercent!.toStringAsFixed(0)} İndirim';
    }
    if (discountAmount != null) {
      return '${discountAmount!.toStringAsFixed(0)}₺ İndirim';
    }
    return 'İndirim';
  }

  Duration? get remainingTime {
    if (expiryDate == null) return null;
    final diff = expiryDate!.difference(DateTime.now());
    return diff.isNegative ? null : diff;
  }

  bool isFresh({Duration maxAge = const Duration(hours: 12)}) {
    if (lastCheckedAt == null) return false;
    return DateTime.now().difference(lastCheckedAt!) <= maxAge;
  }

  bool isTrusted({Duration maxAge = const Duration(hours: 12)}) {
    return isVerified && !isExpired && isFresh(maxAge: maxAge);
  }
}
