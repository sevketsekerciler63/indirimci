import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:indirimci/core/services/scraper_service.dart';

void main() {
  test('scraper preserves HTTP source failures instead of reporting no results', () async {
    final dio = Dio(
      BaseOptions(
        validateStatus: (status) => true,
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 403,
              ),
              type: DioExceptionType.badResponse,
            ),
          );
        },
      ),
    );

    final scraper = ScraperService.withDio(dio);
    final bundle = await scraper.getMultiSiteDealBundle('kalem');

    expect(bundle.deals, isEmpty);
    expect(bundle.statuses, hasLength(2));
    expect(bundle.statuses.every((status) => status.ok), isFalse);
    expect(
      bundle.statuses.every((status) => status.message.contains('403')),
      isTrue,
    );
  });
}
