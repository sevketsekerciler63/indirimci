import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/deal.dart';
import '../models/coupon.dart';

abstract class OfficialDealSource {
  Future<List<Deal>> fetchDeals();
}

abstract class OfficialCouponSource {
  Future<List<Coupon>> fetchCoupons();
}

class EmptyOfficialDealSource implements OfficialDealSource {
  @override
  Future<List<Deal>> fetchDeals() async => [];
}

class EmptyOfficialCouponSource implements OfficialCouponSource {
  @override
  Future<List<Coupon>> fetchCoupons() async => [];
}

class CompositeOfficialDealSource implements OfficialDealSource {
  CompositeOfficialDealSource(this.sources);
  final List<OfficialDealSource> sources;

  @override
  Future<List<Deal>> fetchDeals() async {
    final all = <Deal>[];
    for (final source in sources) {
      try {
        all.addAll(await source.fetchDeals());
      } catch (e) {
        debugPrint('CompositeOfficialDealSource error: $e');
      }
    }
    final seen = <String>{};
    return all.where((deal) {
      final key = '${deal.platform}:${deal.id}:${deal.url}';
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();
  }
}

class CompositeOfficialCouponSource implements OfficialCouponSource {
  CompositeOfficialCouponSource(this.sources);
  final List<OfficialCouponSource> sources;

  @override
  Future<List<Coupon>> fetchCoupons() async {
    final all = <Coupon>[];
    for (final source in sources) {
      try {
        all.addAll(await source.fetchCoupons());
      } catch (e) {
        debugPrint('CompositeOfficialCouponSource error: $e');
      }
    }
    final seen = <String>{};
    return all.where((coupon) {
      final key = '${coupon.platform}:${coupon.code}';
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();
  }
}

class HttpJsonDealSource implements OfficialDealSource {
  HttpJsonDealSource({
    required this.endpoint,
    required this.platform,
    this.authToken,
    Dio? dio,
  }) : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  final Dio _dio;
  final String endpoint;
  final String platform;
  final String? authToken;

  @override
  Future<List<Deal>> fetchDeals() async {
    if (endpoint.trim().isEmpty) return [];
    final response = await _dio.get(
      endpoint,
      options: Options(
        headers: authToken == null || authToken!.isEmpty
            ? null
            : {'Authorization': 'Bearer $authToken'},
      ),
    );
    if (response.statusCode != 200) return [];
    final payload = response.data;
    final rows = _extractList(payload, preferredKey: 'deals');

    return rows.map((row) {
      final now = DateTime.now();
      final discounted = _parseDouble(row['discountedPrice']);
      final original = _parseDouble(row['originalPrice']);
      final discountPercent = row['discountPercent'] == null
          ? (original > 0 ? ((original - discounted) / original) * 100 : 0.0)
          : _parseDouble(row['discountPercent']);
      return Deal(
        id: (row['id'] ?? '${platform}_${row['url'] ?? ''}').toString(),
        title: (row['title'] ?? '').toString(),
        description: (row['description'] ?? '').toString(),
        imageUrl: (row['imageUrl'] ?? '').toString(),
        platform: (row['platform'] ?? platform).toString(),
        category: (row['category'] ?? 'genel').toString(),
        originalPrice: original,
        discountedPrice: discounted,
        discountPercent: discountPercent,
        couponCode: row['couponCode']?.toString(),
        url: (row['url'] ?? '').toString(),
        expiryDate: _parseDate(row['expiryDate']),
        createdAt: _parseDate(row['createdAt']) ?? now,
      );
    }).where((d) => d.title.trim().isNotEmpty && d.url.trim().isNotEmpty).toList();
  }
}

class HttpJsonCouponSource implements OfficialCouponSource {
  HttpJsonCouponSource({
    required this.endpoint,
    required this.platform,
    this.authToken,
    Dio? dio,
  }) : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  final Dio _dio;
  final String endpoint;
  final String platform;
  final String? authToken;

  @override
  Future<List<Coupon>> fetchCoupons() async {
    if (endpoint.trim().isEmpty) return [];
    final response = await _dio.get(
      endpoint,
      options: Options(
        headers: authToken == null || authToken!.isEmpty
            ? null
            : {'Authorization': 'Bearer $authToken'},
      ),
    );
    if (response.statusCode != 200) return [];
    final payload = response.data;
    final rows = _extractList(payload, preferredKey: 'coupons');

    return rows.map((row) {
      return Coupon(
        id: (row['id'] ?? '${platform}_${row['code'] ?? ''}').toString(),
        code: (row['code'] ?? '').toString(),
        platform: (row['platform'] ?? platform).toString(),
        description: (row['description'] ?? '').toString(),
        discountAmount: _parseDoubleNullable(row['discountAmount']),
        discountPercent: _parseDoubleNullable(row['discountPercent']),
        minOrderAmount: _parseDoubleNullable(row['minOrderAmount']),
        category: row['category']?.toString(),
        expiryDate: _parseDate(row['expiryDate']),
        isVerified: row['isVerified'] == true,
        usageCount: _parseInt(row['usageCount']),
        successRate: _parseInt(row['successRate']),
        isHidden: row['isHidden'] == true,
      );
    }).where((c) => c.code.trim().isNotEmpty).toList();
  }
}

List<Map<String, dynamic>> _extractList(
    dynamic payload, {required String preferredKey}) {
  if (payload is List) {
    return payload.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
  if (payload is Map<String, dynamic>) {
    final dynamic nestedData = payload['data'];
    final dynamic rows = payload[preferredKey] ??
        payload['items'] ??
        payload['offers'] ??
        (nestedData is Map<String, dynamic>
            ? (nestedData[preferredKey] ?? nestedData['items'] ?? nestedData['offers'])
            : nestedData);
    if (rows is List) {
      return rows.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
  }
  return const [];
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  try {
    return DateTime.parse(value.toString());
  } catch (_) {
    return null;
  }
}

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

double? _parseDoubleNullable(dynamic value) {
  if (value == null) return null;
  return _parseDouble(value);
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

class ApiService {
  ApiService({
    OfficialDealSource? dealSource,
    OfficialCouponSource? couponSource,
  })  : _dealSource = dealSource ?? EmptyOfficialDealSource(),
        _couponSource = couponSource ?? EmptyOfficialCouponSource();

  final OfficialDealSource _dealSource;
  final OfficialCouponSource _couponSource;

  factory ApiService.fromEnv() {
    // Şu an harici API endpoint yok, boş source'larla başlat
    // İleride gerçek API endpoint'leri eklenince burası güncellenecek
    return ApiService(
      dealSource: EmptyOfficialDealSource(),
      couponSource: EmptyOfficialCouponSource(),
    );
  }

  Future<List<Deal>> fetchRealDeals() async {
    try {
      return await _dealSource.fetchDeals().timeout(
            const Duration(seconds: 15),
            onTimeout: () => <Deal>[],
          );
    } catch (e) {
      debugPrint('ApiService fetchRealDeals error: $e');
      return [];
    }
  }

  Future<List<Coupon>> fetchCoupons() async {
    try {
      return await _couponSource.fetchCoupons().timeout(
            const Duration(seconds: 15),
            onTimeout: () => <Coupon>[],
          );
    } catch (e) {
      debugPrint('ApiService fetchCoupons error: $e');
      return [];
    }
  }
}
