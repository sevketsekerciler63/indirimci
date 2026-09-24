import 'coupon.dart';

class Deal {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String platform;
  final String category;
  final double originalPrice;
  final double discountedPrice;
  final double discountPercent;
  final String? couponCode;
  final String url;
  final DateTime? expiryDate;
  final bool isFlashDeal;
  final bool isHot;
  final DateTime createdAt;
  final DataSourceType source;
  final DateTime? fetchedAt;

  const Deal({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.platform,
    required this.category,
    required this.originalPrice,
    required this.discountedPrice,
    required this.discountPercent,
    this.couponCode,
    required this.url,
    this.expiryDate,
    this.isFlashDeal = false,
    this.isHot = false,
    required this.createdAt,
    this.source = DataSourceType.unknown,
    this.fetchedAt,
  });

  double get savingsAmount => originalPrice - discountedPrice;

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'platform': platform,
      'category': category,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'discountPercent': discountPercent,
      'couponCode': couponCode,
      'url': url,
      'expiryDate': expiryDate?.toIso8601String(),
      'isFlashDeal': isFlashDeal,
      'isHot': isHot,
      'createdAt': createdAt.toIso8601String(),
      'source': source.name,
      'fetchedAt': fetchedAt?.toIso8601String(),
    };
  }

  factory Deal.fromMap(Map<dynamic, dynamic> map) {
    return Deal(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Bilinmeyen Ürün',
      description: map['description']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      platform: map['platform']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      originalPrice: _parseDouble(map['originalPrice']),
      discountedPrice: _parseDouble(map['discountedPrice']),
      discountPercent: _parseDouble(map['discountPercent']),
      couponCode: map['couponCode']?.toString(),
      url: map['url']?.toString() ?? '',
      expiryDate: _parseDate(map['expiryDate']),
      isFlashDeal: map['isFlashDeal'] == true,
      isHot: map['isHot'] == true,
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      source: _parseSource(map['source']),
      fetchedAt: _parseDate(map['fetchedAt']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  static DataSourceType _parseSource(dynamic value) {
    final raw = value?.toString() ?? '';
    for (final item in DataSourceType.values) {
      if (item.name == raw) return item;
    }
    return DataSourceType.unknown;
  }

  bool isFresh({Duration maxAge = const Duration(hours: 6)}) {
    if (fetchedAt == null) return false;
    return DateTime.now().difference(fetchedAt!) <= maxAge;
  }

  bool get hasTrustedSource =>
      source == DataSourceType.officialApi ||
      source == DataSourceType.affiliateFeed ||
      source == DataSourceType.scraper;

  bool get isTrusted =>
      hasTrustedSource &&
      discountedPrice > 0 &&
      (originalPrice <= 0 || originalPrice >= discountedPrice) &&
      isFresh();
}

class PriceHistory {
  final DateTime date;
  final double price;
  final String platform;

  const PriceHistory({
    required this.date,
    required this.price,
    required this.platform,
  });
}
