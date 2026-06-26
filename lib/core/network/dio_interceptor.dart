import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import '../logger/logger.dart';
import '../di/injection.dart';

class DioInterceptor extends Interceptor {
  final SecureStorage _secureStorage;
  final Logger _logger;

  DioInterceptor({required SecureStorage secureStorage, required Logger logger})
    : _secureStorage = secureStorage,
      _logger = logger;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';

    final savedToken = await _secureStorage.read('auth_token');
    if (savedToken != null && savedToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $savedToken';
    }

    _logger.debug('--> HTTP REQUEST: ${options.method} ${options.uri}');
    _logger.debug('Headers: ${options.headers}');
    if (options.data != null) {
      _logger.debug('Body: ${options.data}');
    }

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.debug(
      '<-- HTTP RESPONSE: ${response.statusCode} ${response.requestOptions.uri}',
    );
    if (response.data != null) {
      _logger.debug('Response Body: ${response.data}');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.error(
      '--- HTTP ERROR: ${err.response?.statusCode} ${err.requestOptions.uri}',
    );
    _logger.error('Error Message: ${err.message}', err.error, err.stackTrace);
    if (err.response?.statusCode == 401) {
      try {
        AppLocator.instance.sessionService.expireSession();
      } catch (_) {}
    }
    super.onError(err, handler);
  }
}
