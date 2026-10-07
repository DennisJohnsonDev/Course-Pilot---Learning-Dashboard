import 'package:dio/dio.dart';

import '../error/app_failure.dart';

AppFailure mapDioException(DioException exception) {
  return switch (exception.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => const TimeoutFailure(),
    DioExceptionType.connectionError => const NetworkFailure(),
    DioExceptionType.badResponse => _mapResponse(exception.response),
    DioExceptionType.cancel ||
    DioExceptionType.badCertificate ||
    DioExceptionType.unknown => const UnknownFailure(),
  };
}

AppFailure _mapResponse(Response<Object?>? response) {
  final statusCode = response?.statusCode;
  final message = switch (response?.data) {
    {'message': final String message} => message,
    _ => null,
  };

  if (statusCode == 401) {
    return message == null
        ? const UnauthorizedFailure()
        : UnauthorizedFailure(message);
  }

  return message == null
      ? ServerFailure(statusCode: statusCode)
      : ServerFailure(message: message, statusCode: statusCode);
}
