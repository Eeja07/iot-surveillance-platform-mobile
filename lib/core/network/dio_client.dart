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
