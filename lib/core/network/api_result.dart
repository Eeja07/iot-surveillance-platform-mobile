import 'network_exception.dart';

abstract class ApiResult<T> {
  const ApiResult();
}

class ApiSuccess<T> extends ApiResult<T> {
  final T data;
  const ApiSuccess(this.data);
}

class ApiFailure<T> extends ApiResult<T> {
  final AppException exception;
  const ApiFailure(this.exception);
}
