import 'package:dio/dio.dart';

abstract class AppException implements Exception {
  final String message;
  AppException(this.message);

  @override
  String toString() => message;
}

class UnauthorizedException extends AppException {
  UnauthorizedException([
    super.message = 'Sesi Anda telah berakhir. Silakan login kembali.',
  ]);
}

class ForbiddenException extends AppException {
  ForbiddenException([
    super.message = 'Anda tidak memiliki hak akses untuk tindakan ini.',
  ]);
}

class ValidationException extends AppException {
  final Map<String, dynamic>? errors;
  ValidationException(super.message, {this.errors});
}

class TimeoutException extends AppException {
  TimeoutException([super.message = 'Koneksi ke server habis waktu.']);
}

class ServerException extends AppException {
  final int statusCode;
  ServerException(super.message, {required this.statusCode});
}

class NetworkException extends AppException {
  NetworkException([super.message = 'Tidak ada koneksi internet.']);
}

class UnknownException extends AppException {
  UnknownException([
    super.message = 'Terjadi kesalahan sistem yang tidak diketahui.',
  ]);
}

class ExceptionMapper {
  static AppException fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException();
      case DioExceptionType.connectionError:
        return NetworkException();
      case DioExceptionType.badResponse:
        final response = error.response;
        final statusCode = response?.statusCode ?? 500;
        final data = response?.data;

        String message = 'Terjadi kesalahan server.';
        Map<String, dynamic>? errors;

        if (data != null && data is Map) {
          message = data['message'] ?? message;
          if (data['errors'] != null && data['errors'] is Map) {
            errors = Map<String, dynamic>.from(data['errors']);
          }
        }

        if (statusCode == 401) {
          return UnauthorizedException(message);
        } else if (statusCode == 403) {
          return ForbiddenException(message);
        } else if (statusCode == 422) {
          return ValidationException(message, errors: errors);
        } else {
          return ServerException(message, statusCode: statusCode);
        }
      case DioExceptionType.cancel:
        return UnknownException('Permintaan dibatalkan.');
      default:
        return UnknownException();
    }
  }
}
