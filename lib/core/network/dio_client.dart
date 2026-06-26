import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'dio_interceptor.dart';
import 'network_exception.dart';
import 'api_result.dart';

class DioClient {
  final Dio _dio;

  DioClient({required AppConfig config, required DioInterceptor interceptor})
    : _dio = Dio(
        BaseOptions(
          baseUrl: config.apiBaseUrl,
          connectTimeout: Duration(milliseconds: config.connectTimeoutMs),
          receiveTimeout: Duration(milliseconds: config.receiveTimeoutMs),
        ),
      ) {
    _dio.interceptors.add(interceptor);
    _dio.interceptors.add(RetryInterceptor(dio: _dio));
  }

  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return ApiSuccess(response.data as T);
    } on DioException catch (e) {
      return ApiFailure(ExceptionMapper.fromDioError(e));
    } catch (e) {
      return ApiFailure(UnknownException(e.toString()));
    }
  }

  Future<ApiResult<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return ApiSuccess(response.data as T);
    } on DioException catch (e) {
      return ApiFailure(ExceptionMapper.fromDioError(e));
    } catch (e) {
      return ApiFailure(UnknownException(e.toString()));
    }
  }

  Future<ApiResult<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return ApiSuccess(response.data as T);
    } on DioException catch (e) {
      return ApiFailure(ExceptionMapper.fromDioError(e));
    } catch (e) {
      return ApiFailure(UnknownException(e.toString()));
    }
  }

  Future<ApiResult<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return ApiSuccess(response.data as T);
    } on DioException catch (e) {
      return ApiFailure(ExceptionMapper.fromDioError(e));
    } catch (e) {
      return ApiFailure(UnknownException(e.toString()));
    }
  }

  Future<ApiResult<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return ApiSuccess(response.data as T);
    } on DioException catch (e) {
      return ApiFailure(ExceptionMapper.fromDioError(e));
    } catch (e) {
      return ApiFailure(UnknownException(e.toString()));
    }
  }
}

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration retryInterval;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.retryInterval = const Duration(seconds: 1),
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = err.requestOptions;

    final isNetworkError =
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError;

    if (!isNetworkError) {
      return super.onError(err, handler);
    }

    final extra = requestOptions.extra;
    final int retryCount = (extra['retry_count'] ?? 0) as int;

    if (retryCount < maxRetries) {
      final nextRetryCount = retryCount + 1;
      requestOptions.extra['retry_count'] = nextRetryCount;

      final delay = retryInterval * nextRetryCount;
      await Future.delayed(delay);

      try {
        final response = await dio.fetch(requestOptions);
        return handler.resolve(response);
      } on DioException catch (e) {
        return super.onError(e, handler);
      }
    }

    return super.onError(err, handler);
  }
}
